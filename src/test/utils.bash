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

