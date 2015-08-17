package net.praqma.luci.model

import net.praqma.luci.docker.DockerHost
import net.praqma.luci.docker.DockerHostTest
import org.junit.Ignore
import org.junit.Test


class JenkinsModelTest {

    @Test
    void testCreateDataContainer() {
        if (System.properties['lucitest'] == null) return
        LuciboxModel box = new LuciboxModel("lucitest")
        box.dockerHost = DockerHostTest.host
        box.service('jenkins') {

        }
        JenkinsModel model = box.properties.jenkins
        model.preStart()
    }
}
