---
name: sdlc-scenario-manager
description: Generate, update, or review this project's Markdown acceptance scenarios from agreed specs, maintaining requirement coverage and honest execution evidence.
---

# Scenario manager

Read `project-brain/scenarios/README.md`, the affected specs, and their existing scenarios. Paths are relative to the repository root.

## Generate and update

- Use one scenario file per spec with the same basename; update the scenario index.
- Derive observable outcomes from agreed requirements and use cases. Include normal flows, boundaries, and failures only where the spec defines their behavior.
- Preserve scenario IDs and follow the scenario index format. Cite exact requirement IDs and the source spec.
- If a missing requirement prevents defining the expected result, record the question in the spec and leave the affected scenario draft. Do not invent permissions, validation rules, or error behavior.
- Update affected scenarios when rules change. Mark obsolete scenarios withdrawn with reasons or replacement links; do not reuse IDs.
- Maintain a coverage table for every active requirement. Record exemptions explicitly with reasons. Flag references to missing or withdrawn rules and undocumented gaps.
- Separate definition readiness, implementation status, and verification results. New or changed scenarios are not run until executed against their current definition.
- When a scenario is executed, record date, method, observed outcome, and evidence. Never infer a pass from the presence of code or instructions.

## Review

Check traceability, coverage, runnable preconditions, clear expected results, and stale verification evidence. Distinguish documentation-workflow checks from app acceptance tests. Summarize gaps and failures relevant to the current task. Generate automated tests only when the task scope and selected tooling call for them.
