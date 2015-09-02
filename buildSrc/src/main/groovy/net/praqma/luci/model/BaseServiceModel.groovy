package net.praqma.luci.model

import groovy.transform.CompileStatic
import net.praqma.luci.docker.ContainerInfo
import net.praqma.luci.docker.ContainerKind
import net.praqma.luci.docker.DockerHost

@CompileStatic
abstract class BaseServiceModel {

    String dockerImage

    String serviceName

    LuciboxModel box

    DockerHost dockerHost

    /**
     * Indicate if the data for the service should be stored in a data container.
     * If the value is <code>null</code> the value defined in the lucibox is used.
     */
    Boolean useDataContainer

    boolean includeInWebfrontend = false

    Map buildComposeMap(Context context) {
        List<String> volumes_from = []
        if (useDataContainer == null ? box.useDataContainer : useDataContainer) {
            volumes_from << context.storage(dockerHost).name
        }
        Map answer = [
                image         : dockerImage,
                extra_hosts   : [lucibox: context.internalLuciboxIp],
                container_name: containerName,
                volumes_from  : volumes_from,
                labels        : [(ContainerInfo.BOX_NAME_LABEL)          : box.name,
                                 (ContainerInfo.CONTAINER_KIND_LABEL)    : ContainerKind.SERVICE.name(),
                                 (ContainerInfo.CONTAINER_LUCINAME_LABEL): serviceName]
        ]
        addToComposeMap(answer, context)
        return answer
    }

    void addToComposeMap(Map map, Context context) {

    }

    void prepare(Context context) {
        context.addHost(dockerHost)
    }

    DockerHost getDockerHost() {
        return this.@dockerHost ?: box.dockerHost
    }

    String getContainerName() {
        return "${box.name}_${serviceName}"
    }
}
