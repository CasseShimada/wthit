import org.gradle.api.Project
import org.gradle.api.tasks.SourceSetContainer
import org.gradle.api.tasks.bundling.Jar
import org.gradle.api.tasks.compile.JavaCompile
import org.gradle.kotlin.dsl.*

fun Project.setupPlatform(setRuntimeClasspath: Boolean = true) {
    val rootSourceSets = rootProject.extensions.getByType<SourceSetContainer>()
    val sourceSets = extensions.getByType<SourceSetContainer>()
    val productionRootSourceSetNames = buildSet {
        addAll(setOf("api", "main", "minecraftless", "pluginCore", "pluginExtra", "pluginHarvest", "pluginVanilla"))
        if (providers.gradleProperty("includeTestPlugins").orNull.toBoolean()) add("pluginTest")
    }
    val productionRootSourceSets = rootSourceSets.filter { it.name in productionRootSourceSetNames }

    sourceSets.apply {
        val api by creating
        val main by getting
        val plugin by creating

        listOf(api, plugin).applyEach {
            compileClasspath += main.compileClasspath + rootSourceSets["api"].output
        }

        listOf(plugin, main).applyEach {
            compileClasspath += api.output + rootSourceSets["mixin"].output
        }

        listOf(api, main, plugin).applyEach {
            compileClasspath += rootSourceSets["buildConst"].output
        }

        main.apply {
            resources.srcDir(rootProject.file("src/resources/resources"))

            productionRootSourceSets.forEach {
                compileClasspath += it.output
                if (setRuntimeClasspath) runtimeClasspath += it.output
            }

            if (setRuntimeClasspath) {
                runtimeClasspath += api.output
                runtimeClasspath += plugin.output
            }
        }
    }

    // mixin ap need to access the classes so it needs to be compiled on each platform
    tasks.named<JavaCompile>("compileJava") {
        source(rootSourceSets["mixin"].allJava)
    }

    tasks.named<Jar>("jar") {
        from(sourceSets["api"].output)
        from(sourceSets["plugin"].output)

        productionRootSourceSets.forEach {
            from(it.output)
        }
    }

    tasks.named<Jar>("sourcesJar") {
        dependsOn(":generateTranslationClass")
        includeEmptyDirs = false
        from(sourceSets["api"].allSource)
        from(sourceSets["plugin"].allSource)
        (productionRootSourceSets + rootSourceSets["mixin"] + rootSourceSets["buildConst"]).forEach {
            from(it.allSource)
        }
    }
}

fun Project.setupStub() {
    extensions.configure<SourceSetContainer> {
        val main by getting
        create("stub") {
            compileClasspath += main.compileClasspath
        }
    }
}
