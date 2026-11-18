# 本地构建环境（Flutter 3.47.9 + 定制补丁）

PiliPlus 上游代码依赖一组给 Flutter / material_ui 打的补丁（见 `lib/scripts/`），
stock SDK 直接编译会出现大量「私有 API 不存在」错误。按下面步骤准备环境。

## 1. SDK

```bash
puro use 3.47.9
flutter --version   # Flutter 3.47.9 / Dart 3.13.7
flutter pub get
```

`pubspec.yaml` 里约束已放宽为 `flutter: ">=3.47.9"`，`pub get` 不再卡精确版本。

## 2. 给 Flutter SDK 打补丁

在仓库根目录执行（`$SDK` 为当前 Flutter SDK 路径）：

```bash
SDK=$(grep flutter.sdk android/local.properties | cut -d= -f2)
for p in modal_barrier text_selection mouse_cursor image_anim layout_builder \
         navigation_drawer popup_menu fab null_safety_for_selectable_region \
         selectable_region editable_text text_field scroll_position scrollable \
         scrollable_gesture draggable_scrollable_sheet scaffold text \
         text_painter sliver refresh_indicator double_tap_gesture media_query \
         bottom_sheet_android scroll_view navigator bottom_sheet_ios_flutter; do
  git -C "$SDK" apply "$PWD/lib/scripts/$p.patch"
done
```

## 3. 给 material_ui 包打补丁

先确认实际解析到的版本：

```bash
grep -A3 '"name": "material_ui"' .dart_tool/package_config.json
MU=~/.puro/shared/pub_cache/hosted/pub.dev/material_ui-<版本>
for f in "$PWD"/lib/scripts/material/*.patch; do
  (cd "$MU" && patch -p1 --forward --batch < "$f")
done
```

> 注意：`material_ui` 的补丁集是 `lib/scripts/material/`，不要套用 `lib/scripts/` 下的
> Flutter 补丁（路径不同）。

## 4. 网络 / Gradle

- `android/build.gradle.kts` 与 `android/settings.gradle.kts` 已加入阿里云镜像，
  jitpack 的两个传递依赖已放进 `android/local-maven/` 作为离线兜底。
- 若 `flutter_tools/gradle/settings.gradle.kts` 仍只有 `google()/mavenCentral()`，
  需按同样方式加阿里云镜像（官方源保留在后面）。

## 5. 打包

本机 `flutter build apk` 的 included build 守护进程会卡死，直接用 Gradle：

```bash
cd android
./gradlew assembleDebug --no-daemon --console=plain
# APK: build/app/outputs/flutter-apk/app-debug.apk（相对仓库根目录）
```

小米/Redmi 安装若报 `INSTALL_FAILED_USER_RESTRICTED`，需在手机开发者选项里打开
「通过 USB 安装应用」与「USB 调试（安全设置）」后重启手机，并在弹窗中确认安装。
