package net.praqma.luci.model

import net.praqma.luci.model.yaml.Context

class OnDemandSlaveModel extends BaseServiceModel {

    String dockerImage

    String slaveName

    List<String> labels = []

    void dockerImage(String image) {
        this.dockerImage = image
    }

    void labels(String ...names) {
        this.labels.addAll(names)
    }

}
