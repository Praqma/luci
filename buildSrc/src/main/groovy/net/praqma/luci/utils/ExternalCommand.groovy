package net.praqma.luci.utils

import groovy.transform.CompileStatic

@CompileStatic
class ExternalCommand {

    private static Map<String, String> bins = [
            // Needs some smarts to find binaries
            docker: findBinary('docker', '/usr/local/bin/docker'),
            'docker-machine': findBinary('docker-machine', '/usr/local/bin/docker-machine')
    ]

    int execute(List<String> cmd, Closure output, Closure input = null) {
        String c = bins[cmd[0]]
        if (c) {
            cmd = ([c] + cmd[1..-1]) as List<String>
        }
        ProcessBuilder pb = new ProcessBuilder(cmd)
                .redirectErrorStream(true)
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
    private static String findBinary(String name, String ...suggestions) {
        // TODO handle windows
        File file = (File)path.findResult { String pathElement ->
            File f = new File(pathElement, name)
            f.canExecute() ? f : null
        }
        if (file == null) {
            file = (File)suggestions.findResult { String suggestion ->
                File f = new File(suggestion)
                f.canExecute() ? f : null
            }
        }
        if (file == null) {
            throw new RuntimeException("Can find executable for '${name}'")
        }
        return file?.path
    }
}
