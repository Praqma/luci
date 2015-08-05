#! /bin/sh

docker build -t luci/base:0.1 base/context/
docker build -t luci/java7:0.1 base/java7/context/
docker build -t luci/jenkins:0.1 base/java7/jenkins/context
docker build -t luci/nginx:0.1 base/nginx/context
