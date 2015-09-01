package net.praqma.luci.dev

import groovyx.gpars.dataflow.DataflowVariable
import groovyx.gpars.dataflow.Promise
import net.praqma.luci.docker.DockerHost
import net.praqma.luci.docker.DockerHostImpl
import net.praqma.luci.utils.ClasspathResources

import static groovyx.gpars.dataflow.Dataflow.task

/**
 * Build all docker images for Luci
 */
class BuildAllImages {

    /**
     * Directory
     */
    private File dockerImagesDir

    boolean build(Collection<DockerHost> hosts) {
        hosts.each {
            println "***\n*** Building on ${it}\n***\n"
            build(it)
        }
    }

    boolean build(DockerHost dockerHost = null, boolean doPush = false) {
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

        /**
         * Mapping (full) image name to the exit code for the build of that image
         */
        Map<String, DataflowVariable<Integer>> buildResults = ([:].withDefault {
            new DataflowVariable<Integer>()
        }).asSynchronized()


        Collection<DockerImage> images = props.collect { String key, String version ->
            File dir = new File(dockerDir, key)
            assert dir.exists()
            new DockerImage(dir, version)
        }
        Collection<String> imageNames = images*.fullImageName

        Collection<Promise> tasks = []
        images.each { DockerImage image ->
            Promise<Integer> buildTask = task {
                String baseImage = image.baseImage
                if (baseImage.startsWith('luci/')) {
                    if (!imageNames.contains(baseImage)) {
                        println "WARNING: '${image.name}' has base '${baseImage}' which is not part of build. Did you forget to update version?"
                    }
                } else {
                    baseImage = 'none'
                }
                int rc = 1
                try {
                    // Get rc for base image.
                    DataflowVariable<Integer> rcVar = buildResults[baseImage]
                    assert rcVar != null
                    if (rcVar.val == 0) {
                        println "Building image ${image.fullImageName} with base ${baseImage}"
                        rc = image.build(dockerHost)
                    } else {
                        println "Skipping ${image.name}. Base image is not built"
                    }
                } finally {
                    buildResults[image.fullImageName] << rc
                    println "Finish '${image.fullImageName}' with rc: ${rc}"
                    return rc
                }
            }
            tasks << buildTask
            if (doPush) {
                Promise<Integer> push = buildTask.then { int rc -> // return code from build task
                    if (rc == 0) {
                        rc = image.push(dockerHost)
                    }
                    return rc
                }
                tasks << push
            }
        }
        // Set build result for 'none' to 0, so build begins for images that doesn't depend on luci images
        buildResults['none'] << 0
        tasks.each { it.get() }
        boolean answer = tasks.every { it.get() == 0}
        println "DONE. Built all images ${tasks.size()}"
        return answer
    }

}
