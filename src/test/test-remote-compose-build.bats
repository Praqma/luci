#! /usr/bin/env bats

load utils

@test "Get docker-compose to build our Jenkins suite" {

#    local machname=lucitest-$(date +%Y%m%d-%H%M%S)
    
#    echo "Creating docker host called luci-unittest, please wait..."
#    runZettaTools docker-machine-create $machname


    echo "Using docker-compose to build our complete Jenkins suite remote"
    runZettaTools -v $LUCI_ROOT/src/main/remotecompose/jenkins-suite-compose/docker-compose.yml:/tmp/context/ docker-compose build /tmp/context/docker-compose.yml

#    echo "Cleaning up..."
#    runZettaTools docker-machine rm -f $machname
}


