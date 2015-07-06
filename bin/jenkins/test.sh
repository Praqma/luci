#! /bin/sh

# Execute test on Jenkins

pwd
echo JHS "$@" JHS

source $1/luci-setup.sh

$LUCI_ROOT/bin/runTests
