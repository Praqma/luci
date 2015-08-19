package net.praqma.luci.docker

import groovy.transform.Immutable


@Immutable
class ContainerInfo {

    final String name
    final ContainerKind kind


}
