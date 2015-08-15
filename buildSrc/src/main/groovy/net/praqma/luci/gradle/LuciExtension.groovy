package net.praqma.luci.gradle

import net.praqma.luci.model.LuciboxModel
import net.praqma.luci.model.yaml.Context
import org.gradle.api.Project
import org.gradle.api.Task
import org.gradle.api.tasks.TaskContainer

class LuciExtension {

    private Project project

    LuciExtension(Project project) {
        this.project = project
    }

}
