FROM jenkins
MAINTAINER Henrik Hoegh <heh@praqma.net>
USER jenkins
COPY plugins.txt /usr/share/jenkins/plugins.txt
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/plugins.txt
