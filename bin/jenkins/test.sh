#! /bin/sh

# Execute test on Jenkins

pwd

source $0/luci-setup.sh

$LUCI_ROOT/bin/runTests
