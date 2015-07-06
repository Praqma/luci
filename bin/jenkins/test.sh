#! /bin/sh

# Execute test on Jenkins

pwd
echo JHS "$@" JHS
echo JHS "$1" JHS

source /var/jenkins_home/workspace/LUCI/luci-setup.sh

$LUCI_ROOT/bin/runTests
