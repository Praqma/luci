#! /usr/bin/env bats

load utils
source $LUCI_ROOT/functions/ssh-keys
jPort=18080

processLines() {
# We need to listen to the Jenkins output
# and wait untill both Jenkins and the jnlp
# is up af running.
    while read line; do
        case "$line" in 
            *"setting agent port for jnlp"*)
                echo "Jenkins Jnlp up and running! $points [$(date)]"
                return 0
                ;;
            *)
                ;;
        esac
    done
    return 1
}

waitForJenkinsRunning() {
    # TODO seems the docker logs command creates a container that is not cleaned up
    runZettaTools docker logs -f -t $1 | processLines
    local rc=$?
    return $rc
}

runJenkinsCli() {
    local cli=$1
    shift 
    java -jar "$cli" -s http://$LUCI_DOCKER_HOST:$jPort -noKeyAuth "$@"
}

@test "Running Jenkins container" {
#Prepare
    runZettaTools -v $LUCI_ROOT/src/main/remotedocker/jenkins/context/:/tmp/context docker build -t luci-jenkins /tmp/context/
    runZettaTools -v $LUCI_ROOT/src/main/remotedocker/jenkins-slaves/simpel-ssh/context/:/tmp/context docker build -t luci-ssh-slave /tmp/context/ 
    #Verify
    local tmpdir=$(tempdir)

    local keydir=$tmpdir/keys
    generateSshKey $keydir "SSH-key-for-LUCI"
    cat $keydir/id_rsa.pub > $keydir/authorized_keys

    # TODO Jenkins seems not to start if jenkins_home is on shared drive in boot2docker.
    # So if we are using boot2docker create a temp dir on the boot2docker host, and use that as jenkins_home
    if type boot2docker > /dev/null 2>&1 ; then
        jenkins_home=$(boot2docker ssh mktemp -d)
    else
        #Init a variable to house the jenkins_home folder. The home folder needs to be created here.
        #Else, it will be created by a container, by root and jenkins then cant access it.
        local jenkins_home=$tmpdir/home
        mkdir $jenkins_home
    fi

    echo "starting Jenkins. jenkings home: $jenkins_home"
    jcid=$(runZettaTools docker run -v $keydir:/root/.ssh -v $jenkins_home:/var/jenkins_home -d -p $jPort:8080 -p 50000:50000 luci-jenkins)
    cleanup_container $jcid

    waitForJenkinsRunning $jcid

    echo "starting tests"    
    runZettaTools curl -s --head $LUCI_DOCKER_HOST:$jPort | head -n 1 | grep -q "HTTP/1.1 200 OK"
    
    echo "Jenkins is up, lets move on [$(date)]"

    jscid=$(runZettaTools docker run -v $keydir:/home/jenkins/.ssh/ -d luci-ssh-slave)
    cleanup_container $jscid
    echo "slave started. cid: '$jscid'"


    [ $(runZettaTools docker inspect --format '{{ .State.Running }}' $jcid) = "true" ]

    local cli=$tmpdir/cli.jar
    
    wget http://$LUCI_DOCKER_HOST:$jPort/jnlpJars/jenkins-cli.jar -O "$cli"
    
    runJenkinsCli $cli create-job luci < $LUCI_ROOT/src/test/jenkins-jobs/simpleJob.xml
    runJenkinsCli $cli build luci
    
    runZettaTools curl -s http://$LUCI_DOCKER_HOST:$jPort/job/luci/1/consoleText | grep -q "SUCCESS"

    jsip=$(runZettaTools docker inspect --format '{{ .NetworkSettings.IPAddress }}' $jscid)
    runZettaTools docker exec $jcid ssh -oStrictHostKeyChecking=no jenkins@$jsip env 
}

teardown() {
    cleanup_perform
}

