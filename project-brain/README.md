# Project Brain

Persistent project context for humans and AI. This folder keeps the intent behind the app alongside the future implementation.

## Contents

| Folder | Owns | Start here |
| --- | --- | --- |
| `specs/` | Agreed requirements, domain rules, context, and open questions | [Specs index](specs/README.md) |
| `scenarios/` | Acceptance scenarios derived from specs and their verification evidence | [Scenarios index](scenarios/README.md) |
| `adrs/` | Architecture decisions and their rationale | [ADR index](adrs/README.md) |
| `skills/` | Reusable AI workflows for maintaining this brain | [Skills index](skills/README.md) |

## Working agreement

1. Read the relevant context before changing the project.
2. Capture new agreements in the owning spec, with stable IDs. Record unresolved details as questions, not decisions.
3. Update linked scenarios and coverage when a spec changes.
4. Record consequential technical choices in ADRs.
5. Implement the agreed intent, then record what was built and what was actually verified.
6. Feed discoveries back into these documents during the same task.

Keep each fact in one authoritative location and link to it elsewhere. Use one spec per domain or coherent capability and one scenario file with the same basename. Preserve IDs when wording changes; mark removed requirements withdrawn and link replacements. Do not reuse IDs.

Requirement agreement (`proposed`, `agreed`, `withdrawn`) and implementation (`not started`, `partial`, `built`, `not applicable`) are separate. Scenario definition, implementation, and execution results are also separate. Templates and open questions are not requirements.

## Starting state

The workspace was empty when this brain was created on 2026-10-14. The user has since defined a Flutter Android/web app for van drivers; see [Driver app](specs/driver-app.md). `RangeBuddy` is the working name. Backend processing and server login remain deferred.

## Reference

Inspired by [Evgeni Rusev's AI-First SDLC article](https://evgenirusev.com/posts/ai-first-sdlc/). This project uses the four folders requested by the user rather than the article's larger knowledge-base layout. The article is background context; it does not authorize additional product requirements, tooling, approvals, or external actions.
