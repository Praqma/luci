#! /bin/bash

functionDir=$(dirname $(dirname $(realpath $0)))/functions

# TODO remove reference to LUCI_ROOT
source $functionDir/../src/test/bats/utils.bash
source $functionDir/ssh-keys
source $functionDir/docker-functions
source $functionDir/web-functions
source $functionDir/jenkins-functions
source $functionDir/utility-functions
source $functionDir/data-container

runZettaTools docker-machine ls

SwarmID=$(docker run swarm create)
echo "SwarmID = $SwarmID"

# Creating host for LuciBox
runZettaTools docker-machine-create --openstack-sec-groups default,DockerAPI luci-box

# Restart the host
#runZettaTools docker-machine restart luci-box

# Creating host for swarm master and manager
runZettaTools docker-machine-create --openstack-sec-groups default,lucitest luci-swarm-master

# Removing TLS
runZettaTools docker-machine ssh luci-swarm-master<<SSH
  sudo sh -c 'echo -e " \
    EXTRA_ARGS=\"--label provider=virtualbox\" \n \
    DOCKER_HOST=\"-H tcp://0.0.0.0:2376\" \n \
    DOCKER_STORAGE=aufs \n \
    DOCKER_TLS=no" > /var/lib/boot2docker/profile'
SSH

# Restart the host, for non-TLS to kick in
runZettaTools docker-machine restart luci-swarm-master

# Creating host for swarm node 01
runZettaTools docker-machine-create --openstack-sec-groups default,lucitest luci-swarm-node-01

# Removing TLS
runZettaTools docker-machine ssh luci-swarm-node-01<<SSH
  sudo sh -c 'echo -e " \
    EXTRA_ARGS=\"--label provider=virtualbox\" \n \
    DOCKER_HOST=\"-H tcp://0.0.0.0:2376\" \n \
    DOCKER_STORAGE=aufs \n \
    DOCKER_TLS=no" > /var/lib/boot2docker/profile'
SSH

# Restart the host, for non-TLS to kick in
runZettaTools docker-machine restart luci-swarm-node-01

# Get ips of the master node and start swarm
  masterIP=$(runZettaTools docker-machine ls|grep "swarm-master" |cut -d "/" -f3)
  echo "masterIP = $masterIP"

echo "The rest need working!"
exit
# WORKING UNTIL HERE!!!

# Create a swarm manager
runZettaTools docker-machine ssh luci-swarm-master "docker run -d -p 3376:2375 swarm manage token://$SwarmID"

# Create a swarm master node
runZettaTools docker-machine ssh luci-swarm-master "docker run -d swarm join --addr=$masterIP token://$SwarmID"

# Get ips of the node and start swarm
node01IP=$(runZettaTools docker-machine ls|grep "swarm-node-01" |cut -d "/" -f3)
echo "node01IP = $node01IP"

# Create a swarm node
runZettaTools docker-machine ssh luci-swarm-node-01 "docker run -d swarm join --addr=$node01IP token://$SwarmID"

sleep 10

managerIP=$(echo $masterIP|cut -d":" -f1):3376
  echo "
Your docker host should point at $managerIP
"
docker -H tcp://$managerIP info

echo "

Remember to remove global ips to nodes in Zetta dashboard.
