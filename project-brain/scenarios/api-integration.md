# API integration scenarios

Source: [API spec](../specs/api-integration.md)
Updated: 2026-10-15
All definitions ready; client implementation built. Mocked evidence below verifies client behavior; actual API/platform behavior remains a separate gap.

| Scenario | Requirements | Definition / expected result |
| --- | --- | --- |
| SC-API-001 | R-API-001, R-API-008, R-API-009 | Exact routes, encoded own-plate path, JSON fields/types, `Authorization: RangeBuddy <exact token>` for all protected calls, no Authorization on activation. UTC dates, numeric decimal parsing, bounds and independent month/year defaults; no extra fields/pagination. Reject invalid configuration and insecure production URLs. |
| SC-API-002 | R-API-002, R-API-003, R-API-009 | Activate with 200 and 201, obscure password, persist exact returned token and plate without password/hash, and show returned last_kms even on reactivation. Failed activation preserves inputs except password and writes no session. Busy state prevents duplicates. |
| SC-API-003 | R-API-003, R-API-007, R-API-009 | Restore token/plate from secure storage and GET the van; offline, unknown 401, 404 and server failure retain session with retry. Explicit invalid token clears it. Malformed storage/read/delete failure is recoverable, never leaks secrets. A different API base never receives the token. |
| SC-API-004 | R-API-004, R-API-008, R-API-009 | Integer mileage must exceed last_kms; positive bounded decimals have at most three places. Date/time can be selected. During POST disable writes; after 201 refresh van and selected history. Failed writes retain inputs; accepted write with refresh failure clears submitted inputs and offers refresh without another POST. |
| SC-API-005 | R-API-005, R-API-008, R-API-009 | Show monthly newest-first history, empty and loading states; change month/year and refresh with exactly those query values. Respect Bucharest grouping and 2000–2100 limits. Failure stays visible with manual retry. |
| SC-API-006 | R-API-006, R-API-007, R-API-008, R-API-009 | Plate dialog sends only new_license_plate/password, disables pending submission, keeps valid session on wrong password/conflict/rate limit, clears password and remembers returned plate with same token. Failed local save after PUT offers save-only retry. |
| SC-API-007 | R-API-007, R-API-008, R-API-009 | Sign out after explaining no server revocation; clear secure session and return to activation. Clear failure is visible. 400 fields, 401 password, 404 van, 409 conflict, 429 limit and 500/503 errors produce appropriate feedback; no automatic write retries. |
| SC-API-008 | R-API-004, R-API-005, R-API-006 | Romanian activation/home/history/dialog layouts work at 320 and 1440 pixels; native date/time controls are localized. Android/web compilation passes. Actual keyboard and platform storage require separate runtime evidence. |

## Coverage

Every R-API-001 through R-API-009 is mapped above. Gaps: production contract/CORS, actual Android/browser secure storage, physical keyboard and device runtime, and confirmation of exact invalid-token payload. All automated checks must mock HTTP/storage.

## Executed verification — 2026-10-15

`./tool/flutterw test --no-pub`: all 38 tests passed. `./tool/flutterw analyze --no-pub`: no issues. `dart format lib test tool/capture_previews.dart`: no remaining changes. All networking uses MockClient; session restoration uses SecureSessionStore with an injected in-memory SecretStorage. No production requests were made.

| Scenario | Result | Executed evidence and limits |
| --- | --- | --- |
| SC-API-001 | passed (mocked) | Exact JSON bodies, routes, encoded plate, header scheme/token, 200/201 activation, 201 entries, numeric parsing, UTC dates, independently omitted month/year, no pagination, range/precision validation, base URL/HTTPS checks and cross-server token blocking. |
| SC-API-002 | passed (mocked) | Activation, restored existing mileage, obscured password, password clearing, exact secure record keys, reopening, duplicate-submit guard and local-save-only recovery after activation. |
| SC-API-003 | passed (mocked) | Secure round trip/restoration, unknown 401/404/503/offline retaining session, explicit token invalidation, failed clear recovery, malformed/read-failed storage and API-bound records. |
| SC-API-004 | passed (mocked) | Integer/strictly increasing mileage, decimal precision/bounds, date/time picker flow, pending POST disabled, cleared successful form, refreshed server mileage/history, retained failed inputs and read-only refresh recovery. |
| SC-API-005 | passed (mocked) | Newest-first decoding, empty history, month/year UI query selection and independent defaults. Bucharest UTC month boundaries and summer/winter offsets verified with timezone data. |
| SC-API-006 | passed (mocked) | Wrong password retains valid session/dialog, transient password cleared, successful returned plate stored with unchanged token, new encoded lookup, failed persistence recovery without repeating PUT, invalid token closes dialog. |
| SC-API-007 | passed (mocked) | All specified HTTP statuses, field errors, safe offline/timeout/malformed-response handling, no automatic write retries, redirects rejected, sign-out explanation, failed clear retaining session and successful clear/reopening. |
| SC-API-008 | partial | Layout widgets passed at widths 320 and 1440, Romanian locale/date/time controls exercised, mocked real-font screenshots regenerated and visually inspected, web compilation passed. Android debug compilation passed; actual keyboard, platform storage, CORS and device runtime not run. |

Artifacts: [Activation](../../artifacts/previews/setup.png), [Home](../../artifacts/previews/home.png). Tests: [data](../../test/data_test.dart), [screens](../../test/app_test.dart), [mock support](../../test/support.dart).

Final build evidence — 2026-10-15: `./tool/flutterw build apk --debug --no-pub` succeeded (71.7 seconds), producing `build/app/outputs/flutter-apk/app-debug.apk`. `./tool/flutterw build web --no-pub --no-web-resources-cdn` succeeded. These compilation checks do not exercise production HTTP or platform session restoration.
