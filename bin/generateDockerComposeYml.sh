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

  upstream docker-artifactory {
    server artifactory:8080;
  }

  server {
    listen 80;

  location / {
    proxy_pass http://docker-backend;
  }

  location /v1/_ping {
    proxy_pass http://docker-backend;
  }

  location /v1/users {
    proxy_pass http://docker-backend;
  }

  location /artifactory {
      proxy_pass http://docker-artifactory;
      proxy_read_timeout 90;
  }

  location ^~ /ui/ {
      auth_basic off;
      proxy_pass http://docker-frontend/;
      proxy_redirect    off;
  }


}
EOF
