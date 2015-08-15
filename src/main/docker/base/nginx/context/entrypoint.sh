#! /bin/bash

while getopts "s:" arg; do
  case $arg in
      s) services=$OPTARG          ;;  # enabled services      
  esac
done
echo "Services: $servies"

shift $((OPTIND-1))

mkdir -p /luci/etc/nginx/conf.d

for s in $services ; do
    ln -s /luci/etc/nginx/available.d/$s.conf /luci/etc/nginx/conf.d/
done

exec nginx -g "daemon off;" "$@"


