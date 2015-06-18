FROM jenkins:1.609.1
MAINTAINER Praqma <info@praqma.net>
USER jenkins
COPY plugins.txt /usr/share/jenkins/plugins.txt
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/plugins.txt
