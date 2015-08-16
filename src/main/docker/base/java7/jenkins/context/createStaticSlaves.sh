#! /bin/bash

nodesDir=${JENKINS_HOME:-/var/jenkins_home}/nodes/
for s in "$@" ; do
    echo "Creating node '$s'"
    slaveName=$s
    dir="$nodesDir/$slaveName"
    mkdir -p $dir
    cat > "$dir/config.xml" <<EOF
<?xml version='1.0' encoding='UTF-8'?>
<slave>
  <name>$slaveName</name>
  <description></description>
  <remoteFS></remoteFS>
  <numExecutors>2</numExecutors>
  <mode>NORMAL</mode>
  <retentionStrategy class="hudson.slaves.RetentionStrategy\$Always"/>
  <launcher class="hudson.slaves.JNLPLauncher"/>
  <label></label>
  <nodeProperties/>
  <userId>anonymous</userId>
</slave>
EOF
done
