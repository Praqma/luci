package net.praqma.luci.docker

import groovy.transform.Immutable
import groovy.transform.ToString


@ToString
class ContainerInfo {

    static final String BOX_NAME_LABEL = "net.praqma.lucibox.name"
    static final String CONTAINER_KIND_LABEL = "net.praqma.lucibox.kind"
    static final String CONTAINER_LUCINAME_LABEL = "net.praqma.lucibox.luciname"

    final String id
    final String luciName
    final ContainerKind kind
    final String status

    ContainerInfo(String id, String luciName, String kind, String status) {
        this.id = id
        this.luciName = luciName
        this.kind = ContainerKind.from(kind)
        this.status = status
    }
}
