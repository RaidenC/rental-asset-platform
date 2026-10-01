# Execution metadata

The `.agent/execution/` directory contains machine-readable phase execution
metadata only. It is not canonical design, an implementation plan, or a
replacement ExecPlan system. Canonical design and accepted implementation-plan
artifacts live at their registered Project Library paths.

Copy `execution/phase-NN.yaml.example` to
`execution/phase-<phase-id>.yaml` only after Project/Sol has produced the
accepted GREENLIGHT metadata. Do not invent phase data during bootstrap.

Run `./scripts/phase-preflight <phase-id>` before implementation. The
execution coordinator owns manifests and changes to this directory.
