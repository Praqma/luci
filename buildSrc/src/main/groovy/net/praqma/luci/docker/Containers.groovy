package net.praqma.luci.docker

import net.praqma.luci.model.LuciboxModel

/**
 * Class to access and create on demand mixin containers
 */
class Containers {

    private Map<String, String> containers = [:]

    private LuciboxModel box

    Containers(LuciboxModel box) {
        this.box = box
    }

    String get(String n) {
        return containers[n]
    }

    void addContainer(Container con) {
        containers[con.luciName] = con.name
    }

    /*
    String java8(DockerHost host) {
        return mixin(host, 'java8', 'luci/mixin-java8:0.2')
    }
    */

    private mixin(DockerHost host, String mixinName, String image) {
        String n = "mixin_${mixinName}"
        if (containers[n] == null) {
            Container container = new Container(image, box, host, ContainerKind.CACHE, n)
            container.create()
            containers[n] = container.name
        }
        return containers[n]

    }
}
