package net.praqma.luci.gradle

import net.praqma.luci.dev.BuildAllImages
import net.praqma.luci.dev.DockerImageBuilder
import net.praqma.luci.docker.DockerHost
import net.praqma.luci.model.LuciboxModel
import net.praqma.luci.utils.SystemCheck
import org.gradle.api.GradleException
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.tasks.TaskContainer

class LuciPlugin implements Plugin<Project> {

    @Override
    void apply(Project project) {
        project.apply(plugin: 'base')
        project.extensions.create('luci', LuciExtension, project)

        def boxes = project.container(LuciboxModel)
        project.luci.extensions.boxes = boxes

        project.afterEvaluate {
            createTasks(project)
        }
    }

    void createTasks(Project project) {
        TaskContainer tasks = project.tasks
        DockerHost defaultHost = defaultDockerHost(project)

        // General Luci tasks
        tasks.create('luciSystemCheck') {
            group 'luci'
            description "Check the systems fitness for playing wiht Luci"

            doFirst {
                new SystemCheck(new PrintWriter(System.out)).perform()

                println "Docker host: ${defaultDockerHost(project)}"
            }
        }

        tasks.create('luciBuildAllImages') {
            group 'luci'
            description 'Build all images needed for Luci'

            doFirst {
                boolean sucess = new BuildAllImages().build(defaultHost)
                if (!sucess) {
                    throw new GradleException("Error building images")
                }
            }
        }

        // Box specific tasks
        project.luci.boxes.each { LuciboxModel box ->
            if (box.dockerHost == null) {
                box.dockerHost = defaultHost
            }
            // Task to generate docker-compose yaml and other things needed
            // to star the lucibox
            String taskNamePrefix = "luci${box.name.capitalize()}"
            String taskGroup = "lucibox ${box.name.capitalize()}"

            tasks.create("${taskNamePrefix}Up") {
                group taskGroup
                description "Bring up '${box.name}'"
                doFirst {
                    File dir = project.file("${project.buildDir}/luciboxes/${box.name}")
                    dir.mkdirs()
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
            host = DockerHost.getDefault()
        }
        return host
    }
}
