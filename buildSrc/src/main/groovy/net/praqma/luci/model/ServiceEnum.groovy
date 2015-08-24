package net.praqma.luci.model

import net.praqma.luci.docker.DockerImage

enum ServiceEnum {

    WEBFRONTEND(NginxModel, DockerImage.SERVICE_NGINX),
    JENKINS(JenkinsModel, DockerImage.SERVICE_JENKINS),
    ARTIFACTORY(ArtifactoryModel, DockerImage.SERVICE_ARTIFACTORY)

    final Class<?> modelClass

    final DockerImage dockerImage

    String getName() {
        return name().toLowerCase()
    }

    ServiceEnum(Class<?> modelClass, DockerImage image) {
        this.modelClass = modelClass
        this.dockerImage = image
    }

}
