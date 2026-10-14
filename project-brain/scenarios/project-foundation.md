# Project foundation scenarios

Source: [Project foundation spec](../specs/project-foundation.md)
Updated: 2026-10-14

These are documentation and AI-workflow checks. Application acceptance scenarios will be added when app requirements are agreed.

## SC-BRAIN-001 — Brain structure and readable documentation

Covers: R-BRAIN-001, R-BRAIN-002
Definition: ready | Implementation: built | Verification: passed

Evidence (2026-10-14): inspected the four immediate folders; a Python filesystem check confirmed all 11 Markdown documents are nonempty and all 17 local Markdown links resolve.

Given the project's main folder:
1. Inspect `project-brain/` → its immediate subfolders are exactly `specs`, `scenarios`, `adrs`, and `skills`.
2. Open its index and linked documents → each link resolves to a readable Markdown file.

## SC-BRAIN-002 — New agreements update specs

Covers: R-BRAIN-003
Definition: ready | Implementation: partial | Verification: not run

Given a future conversation adds or changes a requirement:
1. Complete the related task → the owning spec reflects the new agreement with an ID, source, and dated change entry.
2. Inspect any unresolved detail → it is listed as an open question or proposal, not as an agreed rule.
3. If a rule was replaced → the previous ID is retained as withdrawn with a replacement link.

## SC-BRAIN-003 — Changed specs update scenario coverage

Covers: R-BRAIN-004
Definition: ready | Implementation: partial | Verification: not run

Given an agreed requirement is added, changed, or withdrawn:
1. Run the scenario-maintenance workflow → the matching scenario file reflects the changed behavior.
2. Review its coverage table → active requirement IDs link to scenarios or documented exemptions; withdrawn IDs are removed from active coverage.
3. Inspect new scenarios → they describe observable outcomes and show verification as not run until executed.

## SC-BRAIN-004 — Architecture decisions retain rationale

Covers: R-BRAIN-005
Definition: ready | Implementation: built | Verification: passed

Evidence (2026-10-14): read the ADR index and ADR-001 and checked the recorded decision, source, rationale, alternatives, consequences, and implementation gaps; the local-link check confirmed the ADR index link resolves.

Given the initial project-brain decision:
1. Open the ADR index → it links to ADR-001.
2. Read ADR-001 → it states status, context, decision, rationale, alternatives, consequences, and implementation gaps.

## SC-BRAIN-005 — Maintenance skills are available locally

Covers: R-BRAIN-006
Definition: ready | Implementation: built | Verification: passed

Evidence (2026-10-14): read root instructions and both linked skills; local links resolve. Direct Python checks passed for each skill's name, description, simple frontmatter, and absence of scaffold placeholders. The bundled skill validator could not run because PyYAML is absent; full validator execution remains unavailable.

Given an AI session reads the root `AGENTS.md`:
1. Follow the local skill links → the spec and scenario managers exist as `SKILL.md` files with names and descriptions.
2. Read their workflows → they explain how to update specs and regenerate traceable scenarios without inventing requirements.

## Coverage

| Requirement | Scenarios |
| --- | --- |
| R-BRAIN-001 | SC-BRAIN-001 |
| R-BRAIN-002 | SC-BRAIN-001 |
| R-BRAIN-003 | SC-BRAIN-002 |
| R-BRAIN-004 | SC-BRAIN-003 |
| R-BRAIN-005 | SC-BRAIN-004 |
| R-BRAIN-006 | SC-BRAIN-005 |
