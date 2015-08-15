#! /bin/bash

# Download and install plugins specified on command line

set -e

REF=/usr/share/jenkins/ref/plugins
mkdir -p $REF

for spec in "$@" ; do
    plugin=(${spec//:/ });
    [[ ${plugin[0]} =~ ^# ]] && continue
    [[ ${plugin[0]} =~ ^\s*$ ]] && continue
    [[ -z ${plugin[1]} ]] && plugin[1]="latest"
    echo "Downloading ${plugin[0]}:${plugin[1]}"
    curl -s -L -f ${JENKINS_UC}/download/plugins/${plugin[0]}/${plugin[1]}/${plugin[0]}.hpi -o $REF/${plugin[0]}.jpi
done

