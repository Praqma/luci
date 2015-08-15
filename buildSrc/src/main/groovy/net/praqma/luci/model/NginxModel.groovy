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
        map.ports = [ '80:80']
        map.links = [ 'jenkins:jenkins', 'artifactory:artifactory']
        def services = context.box.services.findAll { it.includeInWebfrontend }*.serviceName
        map.command = ['-s', services.join(' ') ]
    }
}

@Immutable
class User {
    String name
    String password
}