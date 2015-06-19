#! /usr/bin/env bats

load utils
jPort=18080

@test "Running Jenkins container" {
#Prepare
    runZettaTools -v $LUCI_ROOT/src/main/remotedocker/jenkins/context/:/tmp/context docker build -t luci-jenkins /tmp/context/


#Verify
    run runZettaTools -v $LUCI_ROOT/src/main/remotedocker/jenkins/context/:/tmp/context docker run -d -p $jPort:8080  luci-jenkins
    [ $status -eq 0 ]    
    local cid=$output

    sleep 15

# TO-DO
#    run docker logs -f $cid 2>&1 | while read line; do
#    case "$line" in 
#      *"Jenkins is fully up and running"*)
#        jenkinsState="done"
#        echo "Found Jenkins!"
#        exit 123
#        ;;
#      *)
#        ;;
#      esac
#    done 
#    rc=$?
#    echo $rc
#    echo $jenkinsState
#    [ $rc -eq 123 ]

    run runZettaTools docker inspect --format '{{ .State.Running }}'  $cid
    [ $output = "true" ]

    res=$(curl -s --head localhost:$jPort | head -n 1 | grep -c "HTTP/1.1 200 OK")
    [ $res = "1" ]

    wget http://localhost:$jPort/jnlpJars/jenkins-cli.jar -O jenkins-cli.jar
#    java -jar jenkins-cli.jar -s http://localhost:$jPort/ create-job luci ./jobs/simpleJob.xml

#    java -jar jenkins-cli.jar -s http://localhost:$jPort/ build-job luci

    rm -f jenkins-cli.jar

#Cleanup
#    run runZettaTools docker rm -f $cid
}

