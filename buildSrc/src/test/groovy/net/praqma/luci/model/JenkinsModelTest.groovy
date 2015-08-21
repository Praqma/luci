package net.praqma.luci.model

import net.praqma.luci.docker.DockerHostTest
import net.praqma.luci.model.yaml.Context
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
        Context ctx = new Context(box: box)
        model.preStart(ctx)

        // Verify the sshkeys container
        //new ExternalCommand(model.dockerHost).execute('docker', 'run ','--volumes-from', keys.name, 'debian:jessie', 'ls', '-l', '/luci/sshkeys')

        def containers = box.containers()

        assert containers.sshkeys != null

        new ExternalCommand(model.dockerHost).execute('docker', 'run', '--rm', '--volumes-from', containers.sshkeys.id, 'debian:jessie', 'ls', '/luci/sshkeys')

        box.destroy()
    }

}
