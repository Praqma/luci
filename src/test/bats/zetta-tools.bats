#! /usr/bin/env bats

load utils
source $LUCI_ROOT/functions/ssh-keys

@test "Check docker command can be executed in zetta-tools" {
    docker  run --rm -v $LUCI_CONFIG/zetta_config:/config -v ~/.docker/machine:/root/.docker/machine -v /var/run/docker.sock:/var/run/docker.sock luci/tools:0.1 docker ps
}

@test "Remote docker build with zetta-tools" {
    skip "Fix test. Build remote from data in data container"
    
    local tag=$RANDOM
    local dhost
    local tmpdir=$(tempdir)

    local keydir=$tmpdir/keys
    generateSshKey $keydir "SSH-key-for-LUCI"

    echo "Using tag: $tag"
    dockerMachineAquire dhost "Testing docker build"

    jdcid=$(runZettaTools docker create -v $keydir/id_rsa.pub:/data/server-keys/authorized_keys luci-data)
    sh $LUCI_ROOT/bin/generateJenkinsConfigXml.sh $jdcid $LUCI_DOCKER_HOST $LUCI_DOCKER_PORT > $LUCI_ROOT/src/main/remotedocker/jenkins/context/config.xml

    $LUCI_ROOT/bin/generateJenkinsLocateConfiguration.sh $LUCI_DOCKER_HOST $jPort heh@praqma.net > $LUCI_ROOT/src/main/remotedocker/jenkins/context/jenkins.model.JenkinsLocationConfiguration.xml

    runZettaTools -v $LUCI_ROOT/src/main/remotedocker/jenkins/context/:/tmp/context dm $dhost \
                  build -t jenkins:$tag /tmp/context/

    runZettaTools dm $dhost images | grep "jenkins.*$tag"

    rm -f $LUCI_ROOT/src/main/remotedocker/jenkins/context/config.xml
    rm -f $LUCI_ROOT/src/main/remotedocker/jenkins/context/jenkins.model.JenkinsLocationConfiguration.xml

}
