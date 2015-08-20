#! /bin/bash

# Execute test on Jenkins

LUCI_ROOT=$(realpath $1)

cd $LUCI_ROOT

# Volumes before executing luci
docker run --rm -v /var/lib/docker:/docker debian:jessie ls -1 /docker/volumes > /tmp/luci-volumes.txt

echo "Containers before tests:"
docker ps -a
echo "--- end ---"

$LUCI_ROOT/bin/buildAllImages.sh

./gradlew luciDemoUp
sleep 20
./gradlew luciDemoDestroy

echo "Containers after tests:"
docker ps -a
echo "--- end ---"

echo "New Docker volumes"
docker run --rm -v /var/lib/docker:/docker debian:jessie ls -1 /docker/volumes | grep -Fxv -f /tmp/luci-volumes.txt
echo "--- end ---"

exit $rc
