package net.praqma.luci.gradle

import net.praqma.luci.docker.DockerHost
import net.praqma.luci.model.LuciboxModel
import net.praqma.luci.model.yaml.Context
import net.praqma.luci.utils.ExternalCommand
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.Task
import org.gradle.api.tasks.TaskContainer

class LuciPlugin implements Plugin<Project> {

    @Override
    void apply(Project project) {
        project.extensions.create('luci', LuciExtension, project)

        def boxes = project.container(LuciboxModel)
        project.luci.extensions.boxes = boxes

        project.afterEvaluate {
            createTasks(project)
        }
    }

    void createTasks(Project project) {
        TaskContainer tasks = project.tasks
        project.luci.boxes.each { LuciboxModel box ->
            if (box.dockerHost == null) {
                box.dockerHost = defaultDockerHost(project)
            }
            // Task to generate docker-compose yaml and other things needed
            // to star the lucibox
            String taskNamePrefix = "luci${box.name.capitalize()}"
            String taskGroup = "lucibox ${box.name.capitalize()}"
            File dir = project.file("${project.buildDir}/luciboxes/${box.name}")

            tasks.create("${taskNamePrefix}Up") {
                group taskGroup
                description "Bring up '${box.name}'"
                doFirst {
                    box.bringUp(dir)
                }
            }

            tasks.create("${taskNamePrefix}Down") {
                group taskGroup
                description "Take down '${box.name}'"
                doFirst {
                    box.takeDown()
                }
            }

            tasks.create("${taskNamePrefix}Destroy") {
                group taskGroup
                description "Destroy '${box.name}', delete all containers includeing data containers"
                doFirst {
                    box.destroy()
                }
            }
        }
    }

    private DockerHost defaultDockerHost(Project project) {
        DockerHost host = null
        if (project.hasProperty('dockerMachine')) {
            String dockerMachine = project['dockerMachine']
            project.logger.lifecycle("Default dockerhost is '${dockerMachine}'")
            host = DockerHost.fromDockerMachine(dockerMachine)
        } else {
            project.logger.lifecycle("Default dockerhost is defined by env vars")
            host = DockerHost.fromEnv()
        }
        return host
    }
}
