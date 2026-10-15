# RangeBuddy

Flutter client for van drivers, targeting Android and web for local testing. Material 3, a navy/teal palette, and bundled Roboto fonts keep the interface simple and consistent.

The interface is Romanian (`ro_RO`), including Material controls, validation, and server feedback. Decimal values display with commas; both comma and dot input are accepted.

## Implemented

- Setup: licence plate, admin password, and starting kilometres (default 0).
- Main screen: plate header, current kilometres, litres added, price per litre, and Send entry.
- Password-protected licence-plate and starting-kilometres editors.
- Current odometer in the home header, persisted after a confirmed server submission.
- Persistent local setup across app restarts/browser reloads.
- Numeric validation, submission progress, and errors that retain the entry.

No server login guard is included. Debug builds show a **Deconectare** button below the fuel form to remove the local van setup and return to setup for testing. The action is absent in profile/release builds. Local setup persistence is not a server login session. Admin password verification is local, with a salted PBKDF2 verifier; production server authentication remains future work.

## Run locally

With Flutter installed:

```sh
flutter pub get
flutter run -d chrome
```

Or use a browser-independent development server:

```sh
./tool/flutterw run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

Open `http://127.0.0.1:8080`. The wrapper uses the persistent Flutter SDK in `.tooling/flutter` when present, then Flutter on PATH or the earlier temporary SDK as a fallback. The generated project requires Dart 3.13.5 or later in the 3.x series.

Android command-line tooling is configured for this Mac in ignored `.tooling/android-sdk`, using Java 21 and a project-local Gradle cache. Android Studio is not required. No emulator or system image is installed, as requested. For another computer, follow the [Android setup guide](https://docs.flutter.dev/platform-integration/android/setup).

Connect a physical Android phone with USB debugging enabled, approve the computer on the phone, then:

```sh
./tool/flutterw devices
./tool/flutterw run -d <android-device-id>
./tool/flutterw build apk --debug
```

The debug APK is generated at `build/app/outputs/flutter-apk/app-debug.apk`. Android project files and internet permission are included. Release signing is still the Flutter template's debug signing and must be configured before distribution.

In VS Code, the Flutter/Dart extensions are installed and workspace settings point to the local toolchain. Reload the VS Code window, select the connected Android phone in the status bar, choose **RangeBuddy — Android (debug)**, and press **F5**. **Cmd+Shift+B** runs the **Android: build debug APK** task. SDK environment variables are also available in newly opened VS Code terminals. The workspace settings contain paths for this Mac; update them if the project is moved.

## Server integration

Without configuration, Send entry shows an **Entry preview** dialog. Nothing is transmitted, stored as a fuel record, or processed. Inputs remain in the form; they do not survive app closure. Preview leaves the saved odometer unchanged; only confirmed server submissions update it.

An HTTP adapter can be enabled when a test server exists:

```sh
flutter run -d chrome --dart-define=FUEL_API_URL=https://your-server.example/fuel-entries
```

The provisional request is a JSON POST:

```json
{
  "licencePlate": "B 123 ABC",
  "odometerKm": 125150,
  "fuelLitres": 42.5,
  "pricePerLitre": 7.25,
  "recordedAt": "2026-10-14T12:00:00.000Z"
}
```

The adapter treats HTTP 2xx as accepted, with no response-body contract yet. Currency and backend contract remain undecided. No admin password is sent. Web servers must allow the testing origin through CORS; Android release networking uses HTTPS by default. There are no automatic retries or offline fuel queues.

## Checks and previews

```sh
./tool/flutterw analyze
./tool/flutterw test
./tool/flutterw build web --no-web-resources-cdn
./tool/flutterw test tool/capture_previews.dart
```

The preview helper writes [setup](artifacts/previews/setup.png) and [home](artifacts/previews/home.png) screenshots. Tests cover setup, reopening, protected editing, baseline editing, validation, honest preview behavior, HTTP payloads/errors, failed persistence, duplicate submission prevention, and narrow/wide layouts.

Read [Project Brain](project-brain/README.md) for the agreed specs, derived scenarios, architecture decisions, and open questions. Root [AGENTS.md](AGENTS.md) instructs future AI sessions to keep those files updated.

## Launcher branding

The Android and installed-web home-screen icon uses the supplied DENICAR logo and displays **DENICAR**. The original JPG is in `assets/branding/denicar.jpg`; regenerate the PNG resources with `sh tool/generate_launcher_icons.sh` (requires ImageMagick). Android adaptive icons include white padding to retain the full wordmark under launcher masks. Rebuild and reinstall/update the app to apply launcher changes; hot reload does not update them.
