allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

extra["compileSdkVersion"] = 36
extra["minSdkVersion"] = 21
extra["targetSdkVersion"] = 34

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
    plugins.withType<com.android.build.gradle.api.AndroidBasePlugin> {
        val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        android?.let {
            if (it.namespace == null) {
                val packageName = if (project.name == "isar_flutter_libs") {
                    "dev.isar.isar_flutter_libs"
                } else {
                    "com.example.${project.name.replace("-", "_").replace(".", "_")}"
                }
                it.namespace = packageName
                println("Injected namespace for ${project.name}: $packageName")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
