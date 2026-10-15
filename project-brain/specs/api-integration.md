# Express API integration

Updated: 2026-10-15
Source: user-supplied integration request and follow-up API URL.
Scenarios: [API integration](../scenarios/api-integration.md)
Architecture: [ADR-003](../adrs/ADR-003-api-session.md)

## Requirements

All requirements are agreed and implemented in the client. Verification uses mocked HTTP/storage; live API and physical platform-storage behavior remain unverified.

| ID | Requirement | Agreement | Implementation |
| --- | --- | --- | --- |
| R-API-001 | Use the existing Express API only, with typed models and injectable HTTP service. Base URL ends in /api/rangebuddy and is configurable. Default: https://emailplatformbackend.onrender.com/api/rangebuddy. No direct Supabase, service-role credentials, extra device-request fields, or invented endpoints. HTTPS in production. | agreed | built |
| R-API-002 | Activate with plate, integer initial mileage and transient obscured admin password; accept 200/201, securely save the exact returned token and remember the returned plate. Reactivation preserves server mileage/history; token rotation is server-owned. | agreed | built |
| R-API-003 | Store the device token with flutter_secure_storage, restore the session using token plus remembered plate, and load its van. Never persist passwords/hashes or log tokens, credentials, headers, or sensitive bodies. | agreed | built |
| R-API-004 | Display the vehicle plate and latest server mileage. Submit validated integer mileage, litres, unit price and user-selected date/time; refresh van and selected monthly history after a 201 response. Prevent double submits and never automatically retry writes. | agreed | built |
| R-API-005 | Display newest-first monthly fuel history with month/year selection, manual refresh, loading, empty, offline and error states. Send no pagination parameters; use the server’s Europe/Bucharest month grouping. | agreed | built |
| R-API-006 | Change the plate in a password-requiring dialog using the specified PUT. Remember the server-returned plate after success and keep the token unchanged. Do not persist the password. | agreed | built |
| R-API-007 | Local sign-out clears session storage and explains that the server token is not revoked. An explicit invalid-device-token 401 clears the session and returns to activation. Wrong admin passwords remain form errors; network/server errors and van 404 do not clear sessions. | agreed | built |
| R-API-008 | Apply the exact validation and error contract below, including rate limits, field errors and bounds. Treat accepted writes separately from subsequent refresh/storage failures to avoid duplicate submissions. | agreed | built |
| R-API-009 | Add mocked tests for serialization, exact authorization, secure restoration, activation, entries, plate changes and error handling; run formatting, analysis and tests without production calls. | agreed | built |

## API contract (supplied verbatim)


1. POST /activate
No Authorization header.
Body:
{
  "license_plate": "B123ABC",
  "initial_kms": 100000,
  "password": "admin password entered by the user"
}
Response: 201 for a new van, 200 for an existing van:
{
  "token": "<opaque device token>",
  "van": {
    "id": 1,
    "license_plate": "B123ABC",
    "activation_date": "2026-10-15",
    "initial_kms": 100000,
    "last_kms": 100000
  }
}
Securely store the exact returned token. Do not persist the password.
Reactivation rotates the token, invalidating the previous one, but preserves existing mileage and history.

All subsequent requests use:
Authorization: RangeBuddy <token>
Do NOT use Bearer.
JSON requests use Content-Type: application/json.

2. POST /entries
Body:
{
  "current_kms": 100500,
  "litres": 45.5,
  "price_per_litre": 7.25,
  "fuel_date": "2026-10-15T10:00:00Z"
}
Response: 201 with:
{
  "id": 1,
  "van_id": 1,
  "current_kms": 100500,
  "litres": 45.5,
  "price_per_litre": 7.25,
  "fuel_date": "2026-10-15T10:00:00Z"
}
current_kms must be an integer strictly greater than the van's last_kms.
Litres and price must be positive numbers with at most three decimal places.
Send dates using date.toUtc().toIso8601String().
After success, refresh the van and fuel history.

3. GET /entries?month=10&year=2026
Returns a JSON array of fuel entries, newest first.
Each entry also includes a nested "van" object with the same fields as the activation response.
An empty result is [].
Month is 1–12; year is 2000–2100.
Omitted month/year default independently to the current month/year.
The backend groups months using Europe/Bucharest time.
There are no client-facing pagination parameters.

4. GET /vans/:licensePlate
URL-encode the plate.
Returns the van object directly.
The device can access only its own van.
There is no /me endpoint.

5. PUT /vans/license-plate
Body:
{
  "new_license_plate": "B456XYZ",
  "password": "admin password entered by the user"
}
Returns the updated van object.
The device token stays valid.
Update the locally remembered plate after success; do not persist the password.

Validation and errors:
- Never send van_id, isAdmin, or extra fields in device requests.
- Plates are trimmed and uppercased; maximum 20 characters.
- Plate pattern: ^[A-Z0-9]+(?:[ -][A-Z0-9]+)*$
- Mileage range: 0–2147483647.
- Maximum litres: 9999999.999; maximum price_per_litre: 99999.999.
- Parse JSON decimal values as num, then .toDouble().
- Errors generally return {"error":"message"}.
- Validation may also include:
  {"error":"Invalid request","fields":[{"field":"litres","message":"..."}]}
- Handle 400 validation, 401 authentication, 404 missing van,
  409 plate conflict, 429 rate limiting, and 500/503 server errors.
- Activation and plate changes share a limit of five requests per
  15 minutes per IP, including successful requests.
- Do not automatically retry activation or write requests.


## Implementation choices and limits

- Preserve StatefulWidget state, injected dependencies, Material styling, Romanian interface and DENICAR launcher identity.
- Replace the local password-verifier/preview flow. There is no endpoint for baseline editing; initial mileage can be entered at activation, but no local post-activation mileage editor remains.
- Securely store token, remembered plate and API origin/path in one record, binding credentials to the configured backend. Do not send saved credentials to a different base URL.
- Remove the obsolete local profile/password verifier on session loading; no migration of prototype credentials to server credentials.
- Failure to refresh after an accepted entry shows a refresh-only recovery action; do not classify it as a failed submission. A successful plate change with failed local persistence updates the active session and offers local-save recovery without repeating the PUT.
- Display dates in the device local timezone with an explicit label; filter by server Bucharest calendar month, independently of device timezone. Initial filter defaults to the current Bucharest month/year.

## Open questions

- Exact machine-readable invalid-token error payload was not supplied. Conservative implementation will recognize only explicit `invalid_device_token` codes or the exact message `Invalid device token` (case-insensitive, optional final period); unknown 401 errors retain the session. Confirm against the real backend before release.
- Live backend/CORS and platform secure-storage behavior remain unverified until explicitly exercised. No backend changes are authorized.

## Change history

- 2026-10-15: Captured the supplied full integration contract, replacing deferred backend/login assumptions. User supplied the production API URL. No production requests are needed for automated verification.

- 2026-10-15: Implemented the API client and all connected UI flows; 38 mocked data/widget tests passed, formatting is clean, and analysis reports no issues. Web release compilation and mocked screenshot capture passed. See scenarios for remaining runtime gaps.
