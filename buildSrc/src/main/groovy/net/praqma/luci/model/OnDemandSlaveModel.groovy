package net.praqma.luci.model

class OnDemandSlaveModel extends BaseServiceModel {

    String dockerImageString
    String slaveName

    void dockerImage(String image) {
        this.dockerImageString = image
    }
}
