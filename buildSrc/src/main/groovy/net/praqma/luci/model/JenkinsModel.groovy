package net.praqma.luci.model

import groovy.transform.CompileDynamic
import groovy.transform.CompileStatic
import net.praqma.luci.docker.Container
import net.praqma.luci.docker.ContainerKind
import net.praqma.luci.docker.DockerHost
import net.praqma.luci.utils.ExternalCommand

@CompileStatic
class JenkinsModel extends BaseServiceModel {

    int slaveAgentPort = -1 // -1 => Let LUCI assing port

    /** Number of executors for master */
    int executors = 0

    private Map<String, StaticSlaveModel> staticSlaves = [:]

    private Map<String, OnDemandSlaveModel> onDemandSlaves = [:]

    private List<String> pluginList = []

    void plugins(String... plugins) {
        pluginList.addAll(plugins)
    }

    @Override
    @CompileDynamic
    void addToComposeMap(Map map, Context context) {
        super.addToComposeMap(map, context)


        DockerHost h = context.box.dockerHost
        String url = "http://${h.host}:${h.port}"
        map.command = ['-d', 'luci-slave-data',
                       '-c', "http://${h.host}:${h.port}" as String,
                       '-j', "http://${h.host}:${box.port}/jenkins" as String,
                       '-e', 'luci@praqma.net',
                       '-x', executors as String,
                       '-a', slaveAgentPort as String]
        if (staticSlaves.size() > 0) {
            // A slave is represented as <name>:<executors>:label1:label2:...
            Collection<String> args = staticSlaves.values().collect { StaticSlaveModel m ->
                String labelString = m.labels.collect { ":${it}"}.join()
                "${m.slaveName}:${m.executors}" + labelString }
            map.command << '-s' << args.join(' ')
        }
        if (onDemandSlaves.size() > 0) {
            // A slave is represented as <image>:<name>
            Collection<String> args = onDemandSlaves.values().collect { OnDemandSlaveModel m ->
                "${m.dockerImage}:${m.slaveName}" }
            map.command << '-t' << args.join(' ')
        }
        if (pluginList.size() > 0) {
            map.command << '-p' << pluginList.join(' ')
        }
        map.command << '--' << '--prefix=/jenkins'
        map.ports = ["${slaveAgentPort}:${slaveAgentPort}" as String] // for slave connections
        //map.ports << '10080:8080' // Enter container without nginx, for debug
        map.volumes_from << context.sshKeys(dockerHost).name
    }

    void addServicesToMap(Map<String, ?> map, Context context) {
        staticSlaves.each { String name, StaticSlaveModel slave ->
            map[slave.serviceName] = slave.buildComposeMap(context)
        }
    }

    void staticSlave(String slaveName, Closure closure) {
        StaticSlaveModel slave = new StaticSlaveModel()
        slave.slaveName = slaveName
        slave.with closure
        slave.serviceName = "${ServiceEnum.JENKINS.name}${slaveName.capitalize()}"
        slave.box = box
        staticSlaves[slaveName] = slave
    }

    void onDemandSlave(String slaveName, Closure closure) {
        OnDemandSlaveModel slave = new OnDemandSlaveModel()
        slave.slaveName = slaveName
        slave.with closure
        slave.box = box
        onDemandSlaves[slaveName] = slave
    }

    /**
     * Execute a cli command against jenkins
     */
    @CompileDynamic
    void cli(List<String> cmd, Closure input) {
        new ExternalCommand(dockerHost).execute(["docker", "exec", "${box.name}_${ServiceEnum.JENKINS.name}", *cmd], null, input)
    }

    @CompileDynamic
    void preStart(Context context) {
        if (slaveAgentPort == -1) {
            slaveAgentPort = assignSlaveAgentPort()
        }
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
