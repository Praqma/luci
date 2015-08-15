package net.praqma.luci.model

import net.praqma.luci.model.yaml.Context

class JenkinsModel extends BaseServiceModel {

    private Map<String, StaticSlaveModel> staticSlaves = [:]

    @Override
    void addToComposeMap(Map map, Context context) {
        super.addToComposeMap(map, context)
        map.command = ['-d', 'luci-slave-data',
                       '-c', 'http://1.2.3.4',
                       '-j', 'http://lucibox/jenkins',
                       '-e', 'luci@praqma.net',
                       '--', '--prefix=/jenkins']
        map.ports = ['10080:8080'] // for debug
    }

    void addServicesToMap(Map<String, ?> map, Context context) {
        staticSlaves.each { String name, StaticSlaveModel slave ->
            String serviceName = "${ServiceEnum.JENKINS.name}Slave${name.capitalize()}"
            map[serviceName] = slave.buildComposeMap(context)
            map[serviceName].links = ["${ServiceEnum.JENKINS.name}:master" as String]
        }
    }

    void staticSlave(String slaveName, Closure closure) {
        StaticSlaveModel slave = new StaticSlaveModel()
        slave.with closure
        staticSlaves[slaveName] = slave
    }
}
