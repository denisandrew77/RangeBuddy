# ADR-003: Express API with a secure device session

Date: 2026-10-15
Status: accepted
Source: explicit user integration contract; implementation details chosen within that scope.
Supersedes: ADR-002 prototype authentication, storage, payload and preview choices. Its Flutter/Material/localization choices remain applicable.
Related: [API spec](../specs/api-integration.md)

## Decision and rationale

Keep dependency injection, StatefulWidget state and existing Material components. Use package:http for a typed API service and flutter_secure_storage behind an injectable storage abstraction for an atomic session record (exact token, returned plate, configured base URL). Clear old shared-preferences profile verifiers; never migrate them into authenticated sessions. Server van data is authoritative and loaded via the encoded plate route. No cached history is presented as live data.

Retaining the prototype verifier/preview would contradict the supplied server authentication and mileage rules. A new state framework or direct Supabase access would add scope without benefit. Storing token and plate in separate records permits partial sessions; a single encrypted record avoids that. Binding the record to the backend prevents accidental cross-environment token leakage.

## Consequences

Secure storage failures block session restoration and offer explicit retry/local sign-out. Network/lookup failures retain the saved session. Accepted writes and subsequent refresh/save failures get separate feedback/recovery so writes are not retried automatically. No baseline edit endpoint is invented. Local sign-out does not revoke the server token. Passwords exist only in transient form/request memory and are cleared after each attempt. Android backup is disabled per the storage package guidance; web storage requires HTTPS or localhost and remains subject to browser-origin protections.

## Implementation gaps

Client implementation complete: all 38 mocked tests passed and static analysis is clean. Android debug and web compilation, plus mocked real-font screenshot generation, passed. Production API behavior, exact invalid-token payload, browser CORS and physical-device secure storage remain unverified. No production API calls are part of tests.
