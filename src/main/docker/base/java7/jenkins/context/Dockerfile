FROM luci/java7:0.2

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

COPY addPlugin.sh /luci/bin/

# Install standard plugins
RUN /luci/bin/addPlugin.sh ssh-slaves:1.9 durable-task:1.5 token-macro:1.10 docker-plugin:0.11.0 parameterized-trigger:2.27 mailer:1.15
RUN /luci/bin/addPlugin.sh scm-api:0.2 promoted-builds:2.21 matrix-project:1.6 git-client:1.17.1 ssh-credentials:1.11 credentials:1.22
RUN /luci/bin/addPlugin.sh git:2.3.5 cloudbees-folder:4.8 vsphere-cloud:2.6 config-file-provider:2.8.1 job-dsl:1.35

COPY credentials.xml /usr/share/jenkins/ref/

COPY generateJenkinsConfigXml.sh /luci/bin/
COPY generateJenkinsLocateConfiguration.sh /luci/bin/
COPY createStaticSlaves.sh /luci/bin/
COPY connectSlave.sh /luci/bin/

COPY slaves.conf /luci/etc/
COPY cli.sh /usr/local/bin/

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

