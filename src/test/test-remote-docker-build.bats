#! /usr/bin/env bats

load utils

@test "Check docker build inside zetta-tools" {
    dockerMachineAquire dhost "Testing docker build"
    runZettaTools -v $LUCI_ROOT/src/main/remotedocker/jenkins/context/:/tmp/context dm $dhost build -t jenkins /tmp/context/
    dockerMachineRelease $dhost
}

