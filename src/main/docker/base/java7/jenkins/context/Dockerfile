FROM luci/java7:0.1

RUN apt-get install -y wget git zip 

ENV JENKINS_HOME /var/jenkins_home

# Jenkins home directoy is a volume, so configuration and build history 
# can be persisted and survive image upgrades
#VOLUME /var/jenkins_home

# `/usr/share/jenkins/ref/` contains all reference configuration we want 
# to set on a fresh new installation. Use it to bundle additional plugins 
# or config file with your custom jenkins Docker image.
RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d

COPY init.groovy /usr/share/jenkins/ref/init.groovy.d/tcp-slave-agent-port.groovy

ENV JENKINS_VERSION 1.609.2
ENV JENKINS_SHA 59215da16f9f8a781d185dde683c05fcf11450ef

# could use ADD but this one does not check Last-Modified header 
# see https://github.com/docker/docker/issues/8331
RUN curl -fL http://mirrors.jenkins-ci.org/war-stable/$JENKINS_VERSION/jenkins.war -o /usr/share/jenkins/jenkins.war \
  && echo "$JENKINS_SHA /usr/share/jenkins/jenkins.war" | sha1sum -c -

ENV JENKINS_UC https://updates.jenkins-ci.org

# for main web interface:
EXPOSE 8080

# will be used by attached slave agents:
EXPOSE 50000

ENV COPY_REFERENCE_FILE_LOG /var/log/copy_reference_file.log
RUN touch $COPY_REFERENCE_FILE_LOG 

COPY plugins.sh /usr/local/bin/plugins.sh
COPY plugins.txt /tmp/
RUN /usr/local/bin/plugins.sh /tmp/plugins.txt

COPY credentials.xml /usr/share/jenkins/ref/

COPY generateJenkinsConfigXml.sh /lucijenkins/
COPY generateJenkinsLocateConfiguration.sh /lucijenkins/
COPY slaves.conf /lucijenkins/

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

