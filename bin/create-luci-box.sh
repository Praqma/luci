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

nginxContainer="luci-nginx"
artifactoryContainer="luci-artifactory"
cleanup_container $nginxContainer
cleanup_container $artifactoryContainer

# Get uniq names for our Jenkins server and data containers
jenkinsContainer="luci-jenkins"
secretsContainer="luci-secret"
dataContainer="luci-data"

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

