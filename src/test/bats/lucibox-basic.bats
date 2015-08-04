#! /usr/bin/env bats

load utils
source $LUCI_ROOT/functions/ssh-keys
source $LUCI_ROOT/functions/docker-functions
source $LUCI_ROOT/functions/web-functions
source $LUCI_ROOT/functions/jenkins-functions
source $LUCI_ROOT/functions/utility-functions
source $LUCI_ROOT/functions/data-container

jPort=10080

@test "Starting LUCIbox basic" {
echo "LUCI_DOCKER_HOST: $LUCI_DOCKER_HOST"

#Create a nginx container
$LUCI_ROOT/bin/generateLuciboxBasicNginxConf.sh > $LUCI_ROOT/src/main/remotedocker/nginx/context/default.conf
buildDockerImage $LUCI_ROOT/src/main/remotedocker/nginx/context luci-nginx

#Create a artifactory container
buildDockerImage $LUCI_ROOT/src/main/remotedocker/artifactory/context luci-artifactory

#Create a Jenkins container
local jenkinsContainer=$(uniqueName jenkinsMaster)
local secretsContainer=$(uniqueName sshkeys)
local dataContainer=$(uniqueName data)

createSecretKeysContainer $secretsContainer
createStandardDataContainer $dataContainer $secretsContainer

#We start the Jenkins system up, and waits for it to answer.
echo "Starting Jenkins system"
startJenkins $jenkinsContainer $secretsContainer $dataContainer $jPort "jenkins"

#Build our slaves
buildDockerImage $LUCI_ROOT/src/main/remotedocker/jenkins-slaves/base/context/ base
buildDockerImage $LUCI_ROOT/src/main/remotedocker/jenkins-slaves/shell/context/ luci-shell-slave


#Start NginX with link to $jenkinsContainer and artifactory
runZettaTools docker run -d --name luci-artifactory luci-artifactory
runZettaTools docker run -d --name luci-nginx --link luci-artifactory --link $jenkinsContainer:luci-jenkins -p 80:80 -v $LUCI_ROOT/src/main/remotedocker/nginx/context/:/etc/nginx/conf.d/ nginx

#Use this, to pause the test before end. This way you can load jenkins in  a browser and test things out.
#read -p "Press [Enter] key to continue..."
}
