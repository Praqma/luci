package net.praqma.luci.gradle

import net.praqma.luci.model.LuciboxModel
import net.praqma.luci.model.yaml.Context
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
                    Context context = new Context(box: box, internalLuciboxIp: box.dockerHost.host)
                    dir.mkdirs()
                    new FileWriter(yaml).withWriter { Writer w ->
                        box.generateDockerComposeYaml(context, w)
                    }
                }
            }

            Task preStartTask = tasks.create("${taskNamePrefix}PreStart") {
                group 'luci'
                dependsOn prepareTask
                doFirst {
                    box.preStart()
                }
            }

            Task upTask = tasks.create("${taskNamePrefix}Up") {
                group 'luci'
                description "Bring '${box.name}' up"
                dependsOn preStartTask
                doFirst {
                    project.exec {
                        executable 'docker-compose'
                        args '-f', yaml.path, 'up'
                    }
                }
            }
        }

    }

}
