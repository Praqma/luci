#! /bin/sh

function build {
    local path=$1
    local name=$(basename $1)
    local ver=$2
    echo "*** Building $path ***"
    docker build -t luci/$name:$ver $LUCI_ROOT/src/main/docker/$path/context
    echo "*** Done with $path ***"
    echo ''
}

build base 0.1
build base/java7 0.1
build base/java7/jenkins 0.1
build base/nginx 0.1
