pluginManagement {
    repositories {
        mavenCentral()
        gradlePluginPortal()
        maven("https://maven.fabricmc.net")
        maven("https://maven.neoforged.net/releases")
        maven("https://maven.minecraftforge.net/")
        maven("https://maven.quiltmc.org/repository/release")
        maven("https://repo.spongepowered.org/repository/maven-public")
    }

    resolutionStrategy.eachPlugin {
        when (requested.id.id) {
            "org.spongepowered.mixin" -> useModule("org.spongepowered:mixingradle:${requested.version}")
        }
    }
}

plugins {
    id("org.gradle.toolchains.foojay-resolver-convention") version "0.8.0"
}

rootProject.name = "wthit-26.2"

fun platform(name: String) {
    include(name)
    project(":${name}").projectDir = file("platform/${name}")
}

val supportedPlatforms = setOf("mojmap", "fabric", "forge", "neo", "textile")
val requestedPlatforms = providers.gradleProperty("enabledPlatforms").orNull
    ?.split(',')
    ?.map(String::trim)
    ?.filter(String::isNotEmpty)
    ?.toSet()

val enabledPlatforms = if (requestedPlatforms == null) {
    supportedPlatforms
} else {
    require(requestedPlatforms.all(supportedPlatforms::contains)) {
        "Unknown platform in enabledPlatforms=$requestedPlatforms; supported values are $supportedPlatforms"
    }

    buildSet {
        addAll(requestedPlatforms)
        if ("fabric" in requestedPlatforms) add("textile")
    }
}

fun enabledPlatform(name: String) {
    if (name in enabledPlatforms) platform(name)
}

enabledPlatform("mojmap")

//platform("bukkit")
enabledPlatform("fabric")
enabledPlatform("forge")
enabledPlatform("neo")
enabledPlatform("textile")
//platform("quilt")
