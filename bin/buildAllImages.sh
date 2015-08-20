#! /bin/bash

doPush='no'

# TODO This logic doesn't work with spaces in file names
abspath=$(cd ${0%/*} && echo $PWD)
luciRoot=$(dirname $abspath)

echo "luciRoot: $luciRoot"

function buildHelper {
    local path=$1
    local name=$2
    local ver=$3
    local fullName="luci/$name:$ver"
    echo "*** Building $path ***"
    docker build -t $fullName $luciRoot/src/main/docker/$path/context
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
build data 0.2 &
build tools 0.2 &
(
    build base 0.2
    build base/mixin-java8 0.2 &
    build base/nginx 0.2 &
    (
        build base/java7 0.2
        build base/java7/jenkins 0.2 &
        (
            build base/java7/tomcat7 0.2
            build base/java7/tomcat7/artifactory 0.2
        ) &
        (
            build base/java7/slave-base 0.2
            build base/java7/slave-base/slave-shell 0.2 &
            build base/java7/slave-base/slave-gradle 0.2 &
            wait
        ) &
        wait
    ) &
    wait
) &
wait
echo "Built all luci images"
