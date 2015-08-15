package net.praqma.luci.model

import net.praqma.luci.docker.DockerHost
import net.praqma.luci.model.yaml.Context
import org.yaml.snakeyaml.Yaml

class LuciboxModel {

    private String name

    private Map<ServiceEnum, ?> serviceMap = [:]

    DockerHost dockerHost = DockerHost.fromEnv()

    Integer socatForTlsHackPort

    LuciboxModel(String name) {
        this.name = name
        service 'webfrontend'
    }

    Collection<BaseServiceModel> getServices() {
        return serviceMap.values()
    }

    void service(String serviceName, Closure closure) {
        ServiceEnum e = ServiceEnum.valueOf(serviceName.toUpperCase())
        BaseServiceModel model = e.modelClass.newInstance()
        model.serviceName = serviceName
        model.dockerImage = e.dockerImage
        ServiceEnum old = serviceMap.put(e, model)
        if (old != null) {
            throw new RuntimeException("Double declaration of service '${serviceName}'")
        }
        def m = this // Don't underthis it?!? Works when this is assigned to m, if using 'this' directly it doesn't
        m.metaClass[serviceName] = { Closure c ->
            model.with c
        }
        model.with closure
    }

    void service(String... serviceNames) {
        serviceNames.each { name ->
            service(name, {})
        }
    }

    private Map buildYamlMap(Context context) {
        Map m = [:]
        serviceMap.each { ServiceEnum service, BaseServiceModel model ->
            String s = service.getName()
            m[s] = model.buildComposeMap(context)
            model.addServicesToMap(m, context)
        }
        if (socatForTlsHackPort && dockerHost.tls) {
            m['dockerHttp'] = [
                    image  : 'sequenceiq/socat',
                    ports  : ["${socatForTlsHackPort}:2375" as String],
                    volumes: ['/var/run/docker.sock:/var/run/docker.sock']
            ]
        }
        return m
    }

    void generateDockerComposeYaml(Context context, Writer out) {
        Map map = buildYamlMap(context)
        new Yaml().dump(map, out)
    }
}
