#!/bin/sh

#define parameters which are passed in.
LUCI_DATAVOLUME_ID=$1
LUCI_DOCKER_HOST=$2
LUCI_DOCKER_PORT=$3

#define the template.
cat  << EOF
<?xml version='1.0' encoding='UTF-8'?>
<hudson>
  <disabledAdministrativeMonitors/>
  <version>1.609.1</version>
  <numExecutors>2</numExecutors>
  <mode>NORMAL</mode>
  <useSecurity>true</useSecurity>
  <authorizationStrategy class="hudson.security.AuthorizationStrategy\$Unsecured"/>
  <securityRealm class="hudson.security.SecurityRealm\$None"/>
  <disableRememberMe>false</disableRememberMe>
  <projectNamingStrategy class="jenkins.model.ProjectNamingStrategy\$DefaultProjectNamingStrategy"/>
  <workspaceDir>\${JENKINS_HOME}/workspace/\${ITEM_FULLNAME}</workspaceDir>
  <buildsDir>\${ITEM_ROOTDIR}/builds</buildsDir>
  <jdks/>
  <viewsTabBar class="hudson.views.DefaultViewsTabBar"/>
  <myViewsTabBar class="hudson.views.DefaultMyViewsTabBar"/>
  <clouds>
    <com.nirima.jenkins.plugins.docker.DockerCloud plugin="docker-plugin@0.9.3">
      <name>LocalDocker</name>
      <templates>
        <com.nirima.jenkins.plugins.docker.DockerTemplate>
          <image>luci-ssh-slave</image>
          <dockerCommand></dockerCommand>
          <lxcConfString></lxcConfString>
          <hostname></hostname>
          <dnsHosts/>
          <volumes/>
          <volumesFrom2>
            <string>$LUCI_DATAVOLUME_ID</string>
          </volumesFrom2>
          <environment/>
          <bindPorts></bindPorts>
          <bindAllPorts>false</bindAllPorts>
          <privileged>false</privileged>
          <tty>false</tty>
          <labelString>ssh-slave</labelString>
          <credentialsId>cf65a07f-851a-4d80-aa44-8e5635ccd1e6</credentialsId>
          <idleTerminationMinutes>5</idleTerminationMinutes>
          <sshLaunchTimeoutMinutes>1</sshLaunchTimeoutMinutes>
          <jvmOptions></jvmOptions>
          <javaPath></javaPath>
          <prefixStartSlaveCmd></prefixStartSlaveCmd>
          <suffixStartSlaveCmd></suffixStartSlaveCmd>
          <remoteFsMapping></remoteFsMapping>
          <remoteFs>/home/jenkins</remoteFs>
          <instanceCap>2147483647</instanceCap>
          <mode>EXCLUSIVE</mode>
          <retentionStrategy class="com.nirima.jenkins.plugins.docker.strategy.DockerOnceRetentionStrategy">
            <idleMinutes>0</idleMinutes>
            <idleMinutes defined-in="com.nirima.jenkins.plugins.docker.strategy.DockerOnceRetentionStrategy">0</idleMinutes>
          </retentionStrategy>
          <numExecutors>1</numExecutors>
        </com.nirima.jenkins.plugins.docker.DockerTemplate>
      </templates>
      <serverUrl>http://$LUCI_DOCKER_HOST:$LUCI_DOCKER_PORT</serverUrl>
      <containerCap>2147483647</containerCap>
      <connectTimeout>5</connectTimeout>
      <readTimeout>15</readTimeout>
      <version></version>
      <credentialsId></credentialsId>
    </com.nirima.jenkins.plugins.docker.DockerCloud>
  </clouds>
  <quietPeriod>5</quietPeriod>
  <scmCheckoutRetryCount>0</scmCheckoutRetryCount>
  <views>
    <hudson.model.AllView>
      <owner class="hudson" reference="../../.."/>
      <name>All</name>
      <filterExecutors>false</filterExecutors>
      <filterQueue>false</filterQueue>
      <properties class="hudson.model.View\$PropertyList"/>
    </hudson.model.AllView>
  </views>
  <primaryView>All</primaryView>
  <slaveAgentPort>50000</slaveAgentPort>
  <label></label>
  <nodeProperties/>
  <globalNodeProperties/>
</hudson>
EOF
