#! /usr/bin/env bats

load utils

@test "Check docker-compose command can be executed in zetta-tools" {
    runZettaTools docker-compose --version
}

