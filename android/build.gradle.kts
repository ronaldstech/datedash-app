allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val configureAndroid = {
        val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        android?.apply {
            try {
                compileSdkVersion(36)
                defaultConfig.targetSdkVersion(36)
            } catch (e: Exception) {
                // Handle cases where it might be too late
            }
        }
    }

    if (project.state.executed) {
        configureAndroid()
    } else {
        project.afterEvaluate {
            configureAndroid()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
