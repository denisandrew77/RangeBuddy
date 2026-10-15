# ADR-002: Flutter client with persistent local setup and a replaceable submission adapter

Date: 2026-10-14
Status: superseded in part by ADR-003 (API/authentication/storage); Flutter/UI/localization retained
Source: user chose Flutter Android/web and deferred backend/login guard; client organization and storage are implementation choices made within that scope.
Related spec: [Driver app](../specs/driver-app.md)

## Context

The UI must work before a server exists. Setup needs to survive restarts, and admin password checks protect local plate editing.

## Decision

Use Flutter Material 3 for both targets. Separate profile storage, password verification, fuel submission, and screens so tests can substitute dependencies. Use shared_preferences for prototype profile persistence, cryptography PBKDF2-HMAC-SHA256 with a random salt for the admin password verifier, and an HTTP adapter selected by an optional compile-time URL. Without a URL, return an explicit preview rather than simulate server success.

## Rationale and alternatives

Flutter follows the user's choice and shares UI across Android/web. Lightweight injected services are sufficient for these screens; a larger state-management framework would add overhead. Memory-only setup would be lost after reopening. Plaintext password storage is unnecessary. Local password verification supports the requested prototype while server authentication remains deferred.

## Consequences

Local storage can be cleared or modified and is not a production authentication boundary. A salted verifier reduces plaintext exposure but does not make local storage a secure vault. No backend or permanent server session is implemented. The optional HTTP payload is provisional, and production authorization must be enforced by the future server. No fuel records are silently persisted as a substitute for server submission.

## Implementation gaps

Development reset (2026-10-14): expose sign-out through a `kDebugMode`-guarded callback. Remove only `rangebuddy.van.v1` from local storage before clearing the active profile. Failed removal preserves the active setup; profile/release builds do not expose the action. This implements the user's development-only exception without introducing server logout.

Language update (2026-10-14): the user chose a Romanian-only interface. Use Flutter's SDK `flutter_localizations` delegates and an explicit `ro_RO` locale for built-in controls alongside translated app text. Display decimal commas in UI; preserve API/storage field names and numeric serialization.

The client screens, injected services, persistence adapter, password verifier, HTTP adapter, and preview mode are implemented. Static analysis, automated client checks, screenshot rendering, and web compilation passed. Fonts and web rendering resources are bundled for local testing. A temporary Flutter SDK and package cache were used because Flutter was absent from PATH; `tool/flutterw` provides a local fallback.

Android setup update (2026-10-14): command-line tooling, Java 21, Flutter/Dart VS Code extensions, and persistent project-local SDK/cache paths are configured. Android debug compilation and APK signature verification passed. See [Android development](../specs/android-development.md). No emulator or system image is installed, per the user's explicit instruction.

Backend processing, agreed API contract, production authentication/session renewal, and credential recovery remain unbuilt. Real device/browser persistence and interactive keyboard behavior remain unverified because no physical Android phone is connected. Android release signing is still the generated debug-signing configuration.

Odometer update (2026-10-14): add an optional `lastOdometerKm` to the existing local profile JSON, with old profiles falling back to their baseline. This avoids a separate storage key and keeps reset behavior unchanged; existing installations need no reset. Only the reading is persisted, not fuel records. A separate fuel history/store was considered unnecessary while backend processing is deferred. The user confirmed that only server-accepted entries update the reading; preview leaves it unchanged. Failed local saves must not be reported as failed server delivery or encourage duplicate sends. The provisional fuel payload now uses `pricePerLitre` in place of `totalPaid`, following the user’s changed field meaning.

Verification of the odometer/price revision: 22 widget/data tests and static analysis passed; preview capture and Android debug compilation succeeded. Actual backend delivery and physical-device storage remain unverified.
