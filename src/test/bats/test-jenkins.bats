#! /usr/bin/env bats

load utils

jPort=18080

processLines() {
# We need to listen to the Jenkins output
# and wait untill both Jenkins and the jnlp
# is up af running.
    local points=0
    while read line; do
        case "$line" in 
            *"Jenkins is fully up and running"*)
                points=$((points+1))
                echo "Jenkins up and running!"
                if (( $points == 2 )) ; then
                      return 0
                fi
                ;;
            *"setting agent port for jnlp"*)
                points=$((points+1))
                echo "Jenkins Jnlp up and running!"
                if (( $points == 2 )) ; then
                      return 0
                fi
                ;;
            *)
                ;;
        esac
    done
    return 1
}

waitForJenkinsRunning() {
    # TODO seems the docker logs command creates a container that is not cleaned up
    runZettaTools docker logs -f $1 2>&1 | processLines
    local rc=$?
    return $rc
}

@test "Running Jenkins container" {
    #Prepare
    runZettaTools -v $LUCI_ROOT/src/main/remotedocker/jenkins/context/:/tmp/context docker build -t luci-jenkins /tmp/context/
    
#Verify
    run runZettaTools -v $LUCI_ROOT/src/main/remotedocker/jenkins/context/:/tmp/context docker run -d -p $jPort:8080 -p 50000:50000 luci-jenkins
    [ $status -eq 0 ]    
    local cid=$output
    cleanup_container $cid

    waitForJenkinsRunning $cid

    run runZettaTools docker inspect --format '{{ .State.Running }}' $cid
    [ $output = "true" ]

    res=$(runZettaTools curl -s --head $LUCI_DOCKER_HOST:$jPort | head -n 1 | grep -c "HTTP/1.1 200 OK")
    [ $res = "1" ]

    wget http://$LUCI_DOCKER_HOST:$jPort/jnlpJars/jenkins-cli.jar -O /tmp/jenkins-cli.jar

    java -jar /tmp/jenkins-cli.jar -s http://$LUCI_DOCKER_HOST:$jPort -noKeyAuth create-job luci < $LUCI_ROOT/src/test/test-jobs/simpleJob.xml
    java -jar /tmp/jenkins-cli.jar -s http://$LUCI_DOCKER_HOST:$jPort -noKeyAuth build luci

    res=$(runZettaTools curl -s http://$LUCI_DOCKER_HOST:$jPort/job/luci/1/consoleText|grep -c "SUCCESS")
    [ $res = "1" ]

#Cleanup
    rm -f /tmp/jenkins-cli.jar
}

teardown() {
    cleanup_perform
}

