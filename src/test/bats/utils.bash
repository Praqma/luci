source $LUCI_ROOT/functions/zetta-tools
source $LUCI_ROOT/functions/testing

### Cleanup after test execution
CLEANUP_CONTAINERS=()
CLEANUP_ACTIONS=()

# Stop and remove
# 1: Container name or id
function cleanup_container() {
    CLEANUP_CONTAINERS=(${CLEANUP_CONTAINERS[@]} $1)
}

# Creates a tempdir
# As default it is created inside the users home directory, so it is accessible on the host machine
# when running docker in boot2docker
function tempdir() {
    local parentDir=$LUCI_ROOT/build/tmp
    mkdir -p "$parentDir"
    mktemp -d -p "$parentDir"
}

### Create a temp dir that is deleted as part of cleanup
function cleanup_tempdir() {
    local name=$(tempdir)
    local action="rm -r $name"
    CLEANUP_ACTIONS=(${CLEANUP_ACTIONS[@]} action)
    echo $name
}

# Perform the actual cleanup
function cleanup_perform() {
    if [ -n "$CLEANUP_CONTAINERS" ] ; then
        local containers=${CLEANUP_CONTAINERS[@]}
        CLEANUP_CONTAINERS=()
        echo "Deleting containers:"
        runZettaTools docker rm -f ${containers[@]}
    fi
    for action in $CLEANUP_ACTIONS ; do
        eval "$action"
    done
    CLEANUP_ACTIONS=()
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
    if mv "$(find "$POOL_DIR/free" -type f -maxdepth 1 | head -1)" $tmpdir ; then
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



### Constructing test projects for Jenkins

# Construct a test project for Jenkins (i.e. a project that can be build by Jenkins)
# The git url for the project is returned.
# The project is registrered for automatically cleanup
function constructJenkinsTestProject() {
    # A test project for jenkins is constructed by merging the
    # source for a project with the buildsystem.
    # The
    local sourceDir="$LUCI_ROOT/src/test/jenkins-projects/$1"
    local buildSystemDir="$LUCI_ROOT/src/test/jenkins-buildsystems/$2"

    local target=$(cleanup_tempdir)

    cp -r $sourceDir/* $buildSystemDir/* $target

    (cd $target; git init; git add --all; git commit -m"Commit for Luci test project" )
    echo "file://$target"
}
