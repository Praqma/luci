import hudson.model.*;
import jenkins.model.*;


Thread.start {
      sleep 10000
      int slaveAgentPort = System.getenv().JENKINS_SLAVE_AGENT_PORT
      println "--> setting agent port for jnlp ${slaveAgentPort}"
      Jenkins.instance.setSlaveAgentPort(slaveAgentPort)
}
