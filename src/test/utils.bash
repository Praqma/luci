source $LUCI_ROOT/functions/zetta-tools

function group() {
    case $1 in
        complete) # Skip test unless we are execution complete test group
            [ $TEST_GROUP = 'complete' ] || skip "part of 'complete' group"
            ;;

        quick) # Never skip quick tests
            ;;
        *)
            echo "Invalid test group '$1'"
            exit 1
    esac
}

### Docker Machnine pool
#
# Implementation of a pool of docker machines that can be used in tests.
# A docker machine is aquired with 'dockerMachineAquire'. It returns the name of the machine.
# When done using the machine it *must* be returned to the pool with 'dockerMachineRelease'
#
# 
POOL_DIR=$LUCI_CONFIG/dmpool
function dockerMachineRelease() {
    local name=$1
    _cleanDockerMachine "$name"
    mv "$POOL_DIR/busy/$name" "$POOL_DIR/free/$name"
    touch "$POOL_DIR/free/$name" # update timestamp
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
    if mv "$(find "$POOL_DIR/free -type f -depth 1" | head -1)" $tmpdir ; then
        name="$(ls -1 $tmpdir | head -1)"
        mv "$tmpdir/$name" "$POOL_DIR/busy"
        echo "Docker machine '$name' obtained from pool"
    else
        name="lucitest-$USER-$(date +%Y%m%d-%H%M%S)"
        runZettaTools docker-machine-create --openstack-sec-groups default,lucitest $name
        _initDockerMachine "$name"
        echo "Docker machine '$name' created"
    fi
    echo "$desc" >> "$POOL_DIR/busy/$name"
    eval "$1=$name"
    return 0
}

_cleanDockerMachine() {
    runZettaTools docker rm -f $(docker ps -q) || true
}

_initDockerMachine() {
    true # noop
}
