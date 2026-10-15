# RangeBuddy

Flutter client for van drivers, targeting Android and web for local testing. Material 3, a navy/teal palette, and bundled Roboto fonts keep the interface simple and consistent.

The interface is Romanian (`ro_RO`), including Material controls, validation, and server feedback. Decimal values display with commas; both comma and dot input are accepted.

## Implemented

- Server activation using plate, initial integer mileage (default 0) and transient administrator password.
- Device token and remembered plate in `flutter_secure_storage`; authenticated restoration via the own-van lookup.
- Vehicle overview with current server mileage; fuel entry with integer mileage, litres, price per litre and date/time selection.
- Monthly fuel history, month/year filters, refresh, empty/offline/error states and duplicate-submit prevention.
- Server-verified password-protected plate-change dialog; token stays unchanged after a plate change.
- Local sign-out in every build. It clears session storage and does not revoke the server token.

Prototype local password verification and preview submission have been replaced. Old prototype profiles are removed on session loading; activate the device against the server. Initial mileage cannot be edited after activation because the API exposes no endpoint for that. Reactivation preserves the server’s existing mileage and history and rotates its token.

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

The configured default is `https://emailplatformbackend.onrender.com/api/rangebuddy`. All protected calls send `Authorization: RangeBuddy <token>`; activation has no Authorization header. No direct Supabase connection or service credentials are used.

Override the base URL at build/run time (it must end in `/api/rangebuddy`):

```sh
./tool/flutterw run -d chrome --dart-define=RANGEBUDDY_API_BASE_URL=https://your-server.example/api/rangebuddy
./tool/flutterw build apk --debug --dart-define=RANGEBUDDY_API_BASE_URL=https://your-server.example/api/rangebuddy
```

HTTPS is required outside debug builds. Secure storage on web requires HTTPS or localhost, and the backend must allow the browser origin through CORS. Android backup is disabled for the device’s encrypted session storage. A session is bound to its API base URL; switching servers requires local sign-out/reactivation before its token can be used.

Entries send exactly `current_kms`, `litres`, `price_per_litre`, and UTC `fuel_date`. Mileage must be an integer greater than the latest server mileage; litres and price have at most three decimal places and accept comma or dot input. Currency remains unspecified. History filters follow server Europe/Bucharest months; dates are displayed/selected in device local time.

Requests do not retry writes or follow redirects automatically. If a write succeeds but refresh or local persistence fails, recovery performs reads or local saving without repeating the write. Unknown 401 errors, wrong passwords, network failures and van 404 retain the session. Explicit invalid-token 401 errors clear it. The backend’s exact invalid-token payload still needs confirmation: currently recognized markers are `code`/`error: invalid_device_token` or `error: Invalid device token` (case-insensitive, optional final period).

The [API spec](project-brain/specs/api-integration.md) records the supplied contract and known verification gaps. Automated checks use mocked networking and storage; production has not been contacted during implementation.

## Checks and previews

```sh
./tool/flutterw analyze
./tool/flutterw test
./tool/flutterw build web --no-web-resources-cdn
./tool/flutterw test tool/capture_previews.dart
```

The preview helper writes [setup](artifacts/previews/setup.png) and [home](artifacts/previews/home.png) screenshots. Tests cover exact HTTP payloads/authorization, secure session restoration, activation/reactivation, fuel submission, monthly history, plate changes, error recovery, storage failures, duplicate-submit prevention, date/time controls, and narrow/wide layouts. The preview helper also uses mocked API/storage.

Read [Project Brain](project-brain/README.md) for the agreed specs, derived scenarios, architecture decisions, and open questions. Root [AGENTS.md](AGENTS.md) instructs future AI sessions to keep those files updated.

## Launcher branding

The Android and installed-web home-screen icon uses the supplied DENICAR logo and displays **DENICAR**. The original JPG is in `assets/branding/denicar.jpg`; regenerate the PNG resources with `sh tool/generate_launcher_icons.sh` (requires ImageMagick). Android adaptive icons include white padding to retain the full wordmark under launcher masks. Rebuild and reinstall/update the app to apply launcher changes; hot reload does not update them.
