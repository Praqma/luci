#! /bin/bash

# Execute test on Jenkins

LUCI_ROOT=$(realpath $1)

. $1/luci-setup.sh

docker run --rm -v /var/lib/docker:/docker ubuntu:14.04 ls -1 /docker/volumes > /tmp/luci-volumes.txt

echo "Containers before tests:"
docker ps -a
echo "--- end ---"

$LUCI_ROOT/bin/runtests
rc=$?

echo "Containers after tests:"
docker ps -a
echo "--- end ---"

echo "New Docker volumes"
docker run --rm -v /var/lib/docker:/docker ubuntu:14.04 ls -1 /docker/volumes | grep -Fxv -f /tmp/luci-volumes.txt
echo "--- end ---"

exit $rc
