package net.praqma.luci.docker

import net.praqma.luci.model.JenkinsModel
import net.praqma.luci.model.LuciboxModel
import net.praqma.luci.utils.ExternalCommand

/**
 * Class to access and create on demand mixin containers
 */
class Containers {

    private Map<String, Container> containers = [:]

    private LuciboxModel box

    Containers(LuciboxModel box) {
        this.box = box
    }

    String get(String n) {
        return containers[n].name
    }

    void addContainer(Container con) {
        containers[con.luciName] = con
    }

    /*
    String java8(DockerHost host) {
        return mixin(host, 'java8', 'luci/mixin-java8:0.2')
    }
    */

    /**
     * Storage container for all services
     */
    Container storage(DockerHost host) {
        return ensureContainerExists(host, 'storage', DockerImage.STORAGE, ContainerKind.CACHE)
    }

    Container sshKeys(DockerHost host) {
        return ensureContainerExists(host, 'sshKeys', DockerImage.DATA,
                ContainerKind.CACHE, volumes: '/luci/etc/sshkeys') { Container container ->
            new ExternalCommand(host).execute('docker', 'run', '--rm', container.volumesFromArg, DockerImage.TOOLS.imageString,
                    'ssh-keygen', '-t', 'rsa', '-b', '2048', '-C', 'jenkins@luci', '-f',
                    '/luci/etc/sshkeys/id_rsa', '-q', '-N', '')

        }
    }

    Container jenkinsConfig(JenkinsModel jenkins) {
        DockerHost host = jenkins.dockerHost
        String jenkinsHome = '/var/jenkins_home'
        return createNewContainer(host, 'jenkinsConfig', DockerImage.DATA, ContainerKind.CACHE,
                volumes: ["${jenkinsHome}/init.groovy.d"]) { Container con ->
            jenkins.initFiles.each { File file ->
                new ExternalCommand(host).execute('docker', 'cp', file.path, "${con.name}:/${jenkinsHome}/init.groovy.d")
            }

        }
    }

    Container java8mixin(DockerHost host) {
        return ensureContainerExists(host, 'mixin-java8', DockerImage.MIXIN_JAVA8, ContainerKind.CACHE, volumes: '/luci/mixins/java')
    }

    /**
     * Data container for jenkins slaves
     */
    Container jenkinsSlave(DockerHost host) {
        String vol = '/luci/data/jenkinsSlave'
        Container con = ensureContainerExists(host, 'jenkinsSlave', DockerImage.MIXIN_JAVA8,
                ContainerKind.CACHE, volumes: [vol]) { Container container ->
            Container.Volume volume = container.volume(vol)

            // Extract slave.jar from jenkins.war and store in the volume
            Closure c = { InputStream inputStream ->
                volume.file('slave.jar').addStream(inputStream)
            }

            def ec = new ExternalCommand(host)
            int rc = ec.execute('docker', 'run', '--rm', DockerImage.SERVICE_JENKINS.imageString, 'unzip', '-p',
                    '/usr/share/jenkins/jenkins.war', 'WEB-INF/slave.jar', out: c, err: System.err)
            assert rc == 0

            // Add slaveConnect script to container. Use for the slave to connect to master
            volume.file('slaveConnect.sh').addResource('scripts/connectSlave.sh')

            // Copy public key to jenkinsSlave as authorized keys
            // so Jenkins master can ssh to the slaves
            rc = ec.execute('docker', 'run', '--rm',
                    sshKeys().volumesFromArg, container.volumesFromArg,
                    DockerImage.TOOLS.imageString, 'cp', '/luci/etc/sshkeys/id_rsa.pub', '/luci/data/jenkinsSlave/authorized_keys')
            assert rc == 0
        }

        return con
    }

    private Container createNewContainer(Map<String, ?> args, DockerHost host, String luciName, DockerImage image, ContainerKind kind, Closure initBlock = null) {
        return createContainerHelper(args, true, host, luciName, image, kind, initBlock)
    }

    private Container ensureContainerExists(DockerHost host, String luciName, DockerImage image, ContainerKind kind, Closure initBlock = null) {
        return ensureContainerExists([:], host, luciName, image, kind, initBlock)
    }

    private Container ensureContainerExists(Map<String, ?> args, DockerHost host, String luciName, DockerImage image, ContainerKind kind, Closure initBlock = null) {
        return createContainerHelper(args, false, host, luciName, image, kind, initBlock)
    }

    private Container createContainerHelper(Map<String, ?> args, boolean createNew, DockerHost host, String luciName, DockerImage image, ContainerKind kind, Closure initBlock = null) {
        if (createNew) {
            Container container = new Container(image, box, host, kind, luciName)
            container.remove()
            containers.remove(luciName)
        }
        if (containers[luciName] == null) {
            Container container = new Container(image, box, host, kind, luciName)
            if (args.volumes) {
                if (args.volumes instanceof String) {
                    container.volume(args.volumes)
                } else {
                    args.volumes.each { String vol ->
                        container.volume(vol)
                    }
                }
            }
            container.create()
            if (initBlock != null) {
                initBlock(container)
            }
            containers[luciName] = container
        }
        return containers[luciName]

    }

}