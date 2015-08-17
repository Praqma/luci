package net.praqma.luci.model

import net.praqma.luci.docker.DataContainer
import net.praqma.luci.model.yaml.Context
import net.praqma.luci.utils.ExternalCommand

class JenkinsModel extends BaseServiceModel {

    int slaveAgentPort = -1 // -1 => Let LUCI assing port

    private Map<String, StaticSlaveModel> staticSlaves = [:]

    @Override
    void addToComposeMap(Map map, Context context) {
        super.addToComposeMap(map, context)
        map.command = ['-d', 'luci-slave-data',
                       '-c', "http://${context.box.dockerHost.host}" as String,
                       '-j', "http://${context.box.dockerHost.host}/jenkins" as String,
                       '-e', 'luci@praqma.net',
                       '-a', slaveAgentPort as String]
        if (staticSlaves.size() > 0) {
            map.command << '-s' << staticSlaves.keySet().join(' ')
        }
        map.command << '--' << '--prefix=/jenkins'
        map.ports = ["${slaveAgentPort}:${slaveAgentPort}" as String] // for slave connections
        //map.ports << '10080:8080' // Enter container without nginx, for debug
        map.volumes = ['/usr/local/bin/docker:/usr/local/bin/docker', '/var/run/docker.sock:/var/run/docker.sock']
    }

    void addServicesToMap(Map<String, ?> map, Context context) {
        staticSlaves.each { String name, StaticSlaveModel slave ->
            map[slave.serviceName] = slave.buildComposeMap(context)
        }
    }

    void staticSlave(String slaveName, Closure closure) {
        StaticSlaveModel slave = new StaticSlaveModel()
        slave.with closure
        slave.slaveName = slaveName
        slave.serviceName = "${ServiceEnum.JENKINS.name}${slaveName.capitalize()}"
        slave.box = box
        staticSlaves[slaveName] = slave
    }

    /**
     * Execute a cli command against jenkins
     */
    void cli(List<String> cmd, Closure input) {
        new ExternalCommand().execute(["docker", "exec", "${box.name}_jenkins_1", *cmd], null, input)
    }

    void preStart() {
        if (slaveAgentPort == -1) {
            slaveAgentPort = assignSlaveAgentPort()
        }
        // Create data container with slave.jar and slaveConnect.sh script
        // used by static slaves to connect to master
        DataContainer data = new DataContainer(box, 'jenkinsSlave')
        DataContainer.Volume volume = data.volume('/luci/data/jenkinsSlave')
        data.create()
        Closure c = { InputStream inputStream ->
            volume.file('slave.jar').addStream(inputStream)
        }
        int rc = new ExternalCommand().execute(['docker', 'run', '--rm', dockerImage, 'unzip', '-p', '/usr/share/jenkins/jenkins.war', 'WEB-INF/slave.jar'], c)
        assert rc == 0
        volume.file('slaveConnect.sh').addResource('scripts/connectSlave.sh')
    }

    private void createSecretsContainer(String containerName) {
        "docker run luci/tools:0.2 "
    }

    // Map of slave agent ports assigned to a lucibox
    private static Map<String, Integer> assingedPorts = [:]
    private int assignSlaveAgentPort() {
        if (assingedPorts[box.name] != null) return assingedPorts[box.name]
        Set<Integer> ports = assingedPorts.values() as Set
        ports.addAll(box.dockerHost.boundPorts())
        Integer port = (50000..50099).find { !ports.contains(it) }
        if (port == null) {
            throw new RuntimeException("No available slave agent port")
        }
        assingedPorts[box.name] = port
        return port
    }

}
