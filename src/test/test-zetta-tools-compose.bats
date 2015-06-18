#! /usr/bin/env bats

@test "Check docker-compose command can be executed in zetta-tools" {
    runZettaTools docker-compose  --version
}

