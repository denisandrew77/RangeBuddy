# Android development scenarios

Source: [Android development](../specs/android-development.md)
Updated: 2026-10-14
All definitions ready. Implementation and execution evidence are recorded below.

## SC-ANDROID-001 — Android toolchain builds the client

Covers: R-ANDROID-001, R-ANDROID-003

Run the project Flutter wrapper with `doctor -v`, then build a debug APK. Expect Android SDK and Java to be recognized and an APK at `build/app/outputs/flutter-apk/app-debug.apk`. Inspect its manifest for the app identifier and supported SDK values.

## SC-ANDROID-002 — VS Code uses the configured tooling

Covers: R-ANDROID-002

Inspect the installed Flutter/Dart extensions and workspace SDK settings. Expect launch configurations for Android development and local web testing, plus an APK build task using the project wrapper. Interactive F5 execution remains unverified until VS Code launches a connected device.

## SC-ANDROID-003 — Physical device is detected

Covers: R-ANDROID-003

List Android devices through adb and Flutter. If an authorized phone is present, install/launch the debug client. Otherwise record the missing device or authorization and the required user-side action; do not claim a device run.

## Coverage

| Requirement | Scenarios |
| --- | --- |
| R-ANDROID-001 | SC-ANDROID-001 |
| R-ANDROID-002 | SC-ANDROID-002 |
| R-ANDROID-003 | SC-ANDROID-001, SC-ANDROID-003 |

## Verification evidence — 2026-10-14

| Scenario | Result | Evidence and limits |
| --- | --- | --- |
| SC-ANDROID-001 | passed | Flutter doctor marks the Android toolchain healthy and licences accepted. `./tool/flutterw build apk --debug` succeeded. `aapt dump badging` confirms package `com.rangebuddy.range_buddy`, version 0.1.0, minimum API 24, target API 36, and INTERNET permission. `apksigner verify --verbose` passed with APK v2 signing. APK is approximately 148 MB. |
| SC-ANDROID-002 | partial | Flutter/Dart extensions 3.144.0 installed. Workspace launch, tasks, and settings JSON parsed successfully; wrapper passes shell syntax checking. SDK/Java paths match the doctor output. Interactive F5 requires a connected Android phone and remains not run. |
| SC-ANDROID-003 | blocked on device | Both Flutter and adb device listings show no Android phone. No emulator or system image is installed, per the user's explicit constraint. User must connect a USB-debugging-enabled phone and approve the computer before installation/launch can be verified. |

Artifact: [Debug APK](../../build/app/outputs/flutter-apk/app-debug.apk). VS Code: [Launch configurations](../../.vscode/launch.json), [Build tasks](../../.vscode/tasks.json), [Workspace settings](../../.vscode/settings.json).
