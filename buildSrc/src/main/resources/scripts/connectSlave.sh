#! /bin/bash

slaveName=$1

slaveJar=/luci/data/jenkinsSlave/slave.jar

java -jar $slaveJar -jnlpUrl http://master:8080/jenkins/computer/$slaveName/slave-agent.jnlp
