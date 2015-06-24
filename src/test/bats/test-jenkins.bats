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
    runZettaTools docker logs -f $1 | processLines
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
    
#Verify
    local tmpdir=$(mktemp -d)
    generateSshKey $tmpdir "SSH-key-for-LUCI"

    local jenkins_home=$(mktemp -d)
    run runZettaTools docker run -v $tmpdir:/data/praqma-ssh-key -v $jenkins_home:/var/jenkins_home -d -p $jPort:8080 -p 50000:50000 luci-jenkins
    [ $status -eq 0 ]    
    local cid=$output
    cleanup_container $cid

    [ -f $jenkins_home/credentials.xml ]

    waitForJenkinsRunning $cid

echo "Jenkins is up, lets move on [$(date)]"

    run runZettaTools docker inspect --format '{{ .State.Running }}' $cid
    [ $output = "true" ]

    res=$(runZettaTools curl -s --head $LUCI_DOCKER_HOST:$jPort | head -n 1 | grep -c "HTTP/1.1 200 OK")
    [ $res = "1" ]

    local cli=$(mktemp -d)/cli.jar

    wget http://$LUCI_DOCKER_HOST:$jPort/jnlpJars/jenkins-cli.jar -O "$cli"
    
    runJenkinsCli $cli create-job luci < $LUCI_ROOT/src/test/jenkins-jobs/simpleJob.xml
    runJenkinsCli $cli build luci

    res=$(runZettaTools curl -s http://$LUCI_DOCKER_HOST:$jPort/job/luci/1/consoleText | grep -c "SUCCESS")
    [ $res = "1" ]

#Cleanup
    rm -f $cli
}

teardown() {
    cleanup_perform
}

