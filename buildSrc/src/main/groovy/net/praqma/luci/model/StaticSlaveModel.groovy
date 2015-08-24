package net.praqma.luci.model

import groovy.transform.CompileStatic

@CompileStatic
class StaticSlaveModel extends BaseServiceModel {

    String dockerImage

    String slaveName

    List<String> labels = []

    int executors = 2

    void dockerImage(String image) {
        this.dockerImage = image
    }

    void labels(String... names) {
        this.labels.addAll(names)
    }

    @Override
    void addToComposeMap(Map map, Context context) {
        assert box != null
        super.addToComposeMap(map, context)
        map.image = dockerImage
        map.links = ["${ServiceEnum.WEBFRONTEND.name}:nginx" as String, "${ServiceEnum.JENKINS.name}:master" as String]
        map.command = ['sh', '/luci/data/jenkinsSlave/slaveConnect.sh', slaveName]
        map.volumes_from = [context.jenkinsSlave(dockerHost).name]
    }

}
