package net.praqma.luci.model

import net.praqma.luci.docker.DockerHost
import org.junit.Test


class JenkinsModelTest {

    @Test
    void testCreateDataContainer() {
        LuciboxModel box = new LuciboxModel("lucitest")
        box.dockerHost = DockerHost.fromDockerMachine('lucibox')
        box.service('jenkins') {

        }
        JenkinsModel model = box.properties.jenkins
        model.preStart()
    }
}
