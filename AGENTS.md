# Fleet Platform Repository Execution Governance

This file governs repository execution. Canonical product design and accepted
implementation plans remain in the registered Project Library paths named by
each phase execution manifest.

## Authority

Project/Sol owns:

- product, domain, architecture, security, financial, and data-integrity semantics;
- phase scope and canonical design;
- the repo-grounded implementation strategy and accepted implementation plan;
- accepted risks and decisions caused by material repository drift or plan defects.

Codex/Luna owns:

- implementing accepted tasks;
- task-local refactoring and mechanical integration;
- migrations explicitly required by the accepted plan;
- builds, tests, formatting, lint/type fixes, and deterministic validation.

Codex/Luna does not change phase scope, redefine requirements, replace accepted
architecture, weaken authorization or tenant isolation, change financial rules,
resolve material ambiguity, materially change persistence/integration strategy,
modify canonical plans during implementation, or accept new project risk.

**Execute independently inside delegated implementation authority. Escalate
instead of silently redesigning.**

## Canonical source of truth

Canonical phase design and implementation-plan artifacts live at their registered
Project Library paths. Repository-local manifests, summaries, task prompts,
execution notes, and caches are non-canonical execution metadata. They must not
become a competing design or planning authority.

The accepted phase lifecycle is:

1. Project/Sol design, panel review R1/R2/R3, GREENLIGHT, canonical design;
2. Project/Sol repo-grounded implementation plan, independent panel review,
   semantic conformance review, GREENLIGHT, canonical implementation plan;
3. Codex/Luna implementation of that accepted plan.

## Approved-plan prerequisite

Implementation requires all of the following before a normal worker starts:

- approved canonical phase design;
- approved canonical repo-grounded implementation plan;
- GREENLIGHT state;
- repository identity, reviewed branch, full pinned base SHA;
- phase and task identifiers;
- a valid `.agent/execution/phase-<phase>.yaml` manifest.

Missing or invalid metadata is an execution block. Do not invent a plan,
substitute current HEAD for the pinned SHA, or start reasonable-looking work
without the accepted contract. Use `./scripts/phase-preflight <phase>` and emit
the structured escalation/block report when it fails.

## Pinned repository state and drift

The accepted implementation plan is grounded against one GitHub repository,
branch, and full commit SHA. The SHA is part of the implementation contract.
Preflight verifies that the SHA exists, that the phase integration branch has
valid ancestry, and that current state has not materially drifted.

When drift affects aggregates/entities, migrations, APIs/contracts,
authorization, tenant isolation, shared abstractions, integration contracts,
dependencies, module boundaries, or relevant build/test behavior, stop the
affected semantic work and emit `PLAN_ESCALATION` with type
`MATERIAL_REPO_DRIFT`. Do not conceptually rebase the accepted plan in place.

## Worktree and branch isolation

Every parallel writing task uses one task, one branch, and one worktree.

- Phase integration branch: `phase/<phase-id>-<short-description>`.
- Task branch: `agent/<phase>-<task-id>-<short-description>`.
- Default worktree root: `../<repo-name>-worktrees/<phase>/<task-id>/`.
- Never share a writing worktree, reuse a dirty worktree, edit another worker's
  worktree, or overwrite a branch/path collision.

The normal route is:

`pinned reviewed SHA` → `phase integration branch` → task branches/worktrees
→ phase validation → pull request → `main`.

Use `./scripts/agent-worktree` for creation, listing, and removal. Ordinary
task workers never integrate directly into `main`.

## Main and control-plane ownership

Ordinary workers must not directly modify or push `main`. They finish with
focused commits, validation results, a concise handoff, and any escalation.
The execution coordinator integrates accepted task commits into the phase
branch and prepares the phase-level PR.

Coordinator-owned control-plane files are:

- `.codex/**`, `.agent/**`, `.github/**`, and root `AGENTS.md`;
- repository-wide CI/CD and security configuration;
- orchestration scripts, branch-protection configuration, and generated
  aggregate files;
- dependency lockfiles when multiple tasks would contend on them;
- global build configuration and migration ordering/registry files.

A feature worker reports a required control-plane change instead of
opportunistically changing unrelated governance state.

## Execution coordinator

The coordinator verifies prerequisites and pinned state, creates the phase
branch and task worktrees, launches and sequences accepted tasks, parallelizes
only independent work, monitors status, integrates commits, resolves purely
mechanical conflicts, runs integration validation, detects drift, emits
escalations, and prepares a phase completion report.

The coordinator is not an architect. It must not invent requirements, alter
scope or semantics, redesign persistence/integrations, waive verification, or
accept risks.

## Capability versus semantic escalation

Capability/security escalation concerns access: filesystem scope, network,
GitHub credentials, repository settings, or another protected resource. It is
handled by sandbox rules, denial, or explicit privileged execution.

Semantic/project escalation concerns meaning or contract: plan defects,
material repository drift, design/security/data-integrity conflicts, missing
decisions, or an unimplementable assumption. It must go back to Project/Sol;
Auto-review and Codex must not decide it silently.

Required escalation types are:

`MATERIAL_REPO_DRIFT`, `PLAN_DEFECT`, `DESIGN_CONFLICT`, `SECURITY_CONFLICT`,
`DATA_INTEGRITY_CONFLICT`, `MISSING_REQUIRED_DECISION`,
`UNIMPLEMENTABLE_ASSUMPTION`.

Use the exact `PLAN_ESCALATION` contract in
`.codex/PLAN_ESCALATION.md`. Stop only the affected semantic work; preserve
completed evidence and report the escalation.

## Destructive operations and secrets

Never autonomously force-push, rewrite shared history, delete repositories or
unrelated branches, mass-delete unrelated files, destroy production data, run
destructive production migrations, disable security controls/tests/protections,
or discard another agent's work. Fail closed.

Never commit credentials, API keys, tokens, real environment values, or
personal GitHub credentials. Use placeholders and environment-variable names.

## Existing project guardrails

The design baseline and MVP implementation plan remain authoritative for the
Fleet Platform. Existing constraints include Angular plus an ASP.NET Core
modular monolith, PostgreSQL, private object storage, no microservices/Kafka/
Redis without a measured requirement, Turo as an adapter rather than system
of record, and no authoritative AI/LLM calculations. Security and financial
invariants in the canonical specifications remain binding; this file does not
replace those specifications.
