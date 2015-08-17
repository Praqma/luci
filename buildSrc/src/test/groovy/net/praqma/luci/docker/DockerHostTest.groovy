package net.praqma.luci.docker

import org.gradle.api.Project
import org.junit.Test

import javax.inject.Inject


class DockerHostTest {

    static DockerHost getHost() {
        return DockerHost.fromEnv()
    }

    @Test
    void testParseEnvVar() {
        String s = """
export DOCKER_TLS_VERIFY="1"
export DOCKER_HOST="tcp://192.168.99.108:2376"
export DOCKER_CERT_PATH="/Users/jan/.docker/machine/machines/lucibox"
export DOCKER_MACHINE_NAME="lucibox"
# Run this command to configure your shell:

"""
        DockerHost h = DockerHost.fromEnvVarsString(s)
        assert h.host == "192.168.99.108"
        assert h.port == 2376
        assert h.tls
        assert h.certPath == new File("/Users/jan/.docker/machine/machines/lucibox")
    }

    @Test
    void testBoundPorts() {
        if (System.properties['lucitest'] == null) return
        DockerHost h = host
        h.boundPorts()
    }
}


