package net.praqma.luci.docker


class DockerHost {

    static DockerHost fromDockerMachine(String name) {
        String s = "docker-machine env ${name}".execute().text
        return fromEnvVarsString(s)
    }

    static DockerHost fromBoot2docker(String name) {
        assert false
    }

    static DockerHost localhost() {
        assert false
    }

    static DockerHost fromEnv() {
        fromVariables(System.getenv())
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
        }
        return h
    }

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
}
