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
        BaseServiceModel me = this
        def map = prepareService(context)
        List<String> startCmd = ['docker', 'run', '-d']
        map.ports.each {
            startCmd << '-p' << it
        }
        map.volumes_from.each {
            startCmd << '--volumes-from' << it
        }
        startCmd << '--name' << map.container_name
        map.extra_hosts.each { name, ip ->
            startCmd << '--add-host' << "${name}:${ip}".toString()
        }
        map.labels.each { name, value ->
            startCmd << '-l' << "${name}=${value}".toString()
        }
        startCmd << me.dockerImage

        startCmd.addAll(map.command)

        new ExternalCommand(dockerHost).execute(startCmd as String[])
    }
}
