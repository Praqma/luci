package net.praqma.luci.model

import groovy.transform.Immutable
import net.praqma.luci.model.yaml.Context

class NginxModel extends BaseServiceModel {

    private Collection<User> users = []

    NginxModel() {
        this.includeInWebfrontend = false
    }

    def user(String name, String password) {
        users << new User(name, password)
    }

    @Override
    void addToComposeMap(Map map, Context context) {
        super.addToComposeMap(map, context)
        map.ports = [ "${box.port}:80" as String]
        map.links = box.services.findAll { it.includeInWebfrontend }.collect { BaseServiceModel service ->
            "${service.serviceName}:${service.serviceName}" as String
        }
        def services = context.box.services.findAll { it.includeInWebfrontend }*.serviceName
        map.command = ['-s', services.join(' '), '-n', box.name, '-p', box.port as String]
    }

}

@Immutable
class User {
    String name
    String password
}