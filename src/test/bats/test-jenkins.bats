#! /usr/bin/env bats

load utils
source $LUCI_ROOT/functions/ssh-keys
jPort=18080

waitForLine() {
# We need to listen to the Jenkins output
# and wait untill both Jenkins and the jnlp
# is up af running.

    breakPoint=$1
    while read line; do
        case "$line" in
            *"$breakPoint"*) #TODO cleanup
                echo "Breakpoint found [$(date)]"
                return 0
                ;;
            *)
                ;;
        esac
    done
    return 1
}

startJenkinsMaster(){
  local jcidReturnVar=$1
  local keyDir=$2
  local jenkinsHome=$3
  local jeninsPort=$4
  local jenkinsName=$5

  #Start the Jenkins Server container with link to the data container that holds the SSH-keys.
  local _jcid=$(runZettaTools docker run -v $keyDir:/data/praqma-ssh-key -v $jenkinsHome:/var/jenkins_home -d -p $jeninsPort:8080 -p 50000:50000 $jenkinsName)
  cleanup_container $_jcid

  #We have to wait for the Jenkins Server to get started. Not just the server
  #but also the Jnlp service
  waitForJenkinsRunning $_jcid
  eval "$jcidReturnVar=$_jcid"
}

isWebsiteUp(){
  local host=$1
  local port=$2
  runZettaTools curl -s --head $host:$port | head -n 1 | grep -q "HTTP/1.1 200 OK"
}

isContainerRunning(){
  local containerId=$1
  local answer=$(runZettaTools docker inspect --format '{{ .State.Running }}' $containerId)
  if [ "$answer" == "true" ];then
    echo 0
  else
    echo 1
  fi
}

createJenkinsShellJob(){
  local jJobCmd=$1
  local cli=$2
  local jobName=$3
  $LUCI_ROOT/bin/simple-jenkins-job.sh $jJobCmd | runJenkinsCli $cli create-job $jobName
}

createJenkinsDockerJob(){
  local jJobCmd=$1
  local jobLabel=$2
  local cli=$3
  local jobName=$4
  $LUCI_ROOT/bin/docker-jenkins-job.sh $jJobCmd $jobLabel | runJenkinsCli $cli create-job $jobName
}

dockerLogs(){
  #This code is a replacement for docker logs -f
  #This code is not complete. It will print some lines out twice. This
  #needs to be fixed.

  #Argument 1 is container id to be logged
  local cid=$1
  local timeStamp

  while true; do
    local nextTime=$(date +%s)
    runZettaTools docker logs --since=$timeStamp $cid 2>&1

    #This line is nessasary for the process to die, when the function proccessLines dies
    echo "### LUCI $(date)"
    if [ $(runZettaTools docker inspect --format='{{.State.Running}}' $cid) = "false" ]; then
        return 0
    fi

    timeStamp=$nextTime
    sleep 2
  done
}

waitForJenkinsRunning() {
    dockerLogs $1 | waitForLine "setting agent port for jnlp"
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
    runZettaTools -v $LUCI_ROOT/src/main/remotedocker/data/context/:/tmp/context docker build -t luci-data /tmp/context/
    jdcid=$(runZettaTools docker create -v $keydir/id_rsa.pub:/data/server-keys/authorized_keys luci-data)

    #The Jenkins Slave container is build.
    runZettaTools -v $LUCI_ROOT/src/main/remotedocker/jenkins-slaves/shell/context/:/tmp/context docker build -t luci-shell-slave /tmp/context/

    # TODO Jenkins seems not to start if jenkins_home is on shared drive in boot2docker.
    # So if we are using boot2docker create a temp dir on the boot2docker host, and use that as jenkins_home
    if type boot2docker > /dev/null 2>&1 ; then
        jenkins_home=$(boot2docker ssh mktemp -d)
    else
        #Init a variable to house the jenkins_home folder. The home folder needs to be created here.
        #Else, it will be created by a container, by root and jenkins then cant access it.
        local jenkins_home=$tmpdir/home
        mkdir $jenkins_home
    fi

    #The Jenkins Server config.xml file is created dynamicly to incorporate the docker-plugin.
    #This way its configured on startup automaticly. Its placed in JENKINS_HOME and removed after
    #Jenkins is build. The Dockerfile will take care of the config.xml.
    $LUCI_ROOT/bin/generateJenkinsConfigXml.sh $jdcid $LUCI_DOCKER_HOST $LUCI_DOCKER_PORT > $LUCI_ROOT/src/main/remotedocker/jenkins/context/config.xml
    runZettaTools -v $LUCI_ROOT/src/main/remotedocker/jenkins/context/:/tmp/context docker build -t luci-jenkins /tmp/context/
    rm -f $LUCI_ROOT/src/main/remotedocker/jenkins/context/config.xml

    #Verify

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

    #Set location for jenkins-cli.jar
    local cli=$tmpdir/cli.jar

    #Download the jarfile from the Jenkins server
    wget http://$LUCI_DOCKER_HOST:$jPort/jnlpJars/jenkins-cli.jar -O "$cli"

    #Set the shell command for the job and create it on the Jenkins server
    createJenkinsShellJob "env" $cli "luci-shell"
    #Build the shell job
    runJenkinsCli $cli build luci-shell
    #Wait for the job to finish
    dockerLogs $jcid | waitForLine "luci-shell #1 main build"
    #Check if the shell job had a success string in the output
    runZettaTools curl -s http://$LUCI_DOCKER_HOST:$jPort/job/luci-shell/1/consoleText | grep -q "SUCCESS"

    #Call the function createJenkinsDockerJob to create the job
    createJenkinsDockerJob "env" "shell" $cli "luci-docker"
    #Build the docker job
    runJenkinsCli $cli build luci-docker
    #Wait for the job to finish
    dockerLogs $jcid | waitForLine "luci-docker #1 main build"
    #Check if the simple job had a success string in the output
    runZettaTools curl -s http://$LUCI_DOCKER_HOST:$jPort/job/luci-docker/1/consoleText | grep -q "SUCCESS"

    #Get the IP adress of the Jenkins Slave container, and SSH to it from the
    #Jenkins Master contianer with ssh keys
    jsip=$(runZettaTools docker inspect --format '{{ .NetworkSettings.IPAddress }}' $jscid)
    runZettaTools docker exec $jcid ssh -i /data/praqma-ssh-key/id_rsa -oStrictHostKeyChecking=no jenkins@$jsip env

#Use this, to pause the test before end. This way you can load jenkins in  a browser and test things out.
#read -p "Press [Enter] key to continue..."
}

teardown() {
    cleanup_perform
}
