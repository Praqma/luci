#! /bin/bash

doPush='yes'

function buildHelper {
    local path=$1
    local name=$2
    local ver=$3
    local fullName="luci/$name:$ver"
    echo "*** Building $path ***"
    docker build -t $fullName $LUCI_ROOT/src/main/docker/$path/context
    local rc=$?
    if [ "$doPush" = 'yes' ] ; then
        echo "Pushing $fullName"
        docker push $fullName
    fi
    echo "*** Done with $path. RC: $rc ***"
    echo ''
}

function build {
    local path=$1
    local name=$(basename $1)
    local ver=$2
    buildHelper $path $name $ver | awk "\$0=\"$name:\t\"\$0"
}

build tools 0.1 &
(
    build base 0.1
    build base/nginx 0.1 &
    (
        build base/java7 0.1
        build base/java7/jenkins 0.1 &
        (
            build base/java7/tomcat7 0.1 
            build base/java7/tomcat7/artifactory 0.1
        ) &
        (
            build base/java7/slave-base 0.1
            build base/java7/slave-base/slave-shell 0.1 &
            build base/java7/slave-base/slave-gradle 0.1 &
            wait
        ) &
        wait
    ) &
    wait
) &
wait
echo "Built all luci images"
