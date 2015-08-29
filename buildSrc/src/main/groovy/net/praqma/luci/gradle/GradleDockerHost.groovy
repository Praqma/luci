package net.praqma.luci.gradle

import groovy.transform.CompileStatic
import net.praqma.luci.docker.DockerHost
import net.praqma.luci.docker.DockerHostImpl

@CompileStatic
class GradleDockerHost implements DockerHost {

    String name

    GradleDockerHost(String name) {
        this.name = name
    }

    void dockerMachine(String name) {
        copyFrom(DockerHostImpl.fromDockerMachine(name))
    }

    private copyFrom(DockerHost dh) {
        this.uri = dh.uri
        this.certPath = dh.certPath
        this.tls = dh.tls
        this.origination = dh.origination
    }
}
