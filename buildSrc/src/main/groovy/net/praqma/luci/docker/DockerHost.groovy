package net.praqma.luci.docker

import groovy.transform.CompileDynamic
import groovy.transform.CompileStatic
import net.praqma.luci.gradle.LuciPlugin
import net.praqma.luci.model.LuciboxModel
import net.praqma.luci.utils.ExternalCommand

@CompileStatic
class DockerHost {

    static DockerHost fromDockerMachine(String name) {
        StringBuffer out = "" << ""
        int rc = new ExternalCommand().execute('docker-machine', 'env', name, out: out)
        assert rc == 0
        return fromEnvVarsString(out.toString())
    }

    static DockerHost getDefault() {
        String dockerMachine = System.properties['net.praqma.luci.dockerMachine']
        if (dockerMachine != null) {
            return fromDockerMachine(dockerMachine)
        } else {
            return fromEnv()
        }
    }

    static DockerHost fromEnv() {
        return (System.getenv("DOCKER_HOST") != null) ? fromVariables(System.getenv()) : null
    }

    static DockerHost fromVariables(Map<String, String> map) {
        String dockerHost = map['DOCKER_HOST']
        String dockerTlsVerify = map['DOCKER_TLS_VERIFY']
        String dockerCertPath = map['DOCKER_CERT_PATH']

        if (dockerHost == null || dockerHost == '') {
            throw new RuntimeException("'DOCKER_HOST' not defined")
        }
        DockerHost h = new DockerHost()
        h.uri = URI.create(dockerHost)
        h.tls = dockerTlsVerify == "1"
        if (dockerCertPath) {
            h.certPath = new File(dockerCertPath).absoluteFile
        } else {
            h.certPath = null
        }
        return h
    }

    @CompileDynamic
    static DockerHost fromEnvVarsString(String s) {
        Map<String, String> m = [:]
        s.readLines().each { String line ->
            if (line.startsWith('export ')) {
                line = line.substring(7).trim()
                def (key, v) = line.split('=')
                if (v[0] == '"' && v[-1] == '"') {
                    v = v[1..-2]
                }
                m[key] = v
            }
        }
        return fromVariables(m)
    }

    URI uri
    boolean tls
    File certPath

    String getHost() {
        return uri.host
    }

    int getPort() {
        return uri.port
    }

    /**
     *
     * @return Environment variables to set to access this host. Null values means "not set"
     */
    Map<String, String> getEnvVars() {
        return [
                DOCKER_HOST      : uri.toString(),
                DOCKER_TLS_VERIFY: (tls ? '1' : null),
                DOCKER_CERT_PATH : certPath?.path
        ]
    }

    /**
     *
     * @return All ports that a bound on the host
     */
    Collection<Integer> boundPorts() {
        Collection<Integer> answer = [] as Set
        new ExternalCommand(this).execute('docker', 'ps', "--format='{{.Ports}}'", out: { InputStream stream ->
            stream.eachLine { String line ->
                answer.addAll(extractBoundPortsFromLine(line))
            }
        })
        return answer
    }

    @CompileDynamic
    void removeContainers(Collection<String> ids) {
        new ExternalCommand(this).execute('docker', 'rm', '-fv', *ids)
    }

    private Collection<Integer> extractBoundPortsFromLine(String line) {
        Collection<Integer> ports = []
        line.split(',').each { String s ->
            int arrayIndex = s.indexOf('->')
            int colonIndex = s.indexOf(':')
            if (arrayIndex && colonIndex > 0 && arrayIndex > colonIndex) {
                ports << (s[colonIndex + 1..arrayIndex - 1] as Integer)
            }
        }
        return ports
    }
}
