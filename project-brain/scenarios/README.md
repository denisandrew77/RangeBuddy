# Scenarios

Acceptance scenarios make spec requirements observable. Keep one scenario file per spec with the same basename.

| Scenario file | Source spec |
| --- | --- |
| [Project foundation](project-foundation.md) | [Project foundation](../specs/project-foundation.md) |
| [Driver app](driver-app.md) | [Driver app](../specs/driver-app.md) |
| [Android development](android-development.md) | [Android development](../specs/android-development.md) |

## Scenario format

For each scenario record:

- Stable ID: `SC-<DOMAIN>-001` and a behavior-focused title.
- Source spec and exact requirement/use-case IDs covered.
- Definition status: draft, ready, or withdrawn.
- Priority when useful; implementation status: not started, partial, built, or not applicable.
- Preconditions and concrete Given/When/Then steps, or numbered actions with observable expected results.
- Verification: not run, passed, failed, or blocked; date, method, and evidence for executed checks.

Cover normal flows, failures, and boundaries when the spec supports them. Do not invent missing behavior to complete a scenario. Record the missing detail as an open question and leave the affected scenario draft.

Maintain a coverage table mapping each active requirement to scenario IDs or an explicit exemption with its reason. Distinguish documentation checks from application acceptance scenarios. A ready scenario has a usable definition; it has not necessarily been executed.
