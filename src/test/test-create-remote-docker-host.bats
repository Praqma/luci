#! /usr/bin/env bats

load utils

@test "Use openstack CLI with zetta-tools" {
    group quick
    runZettaTools openstack server list
}

@test "Create a docker machine with zetta-tools" {
    group complete

    local machname=lucitest-$(date +%Y%m%d-%H%M%S)
    
    echo "Creating docker host called luci-unittest, please wait..."
    runZettaTools docker-machine-create $machname


    echo "The following output should show a string - Up and running"
    runZettaTools docker-machine ssh $machname echo "Up and running"

    echo "Cleaning up..."
    runZettaTools docker-machine rm -f $machname
}


