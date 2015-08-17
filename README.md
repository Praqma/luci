# LUCI Understands Continuous Integration

## Running LUCI

You need a Docker host to run Luci on. You setup your shell to point at any Docker host as you
would when you use Docker for other purposes. The Lucibox(es) will be created on that Docker host.

Alternatively you can specify a dockerHost in the configuration on a Lucibox. TODO test and document

### Clone LUCI

From https://github.com/Praqma/luci.git clone the gradle branch

### Build Images

Luci provides a number of images. The intent is they will be push the  Docker hub, but currently you have to build them on the target Docker host.
You build the images with the script bin/buildAllImages.sh. Note that script does not fail if one or more images fails to build.

Important: When you pull  be sure to rebuild images, there might be changes. 

### Start and stop a Luci box

In the build.gradle file a few example Luciboxes are defined. If you want to spin up 'demo' you execute
'''./gradlew luciUpDemo'''

If you change the configuration you apply the changes by spinning it up again.

To kill it you stop the containers.

### Gradle Implementation notes

The Luci Gradle plugin should be distributed as a standalone plugin, so you can make any number of Luci Gradle configuration files. But currently you build the plugin whenever you use Luci, that is making the development much more efficient.

### Dependencies

You must have the following installed on the box where you execute the gradle script:
* Java
* Docker
* Docker compose: Must be 1.4.0 or newer
* Docker machine: I'm not sure about this one, but it should be possible ot make it work without
