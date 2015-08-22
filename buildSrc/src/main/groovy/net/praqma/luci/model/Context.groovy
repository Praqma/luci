package net.praqma.luci.model

import groovy.transform.Immutable
import net.praqma.luci.docker.Container
import net.praqma.luci.model.LuciboxModel


class Context {

    /** IP of the lucibox being constructed */
    String internalLuciboxIp

    LuciboxModel box

    Map<String, Container> containers = [:]

    /**
     *
     * @param volumes
     * @return
     */
    String[] volumesFromArgs(String ...volumes) {
        return volumes.collect {
            ["--volumes-from", containers[it].name]
        }.flatten()
    }

    void addContainer(Container con) {
        this.containers[con.luciName] = con
    }
}
