package net.praqma.luci.model

import groovy.transform.Memoized
import groovyx.gpars.GParsPool
import groovyx.gpars.dataflow.DataflowQueue
import groovyx.gpars.dataflow.Promise
import net.praqma.luci.docker.ContainerInfo
import net.praqma.luci.docker.ContainerKind
import net.praqma.luci.docker.DockerHost
import net.praqma.luci.utils.ExternalCommand
import org.yaml.snakeyaml.Yaml

import static groovyx.gpars.dataflow.Dataflow.task

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

    /**
     * Mapping luciname of service to the model class
     */
    private Map<String, BaseServiceModel> serviceMap = [:]

    DockerHost dockerHost

    Integer socatForTlsHackPort = null

    LuciboxModel(String name) {
        this.name = name
        service ServiceEnum.WEBFRONTEND.name
    }

    BaseServiceModel getService(ServiceEnum service) {
        return getService(service.name)
    }

    BaseServiceModel getService(String luciName) {
        return serviceMap[luciName]
    }

    Collection<BaseServiceModel> getServices() {
        return serviceMap.values()
    }

    void addService(BaseServiceModel service) {
        assert serviceMap[service.serviceName] == null
        serviceMap[service.serviceName] = service
    }

    void service(String serviceName, Closure closure) {
        ServiceEnum e = ServiceEnum.valueOf(serviceName.toUpperCase())
        BaseServiceModel model = e.modelClass.newInstance()
        model.serviceName = serviceName
        model.box = this
        model.dockerImage = e.dockerImage.imageString
        ServiceEnum old = serviceMap.put(e.name, model)
        if (old != null) {
            throw new RuntimeException("Double declaration of service '${serviceName}'")
        }
        def m = this // Don't understand this?!? Works when this is assigned to m, if using 'this' directly it doesn't
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
        serviceMap.each { String s, BaseServiceModel model ->
            m[s] = model.buildComposeMap(context)
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
     * <p>
     * This is for example use to create data containers and other containers that
     * isn't defined in the docker-compose
     */
    void preStart(Context context) {
        context.addHost(dockerHost)
        serviceMap.values().each { it.preStart(context) }
    }

    /**
     * @return Containers belonging to this Lucibox
     */
    Map<String, ContainerInfo> containers(ContainerKind... kinds) {
        DataflowQueue queue = new DataflowQueue<>()
        Map<String, ContainerInfo> answer = [:].asSynchronized()
        allHosts.each { DockerHost host ->
            task {
                host.initialize()
                return host.containers(this, kinds)
            }.whenBound { queue << it }
        }
        allHosts.size().times {
            def val = queue.val
            if (val instanceof Throwable) {
                throw val
            } else {
                answer.putAll(val)
            }
        }
        return answer
    }

    /**
     * Bring up this Lucibox.
     */
    void bringUp(File workDir) {
        // Take down any containers that should happend to run, before bringing it up
        takeDown()

        Context context = new Context(this, dockerHost)
        preStart(context)

        context.hosts.each { it.initialize() }

        workDir.mkdirs()
        File yaml = new File(workDir, 'docker-compose.yml')
        new FileWriter(yaml).withWriter { Writer w ->
            generateDockerComposeYaml(context, w)
        }

        Collection<DockerHost> auxHosts = context.auxServices*.dockerHost
        Map<DockerHost, Context> ctxMap = auxHosts.collectEntries { [ it, new Context(this, it)]}
        context.auxServices.each {AuxServiceModel aux ->
            println "Setting up aux service: ${aux.serviceName} on ${aux.dockerHost}"
            aux.startService(ctxMap[aux.dockerHost])
        }

        new ExternalCommand(dockerHost).execute('docker-compose', '-f', yaml.path, 'up', '-d')

        println "Lucibox '${name} will use docker hosts: ${allHosts*.asString()}"
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

    private void removeContainers(ContainerKind... kinds) {
        Collection<ContainerInfo> containers = containers(kinds).values()
        GParsPool.withPool {
            containers.eachParallel { ContainerInfo ci ->
                ci.host.removeContainers([ci.id])
            }
        }
    }

    void printInformation(File workDir) {
        // TODO look at code duplication with bringUp.
        // No arg should be needed in this method
        Context context = new Context(this, dockerHost)
        preStart(context)

        String header = "Lucibox: ${name}"
        println "\n${header}\n${'=' * header.length()}"
        println "Primary host: ${dockerHost.asString()}"

        println "Aux services:"
        context.auxServices.each { AuxServiceModel aux ->
            println "\t${aux.serviceName} @ ${aux.dockerHost.asString()}"
        }
    }

    @Memoized
    Collection<DockerHost> getAllHosts() {
        return services*.dockerHost as Set
    }
}

