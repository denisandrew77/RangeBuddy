# Project instructions

Read [project-brain/README.md](project-brain/README.md) before project work, then the specs, scenarios, and ADRs relevant to the task.

- Capture every new or changed agreement from the conversation in the relevant spec during the same task. Preserve its reason and source when useful; do not rely on chat history alone.
- Keep proposals, assumptions, and unanswered questions distinct from agreed requirements. Do not invent product behavior or infer it from the repository name.
- Update the affected specs before implementing behavior. A clear user instruction is sufficient authorization within its scope; do not ask for redundant confirmation.
- Generate or update the matching scenarios whenever specs change. Link scenarios to stable requirement IDs and record coverage gaps explicitly.
- Record consequential architecture decisions in `project-brain/adrs/`, including alternatives, rationale, consequences, and implementation gaps. Keep unaccepted choices proposed.
- Distinguish intended behavior, actual implementation, and verification evidence. Never mark a scenario passed without executing it.
- Keep these documents current as new facts, constraints, bugs, and decisions emerge. Mention material documentation changes in the response.

## Local workflows

These skills live in the project; read their files directly when relevant. They are not installed globally.

- [Spec manager](project-brain/skills/sdlc-spec-manager/SKILL.md): capture, update, and review agreed requirements.
- [Scenario manager](project-brain/skills/sdlc-scenario-manager/SKILL.md): derive, update, and review acceptance scenarios and coverage.
