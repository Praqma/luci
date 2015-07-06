#! /bin/sh

# Execute test on Jenkins

LUCI_ROOT=$1

. /var/jenkins_home/workspace/LUCI/luci-setup.sh

$LUCI_ROOT/bin/runTests
