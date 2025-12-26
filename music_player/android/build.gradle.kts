allprojects {
    repositories {
        google()
        mavenCentral()

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
    
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}