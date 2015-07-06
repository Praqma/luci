#! /bin/sh

# Execute test on Jenkins

pwd

source $1/luci-setup.sh

$LUCI_ROOT/bin/runTests
