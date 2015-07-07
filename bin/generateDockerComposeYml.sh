#!/bin/sh

#define parameters which are passed in.
luci_jenkins_host=$1
jPort=$2

cat << EOF
upstream docker-backend {
  server registry:5000;
}

upstream docker-frontend {
  server hub:80;
}

server {
#  server_name registry.praqma.net;
  listen 80;

  location / {
    proxy_pass http://registry:5000;
  }

  location /v1/_ping {
    proxy_pass http://docker-backend;
  }

  location /v1/users {
    proxy_pass http://docker-backend;
  }

  location /ui/ {
      rewrite           ^/ui/(.*) /$1 break;
      proxy_pass http://hub:80;
      proxy_redirect    off;
    }

}
EOF
