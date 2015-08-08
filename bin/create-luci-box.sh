#! /bin/bash

source $LUCI_ROOT/src/test/bats/utils.bash
source $LUCI_ROOT/functions/ssh-keys
source $LUCI_ROOT/functions/docker-functions
source $LUCI_ROOT/functions/web-functions
source $LUCI_ROOT/functions/jenkins-functions
source $LUCI_ROOT/functions/utility-functions
source $LUCI_ROOT/functions/data-container

jPort=10080


jenkinsPrefix="jenkins"
echo "LUCI_DOCKER_HOST: $LUCI_DOCKER_HOST"

nginxContainer=$(uniqueName nginx)
artifactoryContainer=$(uniqueName artifactory)
cleanup_container $nginxContainer
cleanup_container $artifactoryContainer

# Get uniq names for our Jenkins server and data containers
jenkinsContainer=$(uniqueName jenkinsMaster)
secretsContainer=$(uniqueName sshkeys)
dataContainer=$(uniqueName data)

# Create a container holding ssh keys
createSecretKeysContainer $secretsContainer
createStandardDataContainer $dataContainer $secretsContainer

# We start the Jenkins system up, and waits for it to answer.
echo "Starting Jenkins system"
startJenkins $jenkinsContainer $secretsContainer $dataContainer $jPort $jenkinsPrefix

# Start artifactory container
runZettaTools docker run -d --name $artifactoryContainer luci/artifactory:0.1

# Start nginX container with link to $jenkinsContainer and $artifactoryContainer
runZettaTools docker run -d --name $nginxContainer --link $artifactoryContainer:artifactory --link $jenkinsContainer:jenkins -p 80:80 luci/nginx:0.1

echo "Luci box basic created at $LUCI_DOCKER_HOST"
