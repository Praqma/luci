# Zetta Tools

Zetta.io is an Openstack based cloud provider. The images has a number of tools installed to interact with the
Zetta.io cloud.

## Authentication and Customization

You authenticate to Zetta.io with a domain, username, and password. You should define them in a .sh file
```
export ZETTA_DOMAIN_NAME=<your domain name>
export ZETTA_DOMAIN_ID=<your domain id>
export ZETTA_USERNAME=<your username>
export ZETTA_PASSWORD=<your password>
export ZETTA_PROJECT=<your project>  # Optional, if not defined it defaults to 'Standard'
```

This file should be in a directory that is bound during container creation.

For initialization the entrypoint sources all \*.sh files in ```/config```. You should bind this directory to a directory with your customization files. At lease the authentication parameter should be defined.

## Docker Machine

docker-machine has its data stored in ``~/.docker/machine``. This directory is defined as a volume, you might want to bind it to a directory of your choice, for example ~/.docker/machine on the host.

## Docker Client

The image contains no docker client. Instead you are supposed to bind the hosts client. Assuming the client on the host is in /usr//local/bin/docker the paramter will be
```
-v /usr/local/bin/docker:/usr/local/bin/docker
```

If you further more wants to interact with the host running the container (e.g. you linux box or boot2docker on OSX/Windows), you can add
```
-v /var/run/docker.sock:/var/run/docker.sock
```
