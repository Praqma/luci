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
  local jenkinsPrefix="jenkins"
  echo "LUCI_DOCKER_HOST: $LUCI_DOCKER_HOST"

  local nginxContainer=$(uniqueName nginx)
  local artifactoryContainer=$(uniqueName artifactory)
  cleanup_container $nginxContainer
  cleanup_container $artifactoryContainer

  # Get uniq names for our Jenkins server and data containers
  local jenkinsContainer=$(uniqueName jenkinsMaster)
  local secretsContainer=$(uniqueName sshkeys)
  local dataContainer=$(uniqueName data)

  # Create a container holding ssh keys
  createSecretKeysContainer $secretsContainer
  createStandardDataContainer $dataContainer $secretsContainer

  # We start the Jenkins system up, and waits for it to answer.
  echo "Starting Jenkins system"
  startJenkins $jenkinsContainer $secretsContainer $dataContainer $jPort $jenkinsPrefix $LUCI_DOCKER_HOST $LUCI_DOCKER_PORT

  # Start artifactory container
  runZettaTools docker run -d --name $artifactoryContainer --volumes-from $dataContainer luci/artifactory:0.1

  # Start nginX container with link to $jenkinsContainer and $artifactoryContainer
  runZettaTools docker run -d --name $nginxContainer --link $artifactoryContainer:artifactory --link $jenkinsContainer:jenkins -p 80:80 luci/nginx:0.1

  # Check if Jenkins is reachable through nginX
  waitForHttpSuccess "$LUCI_DOCKER_HOST/$jenkinsPrefix/" 10

  # Check if Artifactory is reachable through nginX
  waitForHttpSuccess "$LUCI_DOCKER_HOST/artifactory" 100

  # Use this, to pause the test before end. This way you can load jenkins in  a browser and test things out.
  # read -p "Press [Enter] key to continue..."
}
