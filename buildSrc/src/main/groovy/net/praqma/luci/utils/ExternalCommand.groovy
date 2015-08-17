package net.praqma.luci.utils

import groovy.transform.CompileStatic

@CompileStatic
class ExternalCommand {

    private static Map<String, String> bins = [
            // Needs some smarts to find binaries
            docker: '/usr/local/bin/docker',
            'docker-machine': '/usr/local/bin/docker-machine'
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
}
