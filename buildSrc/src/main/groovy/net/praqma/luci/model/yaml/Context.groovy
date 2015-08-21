package net.praqma.luci.model.yaml

import groovy.transform.Immutable
import net.praqma.luci.docker.Container
import net.praqma.luci.model.LuciboxModel


class Context {

    /** IP of the lucibox being constructed */
    String internalLuciboxIp

    LuciboxModel box

    Map<String, Container> containers = [:]
}
