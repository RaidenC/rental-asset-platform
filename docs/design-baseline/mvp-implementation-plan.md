# MVP Vertical-Slice Implementation Plan

**Project:** Rental Asset & Travel Platform / Fleet Management Project  
**Artifact:** `mvp-implementation-plan.md`  
**Canonical path:** `/Projects/Fleet-Management/shared/canonical/mvp-implementation-plan.md`  
**Steward:** `02-system-architecture` — System Architecture  
**Status:** Chat 02 R3 `GREENLIGHT` retained; Chat 06 Turo Import R3 `GREENLIGHT` satisfied with no contract change; Revision 6 is a status-only synchronization with no architecture/phase redesign  
**Revision:** 6  
**Previous revision:** 5  
**Last changed by:** `02-system-architecture`  
**Last material synchronization:** 2026-09-25 — Chat 06 Turo Import R3 `GREENLIGHT` status synchronization; no implementation contract change  
**Depends on:** canonical `mvp-architecture.md` Revision 5, `financial-platform-product-direction.md`, and the current canonical Domain / Investor Finance / Security / Turo Import specifications

---

# 1. Goal

Implement the smallest production-quality application that supports:

```text
Turo CSV upload
→ deterministic preview / validation
→ explicit Vehicle resolution where needed
→ CURRENT commit
→ source financial-completeness proof for affected Vehicle/cutoff scope
→ application-level separately authorized Finance Refresh
→ investor ownership/agreement setup
→ canonical manager-incurred operating-cost entry + simple monthly recurring-cost rules
→ synchronous recurring occurrence materialization during Finance/Statement Refresh
→ deterministic reservation + operating-cost investor projections
→ complete-input fingerprint proves live currentness
→ statement calculation / reconciliation / review
→ statement issue
→ distribution settlement/payment
→ narrow legacy workbook migration / historical reconciliation
→ operational parallel-run cutover gate before platform payout authority
```

Every phase must end in a runnable, demonstrable, testable increment. Do not create phases that only install generic infrastructure with no user-visible or domain-verifiable outcome.

---

# 2. Pre-Codex gate status

Chat 06 Turo Import R3 is **satisfied** and is no longer an outstanding pre-Codex gate. The immutable R3 convergence report is `GREENLIGHT` with 0 Critical, 0 Significant, 0 Minor, and 0 human-decision findings, and it confirms that the focused import convergence introduced no contract change requiring another Chat 02 synchronization.

Current gate/status constraints:

- Chat 06 Turo Import R3 — **SATISFIED / GREENLIGHT**; no contract delta to synchronize into this plan;
- preserve Chat 02 R3 `GREENLIGHT`; Revision 5's focused package-remediation design remains the implementation baseline;
- consume the current synchronized Security compound statement-issue and operating-cost/Finance Refresh authorization contract without reopening the role model;
- preserve the current synchronized Domain and Investor Finance contracts plus Finance R5's required real-PostgreSQL implementation verification.

A future material Import contract change may trigger only the necessary focused synchronization/delta verification. The completed Chat 06 R3 gate itself must not be treated as outstanding.

---

# 3. Codex working rules

For every phase, Codex should:

1. Read the current canonical `AGENTS.md` and artifact registry.
2. Re-read the current canonical source specifications materially touched by the phase.
3. Work from the current canonical artifact revisions, not chat memory.
4. Keep provider-specific types inside Source Ingestion.
5. Keep finance provider-neutral.
6. Keep Source Ingestion independent of Investor Finance; Source Ingestion owns `SourceFinancialCompletenessProofV1`, while post-import finance work is application-level orchestration after import commit.
7. Author ordinary manager-incurred Vehicle costs exactly once as `OperatingCostFact`; do not recreate them as `EconomicAdjustment(VEHICLE_EXPENSE)`.
8. Do not add autonomous finance scheduling, finance SYSTEM materializers, brokers, or outboxes for recurring materialization/currentness.
9. Treat `mvp-architecture.md` Sections 9.7–9.8 as the phase-independent command-security + HTTP-idempotency implementation contract; do not reconstruct those rules ad hoc.
10. Use real PostgreSQL integration tests for RLS, constraints, locks, and transaction semantics.
11. Use decimal types for money; never binary floating point.
12. Add/extend OpenAPI and Angular typed API contracts in the same increment, including required `Idempotency-Key` headers/replay responses.
13. Add observability and negative-path tests in the same phase as the behavior they protect.
14. Do not make AI/LLM calls in import, finance, authorization, or statement-truth paths.
15. Treat import success and financial completeness as separate contracts; never infer Finance completeness from `ReconciledWithQuarantine` or accepted-row counts.
16. Do not transfer real payout authority away from the verified spreadsheet process until the Phase 6 operational cutover gate passes.
17. Stop after the phase is working and reviewed; do not opportunistically build later-phase scope.

---

# 4. Repository baseline

Recommended projects:

```text
src/
  Platform.Web/
  Platform.Worker/
  Platform.Persistence/
  Modules/
    Access/
    FleetOwnership/
    BookingEconomics/
    SourceIngestion/
    FinancialSourceFacts/
    InvestorFinance/
    Audit/

tests/
  Domain.Tests/
  Postgres.IntegrationTests/
  Api.IntegrationTests/
  ObjectStorage.IntegrationTests/
  E2E.Playwright/
```

Angular lives under `Platform.Web/AngularApp` or an equivalent workspace path, while retaining normal Angular CLI/Nx conventions if the repository already has them.

One migration assembly owns the cross-schema relational model.

---

# 5. Phase 1 — Secure Turo upload and deterministic preview

## User outcome

The founder can sign in, establish the Organization context, upload a Turo CSV, and see a deterministic redacted preview with row counts/issues. No canonical Reservation/Trip state is mutated yet.

This is the first working increment.

## Backend scope

Implement only what is needed for preview:

### Access/security

- OIDC/BFF session integration using the existing authentication foundation;
- platform `User` mapping;
- `Membership` + fixed role mapping;
- narrow `identity_bootstrap` path;
- `ActorContext`;
- named permissions required for source management/import; `source.connection.manage` is distinct from `source.import.execute`;
- antiforgery for state-changing browser requests;
- MFA-backed privileged session enforcement according to the security contract;
- tenant transaction helper using `SET LOCAL app.tenant_id`;
- runtime/bootstrap DB roles and RLS tests;
- per-Tenant deployment-scheduler registration for each SYSTEM capability; **no** cross-Tenant `system_job_dispatcher` DB role/function in MVP.

### Source entities

- `Channel` seed for `TURO`;
- `SourceConnection`;
- `SourceArtifact`;
- `ImportBatch`;
- `RawImportRecord`;
- `ImportIssue`;
- source-PII retention-policy/key-lineage fields required by the canonical SourceArtifact/RawImportRecord contract;
- opaque maintenance SYSTEM job schedule/envelope metadata for purge/orphan/audit-retention capabilities.

### Object storage + source-PII retention boundary

Real/production source PII may be accepted in Phase 1 only after this entire boundary is deployable:

- resolve an approved versioned `SourcePIIRetentionPolicy`; no applicable policy → production upload fails closed;
- server-mediated streaming upload + SHA-256;
- create a per-artifact data key and persist only its KMS/envelope-wrapped form/key reference + crypto version;
- encrypt exact artifact bytes under the governed artifact key before durable application-controlled storage;
- encrypt exact `RawImportRecord` source values under the same governed key lifecycle (or an explicitly derived child key); long-lived diagnostic JSON is redacted;
- persist `retention_until`, policy/version, key lineage, and purge state at first receipt;
- server-generated private object key; no public URLs;
- orphan tagging/metadata sufficient for sweep;
- purge executor can destroy/disable readable key material and delete raw object/versioned bytes idempotently.

Resource ceilings are intentionally split:

```text
parser hard safety ceilings: 25 MiB / 50,000 rows / 256 columns / 64 KiB field
initial pre-benchmark synchronous product cap: 5 MiB / 2,000 rows
```

The public synchronous cap is not raised above the measured production-like envelope. If the Phase 1 benchmark fails the architecture budgets, lower the cap before production rather than adding a queue prematurely.

### Deterministic parser/profile

Implement `TuroTripEarningsCsvProfile` only:

- required/duplicate header validation;
- enforce the 50,000-row parser hard safety ceiling, while rejecting above the configured synchronous product cap before expensive processing;
- 256-column limit;
- 64 KiB field limit;
- deterministic string/identifier/date/money parsing;
- all 47 known columns captured;
- no formula/code execution;
- source financial component-sum reconciliation;
- row/batch issue classification;
- redacted durable diagnostics;
- processing identity/hash;
- preview row outcomes where resolvable;
- exact canonical pre-apply ImportBatch states/transitions:

```text
Received → ArtifactValidated → Parsed → Normalized → Validated
→ ReadyToApply | BatchQuarantined
terminal: RejectedArtifact | ParseFailed
```

Do not create a temporary `PreviewComplete` state. Do not implement a generic import designer.

## Minimal APIs

```http
GET  /api/session
GET  /api/source-connections
POST /api/source-connections
POST /api/imports/turo
GET  /api/imports/{batchId}
GET  /api/imports/{batchId}/issues
GET  /api/imports/{batchId}/reconciliation
```

`POST /api/source-connections` requires `source.connection.manage`. `POST /api/imports/turo` requires `source.import.execute` and performs artifact persistence + deterministic preview synchronously within the configured measured product envelope.

## Angular scope

Create the application shell and **Import Workspace**:

- authenticated shell;
- active Organization display;
- SourceConnection setup when absent;
- file selector/drop target;
- CURRENT/HISTORICAL mode selector;
- CURRENT assertion UI but do not commit yet;
- preview count cards;
- issue table grouped by batch-blocking / row-blocking / warning;
- safe redacted diagnostics;
- loading/error/retry states;
- correlation ID on unexpected errors.

## Persistence/migrations

Create only the schemas/tables needed by this phase plus identity/audit scaffolding required to enforce production security.

Enable/force RLS according to the canonical security rollout sequence before phase completion.


## Production safety worker — introduced in Phase 1

Deploy the minimal worker before real source PII is accepted. Tenant provisioning registers one deployment-scheduler invocation per Tenant + SYSTEM capability. Each invocation supplies only server-controlled `tenant_id` + capability; actual work runs through tenant-scoped `app_runtime` + `SET LOCAL app.tenant_id` and re-resolves eligible target records. No cross-Tenant DB dispatcher role/function exists in MVP.

SYSTEM capabilities:

1. `source_pii_retention_purge` — key destruction/disable + raw object/version deletion + purge provenance;
2. `object_orphan_sweep` — remove unreferenced upload/quarantine objects after safety TTL;
3. `security_audit_retention_purge` — delete only audit rows beyond configured retention cutoff through the constrained retention path.

The deployment scheduler does not query Tenant business data to discover work; scheduler configuration is operational provisioning metadata, not database authorization.

## Audit/observability

Audit:

- SourceConnection create/change;
- import upload/start/failure;
- sensitive authorization denial.

Metrics:

- upload size/duration;
- parse duration;
- row counts;
- issue counts;
- parse failures;
- audit append failures;
- source-PII purge failures/backlog;
- orphan sweep backlog;
- SYSTEM scheduled-invocation failures by Tenant + capability;
- audit-retention purge failures.

No raw guest/source values in logs.

## Tests

### Domain/unit

- money/date/status parser fixtures;
- component reconciliation;
- duplicate/header/schema failures;
- size/row/column/field limits;
- formula-like text remains inert data;
- pre-apply ImportBatch transitions use only `Received/ArtifactValidated/Parsed/Normalized/Validated/ReadyToApply/BatchQuarantined/RejectedArtifact/ParseFailed`; deterministic retry never invents a parallel preview status.

### PostgreSQL

- bootstrap role returns only authenticated User memberships;
- `app_runtime` without tenant context sees no Tenant data;
- pooled connection cannot retain another user/tenant context;
- cross-Tenant SourceConnection access fails.

### Object storage / retention

- production upload with no applicable SourcePIIRetentionPolicy fails closed;
- exact source bytes and raw-row strings are ciphertext at rest through application-controlled storage;
- hash matches bytes;
- object key is server-owned;
- DB failure leaves an orphan, not an adopted artifact;
- unauthorized direct key never returns bytes;
- expiry destroys/disables key material + deletes raw object/versioned bytes while redacted/economic provenance remains;
- purged PII cannot be recovered through replay/support;
- concurrent identical-byte uploads for one Tenant resolve to one SourceArtifact identity; each ImportBatch keeps its own SourceConnection context and any losing object is sweepable.

### Worker / SYSTEM authorization

- no cross-Tenant dispatcher DB role/function exists; deployment scheduler supplies only server-controlled Tenant + capability selectors;
- tampered/invalid tenant or capability fails during tenant-scoped revalidation with no business visibility;
- pooled worker connection does not leak Tenant context;
- two Tenants' schedules execute independently with service-principal audit attribution;
- audit-retention capability deletes only records beyond configured cutoff; ordinary app/audit-writer roles cannot delete audit history.

### API/browser

- upload valid synthetic fixture → preview;
- malformed CSV → deterministic safe failure;
- same-Tenant foreign-Organization SourceConnection → denied/batch blocked;
- `source.import.execute` without `source.connection.manage` cannot create/change a SourceConnection;
- missing source import permission → denied;
- no raw PII in preview/log output.

### Performance acceptance

Run a production-like PostgreSQL + object-store smoke/benchmark at the configured synchronous maximum. Record preview request duration, peak request memory, DB write count, configured ingress timeout, and cancellation behavior. The Phase 1 public limit may remain 5 MiB / 2,000 rows only if it meets the architecture budgets; otherwise lower it. Do not advertise the parser 25 MiB / 50,000-row safety ceilings as synchronous product support.

## Exit criteria

A user can complete:

```text
login → upload CSV → view deterministic preview/issues
```

against real PostgreSQL + object storage with RLS enabled, retention policy/key lineage active, and the purge/orphan/audit-retention worker deployable.

No Reservation/Trip has been committed. Phase 1 is production-eligible for real source PII only when the retention/purge and performance acceptance tests pass.

---

# 6. Phase 2 — Explicit Vehicle resolution, CURRENT + HISTORICAL_BACKFILL commit, and trip inspection

## User outcome

The founder can resolve unknown VINs explicitly, commit a CURRENT import, and inspect canonical imported Reservations/Trips/economics.

## Backend scope

### Fleet & Ownership — minimal Vehicle slice

Implement:

- `Vehicle`;
- manual/explicit `CreateVehicle`;
- unique Tenant + normalized VIN;
- managing Organization relationship.

No investor ownership yet.

### Source/integration state

Add:

- `Listing`;
- `ExternalListingBinding`;
- `ExternalReservationBinding`;
- `SourceObservation`;
- `SourceEarningComponent`;
- provider/source chronology fields;
- semantic fingerprint;
- current-source pointer behavior;
- import-owned source financial-completeness state/provenance sufficient to deterministically produce `SourceFinancialCompletenessProofV1(Tenant, SourceConnection, Vehicle, CutoffAt)` with effective CURRENT snapshot/ImportBatch/ProcessingIdentity lineage, blocker/disposition sets, `COMPLETE | INCOMPLETE | UNKNOWN`, and stable proof hash.

### Booking/canonical economics

Add:

- `Reservation`;
- optional `Trip`;
- `ReservationEconomicSnapshot`;
- `ReservationEconomicComponent`;
- Turo → canonical component mapping policy/version/hash;
- `EntitlementAt = completed Trip end`, else null.

### Import apply

Implement:

- explicit unknown-VIN quarantine;
- `CreateVehicleFromImportCandidate` as a user action that calls normal Vehicle creation logic;
- deterministic reprocess after Vehicle resolution;
- CURRENT authorization + recent step-up;
- `Tenant + SourceConnection` advisory lock;
- authoritative re-read under lock;
- NEW/UNCHANGED/REVISED behavior;
- atomic accepted-row apply;
- row-local quarantine;
- structural + financial reconciliation;
- provider chronology vs processor-correction chronology;
- rollback on Apply/Reconciliation failure;
- preserve `ReconciledWithQuarantine` as a valid partial-apply source-ingestion outcome;
- implement provider-neutral source financial completeness independently from batch state:
  - financially relevant quarantined row, disappearance/regression review, unresolved reconciliation issue, or unknown Vehicle/cutoff relation contributes a completeness blocker;
  - blocker relation is deterministically `IN_SCOPE | OUT_OF_SCOPE | UNKNOWN` for the requested Vehicle/cutoff;
  - `UNKNOWN` fails closed downstream; a blocker proven Vehicle-B-only does not block Vehicle A;
  - reviewed dispositions are narrow/immutable/provenanced and cannot clear malformed financial data by free-text acknowledgement;
  - same authoritative source state reproduces the same proof hash/status;
- implement HISTORICAL_BACKFILL as a real apply mode, not a UI-only selector:
  - commit uses the persisted immutable `ImportBatch.mode`;
  - requires `source.import.execute` but not `source.current.apply` and makes no CURRENT freshness assertion;
  - preserves/creates historical SourceObservations and previously unseen historical reservations when allowed;
  - participates in SourceConnection/binding serialization when touching provider bindings;
  - never advances an existing newer provider-current pointer backward or regresses canonical current Reservation/Trip/economic projection;
  - CURRENT racing HISTORICAL_BACKFILL must converge to the same provider-current state regardless of arrival order;
- extend the Phase 1 state machine only with the canonical apply/recovery states:

```text
ReadyToApply → Applying → Reconciled | ReconciledWithQuarantine
Applying → ApplyFailed | ReconciliationFailed
```

A stale `Applying` recovery reacquires the same Tenant + SourceConnection lock and retries the same ProcessingIdentity idempotently.

## APIs

```http
GET  /api/vehicles
POST /api/vehicles
POST /api/imports/{batchId}/reprocess
POST /api/imports/{batchId}/commit

GET /api/reservations
GET /api/reservations/{reservationId}
GET /api/reservations/{reservationId}/economics

// internal/application contract; not a Turo-specific Finance dependency
GetSourceFinancialCompletenessProofV1(TenantId, SourceConnectionId, VehicleId, CutoffAt)
```

Commit requires an idempotency key for both CURRENT and HISTORICAL_BACKFILL. The server derives mode from the persisted batch; CURRENT additionally requires `source.current.apply` + recent step-up, while HISTORICAL_BACKFILL requires `source.import.execute` and the canonical no-current-regression rules.

## Angular scope

Extend Import Workspace:

- unknown-VIN resolution card/dialog;
- explicit Vehicle create confirmation;
- reprocess preview;
- CURRENT step-up flow;
- HISTORICAL_BACKFILL commit path clearly labeled as historical/non-current and never prompting for CURRENT assertion;
- commit button only when batch has no batch-blocking issue;
- final reconciliation/result state;
- quarantine backlog links.

Add **Trips / Reservations** screen:

- paged list;
- Vehicle/status/date filters;
- master/detail view;
- trip odometers/distance;
- canonical economics summary;
- current source revision/provenance summary;
- source warnings without raw PII.

## Background processing

No new background infrastructure is introduced here. The Phase 1 production-safety worker is already running source-PII purge, orphan sweep, and audit-retention capabilities through per-Tenant scheduled invocations. Phase 2 continues to keep CURRENT apply synchronous; do not move it to the worker unless a later measured envelope requires the canonical `USER_DELEGATED` async design.

## Audit/observability

Audit:

- Vehicle creation;
- CURRENT assertion;
- import commit success/failure;
- raw source download if such a diagnostic endpoint is exposed.

Metrics from canonical import contract:

- NEW/UNCHANGED/REVISED/QUARANTINED/REJECTED;
- batch state/duration;
- stale Applying;
- reconciliation failures;
- quarantine backlog;
- source financial-completeness proof counts by COMPLETE / INCOMPLETE / UNKNOWN and blocker code;
- oldest unresolved financially relevant blocker + reviewed-disposition count;
- purge/sweeper health.

## Tests

### Import identity/idempotency

- same reservation ID + same SourceConnection → one canonical Reservation;
- same provider ID on two SourceConnections remains isolated;
- same artifact/process identity rerun is no-op;
- changed source row creates SourceObservation revision, not additive earnings;
- historical correction cannot become CURRENT merely because processed later;
- same bytes can be processed under two SourceConnections without changing SourceArtifact identity.

### Source financial completeness

- relevant financially invalid/quarantined reservation for Vehicle A → valid rows apply, batch may be `ReconciledWithQuarantine`, but Vehicle A proof through relevant cutoff is `INCOMPLETE` or `UNKNOWN`;
- deterministic resolution/reprocess advances source/ProcessingIdentity lineage and may produce `COMPLETE` when no blocker remains;
- Vehicle-B-only quarantine proven `OUT_OF_SCOPE` does not block Vehicle A;
- unresolved Vehicle/cutoff relevance returns `UNKNOWN` and fails closed downstream;
- disappearance/regression awaiting review remains in blocker set until deterministic reprocess or allowed reviewed disposition;
- repeated proof computation over identical authoritative state returns identical status/blocker/disposition set and proof hash; `computed_at` does not affect hash.

### Vehicle behavior

- unknown VIN quarantines;
- import never auto-creates Vehicle;
- explicit Vehicle creation + reprocess resolves row;
- external Vehicle ID cannot silently bind to a different VIN.

### Atomicity/concurrency

- two CURRENT commits for same SourceConnection serialize;
- unexpected failure rolls back all accepted-row canonical/current-pointer writes;
- row-local quarantines do not prevent valid accepted rows from applying;
- cross-profile/version processors still share the same SourceConnection lock;
- HISTORICAL_BACKFILL after a newer CURRENT observation preserves history but does not move the current pointer/canonical projection backward;
- historical-first then CURRENT creates history and allows CURRENT to become effective normally;
- concurrent CURRENT + HISTORICAL_BACKFILL touching the same binding serialize and converge to the same current pointer independent of race order;
- HISTORICAL_BACKFILL retry with the same processing/idempotency identity creates no duplicate observations/reservations.

### Security

- CURRENT without `source.current.apply` denied;
- stale/no recent step-up denied for CURRENT;
- HISTORICAL_BACKFILL with `source.import.execute` succeeds without `source.current.apply`; actor lacking `source.import.execute` is denied;
- SourceConnection disable/reassignment race fails closed;
- no false SUCCESS audit survives rollback.

### Synchronous CURRENT-apply performance

At the same configured product maximum accepted by Phase 1, run CURRENT apply through production-like PostgreSQL and verify the architecture transaction-duration budget. Record lock wait, apply transaction duration, DB write count, and rollback/cancellation behavior. If the apply budget fails, lower the product cap before production; do not silently extend HTTP/transaction timeouts or add async infrastructure.

### E2E

```text
CURRENT: upload → preview unknown VIN → create Vehicle → reprocess → commit → inspect trip
HISTORICAL: upload older snapshot → preview as HISTORICAL_BACKFILL → commit → verify historical provenance and no regression of any newer CURRENT reservation
QUARANTINE: upload CURRENT with one in-scope invalid-money reservation → valid rows commit/ReconciledWithQuarantine → affected Vehicle proof non-COMPLETE → resolve/reprocess → proof COMPLETE
```

## Exit criteria

The real shape of the source boundary is now working end to end:

```text
private CSV → source revisions → canonical Reservation/Trip/economics + provider-neutral source-completeness proof
```

No investor finance calculation is implemented yet. Phase 2 deliberately stops at a correct import boundary. Once Phase 3 introduces Investor Finance, the application orchestrator will add the post-CURRENT authorized Finance Refresh without changing Source Ingestion's dependency direction.

---

# 7. Phase 3 — Investor configuration, Finance Refresh, and live currentness

## User outcome

The founder can associate a Vehicle with an investor/owner, define the management agreement, run an authorized Finance Refresh, and see deterministic current per-reservation investor economics with an explicit CURRENT / STALE / BLOCKED / UNKNOWN status.

After this phase, a successful CURRENT Turo import can also attempt a separately authorized Finance Refresh for affected Vehicles; import success and refresh success are shown independently.

## Backend scope

### Fleet/ownership

Add:

- `Organization.financial_timezone` (required canonical IANA timezone);
- `Party`;
- `OwnershipInterest`;
- exactly one applicable 100% ownership rule;
- half-open effective ranges;
- no overlapping ownership.

### Investor Finance configuration

Add:

- `ManagementAgreementVersion`;
- `ManagementAgreementComponentTreatment`;
- non-overlapping effective ranges;
- immutable terms after use;
- explicit FEEABLE/EXCLUDED classification for every non-zero canonical reservation component;
- extension seam for versioned operating-cost projection policy; Phase 4 will exercise it with real OperatingCostFacts.

Represent the current Aaron reservation rule explicitly:

- 30% management fee rate;
- explicit excluded canonical component set;
- $20 SeaTac pickup delivery charge rule;
- $10 Completed cleaning rule.

Do not hard-code investor/vehicle/provider names inside calculations.

### Reservation calculation engine

Add:

- `ReservationInvestorCalculation`;
- `ReservationInvestorCalculationCurrent`;
- calculation input hash;
- PROVISIONAL vs EARNED;
- `FULL_CURRENT` posting disposition for current unstated earned economics;
- exact decimal intermediate values;
- provider-neutral input contract;
- initial reservation-sourced `EconomicLedgerEntry` types needed for `FULL_CURRENT`.

The ledger sum for a full calculation must equal `InvestorReservationEarnings`; do not post a second management-fee deduction.

### InvestorEconomicsProjectionSnapshot / complete-input currentness

Add the live projection lineage envelope from the canonical Domain/Finance contracts:

```text
Tenant / Organization / Vehicle / OwnershipInterest
AsOfDate / CutoffDate
Organization financial timezone
FingerprintPolicyCode / Version
CompleteInputFingerprint
ProjectionEngineVersion
ProjectionResultHash
InvestorEconomicsProjectionSourceProof[]   // exact consumed COMPLETE proof provenance per applicable source scope
```

Phase 3's complete fingerprint includes, for every applicable external source scope, the exact `SourceFinancialCompletenessProofV1` version/hash/status plus effective source snapshot/ImportBatch/ProcessingIdentity lineage; authoritative current reservation/source lineage; ownership/agreement/component-treatment inputs; effective investor-specific adjustment set (initially empty unless already supported); and engine/policy versions. Phase 4 extends the same fingerprint with OperatingCostFact and recurring-rule/expected-occurrence inputs; do not invent a second freshness mechanism.

CURRENT is derived only when every applicable fresh source proof is `COMPLETE`, the persisted `InvestorEconomicsProjectionSourceProof[]` set matches those proofs exactly, stored fingerprint == freshly computed authoritative fingerprint, and all other required inputs are complete/valid. Mutable stale flags are non-authoritative hints only. `ReconciledWithQuarantine` is never treated as a global Finance boolean.

### Finance Refresh application command

Implement `RefreshInvestorEconomics(vehicleId, cutoff)` as canonical `finance.calculation.write` + recent step-up + Vehicle-scoped in-transaction reauthorization/lock.

Flow in this phase:

```text
Vehicle lock
→ reauthorize finance.calculation.write + recent step-up/resource scope
→ for every applicable external SourceConnection obtain SourceFinancialCompletenessProofV1(Vehicle, cutoff)
→ require every proof COMPLETE and retain exact proof/effective processing lineage
→ resolve Organization timezone + ownership/agreement
→ read current ReservationEconomicSnapshots/source lineage
→ refresh reservation calculations/current pointers/ledger targets
→ compute complete authoritative input fingerprint including source-proof lineage
→ create/reuse InvestorEconomicsProjectionSnapshot + exact InvestorEconomicsProjectionSourceProof[]
```

### CURRENT import → refresh orchestration

Extend the application/composition layer—not Source Ingestion—so a committed CURRENT import returns affected Vehicle IDs and the Web application may then attempt `RefreshInvestorEconomics` as a **second command**.

Required outcomes:

```text
IMPORT_SUCCEEDED + FINANCE_REFRESH_SUCCEEDED
IMPORT_SUCCEEDED + FINANCE_REFRESH_NOT_ATTEMPTED_AUTH_REQUIRED
IMPORT_SUCCEEDED + FINANCE_REFRESH_BLOCKED_SOURCE_INCOMPLETE
IMPORT_SUCCEEDED + FINANCE_REFRESH_FAILED
```

Finance denial/failure/source-incompleteness never rolls back/relabels the import. A newly committed source pointer/proof/blocker/disposition/ProcessingIdentity change changes authoritative fingerprint inputs, so the prior snapshot cannot continue to read CURRENT even if no stale-marker write happened. Only affected/unknown Vehicle scopes block; a deterministically unrelated Vehicle may remain complete.

## APIs

```http
POST /api/investor-parties
POST /api/vehicles/{vehicleId}/ownership-interests
POST /api/ownership-interests/{id}/end
POST /api/ownership-interests/{id}/management-agreements

GET  /api/vehicles/{vehicleId}/economics-setup
GET  /api/vehicles/{vehicleId}/investor-economics
POST /api/vehicles/{vehicleId}/finance-refresh
GET  /api/reservations/{reservationId}/investor-calculation
```

`GET` surfaces are `finance.read` and strictly non-mutating. `POST /finance-refresh` uses `finance.calculation.write`, recent step-up, resource reauthorization, Vehicle lock, and `Idempotency-Key`.

## Angular scope

Add **Vehicle & Investor Setup**:

- investor Party create/select;
- ownership timeline;
- management agreement form;
- explicit reservation-component classification table;
- Organization financial-timezone visibility/configuration through the appropriate admin path;
- readiness/validation messages.

Enhance Trip/Vehicle Economics views:

- show current deterministic investor calculation when one exists;
- show PROVISIONAL/EARNED;
- show fee base, management fee, fixed charges, investor earnings;
- show exact decimal precision;
- show projection currentness CURRENT / STALE / BLOCKED / UNKNOWN, cutoff, last refresh time, and reason code;
- after CURRENT import, clearly distinguish import result from finance-refresh result.

## Audit/observability

Audit:

- investor Party creation where applicable;
- OwnershipInterest create/end;
- ManagementAgreementVersion create/change;
- Finance Refresh success/denial/failure when it changes current projection lineage.

Metrics:

- Finance Refresh count/duration/result;
- currentness counts/reason codes;
- complete-input fingerprint match/mismatch;
- source-proof COMPLETE / INCOMPLETE / UNKNOWN / provenance-mismatch counts;
- calculation count/duration and fail-closed reason;
- post-import refresh attempted/succeeded/denied/failed counts independent from import success.

## Tests

### Finance golden rules

- existing Aaron reservation rules remain unchanged: exclusions, excess distance, Completed cleaning, SeaTac delivery, no standalone 70% rule, fractional cents;
- finance consumes canonical reservation codes only.

### Ownership/agreement

- exactly one applicable 100% owner at `EntitlementAt`;
- half-open range boundaries;
- overlapping owner/agreement rejected;
- missing component treatment fails closed.

### Lineage/idempotency/currentness

- same calculation input hash → no duplicate calculation/ledger;
- changed input creates new immutable version and advances current pointer;
- superseded unstated full rows become statement-ineligible by current-pointer lineage;
- same complete authoritative input set/cutoff reproduces the same `CompleteInputFingerprint` and result hash;
- changed source revision/agreement/ownership/policy input changes fingerprint; previous projection cannot read CURRENT;
- fingerprint serializer ordering/decimal/date/timezone versioning is byte-stable and deterministic.

### Source completeness / currentness

- relevant quarantined reservation → valid rows may already be canonical, but affected Vehicle Finance Refresh cannot publish CURRENT;
- resolved quarantine → new proof/ProcessingIdentity lineage is consumed and refresh may become CURRENT;
- unrelated Vehicle quarantine does not block requested Vehicle when Import proves `OUT_OF_SCOPE`;
- disappearance/regression awaiting review blocks affected Vehicle/cutoff;
- missing/duplicate/extra/foreign/mismatched `InvestorEconomicsProjectionSourceProof` provenance rejects CURRENT;
- complete-input fingerprint exact match includes exact source proof version/hash/effective processing lineage; any proof mismatch makes prior projection non-CURRENT.

### Authorization

- `finance.read`-only actor may view an existing projection but cannot invoke refresh or mutate current-pointer/ledger state;
- missing `finance.calculation.write` or stale/no recent step-up denies refresh;
- permission/Membership revocation racing refresh fails under the Vehicle lock with zero protected mutation;
- same-Tenant foreign-Organization Vehicle/OwnershipInterest target fails closed.

### Import → refresh failure separation

- committed CURRENT source revision followed by refresh denial leaves import committed and prior projection non-CURRENT;
- committed CURRENT source revision with financially relevant quarantine followed by refresh returns BLOCKED/non-current for affected Vehicle while import remains successful;
- committed CURRENT source revision followed by refresh crash/rollback leaves import committed and prior projection non-CURRENT;
- retry Finance Refresh with same idempotency key/input creates no duplicate calculations/ledger output;
- Source Ingestion project/module has no compile-time dependency on Investor Finance.

### E2E

```text
configure investor/ownership/agreement
→ upload + commit CURRENT Turo CSV
→ import succeeds
→ SourceFinancialCompletenessProofV1 for Vehicle/cutoff is COMPLETE
→ separately authorized Finance Refresh succeeds
→ Vehicle Economics shows CURRENT deterministic result
```

Also:

```text
commit changed CURRENT import
→ force Finance Refresh failure
→ import remains successful
→ Vehicle Economics cannot report the old projection CURRENT
```

## Exit criteria

The application replaces the reservation-calculation portion of the spreadsheet and has the final Phase-A currentness/orchestration seam: current source state can refresh live investor economics without Source Ingestion owning Finance, and failed refresh cannot falsely leave a prior live projection CURRENT.

# 8. Phase 4 — Operating costs, monthly recurrence, investor projections, and statement draft/reconciliation

## User outcome

The founder can record real manager-incurred Vehicle costs once, configure simple monthly recurring costs, refresh complete investor economics even in a month with no Turo import, and calculate/reconcile a statement draft whose inputs are proven CURRENT.

## Backend scope

### Canonical OperatingCostFact

Implement the Financial Source Facts module from Architecture Revision 4:

```text
OperatingCostFact
  MANUAL | RECURRING_RULE | LEGACY_IMPORT | CORRECTION
  ORIGINAL | REVERSAL | REPLACEMENT
```

Phase-A rules:

- factual manager-incurred/advanced Vehicle cost is authored exactly once;
- amount is positive source magnitude; reversal semantics come from immutable lineage, not user-entered negative numbers;
- category is factual classification only and never directly means investor chargeability, GL account, tax treatment, settlement, or tax deductibility;
- corrections use REVERSAL + optional REPLACEMENT; never destructive edit;
- an ordinary manager-incurred cost must **not** also create `EconomicAdjustment(VEHICLE_EXPENSE)`.

### Monthly recurring rules / occurrences

Implement:

- `RecurringExpenseRule`;
- immutable prospective `RecurringExpenseRuleVersion`;
- `RecurringExpenseOccurrence`;
- Phase-A `frequency = MONTHLY` only.

Canonical recurrence:

```text
first occurrence = EffectiveFrom local date
later occurrence = same day-of-month
missing day = last local calendar day of month
Organization.financial_timezone controls local dates/month boundaries
no proration
EffectiveTo blocks later dates
edits/disable/re-enable are prospective versions only
```

No recurring rule posts directly to the ledger. No finance scheduler/background worker is added.

### Finance Refresh recurring materialization

Extend Phase 3 `RefreshInvestorEconomics` / Statement Refresh:

```text
under Vehicle lock
→ reauthorize finance.calculation.write + recent step-up
→ resolve Organization.financial_timezone
→ enumerate every due rule occurrence through cutoff
→ if any missing occurrence:
     reauthorize current finance.adjustment.write before any materialization
     create missing RecurringExpenseOccurrence idempotently
     create exactly one OperatingCostFact(source_kind=RECURRING_RULE) per occurrence
→ continue deterministic projection/calculation
```

A refresh lacking current cost-mutation authority fails before creating any occurrence/source fact. No partial materialization is allowed.

### Agreement-driven OperatingCostInvestorProjection

Implement deterministic projection of one OperatingCostFact for one OwnershipInterest under exact agreement/policy inputs:

- source fact never mutates because agreement treatment changes;
- category alone never implies chargeability;
- same cost category may produce zero investor effect under one agreement and non-zero effect under another;
- non-zero investor effect creates current `VEHICLE_EXPENSE`-classified investor subledger effect sourced by `OperatingCostInvestorProjection`, never directly by EconomicAdjustment;
- superseded unstated projection effects become ineligible;
- issued recognized effects remain immutable history; later target uses target-minus-issued-recognized correction logic.

### Investor-specific EconomicAdjustment / reimbursement

Retain only investor-specific manual calculation inputs:

```text
REPAIR_CHARGE
INVESTOR_REIMBURSEMENT
FIXED_OPERATIONAL_CHARGE_OVERRIDE
```

`FIXED_OPERATIONAL_CHARGE_OVERRIDE` remains REPLACE/WAIVE. Reimbursement approval remains a separate workflow that creates exactly one investor-specific adjustment. An actual manager-incurred repair bill may independently exist as OperatingCostFact while a contractually justified investor `REPAIR_CHARGE` may exist; tests must ensure they are not mechanically cloned/double-authored.

### Complete-input fingerprint extension

Extend the Phase 3 fingerprint/currentness input universe with:

- effective OperatingCostFact correction lineages through cutoff;
- applicable operating-cost projection policy identity/hash;
- every recurring rule/version capable of generating occurrences through cutoff;
- the complete expected due occurrence-date set;
- exact materialized occurrence → OperatingCostFact identities;
- effective investor-specific EconomicAdjustment lineages.

Missing/duplicate/ambiguous recurrence or cost-policy input makes live economics BLOCKED/non-current.

### Statement DRAFT / Statement Refresh

Implement Statement DRAFT on top of the same Finance Refresh pipeline:

- period/currency/recognition-policy input;
- run authorized Statement Refresh through period/cutoff **before** candidate selection;
- materialize due recurrence synchronously;
- require complete-input fingerprint CURRENT;
- `ECONOMIC_DATE_V1` candidate selection preview;
- predecessor/debit-carry preview;
- current reservation + operating-cost projection lineage validation;
- exact versioned `StatementReviewFingerprintV1`;
- persist reviewed fingerprint + reviewed_at/by;
- no frozen `InvestorStatementEntry` membership until issue.

## APIs

```http
GET  /api/vehicles/{vehicleId}/operating-costs
POST /api/vehicles/{vehicleId}/operating-costs
POST /api/operating-costs/{id}/corrections

GET  /api/vehicles/{vehicleId}/recurring-expense-rules
POST /api/vehicles/{vehicleId}/recurring-expense-rules
POST /api/recurring-expense-rules/{id}/versions
POST /api/recurring-expense-rules/{id}/disable

POST /api/investor-reimbursements
POST /api/investor-reimbursements/{id}/approve
POST /api/investor-reimbursements/{id}/reject
POST /api/economic-adjustments
POST /api/economic-adjustments/{id}/reversals

POST /api/vehicles/{vehicleId}/finance-refresh
POST /api/statements/drafts
POST /api/statements/{id}/recalculate
GET  /api/statements/{id}
GET  /api/statements/{id}/reconciliation
```

Cost/rule mutations use `finance.adjustment.write` + recent step-up/resource checks, subject to the focused Security verification. Finance/Statement Refresh uses `finance.calculation.write`; when missing recurrence must be materialized it additionally requires current `finance.adjustment.write` before any source-fact insert.

## Angular scope

Extend **Statement Workbench / Vehicle Economics**:

### Operating costs

- add manual manager-incurred cost;
- show immutable correction/reversal/replacement history;
- create/edit/disable monthly recurring rule with prospective effective dates;
- show due/materialized occurrence history;
- show factual cost separately from investor treatment/effect.

### Investor-specific adjustments

- add contractual reservation repair charge where appropriate;
- delivery/cleaning REPLACE/WAIVE;
- create/approve reimbursement;
- display reversals/history;
- no destructive edit.

### Statement/currentness

- explicit Finance Refresh control/status;
- period selection;
- calculate/recalculate;
- exact reservation + operating-cost totals;
- per-source-fact investor projection explanation including zero-treatment cases;
- ledger candidate rows;
- opening/closing debit carry;
- missing-config/blocked-currentness panel;
- complete-input currentness status/cutoff/fingerprint version;
- review timestamp / `StatementReviewFingerprintV1`.

Do not add issue/payment controls until the reconciliation data is stable and tested.

## Audit/observability

Audit:

- OperatingCostFact create/correction;
- recurring rule/version create/edit/disable;
- reimbursement/adjustment create/reversal/approval;
- Finance/Statement Refresh when it materializes recurrence or advances authoritative projection lineage;
- denied finance/cost authorization.

Metrics:

- due recurring count / materialized count / idempotent no-op count;
- operating-cost projection create/reuse/correction-delta count;
- currentness reason counts;
- refresh/draft duration;
- reconciliation mismatches;
- cross-owner-correction-required count.

## Tests

### Source cost → investor effect / agreement treatment

- **one source cost → at most one investor economic effect:** one OperatingCostFact cannot be double-authored through EconomicAdjustment and one projection lineage cannot create duplicate current VEHICLE_EXPENSE effects;
- **different agreement treatment of same cost category:** same factual cost/category under agreement A can produce investor effect zero while agreement B produces a non-zero target, without mutating the source fact;
- valid zero-chargeability remains factual history with no investor-balance effect;
- actual manager repair OperatingCostFact and contractual investor REPAIR_CHARGE are distinct and cannot be automatically cloned from each other.

### Recurring monthly materialization

- **recurring month with no Turo import:** authorized Finance Refresh still materializes all due occurrences through cutoff and includes their projections;
- **duplicate refresh/materialization idempotency:** repeated/concurrent refresh yields one `(Tenant, Rule, OccurrenceDate)`, one ORIGINAL recurring OperatingCostFact, and no duplicate investor effect;
- **Organization financial-timezone/month-end recurrence:** EffectiveFrom anchor date uses Organization timezone; day 29/30/31 falls back to the local month's final calendar day when absent; financial period boundaries are the local month;
- EffectiveTo exclusion and no proration;
- **prospective recurring-rule edits:** edit/disable/re-enable creates new future-effective version behavior only; already materialized occurrence/source facts do not change.

### Authorization / atomicity

- direct cost/rule mutation without `finance.adjustment.write`, with stale step-up, or wrong Organization/Vehicle relation is denied with zero mutation;
- **real PostgreSQL defense-in-depth:** cross-Organization or cross-Vehicle OperatingCostFact correction lineage is rejected even when normal API validation is bypassed; Reservation null-parity/scope and required category/currency/amount correction invariants are likewise enforced per the canonical Domain contract;
- **denied/stale cost-mutation authorization with zero partial materialization:** refresh needing a missing recurrence but lacking current cost mutation authority creates zero RecurringExpenseOccurrence and zero OperatingCostFact;
- permission/Membership revocation racing materialization is rechecked under Vehicle lock and fails with zero partial recurrence/source-fact mutation.

### Complete-input currentness / refresh failure

- **source mutation + failed refresh:** changed CURRENT source revision followed by failed/denied refresh leaves import committed and old projection not CURRENT;
- **cost mutation + failed refresh:** OperatingCostFact correction commits; failed refresh leaves old projection not CURRENT;
- **agreement/rule mutation + failed refresh:** change commits; failed refresh leaves old projection not CURRENT;
- **complete-input fingerprint match:** identical authoritative deterministic input set/cutoff yields same fingerprint/result hash and idempotent projection reuse;
- **complete-input fingerprint mismatch:** source/cost/agreement/rule/ownership/adjustment/policy/engine change yields mismatch; missing/duplicate due occurrence fails completeness; no stale-marker write is required.

### Statement preview

- candidate selection by `EconomicDate` includes only current reservation and current operating-cost projection lineage;
- no PROVISIONAL reservation rows;
- current operating-cost target/delta included exactly once;
- opening debit from predecessor;
- negative period result produces closing debit, not negative payment;
- missing predecessor/period overlap detected;
- statement draft refuses to become reviewable when any applicable source proof is absent/INCOMPLETE/UNKNOWN/mismatched or complete currentness otherwise cannot be proven;
- exact StatementReviewFingerprintV1 changes on membership, six-decimal amount, predecessor/carry, reservation lineage, or operating-cost projection lineage change.

### E2E

```text
create monthly tracking rule
→ run Finance Refresh in a month with no new Turo import
→ occurrence + OperatingCostFact materialize
→ agreement policy projects investor effect
→ statement draft reconciles reservation + operating-cost economics
```

Also:

```text
edit recurring rule prospectively
→ fail a subsequent Finance Refresh
→ prior projection reads non-CURRENT
→ retry authorized refresh
→ only due future occurrence uses new rule version
```

## Exit criteria

The founder can replace the workbook's manual operating-cost/recurring-cost handling and explain the complete live/draft investor result from canonical source facts. Recurrence completeness and live currentness are deterministic without an autonomous scheduler, background finance worker, broker, outbox, or mutable stale-marker dependency. No immutable statement obligation is issued yet.

# 9. Phase 5 — Statement issue, cross-owner recovery, and distribution settlement

## User outcome

The founder can finalize a reviewed statement, preserve immutable membership/totals, record external distribution settlement, and mark the payment paid.

This completes the requested **feature** vertical slice. Real payout authority remains with the existing verified spreadsheet process until Phase 6 legacy migration + operational cutover gates pass.

## Backend scope

### Statement issue

Implement `IssueInvestorStatement` exactly under the canonical Vehicle lock:

1. acquire the canonical Vehicle lock and determine the actual nested issue path **before the first authoritative mutation**;
2. reauthorize current Membership + `finance.statement.issue` **AND** `finance.calculation.write` + recent step-up + Tenant/Organization/Vehicle/OwnershipInterest/statement relationships;
3. if required Statement Refresh will materialize missing recurring costs, additionally reauthorize `finance.adjustment.write` + current cost/rule/affected-resource relationships **before any materialization**; `finance.statement.issue` never implies either nested authority;
4. on any permission/resource/step-up failure, abort atomically with zero recurrence/source-fact materialization, recalculation/current-lineage/projection/ledger advancement, DRAFT membership/totals/cutoff freeze, or issue mutation;
5. run/require authorized **Statement Refresh** through `PeriodEnd` / cutoff, including due recurring occurrence materialization and all reservation/OperatingCostInvestorProjection refresh work;
6. require `SourceFinancialCompletenessProofV1 = COMPLETE` for every applicable external source scope and exact matching `InvestorEconomicsProjectionSourceProof[]` provenance;
7. require an `InvestorEconomicsProjectionSnapshot` whose complete authoritative input fingerprint proves CURRENT for the statement scope/cutoff; existing ledger rows alone are insufficient;
8. validate period/currency/recognition lineage and predecessor/contiguous non-overlapping chain;
9. set `CalculationCutoffAt`;
10. re-select only current-lineage reservation, operating-cost, closed-period, and cross-owner correction ledger rows;
11. recompute `StatementReviewFingerprintV1` from authoritative current candidates and compare exact equality with the last reviewed fingerprint;
12. if source completeness/complete currentness cannot be proven → block issue; if **any reviewed canonical field differs** → `409 STATEMENT_REVIEW_STALE`;
13. compute totals/debit carry;
14. insert exact `InvestorStatementEntry` rows;
15. mark `ISSUED`;
16. append SUCCESS audit;
17. commit atomically.

Issued statement rows/totals are immutable.

### Same-owner closed-period corrections

Complete the path:

```text
issued recognized economics
→ new current EARNED calculation
→ CLOSED_PERIOD_DELTA
→ signed correction only
→ next open statement
```

### Cross-owner correction

Implement the minimum required recovery path before production because post-issue entitlement can change:

- `CrossOwnershipCorrection` REQUIRED/APPROVED/APPLIED/REJECTED;
- derive affected owners from stored state;
- authorize every affected OwnershipInterest;
- no caller-supplied source/target owner authority;
- current-calculation matching requirement;
- per-owner target-minus-recognized ledger lines;
- stale unstated correction lines become ineligible through current calculation lineage;
- all canonical R4/R5 negative persistence tests.

Primary UI may show this only as an exception panel in the Statement Workbench.

### DistributionPayment

Payment and cross-owner correction mutations follow the architecture command-security matrix: `finance.payment.write` / `finance.cross_owner_correct`, recent step-up, in-transaction relationship reauthorization, and required `Idempotency-Key` OpenAPI contracts.

Implement:

- create `PENDING` NORMAL payment;
- validate positive outstanding payable/currency;
- mark PENDING → PAID / FAILED / VOIDED;
- `PAID` terminal;
- optional actual cash amount/reference/date;
- exact `settlement_amount` at six decimals;
- cent cash value separate;
- settlement ledger effect;
- full reversal as a new REVERSAL record;
- no over-settlement.

## APIs

```http
POST /api/statements/{id}/issue

GET  /api/cross-ownership-corrections/{id}
POST /api/cross-ownership-corrections/{id}/approve
POST /api/cross-ownership-corrections/{id}/apply
POST /api/cross-ownership-corrections/{id}/reject

POST /api/statements/{id}/payments
POST /api/distribution-payments/{id}/mark-paid
POST /api/distribution-payments/{id}/mark-failed
POST /api/distribution-payments/{id}/void
POST /api/distribution-payments/{id}/reverse
```

## Angular scope

Complete **Statement Workbench**:

- Issue button gated by permission + step-up + reconciliation state;
- clear immutable-issued state;
- exact frozen statement entries;
- derived settlement status:
  - NO_PAYABLE_DEBIT_CARRIED
  - UNPAID
  - PARTIALLY_SETTLED
  - SETTLED;
- create pending payment;
- mark paid with optional actual cash/reference/date;
- reversal history;
- stale-review conflict sends user back to recalculation/review;
- exception panel for required cross-owner correction.

## Audit/observability

Audit:

- statement issue;
- statement issue denial/stale review conflict as appropriate;
- payment create/status changes/reversal;
- cross-owner correction create/approve/apply/reject;
- maintenance path if used during testing/support.

Metrics/alerts:

- statement issue success/failure/duration;
- stale-review conflict count;
- payment over-settlement rejects;
- payment transition failures;
- cross-owner correction backlog;
- audit append failure alert;
- repeated sensitive authorization-denial alert.

## Tests

### Statement close

- Finance/Statement Refresh, recurring materialization, operating-cost projection refresh, reservation recalculation, and issue serialize under Vehicle lock;
- relevant quarantined/disappeared/regressed source scope with proof `INCOMPLETE`/`UNKNOWN` blocks authoritative DRAFT refresh/issue; unrelated Vehicle proof does not block when Import proves out-of-scope;
- exact source proof version/hash/effective ImportBatch/ProcessingIdentity provenance must match the successful projection fingerprint before issue;
- issue fails closed if complete-input currentness through cutoff cannot be proven;
- existing ledger rows never substitute for required Statement Refresh/currentness proof;
- only current reservation calculation/current OperatingCostInvestorProjection/current correction lineage is eligible;
- `CreatedAt <= CalculationCutoffAt`;
- predecessor/debit chain exactness;
- active overlap/out-of-order issue rejected;
- same issue idempotency key creates one issued statement;
- issued membership immutable;
- byte/canonical-identical reviewed state issues successfully;
- same total/different membership, six-decimal amount change, predecessor/carry change, or current-lineage substitution each returns `STATEMENT_REVIEW_STALE`.

### Same-owner revision

- already issued A → current B → one signed delta only;
- superseded unstated delta becomes ineligible;
- later revision computes against cumulative issued recognized amount.

### Cross-owner R4/R5 convergence cases

Implement all canonical cases, including:

- unstated owner transition;
- issued owner transition requiring correction;
- X +100 recognized → Y +120 target → X -100 / Y +120;
- repeated unstated correction;
- partially issued correction;
- fully issued correction then revision;
- mismatched Tenant/Organization/Vehicle/Reservation/calculation/owner FK rejection;
- stale correction application fails closed;
- duplicate per-owner correction line rejected.

### Payment

- create PENDING only against positive outstanding payable;
- partial settlement;
- exact full settlement;
- cent cash vs six-decimal settlement variance;
- over-settlement rejected;
- PAID terminal;
- one full reversal restores outstanding balance;
- retries do not duplicate payment/ledger line.

### Security

Complete the canonical negative suite for all implemented surfaces, including:

- **issue-only permission cannot invoke hidden refresh:** `finance.statement.issue` without `finance.calculation.write` is denied under Vehicle lock before any mutation;
- **issue + calculation without adjustment fails when recurrence materialization is required:** zero occurrence, zero OperatingCostFact, zero recalculation/currentness/draft/cutoff/issue mutation;
- when no recurrence materialization is required, valid issue + calculation authority is not denied solely because `finance.adjustment.write` is absent;
- permission/Membership/resource revocation racing issue fails before first mutation with zero partial state;
- same-Tenant cross-Organization finance denial;
- permission removal racing issue/payment;
- stale/no recent step-up denied for statement issue, payment write/reversal, and cross-owner correction;
- direct guessed IDs return fail-closed behavior;
- audit SUCCESS commit coupling;
- DENIED audit after rollback;
- append-only audit DB grants.

### Full Playwright E2E

Run one production-like happy path:

```text
login
→ upload CURRENT Turo CSV
→ preview
→ explicitly create missing Vehicle if needed
→ commit
→ inspect trip
→ configure investor ownership/agreement
→ add manager-incurred OperatingCostFact + monthly recurring rule / investor-specific adjustment as applicable
→ Finance/Statement Refresh materializes due recurrence and proves CURRENT
→ calculate/reconcile statement
→ issue
→ create pending distribution payment
→ mark paid
→ verify SETTLED derived state
```

Also run a revision path:

```text
issue prior period
→ import changed reservation economics
→ current recalculation
→ immutable old statement
→ signed next-open correction
```

## Exit criteria

The requested MVP feature workflow is complete, deterministic, tenant-isolated, auditable, and recoverable without implementing general accounting or marketplace synchronization. **Do not transfer real payout authority yet**; Phase 6 must migrate/reconcile legacy history and pass the operational cutover gate.

---

# 10. Phase 6 — Legacy financial migration and production authority transfer

## User / business outcome

The founder can prove that the platform contains the authoritative CR-V/Aaron historical investor record, that live Turo/current finance agrees with the accepted golden evidence, and that the platform is safe to become the payout authority. Until this phase passes, the platform is a parallel-validation system only and the existing verified spreadsheet process remains authoritative for real investor payouts.

This phase implements the **already-defined Finance legacy migration contract only**. It is not a generalized spreadsheet import framework.

## Narrow legacy migration scope

Implement one deterministic migration runner/command specifically for the canonical Aaron/CR-V workbook contract:

```text
Aaron 2026.xlsx SourceArtifact
  → immutable workbook hash/provenance + exact sheet/row/cell locators
  → migration dry run
  → LEGACY_ISSUED_IMPORT reservation calculations/statements where authentic historical provider revision is unavailable
  → historical manager-incurred costs as OperatingCostFact(source_kind = LEGACY_IMPORT)
  → deterministic OperatingCostInvestorProjection / investor subledger effect when chargeable
  → exact historical InvestorStatementEntry membership
  → legacy DistributionPayment/settlement records
  → exact Q1/Q2 reconciliation
  → idempotent apply by workbook hash + sheet + migration version
```

Do **not** fabricate historical `SourceObservation` rows to make lineage look complete. Do **not** create a generic XLSX mapper/import product.

### Dry run must report

- workbook SHA-256 + migration version;
- exact CRV formula-region reservation count and precise workbook locators;
- source-backed versus `LEGACY_ISSUED_IMPORT` classification;
- known anomaly/provisional classifications required by the canonical Finance spec;
- historical manager-incurred OperatingCostFacts + workbook locators + projected investor effects;
- investor-specific reimbursement/repair/override inputs separately from operating costs;
- planned historical statement membership;
- expected exact Q1 `1357.688` and Q2 `1009.786` totals;
- planned legacy settlement/payment records;
- duplicate/already-migrated facts/projections/calculations/statements/payments;
- every unexplained or double-represented difference.

Apply is blocked unless dry run reconciles exactly and one historical real-world cost is represented through exactly one authoritative source path.

## Migration implementation boundary

Preferred surface is an internal/admin migration command or CLI entry point in the modular monolith, not a public/general upload UX. It may read the retained canonical workbook SourceArtifact from private object storage and write only the already-defined canonical Finance/Financial Source Facts aggregates under a migration-specific authorization/audit path.

The migration is idempotent: repeating the same workbook hash + sheet + migration version creates no duplicate OperatingCostFact, OperatingCostInvestorProjection, calculation, ledger line, statement/version, membership, or settlement record and returns the same reconciliation result.

A later migration version may supersede interpretation only through explicit immutable lineage; it never destructively rewrites issued historical statements.

## Mandatory legacy migration tests

- dry-run reproduces the canonical Aaron/CR-V workbook hash/provenance and exact locators;
- Q1 exact statement result = `1357.688`; Q2 exact statement result = `1009.786`;
- `LEGACY_ISSUED_IMPORT` is used when exact historical provider revision cannot be proven; no fake provider revision is created;
- historical manager-incurred cost migrates once through `OperatingCostFact(source_kind = LEGACY_IMPORT)`, not a second `EconomicAdjustment(VEHICLE_EXPENSE)` path;
- historical statement membership is explicit and immutable;
- legacy `PAID` marker creates the canonical legacy settlement semantics without inventing unknown bank evidence;
- re-running identical workbook hash + sheet + migration version is a no-op/idempotent reconciliation;
- unexplained total/membership/source-path difference fails closed;
- attempted double representation of one historical source cost fails closed.

## Operational production cutover gate

The platform does **not** become the authoritative payout workflow merely because Phase 5 features work. Before authority transfer, require all of the following in a production-like/controlled real-data environment:

1. **legacy migration dry-run and apply reconcile exactly** under the canonical migration contract;
2. **latest live Turo source state reconciles**, including source financial-completeness proof and canonical current reservation economics;
3. **exhaustive accepted CR-V golden fixture has zero unexplained variance** across all normative formula-region rows and required historical statement/cost/settlement lineage;
4. **at least three representative normal refresh/close cycles** are run in parallel with the existing verified process and measured; record founder hands-on minutes and exception-handling separately (the Product Direction's 70% effort-reduction target is measured but never overrides correctness);
5. **payout totals and end-to-end lineage are explicitly reviewed** from source artifact/revision → canonical facts → ownership/agreement/rules → projections/subledger → statement → settlement;
6. **any unresolved discrepancy blocks authority transfer**.

Until all six pass:

```text
platform may be exercised with production-like/real inputs in parallel
existing verified spreadsheet process remains payout authority
no real investor payout is authorized solely from the new platform
rollback = do not transfer authority / continue existing verified process
```

After the gate passes, record the explicit cutover decision/date/operator/audit reference. The spreadsheet may remain archived verification evidence but is no longer the authoritative payout workflow.

## Phase 6 exit criteria

- legacy history is migrated once, provenance-complete, and exactly reconciled;
- the live current source/finance path is complete and source-proof/fingerprint CURRENT;
- three parallel representative cycles have no unresolved payout variance;
- the authority-transfer decision is explicit and audited;
- no Books V1, tax, AP, bank-feed, OCR, or generic spreadsheet/recurring-scheduler scope was added.

---

# 11. Work deliberately deferred after Phase 6

Do not pull these into the Codex phases unless a canonical source contract changes:

```text
investor login/portal
customer login
Turo API/OAuth
multi-channel sync
availability engine
direct booking
maintenance workflows
pricing optimization
full accounting/GAAP/tax
bank integration / automated payouts
AP / vendor bills / bank feeds
receipt OCR / generalized receipt extraction
arbitrary/generalized recurring scheduling
PDF statement generation if manual/on-screen export is sufficient
email/SMS delivery
AI import mapping
AI financial explanations
Redis
message broker
microservices
```

If PDF statement export becomes immediately necessary, add it only after issue as a `COMMITTED_COMMAND` continuation over immutable statement data; it must not participate in calculation/issue truth.

---

# 12. Cross-phase quality gates

Every phase is complete only when all applicable gates pass.

## Build/static

- .NET build + analyzers;
- Angular strict TypeScript build;
- lint/format;
- OpenAPI/TypeScript client generation is clean;
- no cross-module forbidden dependency.

## Domain/integration

- unit/domain tests;
- real PostgreSQL integration tests;
- object-storage tests when touched;
- API authorization tests;
- relevant Playwright path;
- every canonical idempotent mutation declares `Idempotency-Key` in OpenAPI/generated Angular clients;
- `IDEMPOTENCY_V1` canonical request hash/version tests pass; same-key/same-payload replay and same-key/different-payload `IDEMPOTENCY_KEY_REUSED` tests pass; revoked/cross-Organization replay is denied under normal 401/403/404 behavior without re-execution or key-existence oracle.

## Security

- every exposed command matches the architecture command-security matrix;
- no runtime DB owner/BYPASSRLS credentials;
- RLS/role health checks pass;
- antiforgery/session rules pass;
- no PII in routine logs;
- negative direct-ID tests pass;
- privileged commands reauthorize inside protected transactions;
- stale/no recent step-up tests cover CURRENT apply, Finance/Statement Refresh, OperatingCostFact/recurring-rule mutation, investor-specific adjustment write, statement issue, payment write, cross-owner correction, and raw/source-PII read;
- `finance.read` tests prove read surfaces cannot advance calculation currentness/create ledger/correction state;
- HISTORICAL_BACKFILL authorization/no-current-regression tests pass;
- `source.connection.manage` remains independently tested from `source.import.execute`;
- per-Tenant SYSTEM scheduled-invocation/tenant/capability/pool-isolation tests pass whenever worker code changes; no cross-Tenant dispatcher DB role exists.

## Financial integrity

- source-financial-completeness proof tests: relevant quarantine blocks affected Vehicle, resolved quarantine may become complete, unrelated Vehicle isolation, disappearance/regression blocker, deterministic proof replay;
- decimal exactness;
- reservation calculation input/provenance hash reproducibility;
- complete authoritative input fingerprint + projection result hash reproducibility;
- one source OperatingCostFact → at most one current investor economic effect per owner/policy lineage;
- recurring occurrence/source-fact uniqueness and refresh idempotency;
- agreement-driven cost treatment, including explicit zero target;
- ledger generation uniqueness;
- statement membership immutability;
- failed refresh after independently committed source/configuration mutation cannot leave the old live projection CURRENT;
- compound issue authorization tests: issue-only denial, conditional adjustment authority, zero partial mutation on authorization race/failure;
- real PostgreSQL cross-Organization/cross-Vehicle OperatingCost correction-lineage negative tests;
- payment exact-settlement/cent-cash/over-settlement/reversal;
- legacy migration dry-run/apply/Q1-Q2/idempotency/fail-closed double-representation tests;
- operational authority-transfer gate evidence from three representative parallel cycles;
- idempotent retries;
- Vehicle-lock concurrency race tests.

## Operations

- structured logs + trace IDs;
- required metrics emitted;
- deterministic failure has safe error code;
- rollback/retry path tested;
- source-PII purge/orphan/audit-retention worker is deployable before real source PII is accepted;
- the configured synchronous import maximum has a recorded production-like preview benchmark, and after Phase 2 a CURRENT-apply benchmark, both within the architecture budgets;
- new SYSTEM job has explicit capability/idempotency/alert behavior and uses per-Tenant scheduled invocation rather than broad cross-Tenant business-data discovery/access;
- **no** finance refresh, recurrence materialization, operating-cost projection, or currentness work is registered as a SYSTEM/background job in Phase A.

---

# 13. Suggested Codex task granularity

Within a phase, prefer vertical tasks that leave the application runnable.

Good examples:

```text
"Add SourceArtifact upload end-to-end: migration + object store + API + Angular upload + tests"

"Add deterministic Turo parser preview: profile + persisted ImportBatch/issues + preview UI + fixture tests"

"Add CURRENT commit for one known Vehicle: source lock + reservation/economic projection + reconciliation + trip list"

"Add HISTORICAL_BACKFILL commit: historical observation persistence + binding serialization + no-current-regression tests"

"Add OwnershipInterest + agreement setup + Finance Refresh currentness for one imported CRV reservation"

"Add CURRENT-import follow-on Finance Refresh orchestration with separate import/refresh outcomes and failure-currentness tests"

"Add OperatingCostFact end-to-end: source fact + agreement-driven projection + investor ledger effect + UI + tests"

"Add monthly recurring tracking cost: prospective rule + Finance Refresh materialization + timezone/month-end/idempotency tests"

"Issue statement end-to-end only after complete-current Statement Refresh, with compound authorization, immutable membership and Playwright coverage"

"Add Aaron/CR-V legacy cutover runner: workbook SourceArtifact provenance + dry-run + LEGACY_ISSUED_IMPORT + historical costs/statements/payments + exact Q1/Q2/idempotency tests"

"Add production authority-transfer checklist/evidence: live-source reconciliation + exhaustive golden fixture + three parallel refresh/close cycles + payout-lineage review"
```

Avoid horizontal tasks such as:

```text
"build repository layer"
"build event architecture"
"add caching framework"
"set up generic job platform"
"create all domain tables"
```

unless the task is inseparable from a working vertical behavior in the same change set.

---


# 14. R1 panel-review revision map

This Revision 2 directly incorporates `panel-review-mvp-system-architecture-r1.md` without changing the five vertical business phases:

- Phase 1 now owns the complete first-real-PII safety boundary: retention policy, envelope-key lineage, encrypted raw values, purge/orphan/audit-retention worker, constrained SYSTEM dispatcher, and production-like synchronous performance gate.
- The architecture command-security matrix is normative for every phase; Phase-local text references it rather than weakening it.
- `StatementReviewFingerprintV1` uses exact canonical reviewed-state equality; “materially changed” is no longer a financial issue-time rule.
- Phase 1 uses the canonical pre-apply ImportBatch state subset and adds concurrent exact-artifact dedupe testing.
- Required idempotency keys are explicit OpenAPI/generated-client contracts rather than backend-only duplicate guards.

These were Revision 2 **plan-level** fixes. R2 completed and returned `REVISE_PLAN`; Revision 3 responses follow.

# 15. R2 panel-review revision map

Revision 3 responds narrowly to `panel-review-mvp-system-architecture-r2.md`:

- `finance.read` is strictly non-mutating. Authoritative recalculation/draft refresh uses canonical `finance.calculation.write` + recent step-up; the focused permission/resource contract is synchronized in `mvp-security-scope.md` Revision 4.
- the Revision 2 cross-Tenant DB dispatcher is removed entirely. MVP SYSTEM maintenance uses per-Tenant deployment schedules plus tenant-scoped `app_runtime`, avoiding a new pre-Tenant/cross-Tenant DB exception.
- HISTORICAL_BACKFILL is implemented coherently in Phase 2: persisted batch mode, source-import authorization, binding serialization, idempotency, no-current-pointer regression, concurrency tests, and E2E coverage.
- idempotency replay is authorization-aware: current resource/direct-ID authorization happens before lookup/replay, committed mutations are never re-executed, and revoked/cross-Organization replay cannot reveal key/resource existence.
- idempotency request identity is versioned as `IDEMPOTENCY_V1` with persisted SHA-256 contract version and stable server-side field/decimal/date canonicalization.

Chat 02 R3 is already `GREENLIGHT`; do not rerun broad Chat 02 review for this focused synchronization. Chat 06 Turo Import R3 is also `GREENLIGHT` and made no contract change. Use only targeted delta verification if a future material Import or Security change alters a contract consumed here.

# 16. Financial Platform Product Direction synchronization record

Revision 4 is derived from canonical MVP Architecture Revision 4 after the accepted Financial Platform Product Direction and synchronized Domain/Investor Finance contracts.

Implementation changes are intentionally limited to Phase-A financial direction:

- Phase 3 adds application-level CURRENT import → independently authorized Finance Refresh orchestration and complete-input currentness;
- Phase 4 replaces ordinary `EconomicAdjustment(VEHICLE_EXPENSE)` with canonical `OperatingCostFact` source facts + deterministic `OperatingCostInvestorProjection`;
- Phase 4 adds only simple MONTHLY recurring rules, materialized synchronously during authorized Finance/Statement Refresh through the canonical operating-cost path;
- import/operating-cost/rule/agreement mutations may commit independently; failed follow-on refresh makes prior projection non-CURRENT through fingerprint mismatch rather than a stale-marker write;
- worker remains maintenance-only; no autonomous finance scheduler, SYSTEM materializer, broker, or finance outbox is added;
- all prior RLS, import, idempotency, Vehicle-lock, statement immutability, and authorization/step-up decisions remain in force.

Required acceptance/negative tests explicitly include:

```text
one source cost -> at most one investor economic effect
different agreement treatment of the same cost category
recurring month with no Turo import
duplicate refresh/materialization idempotency
Organization financial-timezone/month-end recurrence
prospective recurring-rule edits
denied/stale cost-mutation authorization with zero partial materialization
source/cost/agreement/rule mutation + failed Finance Refresh -> prior projection not CURRENT
complete-input fingerprint exact match/mismatch behavior
```

This revision does not add Books V1, tax, AP, bank feeds, OCR, receipt workflows, or generalized recurring scheduling.

---

# 17. Complete-MVP package R1 focused remediation record

Revision 5 is derived from canonical MVP Architecture Revision 5 after the 00R package R1 remediation synchronized Import, Domain, Finance, and Security.

Focused implementation dispositions:

- Phase 2 now produces the provider-neutral `SourceFinancialCompletenessProofV1` contract while retaining `ReconciledWithQuarantine` partial-apply semantics;
- Phase 3 Finance Refresh requires source proof `COMPLETE` per applicable Vehicle/cutoff/source scope and freezes exact proof/effective processing lineage into the complete-input fingerprint/projection provenance;
- Phase 5 statement issue uses Security's compound `finance.statement.issue + finance.calculation.write` authorization and conditionally `finance.adjustment.write` only when recurrence materialization is actually required, with all actual-path authorities checked before first mutation;
- real PostgreSQL OperatingCost correction-lineage scope tests are mandatory;
- Phase 6 schedules the already-defined Aaron/CR-V legacy migration contract and operational payout-authority transfer gate; no generalized spreadsheet importer is introduced;
- unresolved source/legacy/live/golden/parallel-run discrepancies block real payout authority transfer.

No broad Chat 02 redesign or panel review is introduced by this revision. Chat 06 Turo Import R3 is now `GREENLIGHT`, introduced no contract change, and is satisfied rather than an outstanding pre-Codex gate.

---

# 18. Recommended phase review cadence

Because financial/security correctness dominates this MVP:

```text
pre-Phase 1 design status: Chat 06 Turo Import R3 GREENLIGHT satisfied; preserve Chat 02 R3 GREENLIGHT
before Phase 4 cost/recurrence merge: verify implementation matches the already-synchronized Security cost/rule/materialization authorization contract and negative tests
after Phase 1: architecture/security/data review of bootstrap + raw import boundary

before Phase 2 merge: import-specific concurrency/reconciliation review
before Phase 3 merge: finance rule/golden-fixture review
before Phase 4 merge: ledger/current-lineage/adjustment review
before Phase 5 merge: focused finance/security/concurrency verification of source completeness + compound issue authorization
before Phase 6 authority transfer: migration reconciliation + golden fixture + parallel-cycle operational sign-off
```

Review should become narrower over time; do not reopen already resolved scope without a regression or material contract change.

---

# 19. Definition of MVP done

MVP is done when a production-like environment can demonstrate, with real PostgreSQL and private object storage:

```text
1. Authenticated founder enters an authorized Organization context.
2. Turo CSV is privately preserved and deterministically previewed.
3. Unknown Vehicle identity fails closed until explicit Vehicle creation.
4. CURRENT import commits atomically under SourceConnection lock; HISTORICAL_BACKFILL preserves historical revisions without regressing newer provider-current state.
5. Imported Reservation/Trip/economic truth is inspectable without exposing raw PII.
6. Investor/ownership/agreement is configured effective-dated and fail-closed.
7. A committed CURRENT import can attempt a separately authorized Finance Refresh; import/refresh outcomes remain distinct, and `ReconciledWithQuarantine` is evaluated through scope-local `SourceFinancialCompletenessProofV1` rather than as a global Finance boolean.
8. Manager-incurred operating costs are authored once as immutable OperatingCostFact lineage; investor-specific adjustments remain separate.
9. Simple monthly recurring costs materialize synchronously during authorized Finance/Statement Refresh, including months with no Turo import, with Organization-local timezone/month-end semantics and idempotency.
10. Reservation and operating-cost investor economics are deterministic/decimal-exact and agreement-policy-driven; one source cost produces at most one current investor economic effect.
11. Live projection CURRENT status requires every applicable source financial-completeness proof to be COMPLETE with exact matching projection provenance **and** complete authoritative input fingerprint equality; relevant quarantine/disappearance/regression or any source/cost/agreement/rule mutation followed by failed refresh cannot leave an old projection CURRENT.
12. Statement draft explains every current reservation/operating-cost candidate ledger amount and requires complete currentness.
13. Issue freezes exact current-lineage membership under the Vehicle lock, requires source completeness + complete-input currentness + exact reviewed-state equality, and cannot use `finance.statement.issue` as implicit Finance Refresh/cost-mutation authority.
14. Later source/cost/agreement/rule changes never silently rewrite issued history.
15. Payment settlement is separate, explicit, idempotent, and cannot over-settle.
16. Cross-Tenant and same-Tenant cross-Organization negative tests fail closed.
17. RLS is FORCE-enabled using non-owner runtime roles.
18. Sensitive successes/denials/failures have correct durable audit behavior.
19. No autonomous finance scheduler/SYSTEM materializer/broker/outbox exists for Phase-A finance truth.
20. Full Playwright feature happy-path test passes.
21. Aaron/CR-V legacy migration dry-run/apply is provenance-complete, idempotent, and reconciles exact Q1/Q2 historical statements/costs/settlement with no unexplained or double-represented difference.
22. Latest live Turo source state reconciles and exhaustive accepted CR-V golden fixture has zero unexplained variance.
23. At least three representative normal refresh/close cycles run in parallel with the existing verified spreadsheet process; payout totals + lineage are explicitly reviewed.
24. Any unresolved discrepancy blocks authority transfer; until the operational cutover gate passes, the existing verified spreadsheet process remains the real payout authority.
25. The final authority-transfer decision/date/operator/audit reference is explicit; rollback before transfer is simply continuing the existing verified process.
```

Anything beyond those conditions belongs to a later product stage unless it is required to close a verified safety/correctness gap.
