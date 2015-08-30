package net.praqma.luci.model

import groovy.transform.CompileStatic
import net.praqma.luci.docker.Containers
import net.praqma.luci.docker.DockerHost

@CompileStatic
class Context {

    final LuciboxModel box

    final DockerHost dockerHost

    final Collection<AuxServiceModel> auxServices = []

    @Delegate
    final Containers containers

    Context(LuciboxModel box, DockerHost dockerHost) {
        this.box = box
        this.dockerHost = dockerHost
        this.containers = new Containers(box)
    }

    String getInternalLuciboxIp() {
        return box.dockerHost.uri.host
    }

    /**
     * @return the host for the specified service
     */
    DockerHost serviceHost(ServiceEnum service) {
        return box.getService(service).dockerHost
    }

}
