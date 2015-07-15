#!/bin/sh

#define parameters which are passed in.
nginx_port=$1
nginx_image_name=$2

cat << EOF
proxy:
  image: $nginx_image_name
  ports:
   - "$nginx_port:80"
  links:
   - artifactory
artifactory:
  image: luci-artifactory
EOF
