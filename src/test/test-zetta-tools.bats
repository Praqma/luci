#! /usr/bin/env bats

load utils

@test "Check docker command can be executed in zetta-tools" {
    docker  run --rm -v $LUCI_CONFIG/zetta_config:/config -v ~/.docker/machine:/root/.docker/machine -v /var/run/docker.sock:/var/run/docker.sock zetta-tools docker ps
}

@test "Remote docker build with zetta-tools" {
    local tag=$RANDOM
    local dhost

    echo "Using tag: $tag"
    dockerMachineAquire dhost "Testing docker build"

    runZettaTools -v $LUCI_ROOT/src/main/remotedocker/jenkins/context/:/tmp/context dm $dhost \
                  build -t jenkins:$tag /tmp/context/

    runZettaTools dm $dhost images | grep "jenkins.*$tag"
}

function teardown() {
    dockerMachineReleaseAll
}

