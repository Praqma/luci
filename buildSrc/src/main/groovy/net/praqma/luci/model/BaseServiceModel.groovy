package net.praqma.luci.model

import groovy.transform.CompileStatic
import net.praqma.luci.model.yaml.Context

@CompileStatic
abstract class BaseServiceModel {

    String dockerImage

    String serviceName

    LuciboxModel box

    boolean includeInWebfrontend = true

    Map buildComposeMap(Context context) {
        Map answer = [
                image         : dockerImage,
                extra_hosts   : [lucibox: context.internalLuciboxIp],
                container_name: containerName
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

    String getContainerName() {
        return "${box.name}_${serviceName}"
    }
}
