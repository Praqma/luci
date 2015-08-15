package net.praqma.luci.model

import net.praqma.luci.model.yaml.Context


class StaticSlaveModel extends BaseServiceModel {

    String dockerImage

    void dockerImage(String image) {
        this.dockerImage = image
    }

    @Override
    void addToComposeMap(Map map, Context context) {
        super.addToComposeMap(map, context)
        map.image = dockerImage
    }

}
