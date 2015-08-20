package net.praqma.luci.utils

import groovy.transform.CompileStatic
import net.praqma.luci.docker.DockerHost

@CompileStatic
class ExternalCommand {

    /** Docker commands are executed against this docker host */
    private DockerHost dockerHost

    ExternalCommand(DockerHost dockerHost) {
        this.dockerHost = dockerHost
    }

    int execute(List<String> cmd, Closure output, Closure input = null) {
        assert cmd.findAll { it == null }.empty
        String c = Binary.known[cmd[0]]?.executable
        if (c) {
            cmd = ([c] + cmd[1..-1]) as List<String>
        }
        ProcessBuilder pb = new ProcessBuilder(cmd)
                .redirectErrorStream(true)
        Map<String, String> env = pb.environment()
        if (dockerHost == null) {
            // Don't change env
        } else {
            Map<String, String> m = dockerHost.envVars
            m.each { key, value ->
                if (value == null) {
                    env.remove(key)
                } else {
                    env[key] = value
                }
            }
        }

        Process process = pb.start()
        if (input) {
            Thread.start {
                def stream = new BufferedOutputStream(process.outputStream)
                input(stream)
                stream.flush()
            }
        }
        if (output == null) {
            output = { InputStream stream ->
                stream.eachLine { String line -> println line }
            }
        }
        if (output) {
            output(process.inputStream)
        }
        process.waitFor()
        return process.exitValue()
    }

    private static String[] path = System.getenv('PATH').split(File.pathSeparator)
    /**
     * Find a binary on the PATH and if not there look for the first
     * suggestion that exist.
     *
     * @param name
     * @param suggestions
     * @return
     */
    private static String findBinary(String name, String... suggestions) {
        // TODO handle windows
        File file = (File) path.findResult { String pathElement ->
            File f = new File(pathElement, name)
            f.canExecute() ? f : null
        }
        if (file == null) {
            file = (File) suggestions.findResult { String suggestion ->
                File f = new File(suggestion)
                f.canExecute() ? f : null
            }
        }
        return file?.path
    }

}
