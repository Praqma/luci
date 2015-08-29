package net.praqma.luci.model

import net.praqma.luci.docker.DockerHost
import net.praqma.luci.utils.ExternalCommand

/**
 * Trait for services that can run on an Auxiliary host
 *
 * I.e. not the host where the main services are running.
 * Auxiliary services can not be started with docker compose
 */
trait AuxServiceModel {

    def prepareService(Context context) {
        BaseServiceModel me = this as BaseServiceModel
        me.preStart(context)
        return me.buildComposeMap(context)
    }

    void startService(Context context) {
        def map = prepareService(context)
        List<String> startCmd = ['docker', 'run']
        map.ports.each {
            startCmd << '-p' << it
        }
        map.volumesFrom.each {
            startCmd << '--volumes_from' << it
        }
        startCmd << '--name' << map.container_name
        map.extra_hosts.each { name, ip ->
            startCmd << '--add-host' << "${name}:${ip}".toString()
        }
        map.labels.each { name, value ->
            startCmd << '-l' << "${name}:${ip}".toString()
        }

        new ExternalCommand(dockerHost).execute(startCmd as String[])
    }
}
