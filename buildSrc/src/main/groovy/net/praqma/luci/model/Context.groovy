package net.praqma.luci.model

import groovy.transform.Immutable
import net.praqma.luci.docker.Container
import net.praqma.luci.docker.Containers
import net.praqma.luci.model.LuciboxModel


class Context {

    /** IP of the lucibox being constructed */
    String internalLuciboxIp

    LuciboxModel box

    private Containers containers

    Context(String internalLuciboxIp, LuciboxModel box) {
        this.internalLuciboxIp = internalLuciboxIp
        this.box = box
        this.containers = new Containers(box)
    }
/**
     *
     * @param volumes
     * @return
     */
    String[] volumesFromArgs(String ...volumes) {
        return volumes.collect {
            ["--volumes-from", containerName(it)]
        }.flatten()
    }

    void addContainer(Container con) {
        this.containers.addContainer(con)
    }

    String containerName(String luciName) {
        return this.containers[luciName]
    }
}
