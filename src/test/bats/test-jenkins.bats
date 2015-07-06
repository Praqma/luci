#! /usr/bin/env bats

load utils
source $LUCI_ROOT/functions/ssh-keys
source $LUCI_ROOT/functions/docker-functions
source $LUCI_ROOT/functions/web-functions
jPort=10080

waitForLine() {
    # We need to listen to the Jenkins output
    # and wait untill both Jenkins and the jnlp
    # is up af running. Set timeToRun in seconds
    # to break a timeout.
    local breakPoint=$1
    local timeToRun=$2

    local startTime=$(date +%s)
    local endTime=$(($startTime+$timeToRun))


    while read line; do
        if [ $(date +%s) -gt $endTime ]; then
          echo "Time out! ($timeToRun seconds waiting for '$breakPoint')"
          return 2
        fi
        case "$line" in
            *"$breakPoint"*) #TODO cleanup
                echo "Breakpoint found [$(date)]"
                return 0
                ;;
            *)
                ;;
        esac
    done
    echo "No more lines to read!"
    return 1
}

startJenkinsMaster(){
  local jcidReturnVar=$1
  local keyDir=$2
  local jenkinsHome=$3
  local jeninsPort=$4
  local jenkinsName=$5

  #Start the Jenkins Server container with link to the data container that holds the SSH-keys.
  #local _jcid=$(runZettaTools docker run -v $keyDir:/data/praqma-ssh-key -v $jenkinsHome:/var/jenkins_home -d -p $jeninsPort:8080 -p 50000:50000 $jenkinsName)
  local _jcid=$(runZettaTools docker run -v $keyDir:/data/praqma-ssh-key -d -p $jeninsPort:8080 -p 50000:50000 $jenkinsName)
  cleanup_container $_jcid

  #We have to wait for the Jenkins Server to get started. Not just the server
  #but also the Jnlp service
  waitForJenkinsRunning $_jcid
  eval "$jcidReturnVar=$_jcid"
}

waitForJenkinsRunning() {
    dockerLogs $1 | waitForLine "setting agent port for jnlp" 120
    #runZettaTools docker logs -f -t $1 | processLines
    local rc=$?
    return $rc
}

runJenkinsCli() {
    #A function to run commands on the Jenkins Server through jenkins-cli.jar
    local cli=$1
    shift
    java -jar "$cli" -s http://$LUCI_DOCKER_HOST:$jPort -noKeyAuth "$@"
}

@test "Running Jenkins container" {
#Prepare
    local tmpdir=$(tempdir)
    local keydir=$tmpdir/keys

    #We generate new SSH-keys into the tmpdir subfolder "keys" These are then Unsed
    #by the data container to supply both the Jenkins server and slave
    generateSshKey $keydir "SSH-key-for-LUCI"

    #The data image is build and the container is created to house the SSH-keys
    buildDockerImage $LUCI_ROOT/src/main/remotedocker/data/context/ luci-data
    jdcid=$(createDockerKeyImage $keydir luci-data)
    #jdcid=$(runZettaTools docker create -v $keydir/id_rsa.pub:/data/server-keys/authorized_keys luci-data)

    #The Jenkins Slave container is build.
    buildDockerImage $LUCI_ROOT/src/main/remotedocker/jenkins-slaves/shell/context/ luci-shell-slave

    # TODO Jenkins seems not to start if jenkins_home is on shared drive in boot2docker.
    # So if we are using boot2docker create a temp dir on the boot2docker host, and use that as jenkins_home
    if type boot2docker > /dev/null 2>&1 ; then
        jenkins_home=$(boot2docker ssh mktemp -d)
    else
        #Init a variable to house the jenkins_home folder. The home folder needs to be created here.
        #Else, it will be created by a container, by root and jenkins then cant access it.
        local jenkins_home=$(mktemp -d)/home
        mkdir $jenkins_home
    fi

    #The Jenkins Server config.xml file is created dynamicly to incorporate the docker-plugin.
    #This way its configured on startup automaticly. Its placed in JENKINS_HOME and removed after
    #Jenkins is build. The Dockerfile will take care of the config.xml.
    $LUCI_ROOT/bin/generateJenkinsConfigXml.sh $jdcid $LUCI_DOCKER_HOST $LUCI_DOCKER_PORT > $LUCI_ROOT/src/main/remotedocker/jenkins/context/config.xml

    $LUCI_ROOT/bin/generateJenkinsLocateConfiguration.sh $LUCI_DOCKER_HOST $jPort heh@praqma.net > $LUCI_ROOT/src/main/remotedocker/jenkins/context/jenkins.model.JenkinsLocationConfiguration.xml

    buildDockerImage $LUCI_ROOT/src/main/remotedocker/jenkins/context/ luci-jenkins

    #Cleanup
    rm -f $LUCI_ROOT/src/main/remotedocker/jenkins/context/config.xml
    rm -f $LUCI_ROOT/src/main/remotedocker/jenkins/context/jenkins.model.JenkinsLocationConfiguration.xml

    #Verify
    echo "Jenkins home is : $jenkins_home"
    startJenkinsMaster jcid $keydir $jenkins_home $jPort "luci-jenkins"
    echo "jcid is now : $jcid"

    echo "starting tests"
    #Check if the Jenkins Server webpage is responding OK
    isWebsiteUp $LUCI_DOCKER_HOST $jPort

    #Starting a Jenkins Slave, with ssh-keys from the data container
    echo "Starting Jenkins Slave"
    jscid=$(runZettaTools docker run --volumes-from=$jdcid -d luci-shell-slave)
    cleanup_container $jscid

    #Is Jenkins container running?
    echo "Is container running?"
    [ $(isContainerRunning $jcid) = "0" ]

    #Get the IP adress of the Jenkins Slave container, and SSH to it from the
    #Jenkins Master contianer with ssh keys
    jsip=$(runZettaTools docker inspect --format '{{ .NetworkSettings.IPAddress }}' $jscid)
    runZettaTools docker exec $jcid ssh -i /data/praqma-ssh-key/id_rsa -oStrictHostKeyChecking=no jenkins@$jsip env

    #Set location for jenkins-cli.jar
    local cli=$tmpdir/cli.jar

    #Download the jarfile from the Jenkins server
    wget http://$LUCI_DOCKER_HOST:$jPort/jnlpJars/jenkins-cli.jar -O "$cli"


    #Set the shell command for the job and create it on the Jenkins server
    createJenkinsShellJob "env" $cli "luci-shell"
    #Build the shell job
    runJenkinsCli $cli build luci-shell
    #Wait for the job to finish
    dockerLogs $jcid | waitForLine "luci-shell #1 main build" 30
    #Check if the shell job had a success string in the output
    runZettaTools curl -s http://$LUCI_DOCKER_HOST:$jPort/job/luci-shell/1/consoleText | grep -q "SUCCESS"

    #Call the function createJenkinsDockerJob to create the job
    createJenkinsDockerJob "env" "shell" $cli "luci-docker"
    #Build the docker job
    runJenkinsCli $cli build luci-docker
    #Wait for the job to finish
    dockerLogs $jcid | waitForLine "luci-docker #1 main build" 300
    #Check if the simple job had a success string in the output
    runZettaTools curl -s http://$LUCI_DOCKER_HOST:$jPort/job/luci-docker/1/consoleText | grep -q "SUCCESS"


#Use this, to pause the test before end. This way you can load jenkins in  a browser and test things out.
#read -p "Press [Enter] key to continue..."
}

teardown() {
    cleanup_perform
}
