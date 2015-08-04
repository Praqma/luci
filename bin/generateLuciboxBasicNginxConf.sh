# This script outputs the nginx configuration file for
# Jenkins and artifactory behind nginx.
# 1: Name of jenkins master container
# 2: Name of artifactory container
jenkinsContainer=$1 # Container to create
artifactoryContainer=$2
cat << EOF
upstream docker-artifactory {
  server $artifactoryContainer:8080;
}

upstream docker-jenkins {
  server $jenkinsContainer:8080;
}

server {
  listen 80;

location ^~ /jenkins {
    proxy_redirect     off;
    proxy_pass http://docker-jenkins/jenkins;
    proxy_buffering   off;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
}


location /artifactory/ {
      proxy_buffering   off;
      proxy_set_header Host \$host;
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_pass http://docker-artifactory/artifactory/;
  }
}
EOF
