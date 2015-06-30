#! /usr/bin/env bats

load utils
source $LUCI_ROOT/functions/ssh-keys
jPort=18080

#TODO new/better saying name
processLines() {
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
    dockerLogs $1 | processLines "setting agent port for jnlp"
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


#TODO Create a startJenkins function with the three next commands
    #Start the Jenkins Server container with link to the data container that holds the SSH-keys.
    jcid=$(runZettaTools docker run -v $keydir:/data/praqma-ssh-key -v $jenkins_home:/var/jenkins_home -d -p $jPort:8080 -p 50000:50000 luci-jenkins)
    cleanup_container $jcid

    #We have to wait for the Jenkins Server to get started. Not just the server
    #but also the Jnlp service
    waitForJenkinsRunning $jcid
#TODO end

    echo "starting tests"
    #Check if the Jenkins Server webpage is responding OK
#TODO Create function - isWebsiteUp
    runZettaTools curl -s --head $LUCI_DOCKER_HOST:$jPort | head -n 1 | grep -q "HTTP/1.1 200 OK"

    #Starting a Jenkins Slave, with ssh-keys from the data container
    jscid=$(runZettaTools docker run --volumes-from=$jdcid -d luci-shell-slave)
    cleanup_container $jscid

    #Is Jenkins container running?
#TODO Create a function isContainerRunning
    [ $(runZettaTools docker inspect --format '{{ .State.Running }}' $jcid) = "true" ]

    #Set location for jenkins-cli.jar
    local cli=$tmpdir/cli.jar

    #Download the jarfile from the Jenkins server
    wget http://$LUCI_DOCKER_HOST:$jPort/jnlpJars/jenkins-cli.jar -O "$cli"

    #Set the shell command for the job and create it on the Jenkins server
    jJobCmd="env"
    jJob=$($LUCI_ROOT/bin/simple-jenkins-job.sh $jJobCmd)
    echo $jJob | runJenkinsCli $cli create-job luci

    #Build the simple job
    runJenkinsCli $cli build luci

    #Check if the simple job had a success string in the output
    runZettaTools curl -s http://$LUCI_DOCKER_HOST:$jPort/job/luci/1/consoleText | grep -q "SUCCESS"

    #Set the shell command for the docker job and create it on the Jenkins server
#TODO Create function createJenkinsJob
    jJobCmd="env"
    $LUCI_ROOT/bin/docker-jenkins-job.sh $jJobCmd "shell" | runJenkinsCli $cli create-job luci-docker

    #Build the docker job
    runJenkinsCli $cli build luci-docker

    #Wait for the job to finish
    dockerLogs $jcid | processLines "luci-docker #1 main build"

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
