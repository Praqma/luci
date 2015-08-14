package net.praqma.luci.model

import groovy.transform.Immutable

class NginxModel extends BaseServiceModel {
    private Collection<User> users = []

    def user(String name, String password) {
        users << new User(name, password)
    }
}

@Immutable
class User {
    String name
    String password
}