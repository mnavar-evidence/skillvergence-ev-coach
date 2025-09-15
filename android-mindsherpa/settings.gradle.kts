pluginManagement {
    repositories {
        google {
            content {
                includeGroupByRegex("com\\.android.*")
                includeGroupByRegex("com\\.google.*")
                includeGroupByRegex("androidx.*")
            }
        }
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        // Mux Player SDK repository
        maven("https://oss.sonatype.org/content/repositories/snapshots/")
        maven("https://maven.mux.com/")
    }
}

rootProject.name = "MindSherpa"
include(":app")
