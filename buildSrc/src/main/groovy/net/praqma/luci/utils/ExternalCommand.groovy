package net.praqma.luci.utils

import groovy.transform.CompileStatic

@CompileStatic
class ExternalCommand {

    int execute(List<String> cmd, Closure output, Closure input = null) {
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
