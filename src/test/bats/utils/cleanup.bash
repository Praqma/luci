###
# Functionality to cleanup after test execution
###

CLEANUP_CONTAINERS=()
CLEANUP_ACTIONS=()

# Stop and remove
# 1: Container name or id
function cleanup_container() {
    CLEANUP_CONTAINERS=(${CLEANUP_CONTAINERS[@]} $1)
}

### Create a temp dir that is deleted as part of cleanup
function cleanup_tempdir() {
    local name=$(tempdir)
    local action="rm -r $name"
    CLEANUP_ACTIONS=(${CLEANUP_ACTIONS[@]} action)
    echo $name
}

function timestamp() {
    date +%Y%m%d-%H%M%S.%s
}

# Perform the actual cleanup
function cleanup_perform() {
    local testInfoDir="$LUCI_ROOT/build/testInfo/$BATS_TEST_NAME"
    rm -rf "$testInfoDir"
    mkdir -p "$testInfoDir"
    if [ -n "$CLEANUP_CONTAINERS" ] ; then
        local containers=${CLEANUP_CONTAINERS[@]}
        CLEANUP_CONTAINERS=()
        echo "Cleanup containers:"
        for e in $containers ; do
            local dir="$testInfoDir/$e"
            echo $e
            mkdir -p $dir
            runZettaTools docker inspect $e > "$dir/inspect.json"
            runZettaTools docker logs $e > "$dir/log.txt"
        done
        runZettaTools docker rm -f ${containers[@]}
    fi
    for action in $CLEANUP_ACTIONS ; do
        eval "$action"
    done
    CLEANUP_ACTIONS=()
    cat $(ls -t1 ${TMPDIR%/}/bats*.out | head -1) > "$testInfoDir/bats.log"
}
