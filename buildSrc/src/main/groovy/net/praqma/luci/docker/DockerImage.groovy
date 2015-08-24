package net.praqma.luci.docker

import net.praqma.luci.model.ArtifactoryModel
import net.praqma.luci.model.JenkinsModel
import net.praqma.luci.model.NginxModel

/**
 * Constants for docker images
 */
enum DockerImage {

    DATA('debian:jessie'),
    STORAGE('luci/data:0.2'),
    MIXIN_JAVA8('luci/mixin-java8:0.2'),

    SERVICE_JENKINS('luci/jenkins:0.2'),
    SERVICE_NGINX('luci/nginx:0.2'),
    SERVICE_ARTIFACTORY('luci/artifactory:0.2'),

    TOOLS('luci/tools:0.2')


    final String imageString

    DockerImage(String imageString) {
        this.imageString = imageString
    }
}
