#! /usr/bin/env bats

load utils
source $LUCI_ROOT/functions/docker-functions
source $LUCI_ROOT/functions/web-functions

@test "Running Nginx container" {
    local nginxPort=1080
    local registryUiPort=80

    #Build the images we need
    buildDockerImage $LUCI_ROOT/src/main/remotedocker/nginx/context nginx

    #Run the nginx and UI
    ncid=$(runZettaTools docker run -p $nginxPort:80 -d nginx)
    cleanup_container $ncid

    echo "Is container running?"
    [ $(isContainerRunning $ncid) = "0" ]

    isWebsiteUp $LUCI_DOCKER_HOST $nginxPort

}

teardown() {
    cleanup_perform
}
