package net.praqma.luci.model

import net.praqma.luci.docker.ContainerKind
import net.praqma.luci.docker.DataContainer
import net.praqma.luci.docker.DockerHost
import net.praqma.luci.model.yaml.Context
import net.praqma.luci.utils.ExternalCommand
import org.yaml.snakeyaml.Yaml

import java.awt.Container

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
        service ServiceEnum.WEBFRONTEND.name
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

    /**
     * Call before starting the lucibox
     *
     * @param dockerHost If no docker host has been defined use this one for the lucibox
     */
    void preStart(DockerHost dockerHost) {
        if (this.dockerHost == null) {
            this.dockerHost = dockerHost
        }
        createDataContainer()
        serviceMap.values().each { it.preStart() }
    }

    private void createDataContainer() {
        new DataContainer('luci/data:0.2', this, dockerHost, 'storage').create()
    }

    /**
     * Bring up this Lucibox.
     */
    void bringUp(File workDir) {
        preStart()
        Context context = new Context(box: this, internalLuciboxIp: dockerHost.host)
        workDir.mkdirs()
        File yaml = new File(workDir, 'docker-compose.yml')
        new FileWriter(yaml).withWriter { Writer w ->
            generateDockerComposeYaml(context, w)
        }
        new ExternalCommand(dockerHost).execute(['docker-compose', '-f', yaml.path, 'up', '-d']) {
            it.eachLine { println it }
        }
        println ""
        println "Lucibox '${name}' running at http://${dockerHost.host}:${port}"
        println "docker-compose yaml file is at ${yaml.toURI().toURL()}"
    }

    /**
     * Take down the Lucibox.
     * <p>
     * That is stop and remove all service containers.
     */
    void takeDown() {
        removeContainers(ContainerKind.SERVICE)
    }

    /**
     * Destroy the Lucibox.
     * <p>
     * Stop and remove all containers (including data containers) related to this Lucibox.
     */
    void destroy() {
        removeContainers()
    }

    private void removeContainers(ContainerKind...kinds) {
        if (kinds.length == 0) {

        }
        List<String> ids = []
        new ExternalCommand(dockerHost).execute([
                'docker', 'ps', '-a', '--format=\'{{.ID}} {{.Label "net.praqma.lucibox.name"}} {{.Label "net.praqma.lucibox.kind"}}\'',
                    "--filter='na   me=${name}'" as String], {
            it.eachLine { String line ->
                def (id, boxName, kind) = line.split(' ')
                if (kinds.length == 0 || kinds.find { it.name().toLowerCase() == kind} != null) {
                    if (boxName == name) {
                        ids << id
                    }
                }
            }
        }, null)
        dockerHost.removeContainers(ids)
    }

}
