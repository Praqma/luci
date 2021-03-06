source $LUCI_ROOT/functions/zetta-tools
source $LUCI_ROOT/functions/testing
source $LUCI_ROOT/functions/cleanup

# Implement bats setup. Bats script should *NOT* implement this. Currently no alternative provided
setup() {
    docker run --rm -v /var/lib/docker:/docker ubuntu:14.04 ls -1 /docker/volumes > /tmp/luci-$BATS_TEST_NAME-volumes.txt
}

# Implement the bats teardown
# Test cases that needs teardown logic should user cleanup_??? (TODO implement method)
teardown() {
    cleanup_perform
}

# Creates a tempdir
# As default it is created inside the users home directory, so it is accessible on the host machine
# when running docker in boot2docker
function tempdir() {
    local parentDir=$LUCI_ROOT/build/tmp
    mkdir -p "$parentDir"
    mktemp -d -p "$parentDir"
}

### Docker Machnine pool
#
# Implementation of a pool of docker machines that can be used in tests.
# A docker machine is aquired with 'dockerMachineAquire'. It returns the name of the machine.
# When done using the machine it *must* be returned to the pool with 'dockerMachineRelease'
#
#

POOL_DIR=$LUCI_DATA/dmpool
AQUIRED_MACHINES=()
function dockerMachineRelease() {
    for name in $1 ; do
        _cleanDockerMachine "$name"
        mv "$POOL_DIR/busy/$name" "$POOL_DIR/free/$name"
        touch "$POOL_DIR/free/$name" # update timestamp
        echo "Released: $name"
    done
}

# args:
# 1: Variable to assign name of machine
# 2: Description/purpose for the aquisition
function dockerMachineAquire() {
    mkdir -p "$POOL_DIR/free"
    mkdir -p "$POOL_DIR/busy"

    local var=#1
    local desc=$2
    [ -n "$desc" ] || (echo "Missing 'desc' for aquiring docker machine" ; exit 1)

    local name
    local tmpdir=$(mktemp -d)
    # Move the newest free machine to tmpdir. If move fails assume there is no free machine in pool
    while mv "$(find "$POOL_DIR/free" -type f -maxdepth 1 | head -1)" $tmpdir ; do
        local n="$(ls -1 $tmpdir | head -1)"
        # Check if the machine exists? Is server show the best way to do that?
        if runZettaTools openstack server show $n > /dev/null ; then
            mv "$tmpdir/$n" "$POOL_DIR/busy"
            echo "Docker machine '$n' obtained from pool"
            name=$n
            break
        fi
    done
    if [ -z "$name" ] ; then
        name="lucitest-$USER-$(date +%Y%m%d-%H%M%S)"
        runZettaTools docker-machine-create --openstack-sec-groups default,lucitest $name
        _initDockerMachine "$name"
        echo "Docker machine '$name' created"
    fi
    echo "$desc" >> "$POOL_DIR/busy/$name"
    eval "$1=$name"
    AQUIRED_MACHINES=(${AQUIRED_MACHINES[@]} $name)
    return 0
}

# Release all docker machines aquired since last call to this method
# Suggestion: Call this from teardown in bats test, and you don't have to bother about
# releasing machines in individual test cases
function dockerMachineReleaseAll() {
    local machines=$AQUIRED_MACHINES

    AQUIRED_MACHINES=()
    dockerMachineRelease $machines
}

_cleanDockerMachine() {
    local containers=$(docker ps -aq) ; [ -n "$containers" ] && docker rm -f $containers
    [ -n "$containers" ] && runZettaTools docker rm -f $containers
}

_initDockerMachine() {
    true # noop
}
