#! /bin/bash

# Execute test on Jenkins

LUCI_ROOT=$1

. $1/luci-setup.sh

$LUCI_ROOT/bin/runtests
