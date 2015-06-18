#! /usr/bin/env bats

load utils

@test "Check docker build inside zetta-tools" {
    runZettaTools -v $LUCI_ROOT/src/main/remotedocker/jenkins/context/:/tmp/context docker build -t jenkins /tmp/context/
}

