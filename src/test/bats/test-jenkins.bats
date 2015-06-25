#! /usr/bin/env bats

load utils
source $LUCI_ROOT/functions/ssh-keys
jPort=18080
sshPort=10022
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

    mkdir $tmpdir/home
    local jenkins_home=$tmpdir/home

    echo "starting Jenkins"

    run runZettaTools docker run -v $keydir:/root/.ssh -v $jenkins_home:/var/jenkins_home -d -p $jPort:8080 -p 50000:50000 luci-jenkins

    [ $status -eq 0 ]    
    local jcid=$output
    cleanup_container $jcid

    [ -f $jenkins_home/credentials.xml ]

    waitForJenkinsRunning $jcid
    echo "Jenkins is up, lets move on [$(date)]"

    echo "now starting slave"

    run runZettaTools docker run -v $keydir:/home/jenkins/.ssh/ -d -p $sshPort:22 luci-ssh-slave
    [ $status -eq 0 ]
    local jscid=$output
    cleanup_container $jscid
    
    run runZettaTools docker inspect --format '{{ .State.Running }}' $jcid
    [ $output = "true" ]


    echo "starting tests"   
    echo "runZettaTools curl -s --head $LUCI_DOCKER_HOST:$jPort | head -n 1 | grep -c HTTP/1.1 200 OK" 
    res=$(runZettaTools curl -s --head $LUCI_DOCKER_HOST:$jPort | head -n 1 | grep -c "HTTP/1.1 200 OK")
    [ $res = "1" ]
    
    local cli=$tmpdir/cli.jar
    
    wget http://$LUCI_DOCKER_HOST:$jPort/jnlpJars/jenkins-cli.jar -O "$cli"
    
    runJenkinsCli $cli create-job luci < $LUCI_ROOT/src/test/jenkins-jobs/simpleJob.xml
    runJenkinsCli $cli build luci
    
    res=$(runZettaTools curl -s http://$LUCI_DOCKER_HOST:$jPort/job/luci/1/consoleText | grep -c "SUCCESS")
    [ $res = "1" ]

    run runZettaTools docker inspect --format '{{ .NetworkSettings.IPAddress }}' $jscid
    jsip=$output
    echo "jsip : $jsip"
    echo "jcid :$jcid"
    run runZettaTools docker exec $jcid ssh -oStrictHostKeyChecking=no jenkins@$jsip env 
echo "SSH output $output"
    [ $status -eq 0 ]

}

teardown() {
    cleanup_perform
}

