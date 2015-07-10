#! /bin/bash

# Execute test on Jenkins

LUCI_ROOT=$(realpath $1)

. $1/luci-setup.sh

echo "Containers before tests:"
docker ps -a
echo "--- end ---"

$LUCI_ROOT/bin/runtests

echo "Containers after tests:"
docker ps -a
echo "--- end ---"
