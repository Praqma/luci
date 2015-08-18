package net.praqma.luci.model

import groovy.transform.CompileStatic
import net.praqma.luci.docker.DockerHost
import net.praqma.luci.model.yaml.Context

@CompileStatic
abstract class BaseServiceModel {

    String dockerImage

    String serviceName

    LuciboxModel box

    /**
     * Indicate if the data for the service should be stored in a data container.
     * If the value is <code>null</code> the value defined in the lucibox is used.
     */
    Boolean useDataContainer

    boolean includeInWebfrontend = true

    Map buildComposeMap(Context context) {
        List<String> volumes_from = []
        if (useDataContainer == null ? box.useDataContainer : useDataContainer) {
            volumes_from << ("${box.name}__data" as String)
        }
        Map answer = [
                image         : dockerImage,
                extra_hosts   : [lucibox: context.internalLuciboxIp],
                container_name: containerName,
                volumes_from  : volumes_from,
                labels        : ['net.praqma.lucibox.name': box.name as String, 'net.praqma.lucibox.kind': 'service']
        ]
        addToComposeMap(answer, context)
        return answer
    }

    void addToComposeMap(Map map, Context context) {

    }

    void addServicesToMap(Map<String, ?> map, Context context) {

    }

    void preStart() {

    }

    DockerHost getDockerHost() {
        return box.dockerHost
    }

    String getContainerName() {
        return "${box.name}_${serviceName}"
    }
}
