#!/bin/sh

#define parameters which are passed in.
luci_datacontainer=$1
luci_docker_host=$2
luci_docker_port=$3

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
EOF

cat << CLOUD_HEADER
  <clouds>
    <com.nirima.jenkins.plugins.docker.DockerCloud plugin="docker-plugin@0.10.0">
      <name>LocalDocker</name>
      <templates>
CLOUD_HEADER
dirs=$(find $LUCI_ROOT/src/main/remotedocker/jenkins-slaves -maxdepth 1 -mindepth 1 -type d)
for d in $dirs; do
    slave=$(basename $d)
    cat << CLOUD_TEMPLATE
    <com.nirima.jenkins.plugins.docker.DockerTemplate>
      <configVersion>1</configVersion>
      <labelString>$slave</labelString>
      <launcher class="com.nirima.jenkins.plugins.docker.launcher.DockerComputerSSHLauncher">
        <sshConnector plugin="ssh-slaves@1.9">
          <port>22</port>
          <credentialsId>cf65a07f-851a-4d80-aa44-8e5635ccd1e6</credentialsId>
          <jvmOptions></jvmOptions>
          <javaPath></javaPath>
          <launchTimeoutSeconds>60</launchTimeoutSeconds>
          <maxNumRetries>5</maxNumRetries>
          <retryWaitTime>3</retryWaitTime>
        </sshConnector>
      </launcher>
      <remoteFsMapping></remoteFsMapping>
      <remoteFs>/home/jenkins</remoteFs>
      <instanceCap>2147483647</instanceCap>
      <mode>EXCLUSIVE</mode>
      <retentionStrategy class="com.nirima.jenkins.plugins.docker.strategy.DockerOnceRetentionStrategy">
        <idleMinutes>0</idleMinutes>
        <idleMinutes defined-in="com.nirima.jenkins.plugins.docker.strategy.DockerOnceRetentionStrategy">0</idleMinutes>
      </retentionStrategy>
      <numExecutors>1</numExecutors>
      <dockerTemplateBase>
        <image>luci-$slave-slave</image>
        <dockerCommand></dockerCommand>
        <lxcConfString></lxcConfString>
        <hostname></hostname>
        <dnsHosts/>
        <volumes/>
        <volumesFrom2>
          <string>$luci_datacontainer</string>
        </volumesFrom2>
        <environment/>
        <bindPorts></bindPorts>
        <bindAllPorts>false</bindAllPorts>
        <privileged>false</privileged>
        <tty>false</tty>
      </dockerTemplateBase>
    </com.nirima.jenkins.plugins.docker.DockerTemplate>
CLOUD_TEMPLATE
done

cat << CLOUD_FOOTER
      </templates>
      <serverUrl>http://$luci_docker_host:$luci_docker_port</serverUrl>
      <containerCap>2147483647</containerCap>
      <connectTimeout>5</connectTimeout>
      <readTimeout>15</readTimeout>
      <version></version>
      <credentialsId></credentialsId>
    </com.nirima.jenkins.plugins.docker.DockerCloud>
  </clouds>
CLOUD_FOOTER

cat << EOF
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
