package net.praqma.luci.dev

import groovy.transform.Memoized
import net.praqma.luci.docker.DockerHost
import net.praqma.luci.utils.ExternalCommand

import java.util.concurrent.CountDownLatch
import java.util.concurrent.Semaphore

/**
 * Helper class to build a single docker image
 */
class DockerImageBuilder {

    private File contextDir

    private String version

    private Collection<DockerImageBuilder> dependants = []

    CountDownLatch latch

    int initialLatchCount = 0

    boolean errorInBase

    DockerImageBuilder(File contextDir, String version) {
        this.contextDir = contextDir
        this.version = version
    }

    void addDependant(DockerImageBuilder b) {
        dependants.add(b)
        b.initialLatchCount++
    }

    File getDockerFile() {
        return new File(contextDir, 'Dockerfile')
    }

    String getName() {
        return contextDir.name
    }

    @Memoized
    String getBaseImage() {
        return dockerFile.withInputStream { InputStream stream ->
            String fromLine = stream.readLines().find { String line -> line.startsWith("FROM ")}
            if (fromLine == null) {
                throw new RuntimeException("no FROM instruction found in Dockerfile ${dockerFile.path}")
            }
            fromLine.split(' ')[1].trim()
        }
    }

    boolean executeBuild(DockerHost host) {
        String prefix = "${name}: "
        println prefix + "Waiting for base image '${baseImage}' to build"
        latch.await()
        int rc = 1 // non-zero to propagate error from base
        if (errorInBase) {
            println (prefix + "Skipping. Error in base.")
        } else {
            println prefix + "Begin"
            StringBuffer out = "" << ""
            rc = new ExternalCommand(host).execute('docker', 'build', '-t', "luci/${name}:${version}" as String, dockerFile.parent, out: out)
            if (rc != 0) {
                println "ERROR in ${name}"
                println out.toString()
            }
            println prefix + "Finish. RC: ${rc}"
        }
        dependants.each { DockerImageBuilder b ->
            b.errorInBase = (rc != 0)
            b.latch.countDown()
        }
        return rc == 0
    }
}
