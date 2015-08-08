#! /bin/bash

functionDir=$(dirname $(dirname $(realpath $0)))/functions

source $functionDir/cleanup
source $functionDir/zetta-tools
source $functionDir/ssh-keys
source $functionDir/docker-functions
source $functionDir/web-functions
source $functionDir/jenkins-functions
source $functionDir/utility-functions
source $functionDir/data-container

jPort=10080

if [ -z "$DOCKER_HOST" ] ; then
    $DOCKER_HOST='tcp://localhost:2575'
fi
# Remove protocol
hostAndPort=$(echo ${DOCKER_HOST/*:\/\//})
dockerDestHost=$(echo $hostAndPort | cut -f1 -d:)
dockerDestPort=$(echo $hostAndPort | cut -f2 -d:)

echo "Initializing Lucibox on Docker @ $dockerDestHost:$dockerDestPort"

jenkinsPrefix="jenkins"

nginxContainer="luci-nginx"
artifactoryContainer="luci-artifactory"

# Get uniq names for our Jenkins server and data containers
jenkinsContainer="luci-jenkins"
secretsContainer="luci-secret"
dataContainer="luci-data"

# Remote existing containers, except the data containers
runZettaTools docker rm -f $nginxContainer $artifactoryContainer $jenkinsContainer

# Create a container holding ssh keys
createSecretKeysContainer $secretsContainer
createStandardDataContainer $dataContainer $secretsContainer

# We start the Jenkins system up, and waits for it to answer.
echo "Starting Jenkins system"
startJenkins $jenkinsContainer $secretsContainer $dataContainer $jPort $jenkinsPrefix $dockerDestHost $dockerDestPort

# Start artifactory container
runZettaTools docker run -d --name $artifactoryContainer luci/artifactory:0.1

# Start nginX container with link to $jenkinsContainer and $artifactoryContainer
runZettaTools docker run -d --name $nginxContainer --link $artifactoryContainer:artifactory --link $jenkinsContainer:jenkins -p 80:80 luci/nginx:0.1

