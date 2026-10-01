# Codex execution governance

This directory contains repository execution metadata and worker contracts. It
is not canonical product design, domain semantics, or a replacement ExecPlan
system. Canonical phase artifacts are referenced by the phase manifest and live
at registered Project Library paths.

## Normal lifecycle

Project/Sol designs and approves a phase and its repo-grounded implementation
plan. The accepted plan is pinned to a GitHub repository, reviewed branch, and
full commit SHA. Codex/Luna then executes only that plan:

1. create or verify the phase integration branch from the pinned SHA;
2. create one task branch and worktree per independent task;
3. run focused implementation and validation autonomously inside each worktree;
4. hand focused commits to the coordinator;
5. integrate mechanically into the phase branch and run integration validation;
6. open the phase pull request to protected `main`.

There is no second repository-local architecture or implementation-planning
layer. The `.agent/execution/` manifest is only machine-readable execution
metadata.

## Coordinator and worker boundary

The coordinator handles scheduling, worktrees, integration, deterministic
validation, and mechanical conflicts. It does not redesign the product,
reinterpret semantic ambiguity, waive checks, or accept risk.

Workers may implement accepted tasks, refactor locally, perform explicitly
planned migrations, build, test, format, lint, type-check, and make mechanical
corrections. They must stop the affected work and emit `PLAN_ESCALATION` when
repository reality, security, data integrity, or the accepted plan conflicts.

Use `.codex/worker-task-template.md` for launches and
`.codex/PLAN_ESCALATION.md` for semantic escalations. Use
`.codex/phase-completion-template.md` for the coordinator handoff.

## Capability model

`.codex/config.toml` gives ordinary workers workspace-write access, no approval
prompts for routine commands, no shell network access, and no web/app access.
Codex loads project `.codex/` settings only after the repository is trusted;
the first human operator must trust this repository in their local Codex
installation. It never grants full
filesystem access, privilege escalation, or automatic authority to resolve a
semantic escalation. Dependency installation, GitHub settings, and other
network/protected operations are explicit coordinator capabilities.

`./scripts/bootstrap` checks local prerequisites without installing anything.
`./scripts/validate` is the deterministic repository validation entry point.
