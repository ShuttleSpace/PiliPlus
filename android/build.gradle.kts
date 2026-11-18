import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

allprojects {
    repositories {
        // jitpack.io 在国内网络下常被中断 TLS 握手；插件传递依赖 ucrop
        // 以标准 Maven 布局随仓库提供，作为离线可复现的兜底。
        maven { url = uri(rootProject.file("local-maven")) }
        // 国内网络下 Java/Gradle 直连 Maven Central 常被代理中断 TLS 握手，
        // 镜像优先，官方源保留作为 fallback。
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
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
    afterEvaluate {
        if (project.extensions.findByName("android") != null) {
            val androidExtension =
                project.extensions.getByName("android") as com.android.build.gradle.BaseExtension

            if (androidExtension.namespace == null) {
                androidExtension.namespace = project.group.toString()
            }

            androidExtension.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }

            project.tasks.withType<KotlinCompile>().configureEach {
                compilerOptions {
                    jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
                }
            }

            val pluginCompileSdkStr = androidExtension.compileSdkVersion
            val pluginCompileSdk = pluginCompileSdkStr
                ?.removePrefix("android-")
                ?.toIntOrNull()
            if (pluginCompileSdk != null && pluginCompileSdk < 36) {
                project.logger.error(
                    "Warning: Overriding compileSdk version in Flutter plugin: ${project.name} " +
                            "from $pluginCompileSdk to 36 (to work around https://issuetracker.google.com/issues/199180389).\n" +
                            "If there is not a new version of ${project.name}, consider filing an issue against ${project.name} " +
                            "to increase their compileSdk to the latest (otherwise try updating to the latest version)."
                )
                androidExtension.setCompileSdkVersion(36)
            }
        }

        project.buildDir = File(rootProject.buildDir, project.name)
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
