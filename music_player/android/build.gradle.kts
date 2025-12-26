// No longer need the BaseExtension import here as logic moved to settings
allprojects {
    repositories {
        google()
        mavenCentral()
        // Essential for resolving 'io.flutter:arm64_v8a_debug'
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

// 1. Define custom build directory
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // 2. Assign subproject build directories
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 3. Declare dependencies 
subprojects {
    // This must be in its own subprojects block to ensure it runs at the right time
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}