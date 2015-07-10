#! /usr/bin/env bats

load utils
source $LUCI_ROOT/functions/docker-functions
source $LUCI_ROOT/functions/web-functions

@test "Running Registry-UI container" {
#TODO UI cannot be reached through nginx. But ok directly.

    #Prepare
    local tmpdir=$(tempdir)

    #Build the images we need
    $LUCI_ROOT/bin/generateDockerComposeYml.sh $LUCI_DOCKER_HOST 10080 > $LUCI_ROOT/src/main/remotedocker/nginx/context/praqma.conf
    buildDockerImage $LUCI_ROOT/src/main/remotedocker/nginx/context luci-nginx
    rm -f $LUCI_ROOT/src/main/remotedocker/nginx/context/praqma.conf
    buildDockerImage $LUCI_ROOT/src/main/remotedocker/artifactory/context luci-artifactory

    $LUCI_ROOT/bin/generateRegistryCompose.sh 80 luci-nginx > $tmpdir/docker-compose.yml
    echo $tmpdir
    runDockerCompose $tmpdir

    #read -p "Press [Enter] key to continue..."

    stopDockerCompose $tmpdir
}
