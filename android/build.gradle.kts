import org.gradle.api.file.Directory
import org.gradle.api.tasks.Delete

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    afterEvaluate {
        val ext = extensions.findByName("android")
        if (ext != null) {
            try {
                val cls = ext.javaClass
                val setBuildTools = cls.getMethod("setBuildToolsVersion", String::class.java)
                setBuildTools.invoke(ext, "37.0.0")
                val setCompileSdk = cls.getMethod("setCompileSdk", Int::class.javaPrimitiveType)
                setCompileSdk.invoke(ext, 36)
            } catch (e: Throwable) {
                // ignore
            }
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val subprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(subprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
