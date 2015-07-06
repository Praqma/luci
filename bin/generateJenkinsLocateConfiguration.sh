#!/bin/sh

#define parameters which are passed in.
luci_docker_host=$1
luci_jenkins_port=$2
admin_email=$3

cat << EOF
<?xml version='1.0' encoding='UTF-8'?>
<jenkins.model.JenkinsLocationConfiguration>
  <adminAddress>$admin_email</adminAddress>
  <jenkinsUrl>http://$luci_docker_host:$luci_jenkins_port/</jenkinsUrl>
</jenkins.model.JenkinsLocationConfiguration>
EOF
