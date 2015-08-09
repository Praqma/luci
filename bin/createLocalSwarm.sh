# This script creates a Swarm on a local VirtualBox
# Still in Beta...

swarmId=$(docker-swarm c)

echo "swarmId = $swarmId"

docker-machine create --driver virtualbox luci-swarm-master

docker-machine ssh luci-swarm-master<<SSH
  sudo sh -c 'echo -e " \
    EXTRA_ARGS=\"--label provider=virtualbox\" \n \
    DOCKER_HOST=\"-H tcp://0.0.0.0:2376\" \n \
    DOCKER_STORAGE=aufs \n \
    DOCKER_TLS=no" > /var/lib/boot2docker/profile'
SSH

# TODO without -D the machine fails to restart on Jan's macbook
docker-machine -D restart luci-swarm-master

docker-machine create --driver virtualbox luci-swarm-node-01

docker-machine ssh luci-swarm-node-01<<SSH
  sudo sh -c 'echo -e " \
    EXTRA_ARGS=\"--label provider=virtualbox\" \n \
    DOCKER_HOST=\"-H tcp://0.0.0.0:2376\" \n \
    DOCKER_STORAGE=aufs \n \
    DOCKER_TLS=no" > /var/lib/boot2docker/profile'
SSH

docker-machine -D restart luci-swarm-node-01

# Get ips of the master node and start swarm
masterIP=$(docker-machine ls|grep "swarm-master" |cut -d "/" -f3)
echo "masterIP = $masterIP"

# Create a swarm manager
docker-machine ssh luci-swarm-master "docker run -d -p 3375:2375 swarm manage token://$swarmId"

# Create a swarm master node
docker-machine ssh luci-swarm-master "docker run -d swarm join --addr=$masterIP token://$swarmId"

# Get ips of the node and start swarm
node01IP=$(docker-machine ls|grep "swarm-node-01" |cut -d "/" -f3)
echo "node01IP = $node01IP"

# Create a swarm node
docker-machine ssh luci-swarm-node-01 "docker run -d swarm join --addr=$node01IP token://$swarmId"

sleep 10

managerIP=$(echo $masterIP|cut -d":" -f1):3375
echo "
Your docker host should point at $managerIP
"

# Examples (alter localhost to swarm-master ip, if used)
docker -H tcp://$managerIP --tls=false info
#docker -H tcp://$managerIP run -d -p 80:80 nginx
#docker -H tcp://$managerIP run -d -p 80:80 nginx
#docker -H tcp://$managerIP ps
