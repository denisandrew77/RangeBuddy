# Driver app

Updated: 2026-10-15
Source: user's app description and follow-up answers in this conversation.
Scenarios: [Driver app](../scenarios/driver-app.md)
Architecture: [ADR-002](../adrs/ADR-002-flutter-client.md)

## Context and glossary

Van drivers record refuelling data through the existing Express API. The client targets Android and web.

- **Kilometres:** the van's current odometer reading in km.
- **Starting kilometres:** activation input, initially 0; server mileage is authoritative thereafter.
- **Fuel litres:** amount of fuel added during this entry.
- **Price per litre:** unit price of the fuel; replaces the previously requested receipt total.
- **Admin password:** transient server-verified credential used for activation and plate changes.

## Use cases

- UC-DRIVER-001: Set up the van with a plate, admin password, and editable starting kilometres; Create opens the main screen.
- UC-DRIVER-002: Enter kilometres, fuel litres, and price per litre, then submit the entry for processing.
- UC-DRIVER-003: Change the plate in a dialog using the transient admin password, verified by the server.
- UC-DRIVER-004: Reopen the app and continue with the existing setup without being deliberately logged out.

## Agreed requirements

Connected behavior and API details are owned by [API integration](api-integration.md).

| ID | Requirement | Agreement | Implementation |
| --- | --- | --- | --- |
| R-DRIVER-001 | Flutter Android client and web target for local testing. | agreed | built |
| R-DRIVER-002 | Activate the van with plate, admin password and initial kilometres; see R-API-002. | agreed | built |
| R-DRIVER-003 | Initial kilometres default to 0 at activation. Post-activation edits are unavailable under the supplied API contract. | agreed | built |
| R-DRIVER-004 | Main screen shows plate and three numeric fuel fields: current kilometres, litres, price per litre; add date/time selection per R-API-004. | agreed | built |
| R-DRIVER-005 | Submit entries to the Express API; backend integration now in scope (R-API-004). | agreed | built |
| R-DRIVER-006 | Password-protected plate-change dialog backed by server verification (R-API-006). | agreed | built |
| R-DRIVER-007 | Restore a secure device session after reopening (R-API-003). | agreed | built |
| R-DRIVER-008 | Material Design with a modern, simple, classic interface. | agreed | built |
| R-DRIVER-009 | Romanian interface, including built-in Material controls. | agreed | built |
| R-DRIVER-010 | Provide local sign-out, now available in all builds (R-API-007). | agreed | built |
| R-DRIVER-011 | Password-protected local starting-mileage editor. Withdrawn: supplied API has no endpoint; replaced by activation-only initial mileage in R-API-002. | withdrawn | not applicable |
| R-DRIVER-012 | Display current mileage from the server; refresh only after accepted submissions (R-API-004). | agreed | built |
| R-DRIVER-013 | Supplied DENICAR JPG launcher icon and DENICAR home-screen label; source in assets/branding. | agreed | built |

## Open questions

- Currency remains unspecified; do not invent one.
- Final application/package identifier and in-app branding remain unchanged.
- See API spec for explicit invalid-token payload confirmation and integration verification gaps.

## Change history

- 2026-10-14: Captured the app description: setup, three-field fuel entry, protected plate editing, persistent login intent, Flutter Android/web, Material design, and deferred backend/login guard.
- 2026-10-14: User clarified that price means total amount paid and starting kilometres default to 0 with editing allowed.
- 2026-10-14: Implemented the client screens, local profile store, salted admin verifier, preview/HTTP submission adapters, and Material theme. Updated implementation statuses and scenario evidence; recorded the unavailable Android SDK.
- 2026-10-14: User requested Romanian as the interface language. Keep the RangeBuddy brand and API/storage keys unchanged; display decimal values with commas without changing numeric payloads.
- 2026-10-14: User requested sign-out for development. Implement a debug-only local setup reset as an exception to the production no-logout behavior.
- 2026-10-14: Completed the Android command-line/VS Code setup and debug APK build; see [Android development](android-development.md). User explicitly excluded an emulator; physical-device testing awaits a connected phone.

- 2026-10-14: User replaced the receipt total with price per litre, requested password protection for baseline edits, and a current-odometer display on home (R-DRIVER-004, R-DRIVER-011, R-DRIVER-012). These supersede the earlier total-paid choice. User clarified that the current reading updates only after confirmed server submission.

- 2026-10-14: Implemented price-per-litre UI/preview/HTTP payload, protected baseline editor, and persistent current reading updated only after confirmed server submission. All 22 automated tests passed; static analysis has no issues. Runtime platform persistence and a real backend remain unverified.

- 2026-10-15: User requested moving `lib/sigla_denicar.jpg` to the appropriate asset folder, using it as the home-screen pictogram, and labeling the icon DENICAR (R-DRIVER-013).

- 2026-10-15: Moved the supplied original to `assets/branding/denicar.jpg`, generated density-specific legacy/adaptive Android icons and PNG web icons, and set Android/web launcher names to DENICAR. Kept the package identifier and profile storage stable. Static resource checks passed; build and real-device evidence is tracked in SC-DRIVER-011.

- 2026-10-15: API integration request supersedes prototype preview, local password verification, baseline editing and debug-only logout. Contract and new requirements are owned by api-integration.md.

- 2026-10-15: Connected client flows implemented and verified with 38 mocked tests. Actual production API delivery and platform storage remain unverified; see API scenarios.
