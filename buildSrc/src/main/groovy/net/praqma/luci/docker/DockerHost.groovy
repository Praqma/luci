package net.praqma.luci.docker

import groovy.transform.CompileDynamic
import groovy.transform.CompileStatic
import net.praqma.luci.gradle.LuciPlugin
import net.praqma.luci.model.LuciboxModel
import net.praqma.luci.utils.ExternalCommand

trait DockerHost {

    URI uri
    boolean tls
    File certPath

    /** A text describe where this hos is originaiton form, e.g. if it is a docker mahcine or env vars */
    String origination = '<unknown>'

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

    // private
    Collection<Integer> extractBoundPortsFromLine(String line) {
        // Sample line: 0.0.0.0:2375->2375/tcp
        Collection<Integer> ports = []
        line.split(',').each { String s ->
            int arrowIndex = s.indexOf('->')
            int colonIndex = s.indexOf(':')
            if (arrowIndex && colonIndex > 0 && arrowIndex > colonIndex) {
                ports << (s[colonIndex + 1..arrowIndex - 1] as Integer)
            }
        }
        return ports
    }

    String toString() {
        return "${uri}[${origination}]"
    }
}
