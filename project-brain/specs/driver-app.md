# Driver app

Updated: 2026-10-14
Source: user's app description and follow-up answers in this conversation.
Scenarios: [Driver app](../scenarios/driver-app.md)
Architecture: [ADR-002](../adrs/ADR-002-flutter-client.md)

## Context and glossary

Van drivers record refuelling data for future server-side processing. The first delivery is the Flutter client, targeting Android and web for local testing.

- **Kilometres:** the van's current odometer reading in km.
- **Starting kilometres:** editable baseline reading, initially 0.
- **Fuel litres:** amount of fuel added during this entry.
- **Price per litre:** unit price of the fuel; replaces the previously requested receipt total.
- **Admin password:** the password chosen at setup to protect licence-plate and starting-kilometres editing; separate from future server login.

## Use cases

- UC-DRIVER-001: Set up the van with a plate, admin password, and editable starting kilometres; Create opens the main screen.
- UC-DRIVER-002: Enter kilometres, fuel litres, and price per litre, then submit the entry for processing.
- UC-DRIVER-003: Authenticate with the admin password and edit the van's licence plate.
- UC-DRIVER-004: Reopen the app and continue with the existing setup without being deliberately logged out.

## Agreed requirements

| ID | Requirement | Agreement | Implementation |
| --- | --- | --- | --- |
| R-DRIVER-001 | Build a Flutter mobile interface for Android and a web target for local testing. | agreed | built |
| R-DRIVER-002 | Setup asks for the licence plate and admin password. Create opens the main screen. | agreed | built |
| R-DRIVER-003 | Starting kilometres default to 0 and can be edited. | agreed | built |
| R-DRIVER-004 | The main screen displays the licence plate at the top and exactly three entry fields: odometer kilometres, fuel litres, and price per litre. | agreed | built |
| R-DRIVER-005 | A submit button sends the three values to a server for processing; the server is not available in this delivery. | agreed | partial |
| R-DRIVER-006 | Provide a separate licence-plate editing page protected by the admin password. | agreed | built |
| R-DRIVER-007 | Users should remain signed in once logged in; omit the server login guard for now. | agreed | partial |
| R-DRIVER-008 | Use Material Design with a modern, simple, classic interface. | agreed | built |
| R-DRIVER-009 | The app interface is Romanian, including all pages, field labels, actions, hints, validation, errors, tooltips, and built-in Material controls. | agreed | built |
| R-DRIVER-011 | Editing starting kilometres after setup requires the admin password, with a fresh check on every visit. | agreed | built |
| R-DRIVER-012 | The main page displays the current odometer reading, updated only after confirmed server submission and retained across reopening. Before any confirmed entry it uses the starting kilometres. | agreed | built |
| R-DRIVER-010 | Provide an explicit sign-out button for development so setup can be tested again. | agreed | built |

R-DRIVER-001 has successful web and Android debug builds; physical-device execution remains unverified because no phone is connected. R-DRIVER-005 has a tested preview and HTTP adapter; actual backend processing is deferred. R-DRIVER-007 has persistent local setup with no login guard or production logout; server session behavior remains deferred.

## Implementation choices for this delivery

These are reversible client choices, not additional user-agreed domain rules:

- Keep the current reading unchanged during preview, invalid input, and failed submissions. Baseline edits preserve an already recorded reading. If local saving fails after server confirmation, keep the inputs and explain that delivery succeeded but local persistence failed; do not invite a duplicate send.
- Send `pricePerLitre` in the provisional payload instead of `totalPaid`; do not infer a currency or calculate receipt totals.
- Verify the administrator password before displaying the baseline editor; require a fresh check on each visit.
- Edit the baseline in setup, and later from a separate starting-kilometres settings page. Keep the main entry form to three fields.
- Keep the local van setup across restarts. Production has no logout button; development has the explicit exception in R-DRIVER-010. This is local persistence, not implemented server authentication.
- Show “Deconectare” on the main screen only in debug builds. It removes this app's saved van profile (including the admin verifier and baseline) and returns to setup. Retain the current profile if removal fails; disable the action during submission or removal. This local reset does not contact a server.
- Verify the admin password before displaying the plate-edit form, and require it again on a new visit. Persist a salted password verifier rather than plaintext.
- Require a nonempty plate and password; allow kilometres >= 0 and positive litres/price per litre. Support dot/comma decimal input, reject invalid/nonfinite values, and reject current readings below the baseline. Exact domain limits remain open.
- When no server URL is configured, show a clearly labeled preview of the payload and keep the entered values. Do not claim a successful send or server processing.
- Support an optional HTTP POST adapter via `FUEL_API_URL`; the initial JSON contract is provisional until a backend is agreed. Failed requests retain the form for retry.

## Open questions

- Currency for the price-per-litre field (no currency is assumed in this delivery).

- Backend URL, request contract, authentication, session lifetime/renewal, response semantics, and error format.
- Whether readings must increase from the previous submission, or multiple entries at the same reading are allowed.
- Production credential storage and recovery; local prototype password protection is not a server security boundary.
- Final product name and application/package identifier; RangeBuddy remains a working label.

## Change history

- 2026-10-14: Captured the app description: setup, three-field fuel entry, protected plate editing, persistent login intent, Flutter Android/web, Material design, and deferred backend/login guard.
- 2026-10-14: User clarified that price means total amount paid and starting kilometres default to 0 with editing allowed.
- 2026-10-14: Implemented the client screens, local profile store, salted admin verifier, preview/HTTP submission adapters, and Material theme. Updated implementation statuses and scenario evidence; recorded the unavailable Android SDK.
- 2026-10-14: User requested Romanian as the interface language. Keep the RangeBuddy brand and API/storage keys unchanged; display decimal values with commas without changing numeric payloads.
- 2026-10-14: User requested sign-out for development. Implement a debug-only local setup reset as an exception to the production no-logout behavior.
- 2026-10-14: Completed the Android command-line/VS Code setup and debug APK build; see [Android development](android-development.md). User explicitly excluded an emulator; physical-device testing awaits a connected phone.

- 2026-10-14: User replaced the receipt total with price per litre, requested password protection for baseline edits, and a current-odometer display on home (R-DRIVER-004, R-DRIVER-011, R-DRIVER-012). These supersede the earlier total-paid choice. User clarified that the current reading updates only after confirmed server submission.

- 2026-10-14: Implemented price-per-litre UI/preview/HTTP payload, protected baseline editor, and persistent current reading updated only after confirmed server submission. All 22 automated tests passed; static analysis has no issues. Runtime platform persistence and a real backend remain unverified.
