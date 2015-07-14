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

  location /artifactory/ {
      ## proxy_pass http://docker-artifactory;
      ## proxy_read_timeout 90;
  # Start -- Kamran's config -- 2015-07-14
       proxy_buffering   off;
       proxy_set_header Host \$host;
       proxy_set_header X-Real-IP \$remote_addr;
       proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
       # proxy_set_header X-Forwarded-Ssl on;
       # proxy_set_header X-Forwarded-Proto https;

      # artifcatory is the name (link) of container linked with the nginx container
      # Note: Matgrutter's artifactory runs on a "http://hostname:8080/artifactory" out of the box.
      #       So a trailing /artifactory is necessary. 
      #       The location directive also as a trailing slash now.
      proxy_pass http://docker-artifactory/artifactory/;

      # proxy_pass http://caddie.novelda.no:8081/artifactory/;
      # proxy_pass http://172.17.42.1:8081/artifactory/;
      
  # End -- Kamran's config


  }

  location ^~ /ui/ {
      auth_basic off;
      proxy_pass http://docker-frontend/;
      proxy_redirect    off;
  }


}
EOF
