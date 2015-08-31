package net.praqma.luci.gradle

import groovy.transform.CompileStatic
import net.praqma.luci.docker.DockerHost
import net.praqma.luci.docker.DockerHostImpl

@CompileStatic
class GradleDockerHost {

    String name

    @Delegate
    DockerHost dockerHost

    GradleDockerHost(String name) {
        this.name = name
    }

    void dockerMachine(String name) {
        dockerHost = DockerHostImpl.fromDockerMachine(name)
    }

}
