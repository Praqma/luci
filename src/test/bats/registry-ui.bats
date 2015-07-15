#! /usr/bin/env bats

load utils
source $LUCI_ROOT/functions/docker-functions
source $LUCI_ROOT/functions/web-functions

@test "Running Registry-UI container" {
    skip "Seems to make jenkins build unstable"
#TODO UI cannot be reached through nginx. But ok directly.

    #Prepare
    local tmpdir=$(tempdir)

    #Build the images we need
    echo "LUCI_DOCKER_HOST: $LUCI_DOCKER_HOST"
    $LUCI_ROOT/bin/generateNginxConf.sh $LUCI_DOCKER_HOST 10080 > $LUCI_ROOT/src/main/remotedocker/nginx/context/praqma.conf
    buildDockerImage $LUCI_ROOT/src/main/remotedocker/nginx/context luci-nginx
    rm -f $LUCI_ROOT/src/main/remotedocker/nginx/context/praqma.conf
    buildDockerImage $LUCI_ROOT/src/main/remotedocker/artifactory/context luci-artifactory

    $LUCI_ROOT/bin/generateCompose.sh 80 luci-nginx > $tmpdir/docker-compose.yml
    echo $tmpdir
    runDockerCompose $tmpdir
     
    # echo "Press [Enter] key to continue, and stop this test, including shutdown of containers ..."
    # read

    stopDockerCompose $tmpdir
}
