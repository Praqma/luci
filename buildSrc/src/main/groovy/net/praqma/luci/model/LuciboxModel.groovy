package net.praqma.luci.model

class LuciboxModel {

    private String name

    private Map<ServiceEnum, ?> serviceMap = [:]

    LuciboxModel(String name) {
        this.name = name
        service 'webfrontend'
    }

    void service(String serviceName, Closure closure) {
        ServiceEnum e = ServiceEnum.valueOf(name.toUpperCase())
        BaseServiceModel model = e.modelClass.newInstance()
        model.dockerImage = e.dockerImage
        ServiceEnum old = serviceMap.put(e, model)
        if (old != null) {
            throw new RuntimeException("Double declaration of service '${name}'")
        }
        this.metaClass[name] = { Closure closure ->
            model.with closure
        }
        model.with closure
    }

    void service(String ...serviceNames) {
        serviceNames.each { name ->
            service(name, {})
        }
    }

    void generateDockerComposeYaml(Writer output) {

        
    }
}
