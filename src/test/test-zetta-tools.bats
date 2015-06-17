#! /usr/bin/env bats

@test "Check docker command can be executed in zetta-tools" {
    docker  run --rm -v $LUCI_CONFIG/zetta_config:/config -v ~/.docker/machine:/root/.docker/machine -v /var/run/docker.sock:/var/run/docker.sock zetta-tools docker ps
}
