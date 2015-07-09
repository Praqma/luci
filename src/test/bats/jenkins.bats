#! /usr/bin/env bats

load utils
source $LUCI_ROOT/functions/ssh-keys
source $LUCI_ROOT/functions/docker-functions
source $LUCI_ROOT/functions/web-functions
source $LUCI_ROOT/functions/jenkins-functions
source $LUCI_ROOT/functions/utility-functions

jPort=10080

@test "Running Jenkins container" {
    #We start the Jenkins system up, and waits for it to answer.
    echo "Starting Jenkins system"
    startJenkins jdcid jcid $jPort

    #Build the Docker slave we need
    buildDockerImage $LUCI_ROOT/src/main/remotedocker/jenkins-slaves/base/context/ luci-base-slave

    #Starting a Jenkins Slave, with ssh-keys from the data container
    echo "Starting Jenkins Slave"
    local jscid=$(runZettaTools docker run --volumes-from=$jdcid -d luci-base-slave)
    cleanup_container $jscid

    #Get the IP address of the Jenkins Slave container
    local jsip=$(runZettaTools docker inspect --format '{{ .NetworkSettings.IPAddress }}' $jscid)

    #SSH to it the slave from the from the Jenkins master container with ssh keys
    runZettaTools docker exec $jcid ssh -i /data/praqma-ssh-key/id_rsa -oStrictHostKeyChecking=no jenkins@$jsip env

    local cli=$(tempdir)/cli.jar

    #Download the cli jarfile from the Jenkins server
    wget http://$LUCI_DOCKER_HOST:$jPort/jnlpJars/jenkins-cli.jar -O "$cli"

    #Set the shell command for the job and create it on the Jenkins server
    createJenkinsShellJob "env" $cli "luci-shell"

    #Build the shell job
    runJenkinsCli $cli build luci-shell

    #Wait for the job to finish
    dockerLogs $jcid | waitForLine "luci-shell #1 main build" 30

    #Check if the shell job had a success string in the output
    runZettaTools curl -s http://$LUCI_DOCKER_HOST:$jPort/job/luci-shell/1/consoleText | grep -q "SUCCESS"


    #Call the function createJenkinsDockerJob to create the docker job
    createJenkinsDockerJob "env" "base" $cli "luci-docker"

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
