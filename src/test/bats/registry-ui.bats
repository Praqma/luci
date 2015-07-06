#! /usr/bin/env bats

load utils
source $LUCI_ROOT/functions/docker-functions
source $LUCI_ROOT/functions/web-functions

@test "Running Registry-UI container" {
#Prepare
local tmpdir=$(tempdir)

#Build the images we need
  buildDockerImage $LUCI_ROOT/src/main/remotedocker/nginx/context luci-nginx

  $LUCI_ROOT/bin/generateRegistryCompose.sh 80 luci-nginx > $tmpdir/docker-compose.yml

  runDockerCompose $tmpdir

#read -p "Press [Enter] key to continue..."

  stopDockerCompose $tmpdir
}

teardown() {
    runZettaTools docker-compose stop
    cleanup_perform
}

