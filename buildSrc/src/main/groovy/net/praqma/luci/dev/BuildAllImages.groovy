package net.praqma.luci.dev

import net.praqma.luci.docker.DockerHost
import net.praqma.luci.docker.DockerHostImpl
import net.praqma.luci.utils.ClasspathResources
import org.apache.tools.ant.util.ResourceUtils

import java.util.concurrent.CountDownLatch
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Build all docker images for Luci
 */
class BuildAllImages {

    /**
     * Directory
     */
    private File dockerImagesDir

    boolean build(DockerHost dockerHost = null) {
        if (dockerHost == null) {
            dockerHost = DockerHostImpl.getDefault()
        }
        File versionsFile
        if (System.properties['net.praqma.luci.projectRoot'] != null) {
            versionsFile = new File(System.properties['net.praqma.luci.projectRoot'], 'buildSrc/src/main/resources/docker/imageVersions.properties')
        } else {
            versionsFile = new ClasspathResources().resourceAsFile('docker/imageVersions.properties')
        }

        assert versionsFile.exists()
        File dockerDir = versionsFile.parentFile
        println "Build images in directory: ${dockerDir}"

        Properties props = new Properties()
        versionsFile.withInputStream {
            props.load(it)
        }

        Map<String, DockerImageBuilder> builders = props.collectEntries { String key, String version ->
            File dir = new File(dockerDir, key)
            assert dir.exists()
            ["luci/${key}:${version}" as String, new DockerImageBuilder(dir, version)]
        }

        builders.values().each { DockerImageBuilder builder ->
            String baseImage = builder.baseImage
            if (baseImage.startsWith('luci/')) {
                DockerImageBuilder baseBuilder = builders[baseImage]
                if (baseBuilder == null) {
                    println "WARNING: '${builder.name}' has base '${baseImage}' which is not part of build. Did you forget to update version?"
                } else {
                    baseBuilder.addDependant(builder)
                }
            }
        }

        builders.values().each { DockerImageBuilder builder ->
            builder.latch = new CountDownLatch(builder.initialLatchCount)
        }

        Collection<Thread> threads = []
        AtomicBoolean allSuccess = new AtomicBoolean(true)
        builders.values().each { DockerImageBuilder builder ->
            threads << Thread.start {
                boolean success = builder.executeBuild(dockerHost)
                synchronized (allSuccess) {
                    allSuccess.set(allSuccess.get() && success)
                }
            }
        }

        threads.each { it.join() }
        println "DONE. Built all images"
        return allSuccess.get()
    }

    static void main(String[] args) {
        new BuildAllImages().build()
    }


}
