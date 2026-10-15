# Architecture decisions

Record consequential choices about architecture, infrastructure, data, dependencies, and project organization. Product behavior remains in specs.

| ADR | Status | Decision |
| --- | --- | --- |
| [ADR-001](ADR-001-project-brain.md) | accepted | Four-folder Markdown project brain |
| [ADR-002](ADR-002-flutter-client.md) | accepted | Flutter Android/web client, local setup, and replaceable submission adapter |

| [ADR-003](ADR-003-api-session.md) | accepted | Express API and secure device session replace local prototype authentication |

## New ADR format

Use `ADR-<number>-<short-title>.md` and include:

- Title, stable ID, date, status (`proposed`, `accepted`, `superseded`, or `rejected`), and decision source.
- Context and constraints.
- Decision.
- Rationale and alternatives considered.
- Consequences and tradeoffs.
- Implementation status and what remains unbuilt.
- Related specs, scenarios, and superseding ADR where applicable.

Do not rewrite old reasoning to make it appear a later decision was always intended. Create a superseding ADR for a material reversal and link both records. A proposed technical option is not an accepted decision.
