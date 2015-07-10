#! /usr/bin/env bats

load utils
source $LUCI_ROOT/functions/ssh-keys
source $LUCI_ROOT/functions/docker-functions
source $LUCI_ROOT/functions/web-functions
source $LUCI_ROOT/functions/jenkins-functions
source $LUCI_ROOT/functions/utility-functions

jPort=10080

@test "Running Gradle job on Jenkins" {
  skip "Needs to be adapted to new way to start jenkins"
  
  local jenkinsContainer=$(uniqueName jenkinsMaster)
  local secretsContainer=$(uniqueName sshkeys)
  local dataContainer=$(uniqueName data)

  #TODO ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64

  createSecretKeysContainer $secretsContainer
  createStandardDataContainer $dataContainer $secretsContainer

  startJenkins $jenkinsContainer $secretsContainer $dataContainer $jPort

  #Build our base slave image. This will be used by all other slaves
  buildDockerImage $LUCI_ROOT/src/main/remotedocker/jenkins-slaves/base/context/ base

  #Build the Docker slave we need
  buildDockerImage $LUCI_ROOT/src/main/remotedocker/jenkins-slaves/gradle/context/ luci-gradle-slave

  #Starting a Jenkins Slave, with ssh-keys from the data container
  echo "Starting Jenkins Slave"
  local jscid=$(runZettaTools docker run --volumes-from=$dataContainer -d luci-gradle-slave)
  cleanup_container $jscid

  local cli=$(tempdir)/cli.jar
  #Download the cli jarfile from the Jenkins server
  wget http://$LUCI_DOCKER_HOST:$jPort/jnlpJars/jenkins-cli.jar -O "$cli"

  createJenkinsGradleJob $cli "Gradle-Test-Job"

  #Build the docker job
  runJenkinsCli $cli build "Gradle-Test-Job"

  #  read -p "Press [Enter] key to continue..."

  #Wait for the job to finish
  dockerLogs $jenkinsContainer | waitForLine "Gradle-Test-Job #1 main build" 300

}

teardown() {
    cleanup_perform
}
