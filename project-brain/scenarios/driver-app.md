# Driver app scenarios

Source: [Driver app spec](../specs/driver-app.md)
Updated: 2026-10-15

All scenario definitions are ready. Implementation and verification evidence are tracked below. Client validation and preview cases exercise the documented implementation choices, not additional agreed domain rules.

## SC-DRIVER-001 — Create a van

Covers: R-DRIVER-002, R-DRIVER-003, R-DRIVER-004; UC-DRIVER-001

Given a fresh install, setup shows plate, password, and starting km (0). Enter a plate and password, optionally change starting km, and tap Create. Expect the main screen with that plate at the top and the three fuel-entry fields.

## SC-DRIVER-002 — Reopen without losing setup

Covers: R-DRIVER-007; UC-DRIVER-004

Given a completed setup, restart the app or reload the web page using the same storage. Expect the main screen with the saved plate and baseline, without login or setup prompts. Server session behavior is deferred until a backend exists.

## SC-DRIVER-003 — Preview before the server exists

Covers: R-DRIVER-004, R-DRIVER-005; UC-DRIVER-002

Given no configured server URL, enter valid kilometres, litres, and price per litre and submit. Expect a clearly labeled preview with the entered numbers and plate, stating that nothing was sent. The form values remain available.

## SC-DRIVER-004 — Protect licence-plate editing

Covers: R-DRIVER-006; UC-DRIVER-003

Open Edit licence plate. Before entering the password, the editable plate form is hidden. A wrong password keeps it hidden and shows an error. The correct password opens the edit form; saving a changed plate updates the header and persisted setup. Leaving and revisiting requires the password again.

## SC-DRIVER-005 — Edit starting kilometres

Covers: R-DRIVER-003, R-DRIVER-011
Definition: ready | Implementation: built | Verification: passed (widget tests)

Open Starting kilometres from settings. The numeric editor is hidden until the admin password is verified. A wrong password shows an error and keeps the editor hidden. Unlock with the correct password, change 0 to a valid value, and save. Expect the stored profile to update. Reopening retains the value; revisiting the editor requires the password again. Failed storage retains the old profile and entered correction.

## SC-DRIVER-006 — Validation and failed sends preserve data

Covers: R-DRIVER-004, R-DRIVER-005

Try empty, malformed, nonfinite, or negative values and zero litres/price per litre. Expect field errors and no request. Verify comma decimals parse. With a configured test endpoint returning an error, expect an error and retained form values. With a successful endpoint, expect a single POST with the provisional payload and success feedback. Duplicate taps while pending must not create concurrent requests.

## SC-DRIVER-007 — Android/web and Material presentation

Covers: R-DRIVER-001, R-DRIVER-008

Build and launch on Android and web. At narrow phone and desktop widths, use setup, home, and settings without overflow. Test keyboard scrolling and visible focus. Expect a consistent Material 3 interface with readable labels and accessible actions.

## SC-DRIVER-008 — Romanian interface

Covers: R-DRIVER-009
Definition: ready | Implementation: built | Verification: passed (automated client checks)

Open setup, the main screen, the password-protected plate editor, and baseline settings. Expect Romanian labels, hints, buttons, tooltips, validation, and submission feedback. Built-in Material back/copy/paste controls use Romanian localization. A preview for 42.5 litres displays `42,5 L`; parsing accepts comma and dot decimals while HTTP payloads remain numeric (`pricePerLitre` replaces `totalPaid`). Check narrow-width layouts for longer Romanian text.

Evidence (2026-10-14): all 16 existing tests passed using Romanian UI text. Setup test checks the `ro_RO` locale and Romanian Material back tooltip; preview test checks comma-decimal output; HTTP data tests check the unchanged numeric payload. Responsive checks passed at widths 320 and 1440. Regenerated setup/home screenshots were visually inspected. Actual device/browser interaction remains unverified.

## SC-DRIVER-009 — Development sign-out resets setup

Covers: R-DRIVER-010, R-DRIVER-007
Definition: ready | Implementation: built | Verification: passed (widget tests)

In a debug build with a saved van, tap “Deconectare” on the main screen. Expect the local profile to be removed and setup to appear with starting kilometres 0. Reopening must still show setup. During a submission or removal the button is disabled. If removal fails, show a Romanian error and keep the van and current entry. In release builds, the action is not available and setup remains persistent.

Evidence (2026-10-14): all 19 tests passed. New widget tests verify clear-and-reopen, failed removal retaining the profile and inputs, and no button when the development callback is absent. The pending-submission test verifies sign-out is disabled. Root wiring and callback both use `kDebugMode`; production runtime and actual platform-storage removal have not been exercised. Static analysis reported no issues.

## SC-DRIVER-010 — Display current odometer

Covers: R-DRIVER-012
Definition: ready | Implementation: built | Verification: passed (widget/data tests)

Initially show starting kilometres as the current reading in the home header. A successful server entry updates the header and persists the reading across reopening. Preview, invalid input, and server failure leave it unchanged. If local saving fails, retain the old reading and inputs and explain the failure without inviting a repeated server submission. Baseline edits preserve an already recorded current reading.

## SC-DRIVER-011 — DENICAR launcher identity

Covers: R-DRIVER-013
Definition: ready | Implementation: built | Verification: partial (resource checks; physical launcher not run)

Build the Android APK and inspect its packaged application label and launcher resources. Expect DENICAR and icons derived from the supplied JPG, including adaptive resources on API 26+. Confirm the source JPG has moved from lib to assets/branding. Build web and inspect its manifest, PNG icon sizes, favicon, and installation title. Install/update on an Android phone and inspect the icon under supported launcher masks, then tap it to open the app. For web, install to the home screen and inspect the label/icon. Physical-launcher and installed-PWA verification remain separate from build/resource checks.

## Coverage

| Requirement | Scenarios |
| --- | --- |
| R-DRIVER-001 | SC-DRIVER-007 |
| R-DRIVER-002 | SC-DRIVER-001 |
| R-DRIVER-003 | SC-DRIVER-001, SC-DRIVER-005 |
| R-DRIVER-004 | SC-DRIVER-001, SC-DRIVER-003, SC-DRIVER-006 |
| R-DRIVER-005 | SC-DRIVER-003, SC-DRIVER-006 |
| R-DRIVER-006 | SC-DRIVER-004 |
| R-DRIVER-007 | SC-DRIVER-002 |
| R-DRIVER-008 | SC-DRIVER-007 |
| R-DRIVER-009 | SC-DRIVER-008 |
| R-DRIVER-010 | SC-DRIVER-009 |
| R-DRIVER-011 | SC-DRIVER-005 |
| R-DRIVER-012 | SC-DRIVER-010 |
| R-DRIVER-013 | SC-DRIVER-011 |

## Verification evidence — 2026-10-14

| Scenario | Implementation | Verification and limits |
| --- | --- | --- |
| SC-DRIVER-001 | built | Passed widget test: setup required fields, Create, baseline, plate header, and exactly three home fields. Crypto verifier tested separately with the real algorithm. |
| SC-DRIVER-002 | partial | Passed widget-level app reinitialization using the same injected memory store. Actual Android restart/browser storage reload has not been exercised; no server session exists. |
| SC-DRIVER-003 | built | Passed widget test: explicit no-send preview, comma-decimal values, and retained inputs. |
| SC-DRIVER-004 | built | Passed widget test: wrong password rejection, hidden edit form, correct-password unlock, saved header update, and protection on revisit. Real password derivation/verification covered by a separate data test. |
| SC-DRIVER-005 | built | Passed widget test: baseline save and profile hydration; platform-backed persistence remains unverified on a device/browser. |
| SC-DRIVER-006 | built | Passed unit/widget checks for numeric validation, HTTP JSON payload/2xx handling, failure propagation, retained inputs, and disabled pending-submit button. HTTP tests use MockClient; no real backend was contacted. |
| SC-DRIVER-007 | partial | Widget layouts passed at widths 320 and 1440; real-font setup/home PNG previews visually inspected. Web release and Android debug compilation passed. The APK signature was verified. Interactive browser, keyboard, and physical-device checks remain not run; no emulator is installed, as requested. |

Validation files: [App tests](../../test/app_test.dart), [Data tests](../../test/data_test.dart), [Preview helper](../../tool/capture_previews.dart). Screenshots: [Setup](../../artifacts/previews/setup.png), [Home](../../artifacts/previews/home.png).

Final execution: `flutter test --no-pub` passed all 16 tests; `flutter analyze --no-pub` reported no issues; `flutter test tool/capture_previews.dart --no-pub` passed; `flutter build web --no-pub --no-web-resources-cdn` succeeded. Local HTTP smoke checks returned 200 for the entry page, compiled app, bootstrap, CanvasKit, Material icon font, and favicon. These resource checks do not constitute interactive browser testing.

Revision 2026-10-14: SC-DRIVER-003, SC-DRIVER-005, and SC-DRIVER-006 have changed definitions; earlier evidence is historical and does not verify these revisions. Updated definitions verified below.

Latest execution — 2026-10-14: `./tool/flutterw test --no-pub` passed all 22 tests; `./tool/flutterw analyze --no-pub` reported no issues. SC-DRIVER-003 checks the price-per-litre preview and unchanged current reading. SC-DRIVER-005 checks wrong-password rejection, correct unlock, fresh authentication on revisit, persisted baseline, failed save, and preservation of an existing current reading. SC-DRIVER-006 checks numeric `pricePerLitre` HTTP serialization and removal of `totalPaid`. SC-DRIVER-010 checks initial baseline display, confirmed submission and reopening, unchanged reading on preview/server failure, legacy JSON loading, and the explicit local-save-failure message after successful delivery. Stores/services are injected or mocked; no real backend or physical-device persistence was exercised. The preview capture helper passed and the regenerated home image was inspected.

Android compilation of this revision: `./tool/flutterw build apk --debug --no-pub` succeeded and generated `build/app/outputs/flutter-apk/app-debug.apk`. This verifies compilation, not a physical-device run.

Launcher verification — 2026-10-15: source relocation, Android label/icon references, five legacy PNG density dimensions (48/72/96/144/192), adaptive-icon XML, and web manifest name/icon dimensions passed executable resource checks. `sh -n tool/generate_launcher_icons.sh` passed. Generated web launcher icon visually inspected: full supplied wordmark retained on white with padding. Physical Android launcher masks, update/reinstall behavior, and installed web home-screen behavior remain not run.

Build verification — 2026-10-15: `./tool/flutterw build apk --debug --no-pub` and `./tool/flutterw build web --no-pub --no-web-resources-cdn` succeeded. `aapt dump badging` confirms the packaged application label DENICAR and adaptive launcher icon; ZIP inspection confirms foreground/icon resources. Compiled web manifest, PNG files, and document title checks passed. SC-DRIVER-011 remains partial pending actual home-screen installation/inspection.
