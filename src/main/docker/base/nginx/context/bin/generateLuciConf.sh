port=$1
services=$2
cat <<EOF
upstream docker-artifactory {
  server artifactory:8080;
}

upstream docker-jenkins {
  server jenkins:8080;
}

server {
  listen $port;
  root /luci/wwwroot;
  
  include /luci/etc/nginx/conf.d/*.conf;

  location / {
  
  }  

}
EOF



