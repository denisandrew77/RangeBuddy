---
name: sdlc-spec-manager
description: Capture conversation agreements and maintain or review this project's living Markdown specs, keeping unresolved questions and architecture choices separate from product requirements.
---

# Spec manager

Read `project-brain/README.md`, `project-brain/specs/README.md`, and the affected specs. Paths are relative to the repository root.

## Capture and update

- Extract new agreements, changed requirements, relevant constraints, and their reasons from the current conversation or supplied material. A clear user request establishes intent; do not add a second approval step.
- Treat suggestions and ambiguous details as proposed or open. Do not infer app requirements from names, examples, or external reference articles.
- Update the owning domain spec; create one only when the capability needs a separate home. Keep the index current.
- Use context, glossary, use cases, and domain rules as needed. Follow the IDs and status conventions in the specs index. Give each fact one owner and link other references to it.
- Preserve existing IDs. Mark removed rules withdrawn; record replacements and material changes with dates, reasons, and sources.
- Keep agreement and implementation statuses separate. Inspect evidence before claiming behavior is built; code-derived behavior awaiting user confirmation must be labeled unconfirmed.
- Put consequential technical choices and their rationale in ADRs using the ADR index format. Do not mark proposed choices accepted without an established decision.
- Update matching scenarios using `project-brain/skills/sdlc-scenario-manager/SKILL.md` whenever behavior changes. Capture remaining implementation gaps.

## Review

Check for contradictory rules, duplicate ownership, inconsistent vocabulary, unsupported agreements, missing IDs or links, stale implementation claims, and missing scenario coverage. Correct issues supported by available evidence; record unresolved questions rather than filling gaps with invented behavior. Report material changes and any uncertainty relevant to the task.
