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
            // Task to generate docker-compose yaml and other things needed
            // to star the lucibox
            String taskNamePrefix = "luci${box.name.capitalize()}"
            File dir = project.file("${project.buildDir}/luciboxes/${box.name}")
            File yaml = project.file("${dir}/docker-compose.yml")
            Task prepareTask = tasks.create("${taskNamePrefix}Prepare") {
                group 'luci'
                doFirst {
                    box.preStart(defaultDockerHost(project))
                    Context context = new Context(box: box, internalLuciboxIp: box.dockerHost.host)
                    dir.mkdirs()
                    new FileWriter(yaml).withWriter { Writer w ->
                        box.generateDockerComposeYaml(context, w)
                    }
                }
            }

            Task upTask = tasks.create("${taskNamePrefix}Up") {
                group 'luci'
                description "Bring up '${box.name}'"
                dependsOn prepareTask
                doFirst {
                    new ExternalCommand(box.dockerHost).execute(['docker-compose', '-f', yaml.path, 'up', '-d']) {
                        it.eachLine { println it }
                    }
                    println ""
                    println "Lucibox '${box.name}' running at http://${box.dockerHost.host}:${box.port}"
                    println "docker-compose yaml file is at ${yaml.toURI().toURL()}"
                }
            }

            Task downTask = tasks.create("${taskNamePrefix}Down") {
                group 'luci'
                description "Take down '${box.name}'"
                doFirst {
                    // to be implemented
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
