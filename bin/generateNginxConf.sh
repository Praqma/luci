#!/bin/sh

cat << EOF
upstream docker-artifactory {
  server artifactory:8080;
}

server {
  listen 80;

  location /artifactory {
    proxy_pass http://docker-artifactory;
    proxy_read_timeout 90;
  }

}
EOF
