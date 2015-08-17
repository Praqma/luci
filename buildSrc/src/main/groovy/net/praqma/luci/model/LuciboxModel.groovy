package net.praqma.luci.model

import net.praqma.luci.docker.DockerHost
import net.praqma.luci.model.yaml.Context
import org.yaml.snakeyaml.Yaml

class LuciboxModel {

    final String name

    /** Indicate if services should use a data container to store data, or if data should be stored in
     * the container itself.
     *
     * The value can be overridden for specific containers
     */
    boolean useDataContainer = false

    /** Port on web frontend (nginx) */
    int port = 80

    private Map<ServiceEnum, ?> serviceMap = [:]

    DockerHost dockerHost

    Integer socatForTlsHackPort

    LuciboxModel(String name) {
        this.name = name
        service 'webfrontend'
    }

    DockerHost getDockerHost() {
        if (this.@dockerHost == null) {
            this.@dockerHost = DockerHost.fromEnv()
        }
        return this.@dockerHost
    }

    Collection<BaseServiceModel> getServices() {
        return serviceMap.values()
    }

    void service(String serviceName, Closure closure) {
        ServiceEnum e = ServiceEnum.valueOf(serviceName.toUpperCase())
        BaseServiceModel model = e.modelClass.newInstance()
        model.serviceName = serviceName
        model.box = this
        model.dockerImage = e.dockerImage
        ServiceEnum old = serviceMap.put(e, model)
        if (old != null) {
            throw new RuntimeException("Double declaration of service '${serviceName}'")
        }
        def m = this // Don't underthis it?!? Works when this is assigned to m, if using 'this' directly it doesn't
        m.metaClass[serviceName] = { Closure c ->
            model.with c
        }
        m.metaClass['get' + serviceName.capitalize()] = { -> model }
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

    void preStart() {
        createDataContainer()
        serviceMap.values().each { it.preStart() }
    }

    private void createDataContainer() {

    }
}
