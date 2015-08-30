package net.praqma.luci.model

import net.praqma.luci.docker.DockerHostTest
import net.praqma.luci.docker.DockerImage
import net.praqma.luci.utils.ExternalCommand
import org.junit.Test


class JenkinsModelTest {

    @Test
    void testPreStart() {
        LuciboxModel box = new LuciboxModel("lucitest")
        box.dockerHost = DockerHostTest.host

        box.destroy()
        box.service('jenkins') {

        }
        JenkinsModel model = box.properties.jenkins
        Context ctx = new Context(box, box.dockerHost)
        model.preStart(ctx)

        // Verify the sshkeys container
        new ExternalCommand(model.dockerHost).execute('docker', 'run', '--rm', ctx.sshKeys(model.dockerHost).volumesFromArg,
                DockerImage.TOOLS.imageString, 'ls', '/luci/etc/sshkeys')

        box.destroy()
    }

}
