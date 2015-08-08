# This script creates a Swarm on a local VirtualBox
# Still in Beta...

SwarmID=$(docker run swarm create)

  echo "SwarmID = $SwarmID"

  docker-machine create --driver virtualbox luci-swarm-master

docker-machine ssh luci-swarm-master<<SSH
  sudo sh -c 'echo -e " \
    EXTRA_ARGS=\"--label provider=virtualbox\" \n \
    DOCKER_HOST=\"-H tcp://0.0.0.0:2376\" \n \
    DOCKER_STORAGE=aufs \n \
    DOCKER_TLS=no" > /var/lib/boot2docker/profile'
SSH

  docker-machine restart luci-swarm-master

  docker-machine create --driver virtualbox luci-swarm-node-01

docker-machine ssh luci-swarm-node-01<<SSH
  sudo sh -c 'echo -e " \
    EXTRA_ARGS=\"--label provider=virtualbox\" \n \
    DOCKER_HOST=\"-H tcp://0.0.0.0:2376\" \n \
    DOCKER_STORAGE=aufs \n \
    DOCKER_TLS=no" > /var/lib/boot2docker/profile'
SSH

  docker-machine restart luci-swarm-node-01

  # Get ips of the master node and start swarm
  masterIP=$(docker-machine ls|grep "swarm-master" |cut -d "/" -f3)
  echo "masterIP = $masterIP"

  # Create a swarm manager
  docker-machine ssh luci-swarm-master "docker run -d -p 3376:2375 swarm manage token://$SwarmID"

  # Create a swarm master node
  docker-machine ssh luci-swarm-master "docker run -d swarm join --addr=$masterIP token://$SwarmID"


  # Get ips of the node and start swarm
  node01IP=$(docker-machine ls|grep "swarm-node-01" |cut -d "/" -f3)
  echo "node01IP = $node01IP"

  # Create a swarm node
  docker-machine ssh luci-swarm-node-01 "docker run -d swarm join --addr=$node01IP token://$SwarmID"

  sleep 10

  managerIP=$(echo $masterIP|cut -d":" -f1):3376
  echo "
Your docker host should point at $managerIP
"

  # Examples (alter localhost to swarm-master ip, if used)
  docker -H tcp://$managerIP info
  #docker -H tcp://$managerIP run -d -p 80:80 nginx
  #docker -H tcp://$managerIP run -d -p 80:80 nginx
  #docker -H tcp://$managerIP ps

