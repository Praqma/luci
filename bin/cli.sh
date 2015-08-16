#! /bin/bash

cliJar=/luci/data/jenkins/cache/jenkins-cli.jar

mkdir -p $(dirname $clijar)

if [ ! -f $cliJar ] ; then
    curl http://localhost:8080/jenkins/jnlpJars/jenkins-cli.jar > $cliJar
fi

java -jar $cliJar -s http://localhost:8080/jenkins/ "$@"
