# PLAN_ESCALATION

Semantic/project escalations are not permission prompts and must not be
resolved by Auto-review. Stop the affected semantic work and return this
structured packet to Project/Sol.

Allowed `Type` values:

- `MATERIAL_REPO_DRIFT`
- `PLAN_DEFECT`
- `DESIGN_CONFLICT`
- `SECURITY_CONFLICT`
- `DATA_INTEGRITY_CONFLICT`
- `MISSING_REQUIRED_DECISION`
- `UNIMPLEMENTABLE_ASSUMPTION`

```text
PLAN_ESCALATION

Type:
Phase:
Task:
Repository:
Expected branch:
Pinned SHA:
Current SHA:

Observed condition:

Repository evidence:

Relevant accepted-plan section:

Why continuing would require changing or inventing semantics:

Possible options discovered:
(optional, descriptive only)

Work completed before escalation:

Files changed:

Validation already completed:
```

Options and evidence are descriptive only. The worker must not select an
architectural, security, financial, data-integrity, or scope-changing option
without Project/Sol approval.
