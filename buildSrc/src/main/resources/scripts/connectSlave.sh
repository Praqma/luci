#! /bin/bash

slaveName=$1

slaveJar=/luci/data/jenkinsSlave/slave.jar

/luci/mixins/java/bin/java -jar $slaveJar -jnlpUrl http://master:8080/jenkins/computer/$slaveName/slave-agent.jnlp
