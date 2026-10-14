# Android development setup

Updated: 2026-10-14
Source: user asked to handle Android setup after discussing VS Code and command-line tooling instead of Android Studio.
Scenarios: [Android development](../scenarios/android-development.md)

## Requirements

| ID | Requirement | Agreement | Implementation |
| --- | --- | --- | --- |
| R-ANDROID-001 | Set up the tooling needed to build the app for Android on this Mac. | agreed | built |
| R-ANDROID-002 | Configure VS Code to build and run the Flutter app. | agreed | built |
| R-ANDROID-003 | Build a debug APK for development and check for a connected Android device. | agreed | built |

## Implementation choices

- Install Android command-line tools without Android Studio. Use existing Java 21, which avoids the default Java 25 selection for Gradle.
- Keep SDKs and build caches in ignored `.tooling/` under the project. Preserve existing temporary Flutter/cache paths as compatibility links while configuring the project for persistent local paths.
- Install Android API 36, required build tools/platform tools, and the Flutter-selected NDK. Do not install an emulator or system image: the user explicitly excluded emulators. Use a physical Android phone for runtime verification.
- Install the VS Code Flutter extension and its Dart dependency; add project launch/tasks settings.
- Development builds retain the debug-only Deconectare action. Production backend and release publishing/signing remain outside this setup task.

## User-side prerequisites

A physical phone must have USB debugging enabled and authorize this computer on the device. These actions cannot be performed from the Mac on an unconnected or unauthorized phone.

## Change history

- 2026-10-14: Captured the Android/VS Code setup request. Initial inspection found existing Java 21, no Android SDK, no VS Code Flutter extension, and approximately 8.7 GB free.
- 2026-10-14: User explicitly instructed not to install an emulator. Interrupted the emulator download and removed its incomplete installation directory. Continue Android SDK, VS Code, and physical-device setup.
- 2026-10-14: Installed Android command-line tools (verified official SHA-256), API 36, build-tools 36.0.0, platform-tools, and NDK 28.2.13676358; accepted SDK licences as part of the authorized installation. Installed VS Code Flutter/Dart extensions 3.144.0 and configured Java 21, persistent Flutter 3.47.7/Dart 3.13.5, and local caches. Built and signature-verified the debug APK. No physical Android device was detected.
