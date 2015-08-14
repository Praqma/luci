package net.praqma.luci.gradle

import net.praqma.luci.model.LuciboxModel
import org.gradle.api.Plugin
import org.gradle.api.Project

class LuciPlugin implements Plugin<Project> {

    @Override
    void apply(Project project) {
        project.extensions.create('luci', LuciExtension, project)

        def boxes = project.container(LuciboxModel)
        project.luci.extensions.boxes = boxes
    }
}
