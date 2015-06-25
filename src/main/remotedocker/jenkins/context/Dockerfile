FROM jenkins:1.609.1

MAINTAINER Praqma <info@praqma.net>
USER jenkins
#The credentials.xml will be copied to JENKINS_HOME by entrypoint
COPY credentials.xml /usr/share/jenkins/ref/

# Install plugins
COPY plugins.txt /data/
RUN /usr/local/bin/plugins.sh /data/plugins.txt

