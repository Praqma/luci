package net.praqma.luci.model

enum ServiceEnum {

    WEBFRONTEND(NginxModel, 'luci/nginx'),
    JENKINS(JenkinsModel, 'luci/jenkins'),
    ARTIFACTORY(ArtifactoryModel, 'luci/artifactory')

    final Class<?> modelClass

    final String dockerImage

    ServiceEnum(Class<?> modelClass, String imageName) {
        this.modelClass = modelClass
        if (imageName.indexOf(':') == -1) {
            // Use default version
            imageName += ':0.1'
        }
        this.dockerImage = imageName
    }

}
