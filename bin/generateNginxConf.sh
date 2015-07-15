#!/bin/sh

cat << EOF
upstream docker-artifactory {
  server artifactory:8080;
}

server {
  listen 80;

  # Added a trailing / -- kamran
  location /artifactory/ {
    # commented the following two -- kamran
    ## proxy_pass http://docker-artifactory;
    ## proxy_read_timeout 90;

    ## Start --- Kamran introduced the following. 
      proxy_buffering   off;
      proxy_set_header Host \$host;
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
      # proxy_set_header X-Forwarded-Ssl on;
      # proxy_set_header X-Forwarded-Proto https;

      # artifcatory is the name (link) of container linked with the nginx container
      proxy_pass http://docker-artifactory/artifactory/;

      # proxy_pass http://caddie.novelda.no:8081/artifactory/;
      # proxy_pass http://172.17.42.1:8081/artifactory/;
    ## End --- Kamran introduced the above





  }

}
EOF
