#!/bin/sh

#define parameters which are passed in.
nginx_port=$1
nginx_name=$2

cat << EOF
proxy:
  image: $nginx_name
  ports:
   - "$nginx_port:80"
  links:
   - registry
   - hub
   - artifactory
registry:
  image: registry:0.9.1
  environment:
   - STORAGE_PATH=/mnt/registry
  volumes:
   - /mnt/praqma/registry:/mnt/registry
hub:
  image: konradkleine/docker-registry-frontend
  links:
   - registry
  environment:
   - ENV_DOCKER_REGISTRY_HOST=registry
   - ENV_DOCKER_REGISTRY_PORT=5000
artifactory:
  image: luci-artifactory
EOF
