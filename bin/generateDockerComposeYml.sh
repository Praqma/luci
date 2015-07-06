#!/bin/sh

#define parameters which are passed in.
luci_docker_host=$1
jPort=$2

cat << EOF
upstream docker-backend {
  server registry:5000;
}

upstream docker-frontend {
  server hub:80;
}

server {
  server_name registry.praqma.net;
  listen 80;

  chunked_transfer_encoding on;


  client_max_body_size 0;

  proxy_set_header Host \$host;
  proxy_set_header X-Real-IP \$remote_addr;

  location /jenkins/ {
    # Fix the “It appears that your reverse proxy set up is broken" error.
    proxy_pass          http://$luci_docker_host:$jPort;
  }

  location / {
    proxy_pass http://docker-backend;
  }

    location /ui/ {
        rewrite /ui/(.*) /\$1 break;
        auth_basic off;
        proxy_pass http://docker-frontend;
        proxy_set_header        Host \$host;
        proxy_set_header        X-Real-IP \$remote_addr;
        proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

  location /v1/_ping {
    proxy_pass http://docker-backend;
  }

  location /v1/users {
    proxy_pass http://docker-backend;
  }
}
EOF
