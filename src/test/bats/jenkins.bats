#! /usr/bin/env bats

load utils
source $LUCI_ROOT/functions/ssh-keys
source $LUCI_ROOT/functions/docker-functions
source $LUCI_ROOT/functions/web-functions
source $LUCI_ROOT/functions/jenkins-functions
source $LUCI_ROOT/functions/utility-functions
source $LUCI_ROOT/functions/data-container

jPort=10080

@test "Running Jenkins container" {
    local jenkinsContainer=$(uniqueName jenkinsMaster)
    local secretsContainer=$(uniqueName sshkeys)
    local dataContainer=$(uniqueName data)
    
    createSecretKeysContainer $secretsContainer
    createStandardDataContainer $dataContainer $secretsContainer
    
    #We start the Jenkins system up, and waits for it to answer.
    echo "Starting Jenkins system"
    startJenkins $jenkinsContainer $secretsContainer $dataContainer $jPort

    #Check if the Jenkins Server webpage is responding OK
    isWebsiteUp $LUCI_DOCKER_HOST:$jPort
    
    #Is Jenkins container running?
    echo "Is container running?"
    isContainerRunning $jenkinsContainer

    #Build our base slave image. This will be used by all other slaves
    buildDockerImage $LUCI_ROOT/src/main/remotedocker/jenkins-slaves/base/context/ base

    #Build the Docker slave we need
    buildDockerImage $LUCI_ROOT/src/main/remotedocker/jenkins-slaves/base/context/ luci-base-slave

    #Starting a Jenkins Slave, with ssh-keys from the data container
    echo "Starting Jenkins Slave"
    local jscid=$(runZettaTools docker run --volumes-from=$dataContainer -d luci-base-slave)
    cleanup_container $jscid

    local jsip=$(containerIp $jscid)

    #SSH to it the slave from the from the Jenkins master container with ssh keys
    runZettaTools docker exec $jenkinsContainer ssh -i /data/praqma-ssh-key/id_rsa -oStrictHostKeyChecking=no root@$jsip env

    local cli=$(tempdir)/cli.jar

    #Download the cli jarfile from the Jenkins server
    wget http://$LUCI_DOCKER_HOST:$jPort/jnlpJars/jenkins-cli.jar -O "$cli"

    #Set the shell command for the job and create it on the Jenkins server
    createJenkinsShellJob "env" $cli "luci-shell"

    #Build the shell job
    runJenkinsCli $cli build luci-shell

    #Wait for the job to finish
    dockerLogs $jenkinsContainer | waitForLine "luci-shell #1 main build" 30

    #Check if the shell job had a success string in the output
    runZettaTools curl -s http://$LUCI_DOCKER_HOST:$jPort/job/luci-shell/1/consoleText | grep -q "SUCCESS"

    #Call the function createJenkinsDockerJob to create the docker job
    createJenkinsDockerJob "env" "base" $cli "luci-docker"

    #Build the docker job
    runJenkinsCli $cli build luci-docker

    #Wait for the job to finish
    dockerLogs $jenkinsContainer | waitForLine "luci-docker #1 main build" 300

    #Check if the simple job had a success string in the output
    runZettaTools curl -s http://$LUCI_DOCKER_HOST:$jPort/job/luci-docker/1/consoleText | grep -q "SUCCESS"


#Use this, to pause the test before end. This way you can load jenkins in  a browser and test things out.
#read -p "Press [Enter] key to continue..."
}

teardown() {
    cleanup_perform
}
