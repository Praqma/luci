package net.praqma.luci.model

import net.praqma.luci.model.yaml.Context

abstract class BaseServiceModel {

    String dockerImage

    String serviceName

    boolean includeInWebfrontend = true

    Map buildComposeMap(Context context) {
        Map answer = [
                image: dockerImage,
                extra_hosts: [lucibox: context.internalLuciboxIp]
        ]
        addToComposeMap(answer, context)
        return answer
    }

    void addToComposeMap(Map map, Context context) {

    }

    void addServicesToMap(Map<String, ?> map, Context context) {

    }
}
