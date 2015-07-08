#! /usr/bin/env bats

load utils
source $LUCI_ROOT/functions/ssh-keys
source $LUCI_ROOT/functions/docker-functions
source $LUCI_ROOT/functions/web-functions
source $LUCI_ROOT/functions/jenkins-functions
source $LUCI_ROOT/functions/utility-functions

jPort=10080

@test "Running Gradle job on Jenkins" {

  startJenkins jdcid jcid $jPort

  local gitUrl=$(constructJenkinsTestProject hiker-success gradle)
  echo "Git URL : $gitUrl"

#  "./gradlew test"

  #TODO create a jenkins job for a gradle job

}

teardown() {
    cleanup_perform
}
