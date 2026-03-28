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
    project.plugins.withType<com.android.build.gradle.BasePlugin>().configureEach {
        project.extensions.configure<com.android.build.gradle.BaseExtension> {
            compileSdkVersion(35)
            
            // Inject 'flutter' extension to satisfy plugins like geolocator
            if (this is ExtensionAware) {
                try {
                    extensions.add("flutter", mapOf(
                        "compileSdkVersion" to 35,
                        "targetSdkVersion" to 35,
                        "minSdkVersion" to 23
                    ))
                } catch (e: Exception) {
                    // Ignore if already added
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
