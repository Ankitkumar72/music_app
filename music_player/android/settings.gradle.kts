pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val localPropertiesFile = file("local.properties")
        if (localPropertiesFile.exists()) {
            localPropertiesFile.inputStream().use { properties.load(it) }
        }
        val path = properties.getProperty("flutter.sdk")
        require(path != null) { "flutter.sdk not set in local.properties" }
        path
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")

gradle.lifecycle.beforeProject {
    if (this.hasProperty("android")) {
        val android = this.extensions.findByName("android")
        if (android != null) {
            try {
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val currentNamespace = getNamespace.invoke(android)
                
                if (currentNamespace == null) {
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                    val fallbackNamespace = "com.plugin.${this.name.replace("-", ".")}"
                    setNamespace.invoke(android, fallbackNamespace)
                }
            } catch (e: Exception) {
                // Skip if not supported
            }
        }
    }
}
gradle.projectsEvaluated {
    rootProject.allprojects {
        this.extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.apply {
            if (namespace == null) {
                namespace = when {
                    project.name.contains("on_audio_query") -> "com.lucasjosino.on_audio_query"
                    else -> "com.plugin.${project.name.replace("-", "_")}"
                }
            }
        }
    }
}