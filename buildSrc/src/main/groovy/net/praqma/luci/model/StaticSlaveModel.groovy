package net.praqma.luci.model

import groovy.xml.MarkupBuilder
import net.praqma.luci.model.yaml.Context


class StaticSlaveModel extends BaseServiceModel {

    String dockerImage

    String slaveName

    void dockerImage(String image) {
        this.dockerImage = image
    }

    @Override
    void addToComposeMap(Map map, Context context) {
        assert box != null
        super.addToComposeMap(map, context)
        map.image = dockerImage
        map.links = ["${ServiceEnum.WEBFRONTEND.name}:nginx" as String, "${ServiceEnum.JENKINS.name}:master" as String]
        map.command = ['sh', '/luci/data/jenkinsSlave/slaveConnect.sh', slaveName]
        map.volumes_from = ["${box.name}_data_jenkinsSlave" as String]
    }

}
