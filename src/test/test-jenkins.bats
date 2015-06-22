#! /usr/bin/env bats

load utils

jPort=18080

processLines() {
    while read line; do
        case "$line" in 
            *"Jenkins is fully up and running"*)
                echo "Jenkins up and running!"
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
    runZettaTools docker logs -f $1 2>&1 | processLines
    local rc=$?
    return $rc
}

@test "Running Jenkins container" {
    #Prepare
    runZettaTools -v $LUCI_ROOT/src/main/remotedocker/jenkins/context/:/tmp/context docker build -t luci-jenkins /tmp/context/
    
#Verify
    run runZettaTools -v $LUCI_ROOT/src/main/remotedocker/jenkins/context/:/tmp/context docker run -d -p $jPort:8080  luci-jenkins
    [ $status -eq 0 ]    
    local cid=$output
    

    waitForJenkinsRunning $cid

    run runZettaTools docker inspect --format '{{ .State.Running }}' $cid
    [ $output = "true" ]

echo "Container up and running, now start test"

    #TO-DO This needs to run inside zetta-tools
    res=$(curl -s --head $LUCI_DOCKER_HOST:$jPort | head -n 1 | grep -c "HTTP/1.1 200 OK")
    [ $res = "1" ]

#    wget http://$LUCI_DOCKER_HOST:$jPort/jnlpJars/jenkins-cli.jar -O jenkins-cli.jar
#    java -jar jenkins-cli.jar -s http://localhost:$jPort/ create-job luci ./jobs/simpleJob.xml

#    java -jar jenkins-cli.jar -s http://localhost:$jPort/ build-job luci

#    rm -f jenkins-cli.jar

#Cleanup
    run runZettaTools docker rm -f $cid
}

