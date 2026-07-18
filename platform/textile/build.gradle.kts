plugins {
    id("net.fabricmc.fabric-loom")
}

setupPlatform()

dependencies {
    minecraft("com.mojang:minecraft:${rootProp["minecraft"]}")
    implementation("net.fabricmc:fabric-loader:${rootProp["fabricLoader"]}")

    compileOnly("net.fabricmc.fabric-api:fabric-api:${rootProp["fabricApi"]}")
    compileOnly("maven.modrinth:mOgUt4GM:${rootProp["modMenuModrinth"]}")
    compileOnly("me.shedaniel:RoughlyEnoughItems-api-fabric:${rootProp["rei"]}")
    compileOnly("teamreborn:energy:${rootProp["trEnergy"]}")
}

sourceSets {
    main {
        resources.setSrcDirs(emptyList<Any>())
    }
}

loom {
    interfaceInjection.enableDependencyInterfaceInjection.set(false)
    runs {
        configureEach {
            isIdeConfigGenerated = false
        }
    }
}

tasks.compileJava {
    exclude("mcp/mobius/waila/mixed/**")
    exclude("mcp/mobius/waila/mixin/**")
}

tasks.generateDLIConfig {
    enabled = false
}
