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

    # Create a container holding ssh keys
    createSecretKeysContainer $secretsContainer
    createStandardDataContainer $dataContainer $secretsContainer

    # We start the Jenkins system up, and waits for it to answer.
    echo "Starting Jenkins container"
    startJenkins $jenkinsContainer $secretsContainer $dataContainer $jPort "" $LUCI_DOCKER_HOST $LUCI_DOCKER_PORT

    # Is Jenkins container running?
    isContainerRunning $jenkinsContainer

    # Check if the Jenkins Server webpage is responding OK
    isWebsiteUp $LUCI_DOCKER_HOST:$jPort

    local cli=$(tempdir)/cli.jar

    # Download the cli jarfile from the Jenkins server
    wget http://$LUCI_DOCKER_HOST:$jPort/jnlpJars/jenkins-cli.jar -O "$cli"


    # Set the shell command for a simple job and create it on the Jenkins server
    createJenkinsShellJob "env" $cli "luci-shell"

    # Build the shell job
    runJenkinsCli $cli build luci-shell

    # Wait for the job to finish
    dockerLogs $jenkinsContainer | waitForLine "luci-shell #1 main build" 30

    # Check if the shell job had a success string in the output
    runZettaTools curl -s http://$LUCI_DOCKER_HOST:$jPort/job/luci-shell/1/consoleText | grep -q "SUCCESS"


    # Call the function createJenkinsDockerJob to create the docker job
    createJenkinsDockerJob "env" "shell" $cli "luci-docker"

    # Build the docker job
    runJenkinsCli $cli build luci-docker

    # Wait for the job to finish
    dockerLogs $jenkinsContainer | waitForLine "luci-docker #1 main build" 300
    echo "Before running docker job $(date)"


    # Starting a Jenkins Slave, with ssh-keys from the data container
    local jscid=$(runZettaTools docker run --volumes-from=$dataContainer -d luci/slave-shell:0.1)
    cleanup_container $jscid

    # Get the IP adress of the slave, just created
    local jsip=$(containerIp $jscid)

    # SSH to it the slave from the from the Jenkins master container with ssh keys
    runZettaTools docker exec $jenkinsContainer ssh -i /data/praqma-ssh-key/id_rsa -oStrictHostKeyChecking=no root@$jsip env

    # Check if the simple job had a success string in the output
    runZettaTools curl -s http://$LUCI_DOCKER_HOST:$jPort/job/luci-docker/1/consoleText | grep -q "SUCCESS"


# Use this, to pause the test before end. This way you can load jenkins in  a browser and test things out.
# read -p "Press [Enter] key to continue..."
}
