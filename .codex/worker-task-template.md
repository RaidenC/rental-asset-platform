# Codex/Luna worker task template

Fill every placeholder from the accepted execution manifest before launch.

```text
PHASE: <phase-id>
TASK: <task-id>
IMPLEMENTATION PLAN: <canonical reference>
BASE SHA: <full pinned SHA>
REPOSITORY: <owner>/<repository>
EXPECTED BRANCH: <reviewed branch>

Execute this accepted task according to the approved implementation plan.

You have authority for:
- implementation;
- task-local refactoring;
- migrations explicitly required by the plan;
- builds, tests, formatting, lint, and type fixes;
- mechanical corrections that do not alter accepted semantics.

You do not have authority to:
- alter phase scope;
- modify canonical semantics or replace accepted architecture;
- weaken security or tenant isolation;
- change financial/accounting rules;
- invent behavior where a material decision is missing;
- modify the accepted implementation plan;
- accept new project risk;
- modify coordinator-owned control-plane files unless the accepted task says so.

Work autonomously within those boundaries. Do not ask the human for routine
coding decisions that can be safely determined from repository state and the
accepted plan.

Before implementation, verify the pinned repository state. If repository
reality materially conflicts with the accepted plan, stop the affected work
and emit PLAN_ESCALATION.

Complete the task by:
1. implementing the accepted work;
2. running focused validation;
3. fixing implementation defects within scope;
4. running required final validation;
5. committing focused changes with provenance;
6. producing the handoff below.

TASK_COMPLETE

Phase:
Task:
Base SHA:

Implemented:

Files changed:

Validation:
- command → result

Commits:

Assumptions:
- none

Remaining issues:
- none

Plan escalation:
- none
```

Suggested commit trailers when practical:

```text
Phase: <phase-id>
Task: <task-id>
Plan: <implementation-plan identifier/reference>
Base: <full pinned SHA>
```
