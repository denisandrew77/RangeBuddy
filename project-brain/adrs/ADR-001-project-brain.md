# ADR-001: Four-folder Markdown project brain

Date: 2026-10-14
Status: accepted
Source: user's explicit initial setup request; supporting file conventions selected during setup.
Related spec: [Project foundation](../specs/project-foundation.md)

## Context

The project is starting from an empty workspace. Agreements and their reasons need to survive beyond the current chat and guide future AI work.

## Decision

Create `project-brain/` in the main project folder with `specs/`, `scenarios/`, `adrs/`, and `skills/`. Use Markdown, stable requirement and scenario IDs, linked indexes, and local maintenance skills. Add a root `AGENTS.md` pointing AI sessions to the brain and its workflows.

## Rationale

The four-folder layout follows the user's request. Markdown supports direct reading and review. IDs and links let scenarios trace back to requirements. Root instructions make the maintenance workflow visible to future AI sessions.

## Alternatives considered

- Rely on chat history alone: loses durable, project-local context.
- Adopt the article's full private/internal/external knowledge-base layout: adds organization beyond the requested initial scope.

## Consequences

Specs, scenarios, and ADRs must be maintained as work progresses. Markdown records do not execute tests or guarantee that an AI follows instructions. Local skills are read via project links; they are not globally installed.

## Implementation status and gaps

The initial folder structure, documents, root instructions, and two maintenance skills are created. Ongoing maintenance remains future work. App architecture, runtime, storage, hosting, and automated acceptance-test tooling are undecided.
