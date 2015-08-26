package net.praqma.luci.gradle

import net.praqma.luci.docker.DockerHost
import net.praqma.luci.docker.DockerHostImpl
import org.gradle.api.Project

class LuciExtension {

    private Project project

    DockerHost defaultHost = initDefaultHost()

    LuciExtension(Project project) {
        this.project = project
    }

    DockerHost getDefaultHost() {
        if (this.@defaultHost == null) {
            this.@defaultHost = initDefaultHost()
        }
        return this.@defaultHost
    }

    private DockerHost initDefaultHost() {
        DockerHost host = null
        if (project.hasProperty('dockerMachine')) {
            String dockerMachine = project['dockerMachine']
            project.logger.lifecycle("Default dockerhost is '${dockerMachine}'")
            host = DockerHostImpl.fromDockerMachine(dockerMachine)
        } else {
            host = DockerHostImpl.getDefault()
        }
        return host
    }

}
