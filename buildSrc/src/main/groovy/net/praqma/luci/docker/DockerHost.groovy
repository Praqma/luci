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

    boolean isInitialized = false

    /** A text describe where this hos is origination form, e.g. if it is a docker mahcine or env vars */
    String origination = '<unknown>'

    URI getUri() {
        if (isInitialized) {
            return this.@uri
        } else {
            throw new RuntimeException('Host not initialized')
        }
    }

    boolean isTls() {
        if (isInitialized) {
            return this.@tls
        } else {
            throw new RuntimeException('Host not initialized')
        }
    }

    File getCertPath() {
        if (isInitialized) {
            return this.@certPath
        } else {
            throw new RuntimeException('Host not initialized')
        }
    }

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
        if (isInitialized) {
            return "${uri}[${origination}]"
        } else {
            return "<uninitialized>[${origination}]"
        }
    }

    void initialize() {
        isInitialized = true
    }

    void initFrom(DockerHost dh) {
        this.uri = dh.uri
        this.certPath = dh.certPath
        this.tls = dh.tls
        this.origination = dh.origination
        this.isInitialized = true
    }

    DockerHost orig(String s) {
        origination = s
        return this
    }


}
