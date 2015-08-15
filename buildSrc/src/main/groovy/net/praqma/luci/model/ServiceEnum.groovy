package net.praqma.luci.model

enum ServiceEnum {

    WEBFRONTEND(NginxModel, 'luci/nginx:0.2'),
    JENKINS(JenkinsModel, 'luci/jenkins:0.2'),
    ARTIFACTORY(ArtifactoryModel, 'luci/artifactory:0.2')

    final Class<?> modelClass

    final String dockerImage

    String getName() {
        return name().toLowerCase()
    }

    ServiceEnum(Class<?> modelClass, String imageName) {
        this.modelClass = modelClass
        this.dockerImage = imageName
    }

}
