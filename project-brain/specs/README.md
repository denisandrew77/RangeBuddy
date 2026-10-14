# Specs

Record what we agree the project must do and why. Product specs describe behavior rather than implementation; technical decisions belong in ADRs.

| Spec | Scope |
| --- | --- |
| [Project foundation](project-foundation.md) | Agreed brain structure and maintenance workflow; unanswered app questions |
| [Driver app](driver-app.md) | Van setup, fuel entries, protected plate editing, and platform requirements |
| [Android development](android-development.md) | Local Android toolchain, VS Code configuration, and APK verification |

## New spec format

Use a descriptive filename such as `<domain>.md`. Include only sections that add useful context:

- Context: problem, audience, scope, and source of the requirements.
- Glossary: domain terms and roles where needed.
- Use cases: stable IDs such as `UC-<DOMAIN>-001`, actor, goal, and expected outcome.
- Domain rules or requirements: stable IDs such as `R-<DOMAIN>-001`, observable behavior, agreement status, and implementation status.
- Open questions: unresolved details and proposals clearly labeled.
- Change history: dated material agreements or revisions with reasons and sources.

Link relevant scenarios and ADRs. Keep each rule owned by one spec. Preserve withdrawn rules with their replacement link or removal reason. Date entries using the user's timezone.
