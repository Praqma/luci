#! /usr/bin/env bats

load utils
source $LUCI_ROOT/functions/docker-functions
source $LUCI_ROOT/functions/web-functions

@test "Running Nginx container" {
    local nginxPort=1080
    buildDockerImage $LUCI_ROOT/src/main/remotedocker/nginx/context nginx
    ncid=$(runZettaTools docker run -p $nginxPort:80 -d nginx)

    echo "Is container running?"
    [ $(isContainerRunning $ncid) = "0" ]

    isWebsiteUp $LUCI_DOCKER_HOST $nginxPort
}

teardown() {
    cleanup_perform
}
