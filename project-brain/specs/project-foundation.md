# Project foundation

Updated: 2026-10-14
Source: user's initial request in this conversation.
Scenarios: [Project foundation](../scenarios/project-foundation.md)
Architecture: [ADR-001](../adrs/ADR-001-project-brain.md)

## Context

The user is starting a new app and wants a persistent Markdown project brain created first. It must retain agreements from the conversation and support future AI work.

## Glossary

- **Spec:** the authoritative record of agreed intent, requirements, and relevant context.
- **Scenario:** a concrete acceptance check derived from a spec.
- **ADR:** an architecture decision record explaining a technical choice and its consequences.
- **Skill:** reusable instructions an AI reads to carry out a project workflow.

## Requirements

| ID | Requirement | Agreement | Implementation |
| --- | --- | --- | --- |
| R-BRAIN-001 | The main project folder contains `project-brain/` with four immediate subfolders: `specs/`, `scenarios/`, `adrs/`, and `skills/`. | agreed | built |
| R-BRAIN-002 | Project-brain documentation uses Markdown files readable by AI and humans. | agreed | built |
| R-BRAIN-003 | During each task, record new or changed agreements from this conversation and relevant project facts in the appropriate specs. Distinguish unresolved questions from agreements. | agreed | partial |
| R-BRAIN-004 | Generate test scenarios from the specs and update affected scenarios when requirements change. | agreed | partial |
| R-BRAIN-005 | Keep architecture decisions in `adrs/`, including the reasons for the choices. | agreed | built |
| R-BRAIN-006 | Keep reusable AI skills in `skills/` for future needs, including spec maintenance and scenario generation and updates. | agreed | built |

`Partial` for R-BRAIN-003 and R-BRAIN-004 means the initial documents and instructions exist; ongoing maintenance must be demonstrated in future tasks.

## Open questions

- App purpose, initial capabilities, and platforms are now recorded in [Driver app](driver-app.md).
- Is `RangeBuddy` the intended product name or only the workspace name?

Remaining app questions live in the owning spec.

## Change history

- 2026-10-14: Captured the initial request for a four-folder project brain and ongoing documentation of chat agreements. User supplied the [AI-First SDLC article](https://evgenirusev.com/posts/ai-first-sdlc/) as reference.
- 2026-10-14: Added the driver-app spec, matching scenarios, and ADR-002 after the user defined the first client delivery.
