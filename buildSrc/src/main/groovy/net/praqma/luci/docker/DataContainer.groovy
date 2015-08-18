package net.praqma.luci.docker

import com.google.common.io.ByteStreams
import com.google.common.io.Files
import groovy.transform.CompileDynamic
import groovy.transform.CompileStatic
import net.praqma.luci.model.LuciboxModel
import net.praqma.luci.utils.ExternalCommand

@CompileStatic
class DataContainer {

    private String dockerImage
    private String name
    private LuciboxModel box
    private Set<String> volumes = [] as Set
    private ExternalCommand ec

    DataContainer(String dockerImage, LuciboxModel box, DockerHost host, String name) {
        this.dockerImage = dockerImage
        this.box = box
        this.name = "${box.name}__data_${name}"
        // two underscored on purpose, used to distinguish service and data containers
        this.ec = new ExternalCommand(host)
    }

    Volume volume(String v) {
        volumes << v
        return new Volume(v)
    }

    @CompileDynamic
    void create() {
        List<String> v = volumes.collect { ['-v', it] }.flatten()
        List<String> cmd = ['docker', 'create'] + v +
                ['--name', name,
                 '-l', 'net.praqma.lucibox.kind=data', '-l', "net.praqma.lucibox.name=${box.name}" as String,
                 dockerImage]
        ec.execute(cmd, null, null)
    }

    class Volume {
        private String path

        Volume(String path) {
            this.path = path
        }

        VolumeFile file(String filePath) {
            return new VolumeFile(this, filePath)
        }
    }

    class VolumeFile {

        private Volume volume
        private String filePath

        VolumeFile(Volume volume, String filePath) {
            assert volume != null && filePath != null
            this.volume = volume
            this.filePath = filePath
        }

        void addStream(InputStream stream) {
            assert stream != null
            File f = new File(filePath)
            // We need to create a file with the name of the file in the container (that is the way the cp command works)
            File tempDir = Files.createTempDir()
            File tempFile = new File(tempDir, f.name)
            ByteStreams.copy(stream, new FileOutputStream(tempFile))

            String completePath = f.parent ? new File(new File(volume.path), f.parent).absolutePath : volume.path
            ec.execute(['docker', 'cp', tempFile.absolutePath, "${name}:${completePath}" as String], null) { OutputStream out ->
                ByteStreams.copy(stream, out)
            }
            tempFile.delete()
            tempDir.delete()
        }

        void addResource(String resource) {
            addStream getClass().classLoader.getResourceAsStream(resource)
        }

    }
}
