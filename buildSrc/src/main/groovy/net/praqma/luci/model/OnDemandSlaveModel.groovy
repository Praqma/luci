package net.praqma.luci.model

import net.praqma.luci.model.yaml.Context

class OnDemandSlaveModel extends BaseServiceModel {

    String dockerImage

    String slaveName

    void dockerImage(String image) {
        this.dockerImage = image
    }
}
