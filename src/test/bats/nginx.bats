#! /usr/bin/env bats

load utils
source $LUCI_ROOT/functions/docker-functions
source $LUCI_ROOT/functions/web-functions

@test "Running Artifactory behind nginx" {
    local tmpdir=$(tempdir)
    echo JHS $tmpdir

    #Build the images we need
    echo "LUCI_DOCKER_HOST: $LUCI_DOCKER_HOST"
    $LUCI_ROOT/bin/generateNginxConf.sh $LUCI_DOCKER_HOST 10080 > $LUCI_ROOT/src/main/remotedocker/nginx/context/praqma.conf
    buildDockerImage $LUCI_ROOT/src/main/remotedocker/nginx/context luci-nginx
    rm -f $LUCI_ROOT/src/main/remotedocker/nginx/context/praqma.conf

    buildDockerImage $LUCI_ROOT/src/main/remotedocker/artifactory/context luci-artifactory

    $LUCI_ROOT/bin/generateCompose.sh 80 luci-nginx > $tmpdir/docker-compose.yml
    runDockerCompose $tmpdir
    killDockerCompose $(realpath $tmpdir)
#    cleanup_composition $tempdir
    
    # echo "Press [Enter] key to continue, and stop this test, including shutdown of containers ..."
    # read

}
