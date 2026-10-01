# MVP Turo Import Specification

**Project:** Rental Asset & Travel Platform  
**Artifact:** `mvp-turo-import-spec.md`  
**Canonical path:** `/Projects/Fleet-Management/shared/canonical/mvp-turo-import-spec.md`  
**Steward:** `06-data-import` — Chat 06 — Data Import & Turo Migration  
**Phase:** 06 — Data Import & Turo Migration  
**Scope:** Deterministic import boundary for the Turo trip-earnings CSV only  
**Source files analyzed:**
- `trip_earnings_export_20260912.csv`
- `Aaron 2026.xlsx`

**Out of scope:** PostgreSQL table design, investor calculations, management-fee logic, investor distributions, accounting-entry rules, generic spreadsheet-import UI, and LLM-assisted execution.

**Revision:** 2  
**Previous revision:** 1 — focused complete-MVP package CRIT-01 / MIN-01 revision  
**Last changed by:** `06-data-import` — Chat 06 R3 convergence synchronization  
**Last material synchronization:** 2026-09-25 — `panel-review-mvp-turo-import-spec__2026-09-25__r3.md`  
**Revision status:** R3 `GREENLIGHT` with 0 Critical, 0 Significant, and 0 Minor findings. The R3 convergence gate verified the prior R2 fixes, the complete-MVP CRIT-01 source-financial-completeness contract, completed Chat 03 / Chat 05 synchronization, and unchanged Import/Finance authority boundaries. R3 introduced no new substantive import-contract change.

---

## 1. Executive summary

The supplied Turo CSV contains **678 rows and 47 columns**. Every row has a unique `Reservation ID`. The file contains 16 distinct Turo `Vehicle id` values and 16 distinct VINs, with a 1:1 Vehicle-id-to-VIN relationship in this export.

The deterministic MVP boundary should treat each row as a **current Turo observation of one reservation plus its current trip/earning snapshot**.

The critical findings are:

0. **The export is a cumulative YTD mutable snapshot.** Each new download repeats prior reservations and may revise them. It is not an incremental transaction feed.

1. **Reservation ID is the provider reservation key within a SourceConnection.** All 678 Reservation IDs are non-null, numeric strings, eight characters in this export, and unique within this file. Canonical provider identity is `Tenant + SourceConnection + Reservation ID`.
2. **Turo rows are mutable.** Comparing the CSV with `Aaron 2026.xlsx` shows that an existing Reservation ID can later change status, start/end time, guest display name, odometer values, individual earning components, and total earnings.
3. **Do not append financial data on every re-import.** Re-importing an overlapping export must compare the incoming reservation snapshot with the most recent prior source observation. An unchanged row is a no-op. A changed row creates a new source revision/current snapshot; it does not create a second reservation or duplicate earnings.
4. **VIN identifies the canonical physical vehicle; Turo Vehicle id identifies the Turo-side vehicle/listing relationship.** Both must be retained. The free-form `Vehicle` display column must never be the canonical identity.
5. **The entire uploaded artifact and every source value must be captured with retention-governed provenance.** Exact PII-bearing source bytes/strings are encrypted and immutable while retained, but readable retention is finite. Long-lived audit state keeps redacted/minimized source data, hashes, identifiers, economic components, and provenance after PII purge.
6. **The supplied CSV is internally financially reconcilable.** For all 678 rows, `Total earnings` equals the exact sum of every monetary component from `Trip price` through `Sales tax`, to the cent.
7. **Source operational fields can become less complete in later exports.** Several completed CR-V reservations have check-out odometers in `Aaron 2026.xlsx` but blank check-out odometers in the current CSV. Therefore a later null source observation must be preserved, but it must not blindly erase an already-known non-null canonical operational fact.
8. **The workbook is downstream, not source truth.** Its CR-V tab copies/renames only a subset of Turo fields and adds non-Turo fields such as delivery/cleaning operating costs, management fees, repair, tracking costs, ticket reimbursement allocation, and investor earnings.
9. **Every import is tenant- and source-connection-scoped.** External Reservation/Vehicle IDs are never resolved globally or merely by Channel; the boundary includes a `SourceConnection` dimension even though the Seattle MVP initially has one Turo connection.
10. **CURRENT snapshot freshness is an explicit operator assertion, not something upload time can prove.** Platform receipt time and asserted/provider snapshot time are separate.
11. **CURRENT apply is serialized and atomic at the state-mutation boundary.** For this MVP, all accepted rows in one CURRENT batch apply in one database transaction under a `Tenant + SourceConnection` lock, independent of import profile/version. Any processor that can mutate the same provider-current bindings participates in the same lock; unexpected failure rolls back the batch's canonical/current-pointer mutations.
12. **Provider chronology and processor-correction chronology are separate.** Reprocessing an old artifact under corrected parser/mapping logic never makes that old provider snapshot current merely because correction happened later.
13. **Import apply success and source financial completeness are separate.** `ReconciledWithQuarantine` remains a valid source-ingestion outcome, but downstream Finance may treat a Vehicle/cutoff as source-complete only from the deterministic `SourceFinancialCompletenessProofV1` contract.
14. **The completeness proof is an import-owned source/provenance output, not a Finance action.** Import does not run Finance Refresh, calculate investor economics, issue statements, or gain finance permissions.

### MVP import invariant

> Given the same source artifact, source connection, import mode, parser/profile/mapping versions, and pre-existing source state, the importer must produce the same normalized processing result and deterministic canonical commands every time.

Artifact identity, processing identity, and provider source-revision identity are intentionally separate; the same artifact may be reprocessed under a corrected parser/mapping version without pretending that Turo emitted a new file.

No LLM is allowed in this execution path.

---

## 2. Source semantics: Turo export is a YTD mutable snapshot

The Turo trip-earnings export must be modeled as a **year-to-date snapshot of Turo's current state as of the export time**, not as an incremental transaction file.

Operationally:

```text
Export on April 1
= all YTD reservations known to Turo on April 1

Export on July 1
= the same YTD population plus newer reservations,
  with earlier reservations potentially changed

Export on September 12
= the same YTD population plus newer reservations,
  with prior rows potentially revised again
```

A Reservation ID can remain present across many exports while its values evolve.

Typical reasons include:

- a future `Booked` trip changing dates or other booking details;
- `Booked` becoming `In-progress`, `Completed`, or cancelled;
- check-in/check-out operational data appearing after the trip begins/ends;
- gas reimbursement appearing roughly 48 hours after trip end;
- toll/ticket reimbursement appearing materially later;
- other post-trip adjustments changing earning components and `Total earnings`.

Therefore:

> Each import refreshes Turo's latest known YTD state while preserving prior source observations.

The import boundary must never interpret the presence of the same Reservation ID in another YTD export as a second earning event.

### Consequence for current platform state

For each Turo Reservation ID, the platform needs to distinguish:

```text
Source history
    every imported observation, immutable

Current Turo observation
    latest accepted YTD snapshot for that Reservation ID

Canonical business state
    platform-owned Reservation / Trip / financial facts derived
    deterministically from accepted source observations
```

For **live/unissued current-performance views**, investor-facing numbers may derive from the latest accepted canonical economic state rather than a manually frozen quarterly workbook.

For **issued or paid historical statements**, later Turo revisions must never silently rewrite the issued economics. Issued statements remain pinned to the exact source-observation/calculation versions used at issue time; any correction uses the explicit adjustment/restatement policy owned by Chat 05.

The importer's responsibility is to keep Turo-derived facts current, versioned, and auditable while exposing exact source-revision provenance to finance. It also exposes a deterministic provider-neutral source financial-completeness proof so downstream Finance can distinguish a successfully applied CURRENT snapshot from one that still has unresolved source omissions relevant to a Vehicle/cutoff.

---

## 3. Source artifact facts

### CSV artifact

- File: `trip_earnings_export_20260912.csv`
- Size: 374,918 bytes
- SHA-256: `186ab6189a4659129ff47b4c444049a3275c4fb15dd16c9271c29c604c813dde`
- Rows: 678 data rows
- Columns: 47
- Encoding observed: UTF-8-compatible CSV
- Header row is present.
- All 678 Reservation IDs are unique.
- Date range by `Trip start`: 2025-12-22 05:30 PM through 2026-12-23 07:00 AM.
- Date range by `Trip end`: 2026-01-01 12:00 PM through 2026-12-30 09:30 AM.
- The source includes past, current, cancelled, and future reservations in one export.

### Status distribution

| Turo status | Count |
|---|---:|
| Completed | 491 |
| Guest cancellation | 137 |
| Booked | 39 |
| In-progress | 9 |
| Host cancellation | 2 |

No other status values occur in this artifact.

---

## 4. Source schema inventory

### 4.1 Identity, reservation, vehicle, trip, and location fields

| # | Source column | Observed type | Nulls | Unique non-null | Deterministic interpretation |
|---:|---|---|---:|---:|---|
| 1 | Reservation ID | decimal-digit string | 0 | 678 | Turo reservation source identifier; retain as string, not integer |
| 2 | Guest | string | 0 | 622 | Guest display-name snapshot only; not a stable customer key |
| 3 | Vehicle | string | 0 | 16 | Turo display label; preserve verbatim; do not parse as identity |
| 4 | Vehicle name | string | 0 | 12 | Source display metadata, e.g. `Honda CR-V 2025` |
| 5 | Vehicle id | decimal-digit string | 0 | 16 | Turo-side vehicle/listing identifier; retain as string |
| 6 | VIN | 17-character VIN string | 0 | 16 | Canonical physical-vehicle resolver |
| 7 | Trip start | local date/time string | 0 | 622 | Reservation scheduled start snapshot |
| 8 | Trip end | local date/time string | 0 | 631 | Reservation scheduled end snapshot |
| 9 | Pickup location | string | 0 | 13 | Reservation pickup-location snapshot |
| 10 | Return location | string | 0 | 13 | Reservation return-location snapshot |
| 11 | Trip status | enum-like string | 0 | 5 | Source status snapshot |
| 12 | Check-in odometer | integer miles | 176 | 501 | Trip operational observation |
| 13 | Check-out odometer | integer miles | 286 | 390 | Trip operational observation |
| 14 | Distance traveled | integer miles | 288 | 320 | Source-reported trip distance |
| 15 | Trip days | integer | 0 | 22 | Turo billable/scheduled day count |

Observed identifier facts:

- `Reservation ID`: all values are numeric text and eight characters in this export.
- `Vehicle id`: all values are numeric text and seven characters in this export.
- `VIN`: all values are 17 characters and match a normal VIN character set; retain source text exactly after outer whitespace trimming.
- In this export, every Turo `Vehicle id` maps to exactly one VIN and every VIN maps to exactly one `Vehicle id`.

Observed `Trip days` rule:

- For all 678 rows, `Trip days == ceil((Trip end - Trip start) / 24 hours)`.
- Import the source value and validate this relationship.
- Do not replace the source value with a derived value; preserve both the source assertion and parsed timestamps.

Observed locations:

- Pickup and return location are identical on all 678 rows in this artifact.
- This is an observed property of this file, not a system invariant. Preserve both fields separately.

### 4.2 Monetary fields

All monetary source fields are non-null in this CSV. They are formatted strings such as:

- `$771.30`
- `- $154.26`
- `$0.00`

They must be parsed as signed decimal currency values with **USD** as the MVP currency for this import profile. Do not use binary floating point in production import logic.

| Source column | Sign semantics observed | Non-zero rows | Observed range |
|---|---|---:|---:|
| Trip price | positive/zero | 543 | $0.00 to $2,540.70 |
| Boost price | positive/zero | 7 | $0.00 to $20.32 |
| 3-day discount | negative/zero | 369 | -$56.97 to $0.00 |
| 1-week discount | negative/zero | 116 | -$178.92 to $0.00 |
| 2-week discount | negative/zero | 11 | -$271.08 to $0.00 |
| 3-week discount | negative/zero | 3 | -$635.18 to $0.00 |
| 1-month discount | zero in this artifact | 0 | $0.00 |
| 2-month discount | zero in this artifact | 0 | $0.00 |
| 3-month discount | zero in this artifact | 0 | $0.00 |
| Non-refundable discount | negative/zero | 273 | -$254.07 to $0.00 |
| Early bird discount | zero in this artifact | 0 | $0.00 |
| Host promotional credit | zero in this artifact | 0 | $0.00 |
| Delivery | positive/zero | 367 | $0.00 to $108.00 |
| Excess distance | positive/zero | 6 | $0.00 to $159.80 |
| Extras | positive/zero | 63 | $0.00 to $112.50 |
| Cancellation fee | positive/zero | 5 | $0.00 to $208.60 |
| Additional usage | positive/zero | 4 | $0.00 to $40.80 |
| Late fee | positive/zero | 1 | $0.00 to $14.00 |
| Improper return fee | positive/zero | 3 | $0.00 to $50.00 |
| Airport operations fee | zero in this artifact | 0 | $0.00 |
| Airport parking credit | zero in this artifact | 0 | $0.00 |
| Tolls & tickets | positive/zero | 129 | $0.00 to $296.80 |
| On-trip EV charging | zero in this artifact | 0 | $0.00 |
| Post-trip EV charging | zero in this artifact | 0 | $0.00 |
| Smoking | zero in this artifact | 0 | $0.00 |
| Cleaning | zero in this artifact | 0 | $0.00 |
| Fines (paid to host) | positive/zero | 1 | $0.00 to $888.77 |
| Gas reimbursement | positive/zero | 88 | $0.00 to $126.88 |
| Gas fee | zero in this artifact | 0 | $0.00 |
| Other fees | signed | 3 | -$213.31 to $21.10 |
| Sales tax | zero in this artifact | 0 | $0.00 |
| Total earnings | positive/zero in this artifact | 547 | $0.00 to $1,678.45 |

### Financial source invariant

For **all 678 rows** in the supplied CSV:

```text
Total earnings
=
Trip price
+ Boost price
+ 3-day discount
+ 1-week discount
+ 2-week discount
+ 3-week discount
+ 1-month discount
+ 2-month discount
+ 3-month discount
+ Non-refundable discount
+ Early bird discount
+ Host promotional credit
+ Delivery
+ Excess distance
+ Extras
+ Cancellation fee
+ Additional usage
+ Late fee
+ Improper return fee
+ Airport operations fee
+ Airport parking credit
+ Tolls & tickets
+ On-trip EV charging
+ Post-trip EV charging
+ Smoking
+ Cleaning
+ Fines (paid to host)
+ Gas reimbursement
+ Gas fee
+ Other fees
+ Sales tax
```

This is a source reconciliation rule, not yet an accounting rule.

---

## 5. Turo source → canonical boundary mapping

The import boundary should output canonical-domain commands/facts, but it must not decide downstream accounting treatment.

### 5.1 Reservation

| Turo source | Canonical meaning | Rule |
|---|---|---|
| Reservation ID | external reservation reference | Key within `Tenant + SourceConnection`; preserve as opaque string |
| Guest | guest display-name snapshot | Preserve. Do not use as stable Customer identity. |
| Trip start | scheduled reservation start | Parse wall-clock date/time under configured source timezone |
| Trip end | scheduled reservation end | Same |
| Pickup location | pickup-location snapshot | Preserve full source string |
| Return location | return-location snapshot | Preserve full source string |
| Trip status | external reservation status | Deterministic enum mapping |
| Trip days | source billable/scheduled day count | Preserve and validate against timestamps |

### 5.2 Trip

| Turo source | Canonical meaning | Rule |
|---|---|---|
| Check-in odometer | trip check-in odometer | Nullable integer miles |
| Check-out odometer | trip check-out odometer | Nullable integer miles |
| Distance traveled | source-reported trip distance | Nullable integer miles; do not derive over source value |
| Trip status | may drive canonical trip lifecycle | Mapping controlled by domain rules, while original Turo status is always preserved |

Important: a row may describe a reservation before an actual Trip exists. `Booked` and cancellation rows must not imply a completed physical Trip merely because they are present in the export.

### 5.3 Vehicle and Turo listing

| Turo source | Canonical meaning | Rule |
|---|---|---|
| VIN | physical Vehicle resolver | Primary deterministic resolver for canonical Vehicle |
| Vehicle id | Turo external vehicle/listing reference | Key within `Tenant + SourceConnection`; bind to canonical Listing once Vehicle is resolved |
| Vehicle name | source listing/vehicle display metadata | Preserve snapshot |
| Vehicle | free-form Turo display label | Preserve verbatim; never use as sole identity |

#### Required identity behavior

For the current CR-V:

```text
Vehicle          = #3 CR-V CSJ1646 (WA #CSJ1646)
Vehicle name     = Honda CR-V 2025
Vehicle id       = 3148718
VIN              = 2HKRS4H21SH443987
```

The `Vehicle` display text contains fleet-number and plate-like text. It is descriptive source metadata and must not be parsed into canonical identity in the MVP.

#### Vehicle resolver rules

1. Normalize VIN for comparison by trimming outer whitespace and uppercasing.
2. Find canonical Vehicle by VIN.
3. If none exists, the row is `ROW_BLOCKING/QUARANTINED`. **MVP does not auto-create a production Vehicle from imported VIN/source metadata.** An authorized operator must explicitly create/approve the canonical Vehicle before the row is resolved/reprocessed.
4. Bind Turo `Vehicle id` to the resolved canonical Vehicle/Turo Listing relation.
5. If an already-bound Turo `Vehicle id` appears with a different VIN, **quarantine the row/batch for identity conflict**.
6. If an already-known VIN appears with a different Turo Vehicle id, preserve the observation and require explicit handling; it may represent a recreated/replaced Turo listing.
7. Preserve `Vehicle`, `Vehicle name`, `Vehicle id`, and VIN from every observation even after resolution.

### 5.4 Financial earning snapshot

All monetary Turo columns belong to a deterministic **Turo earnings snapshot/component set associated with Reservation ID**.

The import boundary must retain them individually. It must not collapse them into only `Total earnings`.

Examples of distinct component semantics that must remain distinct:

- trip price
- duration discounts
- non-refundable discount
- delivery
- extras
- cancellation fee
- additional usage
- late/improper-return fee
- tolls/tickets
- EV charging
- fines paid to host
- gas reimbursement
- other fees
- sales tax

`Total earnings` is the source-reported aggregate and must also be preserved for reconciliation.

**This spec intentionally does not define ledger accounts or investor allocation.**

---

## 6. Fields preserved even when the MVP does not use them

Every source column is retained.

In particular, the current `Aaron 2026.xlsx` workbook does **not** represent many fields present in the Turo export. The MVP must still preserve them:

- raw `Vehicle` display label
- Turo `Vehicle id`
- VIN
- pickup location
- return location
- distance traveled
- trip days
- 1-month discount
- 2-month discount
- 3-month discount
- early bird discount
- host promotional credit
- cancellation fee
- additional usage
- late fee
- improper return fee
- airport operations fee
- airport parking credit
- on-trip EV charging
- post-trip EV charging
- smoking
- cleaning
- fines paid to host
- gas fee
- other fees
- sales tax

A currently-zero column is still part of the source contract. Zero usage in this one artifact is not justification to discard it.

---

## 7. Comparison with `Aaron 2026.xlsx`

For this MVP specification, use the `CRV` sheet only as the concrete workbook comparison case.

The CRV sheet corresponds to raw Turo vehicle:

```text
#3 CR-V CSJ1646 (WA #CSJ1646)
Vehicle id 3148718
VIN 2HKRS4H21SH443987
```

All 44 Reservation IDs present in the CRV workbook tab are present in the supplied CSV.

### 7.1 Fields that are direct or renamed Turo-source fields

The workbook's first 21 columns are effectively a selected projection of Turo data:

| Workbook column | Turo source |
|---|---|
| Reservation ID | Reservation ID |
| Guest | Guest |
| Vehicle name | Vehicle name |
| Trip start | Trip start |
| Trip end | Trip end |
| Trip status | Trip status |
| Check In Odometer | Check-in odometer |
| Check out Odometer | Check-out odometer |
| Trip price | Trip price |
| Boost price | Boost price |
| 3-day discount | 3-day discount |
| 1-week discount | 1-week discount |
| 2-week discount | 2-week discount |
| 3-week discount | 3-week discount |
| Non-refundable discount | Non-refundable discount |
| Guest Paid Delivery | Delivery |
| Excess distance | Excess distance |
| Extras | Extras |
| Tolls & tickets | Tolls & tickets |
| Gas reimbursement | Gas reimbursement |
| Gross earnings | Total earnings |

The workbook therefore should not become the migration source for those fields when the original Turo export is available.

### 7.2 Workbook-only/downstream fields

These are not columns in the supplied Turo CSV and should not be inferred by the Turo importer:

- workbook `Delivery` operating-cost column
- workbook `Cleaning` operating-cost column
- `Management fees`
- `Repair`
- `Ticket Reimbursement` / `Ticket Reimburstment`
- `Investor earnings`
- tracking subscription/device entries
- inspection/oil-change/repair notes
- quarterly totals / payment markers

They belong to later expense, financial, ownership, or migration work.


The current quarterly workbook is therefore best understood as a manually prepared downstream report. The target system should remove that quarterly data-preparation dependency: once Turo snapshots and non-Turo expenses/ownership facts are current in the platform, an investor should be able to view current performance at any time. This import specification only ensures that the Turo portion of those underlying facts stays current and auditable.


### Current Aaron management-fee behavior observed in the workbook

The CR-V sheet currently calculates management fee as:

```text
30% × (
    Gross earnings
    - Guest Paid Delivery
    - Extras
    - Tolls & tickets
    - Gas reimbursement
)
```

Equivalent current workbook formula:

```excel
=(Gross earnings - Gas reimbursement - Tolls & tickets - Extras - Guest Paid Delivery) * 0.30
```

This is **not** a Turo import rule. It is a downstream investor-agreement/financial-calculation rule and must not be embedded in the Turo CSV mapping.

For MVP planning purposes, the system may reproduce this current Aaron behavior, but the financial design must assume:

- different investors may have different fee rates;
- different investors may include/exclude different earning components from the fee base;
- the same investor's agreement may change over time;
- historical calculations must continue to use the agreement terms that were effective for the applicable period;
- changing a current agreement must not silently recalculate historical results under new terms unless an explicit restatement policy requires it.

Therefore Chat 05 should model investor economic terms as **configurable, versioned, effective-dated agreement rules**, rather than hardcoded formulas or investor-specific branches.

The import boundary remains unchanged:

```text
Turo CSV
    -> deterministic source facts
    -> canonical Reservation / Trip / earning components
    -> downstream agreement rules
    -> management fee / investor allocation
```

The Turo importer must import the complete underlying earning components so future agreement versions can calculate against them without re-parsing historical spreadsheets.

### 7.3 Proof that source rows mutate

Across the 44 overlapping CR-V workbook rows, multiple reservations differ from the current CSV on at least one directly-copied Turo field.

Observed change classes include:

- `Booked` → `Completed`
- `Booked` → `Guest cancellation`
- `In-progress` → `Completed`
- check-in/check-out odometers appearing later
- check-out odometers present in the workbook but blank in the current CSV
- trip start/end times changing
- guest display name changing
- toll/reimbursement values changing
- gas reimbursement appearing later
- total earnings changing

Examples:

**CR-V Reservation 55126068**
- workbook: Booked
- current CSV: Completed
- trip end changed from 10:30 AM to 11:30 AM
- current CSV later contains check-in/out odometers
- gas reimbursement changed from $0.00 to $29.10
- total earnings changed from $1,557.76 to $1,586.86

This makes snapshot revision handling a core MVP requirement rather than an edge case.

---

## 8. Normalization rules

### 8.1 General string handling

For canonical comparison:

- Remove only outer whitespace unless a field has a field-specific rule.
- Preserve the original raw string separately.
- Do not normalize away punctuation/case in guest names, addresses, or Turo display labels.
- Empty CSV field → normalized `null` for nullable non-money fields.
- Money fields in this import profile are expected to be present; an empty monetary source cell is invalid, not automatically zero.

### 8.2 Identifier parsing

`Reservation ID` and `Vehicle id`:

- Treat as opaque source strings.
- Validate decimal digits for this profile.
- Do not store semantics based on numeric magnitude.
- Do not coerce to floating point.
- Leading zeros, if Turo ever introduces them, must remain intact.

VIN:

- Source value preserved verbatim.
- Comparison form = `Trim().ToUpperInvariant()`.
- Validate 17 characters and allowed VIN characters.
- VIN validation failure is an identity error, not a reason to fall back silently to the `Vehicle` display field.

### 8.3 Date/time parsing

Observed source format:

```text
yyyy-MM-dd hh:mm tt
```

Example:

```text
2026-02-27 03:00 PM
```

Rules:

- Strict parse against the approved profile format.
- The CSV supplies no timezone offset.
- The profile must provide the source timezone separately.
- Store:
  - original source string,
  - parsed local date/time,
  - resolved instant once the configured timezone is applied.
- DST ambiguity/nonexistent-local-time behavior must fail deterministically rather than silently selecting an arbitrary instant.
- Do not infer timezone from pickup address row-by-row.

### 8.4 Money parsing

Accepted forms in this file:

```text
$0.00
$771.30
- $154.26
```

Rules:

1. Trim outer whitespace.
2. Detect optional leading `-`.
3. Require `$`.
4. Remove thousands separators if present.
5. Parse base-10 decimal with exactly two currency decimals or a format explicitly permitted by the profile.
6. Apply sign.
7. Currency = USD for this profile.
8. Preserve original string.

Discount columns may be zero or negative in the current artifact. Unexpected positive discounts should be a validation warning/error depending on final policy, not silently negated.

### 8.5 Odometer/distance parsing

- Integer miles.
- Empty → null.
- Negative → invalid.
- `Distance traveled` should normally equal `Check-out - Check-in` when all three are present.
- The supplied CSV contains four rows where this equality fails and the apparent check-out is below check-in while distance is `0`.
- These source anomalies must be preserved and reported; they should not make the entire artifact un-importable if identity and financial data are otherwise valid.

### 8.6 Status mapping

The Turo adapter mapping is normative for this profile:

| Turo source status | Canonical Reservation status | Cancellation party |
|---|---|---|
| `Booked` | `CONFIRMED` | null |
| `In-progress` | `IN_PROGRESS` | null |
| `Completed` | `COMPLETED` | null |
| `Guest cancellation` | `CANCELLED` | `GUEST` |
| `Host cancellation` | `CANCELLED` | `HOST` |

Rules:

- The raw Turo status string is always retained in the SourceObservation.
- A row in `Booked` state does not imply an operational Trip has occurred.
- Cancellation maps to canonical `CANCELLED` plus explicit cancellation party; do not encode guest/host cancellation as separate canonical statuses.
- Any new Turo status is schema drift/unmapped enum and fails closed until this mapping policy is versioned and approved.

---

## 9. Raw-source preservation and privacy design

The MVP requires three preservation levels. `SourceArtifact` is connection-agnostic within a Tenant; processing/import attempts are bound to one immutable `Tenant + SourceConnection` context.

### 9.1 Original artifact

At artifact receipt:

- stream/store the uploaded CSV privately while calculating SHA-256;
- identify the artifact by `Tenant + SHA-256(original bytes)`;
- record connection-agnostic immutable blob/provenance metadata: original filename, content type, byte size, Tenant, `received_at`, source system/channel, and retention-policy version;
- do **not** assign one SourceConnection, import mode, CURRENT assertion, or processor version to the SourceArtifact itself;
- encrypt source bytes with a retention-governed artifact key;
- require an approved, finite `SourcePIIRetentionPolicy` for PII-bearing Turo source data; production receipt/processing fails closed if no approved policy is configured.

Each `ImportBatch` / processing attempt referencing the artifact records its own:

```text
Tenant
SourceConnection
import mode
profile/parser/mapping versions
CURRENT assertion metadata
processing actor/timestamps
```

Therefore the same exact artifact bytes can be processed under SourceConnection A and SourceConnection B without mutating or mislabeling the SourceArtifact.

For this MVP, source-byte retention policy is configured at Tenant + source-system/channel scope (Turo), not per SourceConnection, so connection-agnostic byte dedupe has one unambiguous retention envelope. If future Turo connections require different legal retention policies, storage/retention mechanics must be revisited without moving SourceConnection into provider business identity accidentally.

The artifact's **identity and provenance are permanent**, but readable PII-bearing bytes are not.

During the approved retention horizon:

- exact source bytes are immutable and recoverable only to authorized tenant-scoped operators.

At retention expiry:

- destroy/disable the artifact data key;
- delete original object bytes/versioned copies according to policy;
- mark the artifact source payload purged.

Long-lived state retains what is needed for economic/audit reproducibility without retaining guest-identifying raw data forever:

- Tenant-scoped artifact metadata and SHA-256;
- SourceConnection attribution on each ImportBatch/processing attempt;
- import/reconciliation counts;
- provider external Reservation/Listing IDs and VIN;
- source economic components;
- normalized PII-redacted source observations;
- canonical economic snapshots/calculations and issued-statement provenance.

### 9.2 Raw row

For each physical source row preserve:

- ImportBatch reference, which supplies the immutable Tenant + SourceConnection processing context;
- row number;
- deterministic hash of the exact original parsed row;
- exact original source strings encrypted under the retention-governed source key while retained;
- a separate long-lived PII-redacted/minimized representation;
- parse/validation outcome and resolved SourceObservation reference where applicable.

All 47 source columns are captured. Zero-valued monetary columns are not discarded.

After PII purge, the exact guest-identifying row is intentionally no longer retrievable, while its hash, redacted representation, source economic facts, and provenance remain.

### 9.3 Import diagnostics

`ImportIssue`, logs, traces, metrics, and support diagnostics must not create a second indefinite plaintext copy of raw PII.

- PII-bearing values are redacted in durable issue/log payloads.
- During the retention horizon, authorized troubleshooting refers back to the encrypted RawImportRecord rather than copying the raw value into issue text.
- Never place raw CSV rows, guest names, exact trip locations, or full source payloads in normal application logs.

### 9.4 Normalized source observation

Create a deterministic normalized provider representation keyed by:

```text
Tenant
+ SourceConnection
+ external Reservation ID
```

It contains the provider semantics needed for source revision/audit, including the complete earning component set and source-reported `Total earnings`.

PII-sensitive fields are retained only according to the source retention policy. Long-lived normalized payloads are redacted/minimized, while non-PII economic/provenance fields remain queryable.

The normalized observation is Turo-source state. It is not the canonical finance ledger.

---

## 10. Idempotency, processing identity, source revisions, and duplicate detection

The MVP separates three identities that must not be conflated.

### 10.1 Artifact identity

```text
Tenant + SHA-256(original artifact bytes)
```

This answers: **Have these exact bytes already been received for this Tenant?**

`SourceArtifact` is connection-agnostic. `SourceConnection`, mode, CURRENT assertion, and processor versions belong to the ImportBatch/ProcessingIdentity.

An exact artifact duplicate does not by itself imply that all future processing attempts are forbidden. The same artifact may be intentionally processed under another SourceConnection; provider mutations remain strictly scoped to that processing attempt's connection.

### 10.2 Processing identity

```text
Artifact
+ SourceConnection
+ import mode
+ profile version
+ parser version
+ mapping version
```

This answers: **Have these exact bytes already been processed under this exact deterministic processor contract?**

Rules:

- same artifact + same processing identity is idempotent/no-op after successful completion;
- the same artifact may be reprocessed under a newer parser/profile/mapping version to correct importer logic;
- a new processing attempt never fabricates a new provider artifact.

If corrected processing produces the same normalized provider semantics, it creates no new provider source revision.

If corrected processing materially changes normalized semantics, preserve correction lineage explicitly as a `PROCESSOR_CORRECTION` (or equivalent provenance reason) pointing to the same source artifact/row; do not claim Turo emitted a newer provider snapshot.

#### Processor-correction chronology

Provider snapshot chronology and processor/correction chronology are independent.

Every source observation/correction must preserve enough provenance to identify:

```text
provider snapshot position
    source_snapshot_observed_at / source_snapshot_id / CURRENT assertion lineage

processing position
    processing attempt + parser/profile/mapping versions + processed_at

correction lineage
    corrected_from_observation_id / correction reason
```

Rules:

1. A processor correction **inherits the provider-snapshot ordering position of the source artifact/row it corrects**. Processing it later does not make the provider snapshot newer.
2. Correcting a historical/non-current provider snapshot creates a new immutable correction observation linked to the observation it corrects, at that same provider-snapshot position, but **must not advance the provider-current pointer** past a newer accepted snapshot. The original observation remains audit history.
3. Correcting the **currently effective** provider snapshot creates a new immutable correction observation and may atomically move the effective/current pointer from the prior normalized observation to that correction for the same provider-snapshot position.
4. That replacement is marked as processor correction provenance; it does not claim Turo emitted another snapshot.
5. Current canonical Reservation/Trip/economic projections are recomputed deterministically only when the corrected observation is the effective current provider snapshot.
6. Issued/paid finance remains pinned to its historical source/calculation versions; correction does not silently rewrite issued statements.
7. Repeating the same processor correction with the same ProcessingIdentity/result is idempotent and must not create duplicate correction revisions or pointer advances.

Example:

```text
Provider A imported CURRENT
Provider B imported later CURRENT → B is current
Correct parser for old artifact A
    → corrected A remains historical
    → B stays current

Correct parser for effective artifact B
    → corrected B replaces effective normalized B exactly once
    → no fictional provider snapshot C is created
```

### 10.3 Provider reservation identity

For the revised MVP boundary:

```text
Tenant
+ SourceConnection
+ external Reservation ID
```

`Reservation ID` is therefore opaque and stable only **within a Turo SourceConnection**.

The Seattle MVP may configure exactly one Turo SourceConnection initially, but the identity dimension exists now so a Tenant can later ingest multiple Turo host/accounts without key migration.

The equivalent listing-side identity is:

```text
Tenant
+ SourceConnection
+ external Vehicle/Listing ID
```

### 10.4 Source semantic fingerprint

`UNCHANGED` versus `REVISED` compares the incoming normalized provider-source semantics to the **current observation for that provider reservation identity**.

The fingerprint payload is normative and contains only normalized provider-source semantics, never canonical resolution or processing state.

Canonical serialization includes, in fixed profile-defined key order:

- external Reservation ID;
- guest display-name source value/token;
- source `Vehicle`, `Vehicle name`, `Vehicle id`, and VIN;
- source trip start/end local values;
- pickup/return source values/tokens;
- raw mapped Turo status;
- check-in/check-out odometer, distance, and trip days;
- currency;
- every mapped monetary component code/value, including zeros;
- source `Total earnings`.

It explicitly excludes:

- Tenant/canonical entity UUIDs;
- resolved Vehicle/Listing/Reservation IDs;
- validation warnings/errors;
- batch/row IDs;
- actor/timestamps;
- parser/profile/mapping version numbers;
- current-pointer/revision sequence;
- reconciliation outcome.

Normalization for the fingerprint uses the same deterministic field rules in this specification: opaque IDs as strings, strict local date/time canonical form, decimal money canonical form, null as explicit null, and component codes in mapping-profile order.

Because guest/source-location values may be privacy-sensitive, do not use a raw unsalted hash of PII-bearing canonical text. Use a privacy-safe deterministic keyed fingerprint/HMAC (with key/version provenance) or equivalent approved pseudonymization mechanism. The economic/non-PII payload remains reproducible after source PII purge.

### 10.5 Duplicate Reservation ID inside one artifact

Within one Turo trip-earnings CSV, Reservation ID is expected to be unique within its SourceConnection.

If duplicate Reservation IDs appear:

- identical normalized rows are still malformed duplicate source rows and are quarantined;
- conflicting duplicate rows are a **batch-blocking ambiguity**, because currentness/order inside that artifact cannot be determined.

The supplied artifact has no duplicate Reservation IDs.

### 10.6 Overlap with prior YTD imports

Overlap is the normal case.

For each incoming provider reservation identity:

```text
current source observation?
    no  -> NEW
    yes -> compare source semantic fingerprint
            equal     -> UNCHANGED
            different -> REVISED
```

A repeated/overlapping export never creates a second canonical Reservation solely because it came from another batch.

Important A → B → A rule:

- if current state is B and a newer explicitly accepted CURRENT snapshot returns to semantic state A, create a **new revision** that supersedes B even if an older historical revision also had fingerprint A;
- revision identity is chronological/provenance history, not global dedupe by semantic hash.

---

## 11. Existing reservation changed between exports

This is expected behavior.

### 11.1 Preserve revision history

When the same Reservation ID has a different semantic payload:

1. Preserve the new raw row.
2. Preserve the prior raw row/revision.
3. Create a new normalized source-observation revision.
4. Mark it as the current Turo observation only if the batch is allowed to supersede the current observation.
5. Produce deterministic canonical update commands based on field-specific rules.
6. Do not append another copy of all earnings.

### 11.2 Field-specific canonical update rules

#### Reservation schedule/status fields

Incoming non-null source values may update the Turo-derived canonical projection when the incoming observation is newer.

Examples:

- Booked → Completed
- Booked → Guest cancellation
- changed start/end times
- changed pickup/return location
- changed guest display-name snapshot

Every previous source value remains auditable through source revisions.

#### Financial components

Treat the incoming row as a **replacement Turo earning snapshot for that Reservation ID**, not as an additive transaction batch.

If:

```text
old Total earnings = 364.73
new Total earnings = 491.61
```

the new source state is $491.61, not $856.34.

The finance module may later derive delta postings/reversals from source revision changes; this import boundary must expose old and new component sets deterministically.


This same replacement-snapshot rule applies when post-trip earnings arrive later.

Example lifecycle:

```text
T0: Trip booked
    Total earnings reflects booking state

T1: Trip completed
    row may gain odometers and completed status

T2: ~48 hours later
    Gas reimbursement may appear

T3: days/weeks later
    Toll/ticket reimbursement may appear

T4: later YTD export
    same Reservation ID carries the newly revised component set
```

At each step:

```text
new current Turo earnings snapshot
≠
new independent earning record
```

The importer records a revision and exposes the component delta to downstream finance logic.

#### Odometers and other operational facts

A later blank must **not blindly erase** a previously known non-null canonical fact.

Required distinction:

- latest Turo source observation may be null;
- canonical operational fact may remain the last accepted non-null observation;
- record a source-regression warning/provenance note.

A later non-null source value may fill a prior null.

If a later non-null value conflicts with an existing non-null accepted value, preserve both observations and flag a conflict for review rather than silently overwriting if the domain treats the field as historical actual fact.

---

## 12. Source snapshot freshness and ordering

Upload/processing time cannot prove that a Turo snapshot is newer.

The MVP records separate concepts:

```text
received_at
    platform time when bytes reached the system

source_snapshot_observed_at?
    provider-supplied or operator-asserted time/date describing the source snapshot,
    when such a value is available

source_snapshot_id?
    optional provider watermark/identifier if Turo later exposes one

current_asserted_by / current_asserted_at
    audit evidence that an authorized operator asserted this artifact is the
    newest CURRENT snapshot for this SourceConnection
```

### CURRENT mode

Turo CSV currently provides no trusted in-file export watermark that proves freshness.

Therefore CURRENT mode means:

> An authorized operator explicitly asserts that this artifact is the newest Turo YTD snapshot for this SourceConnection and is allowed to supersede the previously accepted CURRENT snapshot.

Rules:

- never use `received_at` or upload order as evidence of provider freshness;
- filename dates may be captured and checked as a warning signal but are not authoritative;
- if an asserted/provider snapshot time exists and is older than the current accepted snapshot time, block CURRENT apply unless the operator explicitly changes mode or performs an audited override;
- absent a trustworthy provider watermark, the system cannot guarantee that a mistakenly uploaded old file is stale.

Non-authoritative regression checks should surface suspicious CURRENT uploads, including:

- many previously present YTD Reservation IDs disappearing;
- status moving apparently backward (`Completed` → `Booked`);
- broad decreases/reversions in earning components;
- filename/asserted date older than the prior CURRENT snapshot;
- a high percentage of rows matching an older historical revision instead of the current revision.

Such checks may require operator acknowledgement, but they must not masquerade as proof of source ordering.

### HISTORICAL_BACKFILL mode

Historical/backfill artifacts:

- are preserved and processed;
- may create previously unseen historical reservations;
- may add historical source observations;
- never advance the current source pointer over an already accepted newer CURRENT observation.

This makes freshness a recorded business assertion instead of an unsafe inference from upload timestamp.

---

## 13. ImportBatch state machine, quarantine policy, and atomic apply

### 13.1 Minimal state machine

```text
Received
  ↓
ArtifactValidated
  ↓
Parsed
  ↓
Normalized
  ↓
Validated
  ├──────────────→ BatchQuarantined
  ↓
ReadyToApply
  ↓
Applying
  ├──────────────→ ApplyFailed / ReconciliationFailed
  ↓
Reconciled
  or
ReconciledWithQuarantine
```

`RejectedArtifact` and `ParseFailed` remain terminal/retry-from-new-processing-attempt outcomes for artifact-level failures.

### 13.2 Quarantine semantics

The MVP distinguishes issue scope:

**Batch-blocking**
- missing/invalid Tenant context;
- missing SourceConnection;
- SourceConnection belonging to another Tenant;
- initiating actor not authorized to import/manage source data for that Tenant/SourceConnection;
- malformed/unrecognized artifact structure that prevents deterministic parsing;
- missing/duplicate required headers;
- conflicting duplicate Reservation IDs inside one artifact;
- schema ambiguity where deterministic field/component meaning is unknown;
- invalid CURRENT freshness assertion/required acknowledgement.

Tenant + SourceConnection + actor authorization are request/batch trust context, never row-local CSV data. They are validated before row apply eligibility is evaluated.

Result: no canonical/current-source apply for that batch until resolved/reprocessed.

**Row-blocking**
- invalid required identifier/date/money on one row;
- unresolved/invalid VIN or vehicle binding for one row;
- row-local financial reconciliation failure;
- row-local external binding conflict.

Result: quarantine only that row. Other valid rows may apply.

**Warning**
- odometer anomaly;
- later source null of a previously known operational value;
- guest/display-label changes;
- suspicious but explainable source regressions.

Result: row remains eligible to apply.

`ReadyToApply` means **no unresolved batch-blocking issue remains**; it does not require every row to be valid.

Final success state:

- `Reconciled` — all physical rows accounted for and no row remains quarantined;
- `ReconciledWithQuarantine` — valid rows applied atomically and one or more row-local quarantines remain explicitly outstanding.

### 13.3 CURRENT apply serialization

For the MVP, only one CURRENT apply may mutate provider-current/canonical state at a time for:

```text
Tenant + SourceConnection
```

The lock is intentionally **independent of import profile, profile version, parser version, and mapping version**, because those processors can all mutate the same ExternalReservationBinding/current-source pointers and canonical Reservations.

Use a transaction-scoped advisory lock or equivalent database serialization mechanism.

Within the lock, re-read current bindings/observations before comparing fingerprints. Do not rely on stale pre-lock reads.

### 13.4 Atomic apply contract

For the current 678-row scale, all **accepted** rows of one CURRENT batch are applied in one PostgreSQL transaction where practical.

The transaction includes:

- SourceObservation/source-component insertion for NEW/REVISED rows;
- linking UNCHANGED rows to the current observation;
- external binding creation/update under deterministic identity rules;
- canonical Reservation/Trip updates;
- current-source pointer advances;
- per-row apply outcomes;
- final structural and financial reconciliation needed to declare the batch successfully applied.

Row-local quarantined rows are excluded from the mutation set but remain accounted for in the batch.

If any unexpected apply/reconciliation failure occurs:

- roll back the whole apply transaction;
- no accepted row from that attempt may leave a partially advanced current pointer/canonical projection;
- persist `ApplyFailed` or `ReconciliationFailed` in a separate recovery-safe status update;
- retry uses the same ProcessingIdentity and re-executes idempotently.

### 13.5 Crash recovery

If the process crashes after setting `Applying` but before commit:

- the database transaction rolls back;
- a stale `Applying` batch is operator/worker-visible;
- recovery reacquires the same tenant/source-connection lock, re-checks whether a successful processing result already exists, then retries idempotently;
- duplicate SourceObservation revision sequences/current-pointer advances are forbidden.

Artifact/raw-row preservation occurs before apply and is not rolled back with canonical apply.

### 13.6 HISTORICAL_BACKFILL concurrency

Backfill may create missing historical entities/observations but may not move current pointers backward. It uses the same tenant/source-connection identity and reservation-binding serialization when touching a binding so it cannot race unsafely with CURRENT apply.

---

## 14. Validation rules

### 14.1 Blocking artifact/schema validation

Reject/quarantine before canonical apply if:

- required header missing
- duplicate header
- unknown replacement schema that prevents deterministic mapping
- malformed CSV structure
- duplicate Reservation ID with conflicting rows inside the same artifact
- parser cannot deterministically interpret a required identifier/date/money value

New extra source columns should trigger schema-drift review and preservation rather than being silently discarded.

Schema drift policy is fail-closed for semantic mapping:

- an extra unknown **non-monetary** column is preserved and reported; CURRENT apply may proceed only if the approved profile explicitly allows unknown non-semantic columns;
- an extra unknown **monetary/economic** column, especially one with any non-zero value, is batch-blocking until mapped/versioned;
- a known zero-valued component becoming non-zero is valid if its semantics are already mapped (for example a previously unused Turo fee column).

### 14.2 Blocking row validation

A row is quarantined if:

- Reservation ID blank/invalid for approved profile
- Vehicle id blank/invalid
- VIN blank/invalid
- Vehicle id conflicts with an existing binding to a different VIN
- Trip start/end cannot be parsed
- Trip end precedes Trip start
- Trip status not in approved mapping
- any required monetary cell cannot be parsed
- source monetary reconciliation fails
- vehicle cannot be resolved under the approved migration rule

### 14.3 Warning/non-blocking validation

Examples:

- odometer missing for Completed trip
- check-out < check-in
- `Distance traveled != check-out - check-in`
- later source null where previous observation had a non-null odometer
- guest display name changed
- free-form Vehicle label changed while Vehicle id/VIN remain stable
- positive discount amount
- an unusual source component becomes non-zero for the first time

The current artifact contains four odometer arithmetic anomalies. Those should surface as warnings, not cause loss of otherwise-valid financial/history import.

### 14.4 Status-aware validation

Observed source behavior means null odometers are normal for many statuses:

| Status | Rows | Check-in populated | Check-out populated | Distance populated |
|---|---:|---:|---:|---:|
| Completed | 491 | 488 | 392 | 390 |
| Guest cancellation | 137 | 4 | 0 | 0 |
| In-progress | 9 | 9 | 0 | 0 |
| Booked | 39 | 1 | 0 | 0 |
| Host cancellation | 2 | 0 | 0 | 0 |

Therefore odometer nullability must not be modeled simply as “required if Completed.”


### 14.5 Tenant authorization and isolation

Every artifact, batch, raw row, issue, external binding, source observation, and canonical command is created and processed under one immutable Tenant context.

Requirements:

- immutable Tenant + SourceConnection + actor authorization is validated before an ImportBatch is allowed to parse/normalize/apply against that SourceConnection;
- the initiating actor must be authorized to import/manage source data for that Tenant;
- SourceConnection must exist and belong to the same Tenant;
- failure of any of the above is **BATCH_BLOCKING**, applies zero rows, and cannot degrade into row quarantine;
- VIN/Vehicle/Listing/Reservation resolution is tenant-bounded;
- no lookup falls back to a global VIN, external Vehicle ID, or Reservation ID match across tenants;
- background workers carry explicit Tenant ID and use the same tenant-isolation/RLS contract as request processing;
- privileged cross-tenant maintenance is separate and audited.

### 14.6 Untrusted CSV and resource controls

The CSV is untrusted input.

MVP server-side configurable maxima, with these initial defaults:

```text
max file size       25 MiB
max data rows       50,000
max columns         256
max field length    64 KiB
```

The parser should stream rather than load arbitrarily large files into memory.

Rules:

- CSV content is never executed as formulas/code;
- preserved raw source is never mutated/sanitized to make it "safe";
- durable logs/issues use redacted values;
- any future CSV/XLSX export or spreadsheet-oriented preview must escape formula-injection prefixes (`=`, `+`, `-`, `@`) as literal text at the rendering/export boundary without changing stored raw data;
- oversized artifacts/rows/fields fail before canonical apply with deterministic issue codes.


---

## 15. Reconciliation rules

Reconciliation occurs before a batch is considered complete.

### 15.1 Structural reconciliation

Verify:

- source artifact row count
- parsed raw-row count
- normalized-row count
- `NEW` count
- `UNCHANGED` count
- `REVISED` count
- `QUARANTINED` count
- parse-level `REJECTED` count

And:

```text
normalized rows + parse-level REJECTED rows
    == physical source rows

NEW + UNCHANGED + REVISED + QUARANTINED
    == normalized rows
```

These are the exact row-outcome names used in the batch report and persistence contract; do not introduce parallel terms such as `accepted` or `no-op`.

### 15.2 Reservation reconciliation

For this source profile:

- Reservation IDs must be unique inside a valid batch.
- Every normalized row with outcome `NEW`, `UNCHANGED`, or `REVISED` must resolve to exactly one external Turo Reservation reference.
- No `NEW`, `UNCHANGED`, or `REVISED` row may create a duplicate canonical Reservation for the same SourceConnection-scoped Turo Reservation ID.

### 15.3 Financial row reconciliation

For each row:

```text
sum(all individual monetary components) == Total earnings
```

to the cent.

The supplied file passes this rule for all 678 rows.

### 15.4 Batch financial reconciliation

Aggregate:

- each individual component
- Total earnings

from:

1. normalized source rows with outcome `NEW`, `UNCHANGED`, or `REVISED`,
2. applied current Turo source observations for those SourceConnection-scoped Reservation IDs.

The batch must explain differences caused by:

- unchanged overlapping rows,
- revised rows,
- quarantined rows,
- historical rows prevented from superseding newer observations.

Do **not** compare additive totals from two overlapping exports as if both were independent earnings periods.

### 15.5 Source financial-completeness proof

Import apply status and downstream financial source completeness are different contracts.

`ReconciledWithQuarantine` remains a successful source-ingestion/apply state: valid rows are committed and row-local invalid rows remain explicitly quarantined. That batch status alone must **not** be interpreted as either financially complete or financially incomplete for every Vehicle.

The import boundary therefore exposes one provider-neutral read/output contract:

```text
SourceFinancialCompletenessProofV1(
    TenantId,
    SourceConnectionId,
    VehicleId,
    CutoffAt
)
```

`CutoffAt` is supplied by the downstream caller. Import does not define statement periods, investor recognition policy, management agreements, or investor allocation. The proof uses only the approved provider→canonical economics mapping and import-owned source/provenance state to determine whether an unresolved source issue can be proven irrelevant to the requested Vehicle/cutoff.

Minimum proof output:

```text
proof_version = SOURCE_FINANCIAL_COMPLETENESS_V1

scope
  tenant_id
  source_connection_id
  vehicle_id
  cutoff_at

effective_current_provider_snapshot
  source_artifact_id
  source_snapshot_id?                 // provider watermark if one exists later
  source_snapshot_observed_at?
  current_asserted_at
  current_asserted_by

applicable_processing
  import_batch_id
  processing_identity_hash
  import_mode = CURRENT
  profile_version
  parser_version
  mapping_version
  batch_state                         // Reconciled | ReconciledWithQuarantine

status                                // COMPLETE | INCOMPLETE | UNKNOWN
unresolved_blockers[]
reviewed_dispositions[]
proof_hash
computed_at                           // informational; excluded from proof_hash
```

The proof binds to both:

1. **provider snapshot identity/ordering position**, and
2. the **processing identity** that produced the effective source/canonical state.

Reprocessing the same provider snapshot under a corrected deterministic processor can therefore change the applicable ProcessingIdentity without pretending that Turo emitted a newer provider snapshot.

#### Completeness blocker set

The proof must consider unresolved conditions that could omit or incorrectly remove canonical financial source facts for the requested scope, including at least:

```text
QUARANTINED_FINANCIAL_ROW
RESERVATION_DISAPPEARANCE_REVIEW_REQUIRED
FINANCIAL_REGRESSION_REVIEW_REQUIRED
FINANCIAL_RECONCILIATION_UNRESOLVED
SOURCE_SCOPE_UNRESOLVED
```

Examples:

- a row-local invalid/blank money value that quarantines a reservation;
- a reservation present in the prior effective YTD snapshot but absent from the newly asserted CURRENT YTD snapshot;
- a suspicious financial/status regression whose accepted meaning is still under review;
- an unresolved reconciliation condition that means the accepted source set may omit economic facts;
- an unresolved row/issue whose Vehicle/cutoff relationship cannot be determined safely.

Operational-only warnings such as an odometer arithmetic anomaly do not block source financial completeness unless the provider→canonical economic mapping makes the issue financially relevant.

#### Scope-local evaluation

A blocker does not automatically poison every Vehicle.

For each unresolved item, the proof builder must deterministically classify its relation to the requested scope:

```text
IN_SCOPE
OUT_OF_SCOPE
UNKNOWN
```

Rules:

- if the row/previous binding deterministically resolves to Vehicle A, it does not block Vehicle B;
- if the issue can be deterministically proven unable to affect a canonical `ReservationEconomicSnapshot` through the requested cutoff under the approved provider→canonical mapping, it is `OUT_OF_SCOPE`;
- if Vehicle or cutoff relevance cannot be proven either way because required source fields/bindings are invalid or missing, it is `UNKNOWN`;
- `UNKNOWN` is fail-closed for Finance; uncertainty is not treated as absence.

This is deliberately provider-neutral. Import determines only whether source data can safely support canonical economics for the requested scope. It does not decide whether a component is feeable, which investor owns it, how a management agreement treats it, or whether it belongs in a statement.

#### Reviewed deterministic dispositions

An unresolved source-completeness issue may stop blocking only through a deterministic resulting source state or an explicit reviewed disposition with immutable provenance.

Minimum disposition record:

```text
issue_id
resolution_code
resolved_scope
resulting_source_observation_id?
resulting_import_batch_id?
reviewed_by?
reviewed_at?
evidence/provenance reference?
```

Initial resolution codes are intentionally narrow:

```text
REPROCESSED_ACCEPTED
KEEP_PRIOR_CURRENT_OBSERVATION_CONFIRMED
ACCEPT_CURRENT_REGRESSION_CONFIRMED
DETERMINISTICALLY_OUT_OF_SCOPE
```

Rules:

- malformed/unparseable financial data cannot be cleared by a free-text acknowledgement; it requires accepted deterministic source data/reprocessing;
- disappearance/regression review may explicitly preserve the prior current observation or accept the newly validated current state, with auditable reviewer/provenance;
- a free-text note by itself never changes completeness;
- every disposition included in the proof must identify the exact issue and resulting authoritative source lineage.

#### Completeness state

`COMPLETE` means all of the following are true for the requested scope:

1. the effective CURRENT provider snapshot identity is established;
2. the applicable CURRENT ImportBatch/ProcessingIdentity is established;
3. source structural/financial reconciliation required by this contract succeeded;
4. every potentially relevant quarantined/disappeared/regressed/reconciliation issue is either deterministically out of scope or has an accepted reviewed disposition;
5. no unresolved `IN_SCOPE` or `UNKNOWN` completeness blocker remains.

`INCOMPLETE` means at least one known `IN_SCOPE` blocker remains.

`UNKNOWN` means the system cannot deterministically prove whether one or more unresolved issues are outside the requested Vehicle/cutoff or cannot establish the required effective snapshot/processing identity.

Downstream Finance must require `COMPLETE`; both `INCOMPLETE` and `UNKNOWN` are non-current/blocking inputs.

The proof hash is deterministic over the version, scope, effective provider-snapshot identity, applicable ProcessingIdentity, sorted unresolved blockers, and sorted reviewed dispositions. Timestamps such as `computed_at` and display text are excluded. The same authoritative source state therefore produces the same proof hash/status.

This proof is the **only new owned output contract** introduced by complete-MVP CRIT-01. It does not make Import responsible for Finance Refresh, investor calculations, statement issue, operating-cost completeness, or generic accounting completeness.

---

## 16. Error handling and quarantine

### Row outcome categories

```text
NEW
UNCHANGED
REVISED
QUARANTINED
REJECTED
```

Issue scope is explicit: `WARNING`, `ROW_BLOCKING`, or `BATCH_BLOCKING`. A row-local quarantine does not imply whole-batch quarantine.

### Error record must include

- ImportBatch
- source filename/hash
- source row number
- Reservation ID when parseable
- Vehicle id/VIN when parseable
- error code
- severity
- field
- redacted raw source value when safe/needed (never an indefinite PII copy)
- redacted normalized value if available
- deterministic explanation
- whether canonical apply was blocked
- resolution/override provenance if later resolved

### Example error codes

```text
TURO_SCHEMA_MISMATCH
TURO_DUPLICATE_RESERVATION_IN_FILE
TURO_INVALID_RESERVATION_ID
TURO_INVALID_VEHICLE_ID
TURO_INVALID_VIN
TURO_VEHICLE_ID_VIN_CONFLICT
TURO_UNKNOWN_STATUS
TURO_INVALID_DATETIME
TURO_INVALID_MONEY
TURO_TOTAL_EARNINGS_MISMATCH
TURO_ODOMETER_INCONSISTENT
TURO_OPERATIONAL_VALUE_REGRESSED_TO_NULL
TURO_OLDER_SOURCE_OBSERVATION
TURO_UNKNOWN_ECONOMIC_COLUMN
TURO_SOURCE_CONNECTION_MISMATCH
TURO_CURRENT_ASSERTION_REQUIRED
IMPORT_FILE_TOO_LARGE
IMPORT_ROW_LIMIT_EXCEEDED
IMPORT_FIELD_TOO_LARGE
IMPORT_CONCURRENT_CURRENT_APPLY
```

A quarantined row must remain visible and reprocessable after deterministic resolution. Never “fix” raw source data in place. Authorized troubleshooting during the PII retention horizon may follow the issue reference to the encrypted raw row; durable issue/log text remains redacted.

---

## 17. Historical imports versus incremental imports

### Historical/backfill mode

Purpose:
- ingest older exports to build history.

Rules:
- preserve every artifact and source observation;
- create canonical reservations that do not yet exist;
- if a historical observation is older than the current known observation for the same Reservation ID, retain it as history but do not let it overwrite the current Turo projection;
- warnings may be tolerated for incomplete historical operational fields;
- financial row reconciliation remains mandatory.

### Incremental/current-snapshot mode

Purpose:
- repeatedly import newly downloaded **YTD Turo snapshots**.

Rules:
- overlap with earlier imports is expected, often across most of the file;
- an authorized CURRENT assertion allows the batch to supersede the prior current snapshot for the SourceConnection;
- latest accepted source observation wins for mutable Turo-derived reservation/earning snapshot fields;
- unchanged Reservation IDs are no-ops;
- changed Reservation IDs create revisions;
- newly appearing Reservation IDs create new source/canonical records;
- reservations no longer present in a later YTD export are flagged for investigation rather than automatically deleted or cancelled; absence is not a deletion event;
- no duplicate reservations;
- no additive duplicate earnings;
- late gas/toll/ticket reimbursements revise the same reservation's earning component snapshot;
- changes are surfaced in reconciliation/audit output.

### Rebuild/replay scope

Before source-PII purge, a controlled replay may use the retained exact source observations to regenerate the full Turo-derived projection permitted by current mapping rules.

After source-PII purge, replay is intentionally narrower:

- retained non-PII provider economics, identifiers, hashes, and approved derived/provenance fields can be replayed/reconciled;
- purged guest/source-location PII cannot be reconstructed and must remain unavailable;
- issued calculations/statements remain reproducible from their retained economic snapshots and pinned versioned inputs;
- if a long-lived economic rule requires a derived location classification (for example an approved airport/non-airport classification), persist that approved non-PII derived rule input separately rather than retaining the raw address indefinitely.

This privacy limitation is intentional and is not a reason to retain source PII forever.

---

## 18. Representative transformed example — CR-V

Actual source row: Reservation `47612193`.

### Raw Turo values

```yaml
Reservation ID: "47612193"
Guest: "Gary L."
Vehicle: "#3 CR-V CSJ1646 (WA #CSJ1646)"
Vehicle name: "Honda CR-V 2025"
Vehicle id: "3148718"
VIN: "2HKRS4H21SH443987"
Trip start: "2026-02-27 03:00 PM"
Trip end: "2026-03-13 04:00 PM"
Pickup location: "17801 International Boulevard, Seattle, WA 98158"
Return location: "17801 International Boulevard, Seattle, WA 98158"
Trip status: "Completed"
Check-in odometer: "23997"
Check-out odometer: "24866"
Distance traveled: "869"
Trip days: "15"
Trip price: "$771.30"
2-week discount: "- $154.26"
Delivery: "$27.00"
Tolls & tickets: "$296.80"
Total earnings: "$940.84"
```

All omitted monetary source components on this row are `$0.00` and must still exist in the normalized component set.

### Normalized boundary object

```json
{
  "source": "Turo",
  "externalReservationId": "47612193",
  "guestDisplayName": "Gary L.",
  "vehicle": {
    "externalVehicleId": "3148718",
    "vin": "2HKRS4H21SH443987",
    "sourceVehicleLabel": "#3 CR-V CSJ1646 (WA #CSJ1646)",
    "sourceVehicleName": "Honda CR-V 2025"
  },
  "reservation": {
    "startLocal": "2026-02-27T15:00:00",
    "endLocal": "2026-03-13T16:00:00",
    "pickupLocationRaw": "17801 International Boulevard, Seattle, WA 98158",
    "returnLocationRaw": "17801 International Boulevard, Seattle, WA 98158",
    "sourceStatus": "Completed",
    "sourceTripDays": 15
  },
  "tripObservation": {
    "checkInOdometerMiles": 23997,
    "checkOutOdometerMiles": 24866,
    "distanceTraveledMiles": 869
  },
  "earnings": {
    "currency": "USD",
    "tripPrice": "771.30",
    "twoWeekDiscount": "-154.26",
    "delivery": "27.00",
    "tollsAndTickets": "296.80",
    "totalEarnings": "940.84"
  }
}
```

Reconciliation:

```text
771.30 - 154.26 + 27.00 + 296.80 = 940.84
```

---

## 19. Acceptance tests

### Artifact and parsing

1. **Exact source file**
   - Given the supplied CSV,
   - when parsed with this profile,
   - then 678 data rows and 47 named columns are recognized.

2. **Artifact hash**
   - SHA-256 equals `186ab6189a4659129ff47b4c444049a3275c4fb15dd16c9271c29c604c813dde`.

3. **All source columns captured**
   - During the approved PII-retention horizon, all 47 original values are recoverable, including currently-zero columns.
   - After purge, long-lived redacted/minimized provenance and all source economic components remain while guest-identifying raw values are intentionally unavailable.

4. **Unknown/missing header**
   - Missing a required source column prevents apply.
   - A new extra column is preserved and surfaces schema drift; it is never silently dropped.

### Identity

5. **Reservation key**
   - Reservation `47612193` imports with external key exactly `"47612193"`.

6. **CR-V vehicle resolution**
   - Turo Vehicle id `3148718` + VIN `2HKRS4H21SH443987` resolve to the CR-V canonical vehicle/listing binding.

7. **Vehicle display not identity**
   - Changing only the free-form `Vehicle` label does not create a new canonical Vehicle if Vehicle id/VIN binding is unchanged.

8. **Vehicle conflict**
   - Existing Turo Vehicle id mapped to VIN A followed by the same Vehicle id with VIN B quarantines the row.

### Dates and statuses

9. **Strict datetime**
    - `"2026-02-27 03:00 PM"` parses to local `2026-02-27T15:00:00`.
    - Unsupported format fails deterministically.

10. **Trip days**
    - Reservation `47612193` validates 15 source trip days against its start/end duration.

11. **Known statuses**
    - `Booked → CONFIRMED`.
    - `In-progress → IN_PROGRESS`.
    - `Completed → COMPLETED`.
    - `Guest cancellation → CANCELLED + GUEST`.
    - `Host cancellation → CANCELLED + HOST`.
    - An unknown status is not guessed.

### Money

12. **Negative money**
    - `"- $154.26"` parses to decimal `-154.26`.

13. **CR-V row reconciliation**
    - Reservation `47612193` reconciles to `$940.84`.

14. **Whole-file financial reconciliation**
    - Every supplied row passes component-sum-to-total validation.

15. **Malformed monetary cell**
    - Invalid/blank required money text quarantines the row; it does not become zero.

### Idempotency

16. **Same artifact twice**
    - Importing the exact CSV twice creates no duplicate canonical Reservations or duplicate Turo earnings.

17. **Same Reservation unchanged in overlapping export**
    - Same provider semantic fingerprint within the same SourceConnection produces an `Unchanged` outcome and no canonical financial mutation.

18. **Same Reservation changed**
    - An updated row creates a source revision and updates the current Turo-derived snapshot without creating a second Reservation.

19. **CR-V financial revision**
    - Reservation `55126068` can move from the older workbook-observed source state to the newer CSV source state, and the newer Turo earnings snapshot replaces the older current source snapshot rather than being added to it.

20. **Older historical import**
    - An older observation imported after a newer observation is retained for history but does not supersede the newer current observation without explicit override/rebuild semantics.

### Operational-data conflict behavior

21. **Later odometer fill**
    - Prior null check-out plus newer non-null check-out fills the canonical Turo-derived operational fact.

22. **Later source null**
    - Prior accepted non-null check-out plus newer blank source value preserves the new source observation but does not automatically erase the canonical non-null value.

23. **Odometer inconsistency**
    - The four supplied arithmetic-anomaly rows produce warnings and remain importable if all blocking identity/financial checks pass.

### Reconciliation and errors

24. **Counts**
    - Batch report accounts for every physical row exactly once.

25. **Quarantine**
    - A quarantined row retains row number, error code, provenance, and its encrypted raw values during the approved retention horizon; long-lived diagnostics remain redacted.
    - It can be reprocessed after deterministic resolution.

26. **No silent correction**
    - The importer never edits raw source values to make them pass validation.

27. **Deterministic replay**
    - Re-running the same artifact with the same parser/mapping/profile versions produces identical normalized provider semantic fingerprints and row classifications, assuming the same pre-existing canonical/source-observation state.

### R1 review closure — identity, failure, concurrency, privacy, and edge behavior

28. **CURRENT freshness is not upload-time inference**
    - Upload an older YTD artifact after a newer accepted snapshot.
    - A later `received_at` alone must not make the artifact newer.
    - CURRENT application requires explicit authorized current-snapshot assertion; suspicious regression signals are surfaced.

29. **Concurrent CURRENT imports serialize across profiles**
    - Start two CURRENT applies for the same Tenant + SourceConnection using different import profiles/profile versions.
    - Exactly one provider-current mutation transaction holds the `Tenant + SourceConnection` lock at a time.
    - Final current pointers/revision sequences are deterministic with no duplicate economic projection.

30. **Crash mid-apply rolls back**
    - Inject failure after a subset of accepted rows have executed inside the apply transaction.
    - No accepted row's canonical/current-pointer mutation remains committed.
    - Retry produces exactly one final applied state.

31. **Row quarantine does not block valid rows**
    - One row has invalid money while all other rows are valid.
    - The invalid row is `ROW_BLOCKING/Quarantined`.
    - Valid rows apply atomically.
    - Batch ends `ReconciledWithQuarantine`.

32. **Batch-blocking ambiguity applies nothing**
    - Two conflicting rows have the same Reservation ID inside one artifact.
    - Batch is blocked; no accepted canonical/current-source mutations occur.

33. **Same artifact under new processor version**
    - Reprocess identical bytes with a newer parser/mapping version.
    - A new ProcessingIdentity is allowed.
    - If normalized semantics are unchanged, no new provider SourceObservation revision is created.
    - If corrected processor semantics differ, provenance marks a processor correction rather than pretending Turo emitted a new artifact.

34. **Semantic fingerprint excludes processing state**
    - Changing validation warnings, canonical Vehicle UUID, batch ID, actor, or parser metadata without changing provider semantics does not change the provider semantic fingerprint.

35. **Semantic fingerprint detects source change**
    - Changing any mapped earning component, status, schedule, provider identifier/vehicle metadata, operational source field, or retained PII-sensitive source value changes equality under the approved privacy-safe fingerprint contract.

36. **A → B → A creates chronological revision**
    - Import source state A, then B, then a newer explicitly accepted CURRENT snapshot returning to A.
    - The final A creates a new revision superseding B; it is not deduped against the older A revision.

37. **DST ambiguous/nonexistent time**
    - A source local time falling into a DST ambiguity or gap fails deterministically under the configured timezone policy; the importer never silently chooses an arbitrary instant.

38. **Reservation disappears from later YTD export**
    - Missing Reservation ID is reported as snapshot regression/investigation signal.
    - Existing Reservation/current source observation is not deleted or cancelled automatically.

39. **Unknown monetary schema drift**
    - A new unknown monetary column with non-zero data is batch-blocking until mapping/profile version is updated.
    - A known mapped component changing from all-zero historical usage to non-zero remains valid.

40. **PII retention purge**
    - After retention expiry, guest-identifying raw artifact/row data is no longer retrievable.
    - Artifact hash, provider IDs, source economic components, redacted provenance, canonical economics, calculations, and issued-statement reproducibility remain.

41. **Cross-tenant isolation**
    - A Tenant A import cannot resolve or bind Tenant B's Vehicle, Listing, SourceConnection, Reservation, raw row, or source observation even when VIN/provider IDs are identical.

42. **SourceConnection identity scope**
    - Two SourceConnections in the same Tenant may contain the same external Reservation ID without collision.
    - Idempotency/current-revision comparison occurs within each SourceConnection.

43. **CSV formula-injection fixture**
    - Untrusted text beginning with `=`, `+`, `-`, or `@` remains preserved as raw source.
    - Logs/previews/exports treat it as literal text and never execute it.

44. **Resource-limit rejection**
    - Oversized file/row/field is rejected deterministically before canonical apply.

45. **Issued statement is not rewritten**
    - A later Turo source revision updates live/unissued current economics.
    - An already issued/paid statement remains pinned to its exact historical source/calculation revisions until an explicit finance restatement/adjustment workflow occurs.

### R2 convergence closure

46. **Historical processor correction does not advance provider current**
    - Import provider snapshot A as CURRENT.
    - Import newer provider snapshot B as CURRENT so B is effective current.
    - Reprocess old artifact A under a corrected parser/mapping that changes normalized semantics.
    - Corrected A preserves correction lineage at A's provider chronology position.
    - B remains the provider-current observation and current canonical state is not rolled back.

47. **Current processor correction replaces effective normalized state exactly once**
    - Provider snapshot B is the currently effective snapshot.
    - Reprocess B under a corrected deterministic processor and produce materially corrected normalized semantics.
    - The correction atomically replaces the effective normalized/current observation for B's provider-snapshot position exactly once.
    - No fictional newer Turo snapshot is created.
    - Repeating the identical correction is idempotent.

48. **Same bytes processed under two SourceConnections**
    - One Tenant has SourceConnection A and SourceConnection B.
    - The exact same artifact bytes resolve to one connection-agnostic SourceArtifact identity.
    - Separate ImportBatch/ProcessingIdentity records preserve A versus B attribution.
    - Provider Reservation/Listing bindings and current mutations remain isolated by SourceConnection.

49. **Tenant/SourceConnection trust-context failure is batch-level**
    - Missing SourceConnection, foreign-Tenant SourceConnection, or unauthorized actor produces a `BATCH_BLOCKING` failure.
    - Zero rows are eligible/applied.
    - The failure cannot be represented as row-local quarantine.

50. **Post-purge replay does not reconstruct PII**
    - After source-PII purge, replay/reconciliation can regenerate retained economic/provenance projections.
    - Purged guest names/raw source addresses are not recreated.
    - Issued statement economics remain reproducible.

51. **Structural reconciliation uses one row-outcome vocabulary**
    - Batch reports contain only `NEW`, `UNCHANGED`, `REVISED`, `QUARANTINED`, and parse-level `REJECTED`.
    - Reporting does not invent separate `accepted`/`no-op` categories.

### Complete-MVP CRIT-01 source financial-completeness closure

52. **Invalid-money quarantine blocks only the affected Vehicle scope**
    - A CURRENT cumulative export contains one reservation for Vehicle A with invalid required money while all other rows are valid.
    - Valid rows apply atomically and the batch may end `ReconciledWithQuarantine`.
    - `SourceFinancialCompletenessProofV1` for Vehicle A through a cutoff that could include the reservation is `INCOMPLETE` and identifies the quarantined reservation/issue.
    - Import remains successful; no Finance Refresh behavior is executed by Import.

53. **Resolve/reprocess quarantined reservation**
    - The invalid financial source row is resolved through accepted deterministic source data/reprocessing without editing the original raw evidence.
    - The applicable ProcessingIdentity/resulting source lineage advances deterministically.
    - The prior blocker is represented by accepted resolution provenance.
    - The same Vehicle/cutoff proof becomes `COMPLETE` when no other blocker remains.

54. **Quarantine isolated to another Vehicle**
    - A `ReconciledWithQuarantine` CURRENT batch has one financially relevant quarantined row deterministically bound only to Vehicle B.
    - Vehicle A has no other in-scope/unknown blockers.
    - Vehicle A proof may be `COMPLETE`.
    - Vehicle B proof is `INCOMPLETE`.
    - Batch status alone is never used as a global completeness boolean.

55. **Reservation disappearance/regression remains in completeness proof**
    - A previously current reservation for Vehicle A disappears from a later asserted CURRENT YTD snapshot, or a financially relevant regression is awaiting review.
    - The import comparison issue remains visible in `unresolved_blockers` for Vehicle A when relevant to the requested cutoff.
    - Existing prior source facts are not silently deleted merely to make the proof complete.
    - Finance cannot receive `COMPLETE` until deterministic reprocessing or an allowed reviewed disposition resolves the issue.

56. **Completeness replay/idempotency**
    - Recompute `SourceFinancialCompletenessProofV1` twice for the same Tenant + SourceConnection + Vehicle + cutoff and identical authoritative provider snapshot/ProcessingIdentity/issues/dispositions.
    - Status, blocker set, disposition set, and `proof_hash` are identical.
    - `computed_at` does not affect `proof_hash`.

---

## 20. Minimum operational observability and recovery contract

The MVP exposes enough operational state to safely diagnose import failures without reading raw PII.

Minimum metrics/reporting:

- batch state and duration;
- counts: physical / parsed / new / unchanged / revised / quarantined / rejected;
- batch-blocking and row-blocking issue counts;
- schema-drift count;
- reconciliation failure count;
- oldest unreconciled batch;
- stale `Applying` batch age/count;
- quarantine backlog count by source connection;
- source financial-completeness blocker counts by SourceConnection/Vehicle and blocker code;
- CURRENT assertion actor/time and source snapshot asserted time when present.

Recovery rules:

- `ParseFailed` / `BatchQuarantined`: fix profile/input/mode decision, then create/retry a deterministic processing attempt; no canonical apply has occurred.
- `ApplyFailed`: canonical/current-pointer transaction was rolled back; reacquire the `Tenant + SourceConnection` lock and retry the same ProcessingIdentity idempotently.
- stale `Applying`: verify no successful processing result already committed, then safely retry under the same lock.
- `ReconciliationFailed`: treat as unapplied because final apply/reconciliation transaction rolls back; investigate deterministic mismatch before retry.
- `ReconciledWithQuarantine`: applied state is valid for accepted rows; quarantined rows remain outstanding and must not be silently discarded.

First operator-visible signal for a failed import is the ImportBatch state plus redacted structured ImportIssues; no raw PII is required in routine telemetry.


---

## 21. MVP implementation boundary

The MVP Turo importer should implement only:

```text
Turo SourceConnection + authorized Tenant context
    -> TuroTripEarningsCsvProfile
    -> retention-governed artifact preservation
    -> strict CSV parser
    -> source row capture
    -> deterministic normalization
    -> vehicle resolution
    -> validation
    -> source-observation comparison/revision
    -> processor-correction chronology handling
    -> serialized/atomic CURRENT apply at Tenant + SourceConnection scope
    -> canonical Reservation/Trip source commands
    -> Turo earnings component snapshot
    -> reconciliation + quarantine report
    -> provider-neutral SourceFinancialCompletenessProofV1 read/output contract
```

Use a small profile/adapter interface so another Turo/export format can be added later, but do not build a generic no-code ETL/mapping system now.

The execution path contains no LLM.

---

## 22. Decisions

### Decision — Turo reservation identity is scoped by SourceConnection

**Decision:** Use `Tenant + SourceConnection + external Reservation ID` as the provider reservation identity.

**Rationale:** Reservation ID is unique and stable in the supplied export/workbook evidence, but the evidence does not prove provider-global uniqueness across multiple Turo host accounts. SourceConnection avoids a foundational key migration.

**Tradeoff:** Adds one integration-scope concept even though the Seattle MVP initially uses one Turo connection.

**Revisit if:** Never remove the scope; a future provider-global UUID may become an additional binding key.

### Decision — VIN resolves Vehicle; Turo Vehicle id represents the Turo-side vehicle/listing identity

**Rationale:** Physical vehicle identity and marketplace identity are different concepts. The current file supplies both with a 1:1 mapping.

**Tradeoff:** Requires explicit handling if a Turo listing is recreated for the same VIN.

**Revisit if:** Turo API semantics prove `Vehicle id` means something different than the export suggests.

### Decision — Every import row is a mutable source snapshot, not an additive financial transaction

**Rationale:** The workbook/current-CSV comparison proves values for the same Reservation ID change.

**Tradeoff:** Downstream finance logic must process revisions/deltas rather than naive append-only earnings rows.

**Revisit if:** A future Turo transaction-level API provides immutable earning-event IDs.

### Decision — Latest source null does not erase prior accepted non-null operational facts automatically

**Rationale:** Current CSV contains blank check-out odometers where the workbook has values.

**Tradeoff:** Current canonical fact may intentionally differ from the latest raw Turo snapshot; provenance must make that explicit.

**Revisit if:** We establish that the workbook odometers were manually entered rather than previously sourced from Turo, or Turo documents null as an intentional correction/removal.

### Decision — Capture all 47 source columns under finite PII retention

**Rationale:** The investor workbook ignores many fields that are economically/operationally relevant and may become non-zero later. Source fidelity is required for reconciliation.

**Tradeoff:** Exact PII-bearing bytes/strings cannot remain readable forever; raw fidelity and privacy retention must coexist.

**Revisit if:** Never drop source economic/provenance fidelity. Retention policy may evolve, but exact readable PII remains policy-governed.


### Decision — CURRENT freshness is an explicit assertion

**Decision:** `received_at` never determines provider freshness. CURRENT apply requires an authorized assertion that the artifact is the newest snapshot for its SourceConnection unless a future provider watermark proves ordering.

**Rationale:** An old file uploaded later otherwise looks falsely newer.

**Tradeoff:** Human error remains possible; regression warnings/acknowledgement reduce but cannot eliminate it without provider metadata.

**Revisit if:** Turo exposes a trustworthy export sequence/watermark/API cursor.

### Decision — Accepted CURRENT rows apply atomically under one source-connection lock

**Decision:** Serialize CURRENT provider-state mutation per `Tenant + SourceConnection`, independent of profile/parser/mapping version, and use one transaction for all accepted rows at MVP scale.

**Rationale:** Prevent mixed current pointers/canonical state after crash or concurrent uploads.

**Tradeoff:** Longer transaction than per-row apply, acceptable for the current 678-row/near-term fleet scale.

**Revisit if:** Batch sizes grow enough that transaction duration/locking becomes operationally material; then move to checkpointed per-row application with explicit CAS/current-pointer semantics.

### Decision — SourceArtifact is connection-agnostic; processing attempts own SourceConnection context

**Decision:** `SourceArtifact` identity is `Tenant + SHA-256(bytes)` and contains connection-agnostic immutable blob/provenance. `ImportBatch` / ProcessingIdentity owns `SourceConnection`, mode, CURRENT assertion, and processor versions.

**Rationale:** The same bytes can be processed under different source accounts without mutating artifact metadata or weakening provider identity isolation.

**Tradeoff:** Artifact storage/provenance and processing attribution are separate concepts.

**Revisit if:** A future source legally/operationally requires source-account-specific byte retention; then retention/storage mechanics may split while preserving the conceptual distinction between artifact identity and processing attribution.

### Decision — Processor corrections preserve provider snapshot chronology

**Decision:** Corrected processing never changes the provider ordering position of the source snapshot being corrected. Historical corrections cannot advance current; correction of the effective current snapshot may replace that effective normalized representation under explicit correction provenance.

**Rationale:** `processed_at` is not provider freshness.

**Tradeoff:** Source revision history carries both provider chronology and processor-correction lineage.

**Revisit if:** Turo exposes immutable versioned source events that eliminate snapshot reprocessing ambiguity.

### Decision — Row-local quarantine allows partial batch success

**Decision:** Batch/schema ambiguity blocks the whole batch; row-local invalid data quarantines only that row. Valid rows may apply atomically and the batch ends `ReconciledWithQuarantine`.

**Rationale:** One malformed reservation should not block hundreds of valid YTD reservations when its failure is isolated and accounted for.

**Tradeoff:** The current YTD projection may temporarily omit quarantined reservations.

**Revisit if:** A future source requires cross-row invariants that make isolated application unsafe.

### Decision — Import apply success and source financial completeness are separate

**Decision:** Preserve `ReconciledWithQuarantine` as a valid source-ingestion outcome and expose `SourceFinancialCompletenessProofV1` per Tenant + SourceConnection + Vehicle + cutoff. Finance may treat source input as complete only when that proof is `COMPLETE`.

**Rationale:** Partial row quarantine is operationally valuable, but a financially relevant omitted reservation cannot be hidden behind a successful batch state or a fingerprint over only accepted rows.

**Tradeoff:** Import must retain/query enough issue, prior-snapshot, Vehicle-scope, reconciliation, and disposition provenance to produce a deterministic completeness proof.

**Revisit if:** A future provider supplies transaction-level immutable financial events with authoritative completeness/watermark semantics; the downstream proof may simplify, but apply success and financial completeness remain distinct concepts.

### Decision — Unknown VIN does not auto-create a Vehicle in MVP

**Decision:** A valid imported VIN with no approved canonical Vehicle is row-blocking/quarantined. Vehicle creation is an explicit authorized asset-management action.

**Rationale:** Prevents untrusted/imported source data from silently creating production assets and closes a deterministic implementation branch.

**Tradeoff:** Initial migration requires pre-creating/approving Vehicles before all rows can reconcile.

**Revisit if:** A dedicated migration workflow later supports reviewed draft-asset creation with explicit approval.

### Decision — Same bytes may be reprocessed under corrected deterministic processor versions

**Decision:** Artifact identity, ProcessingIdentity, and provider source revision are separate.

**Rationale:** Parser/mapping corrections must be replayable without fabricating a new Turo artifact/revision.

**Tradeoff:** More provenance concepts.

**Revisit if:** Never collapse them; future infrastructure may implement them differently.

---

## 23. Cross-context policy disposition and evidence caveat

The source-account, timezone, guest-identity, and Vehicle-creation decisions are resolved in this specification:

- provider identity is SourceConnection-scoped;
- the Seattle MVP Turo connection uses `America/Los_Angeles`;
- Guest display name remains a source snapshot only and does not create/merge canonical Customer identity;
- a valid unknown VIN does not auto-create a production Vehicle; the row is quarantined pending explicit Vehicle approval/creation.

### Finance-owned closed-period policy — resolved

Late reimbursement/source revisions after an investor statement has already been issued are **not an open Import question**.

The current canonical Finance policy is:

- issued statement history remains immutable;
- later same-owner applicable reservation economics use the deterministic next-open-statement signed `CLOSED_PERIOD_CORRECTION` path based on current target minus cumulative issued recognized economics;
- cross-owner changes use the Finance-owned `CrossOwnershipCorrection` workflow;
- full historical restatement remains deferred/manual.

Import does not implement any of those calculations or statement behaviors. It preserves the exact source revisions, current-source lineage, and source financial-completeness proof required for Finance to apply its current policy.

### Non-blocking evidence caveat

Some CR-V check-in/check-out odometer values in `Aaron 2026.xlsx` differ in completeness from the current Turo CSV. The files do not prove whether every workbook odometer was copied from an older Turo export or manually edited. The import rule therefore remains source-safe regardless: preserve each observation and never let a later null blindly erase an accepted non-null operational fact.

---

## 24. R2 panel-review resolution record

This section is the handoff to the R3 convergence review.

| R2 finding | Revision disposition |
|---|---|
| R2-A01 lock scope narrower than mutable state | **Plan addressed:** CURRENT mutation lock is exactly `Tenant + SourceConnection`, independent of profile/parser/mapping version; cross-profile concurrency test added. |
| R2-A02 processor correction chronology/current pointer undefined | **Plan addressed:** provider chronology and processing chronology are separate; historical corrections cannot advance current; current-snapshot corrections replace effective normalized state exactly once; tests added. |
| R2-D01 SourceArtifact vs SourceConnection ownership inconsistent | **Plan addressed:** SourceArtifact is `Tenant + SHA256` connection-agnostic blob/provenance; ImportBatch/ProcessingIdentity owns SourceConnection and assertions; same-bytes/two-connections test added. |
| SEC-004 trust context both batch- and row-blocking | **Plan addressed:** Tenant/SourceConnection/actor authorization is batch-level fail-closed only; removed from row validation; zero-row-apply negative test added. |
| M-01 post-purge full rebuild overpromised | **Plan addressed:** post-purge replay limited to retained non-PII economic/provenance projection; PII is intentionally non-reconstructible. |
| M-02 reconciliation vocabulary inconsistent | **Plan addressed:** exact `NEW/UNCHANGED/REVISED/QUARANTINED/REJECTED` vocabulary used. |
| Vehicle auto-creation decision open | **Decision closed:** unknown VIN does not auto-create Vehicle; row quarantines pending explicit approval/creation. |

### Security Findings Register entering R3

```text
SEC-001  RESOLVED — retention-governed raw source / PII purge
SEC-002  RESOLVED — tenant authorization and isolation
SEC-003  RESOLVED — untrusted CSV/resource/output controls
SEC-004  REVIEW FOR RESOLUTION — Tenant/SourceConnection context is batch-level fail-closed only
```

R3 resolved `SEC-004`; the final R3 register is recorded below and in the immutable R3 report.

### Complete-MVP package R1 focused resolution — pre-R3

The complete-MVP package review introduced one new cross-boundary blocker after the prior R2 import revision:

| Finding | Chat 06 disposition |
|---|---|
| CRIT-01 — `ReconciledWithQuarantine` can defeat Finance complete-input guarantee | **Addressed in Import:** preserve partial apply semantics; add `SourceFinancialCompletenessProofV1` with effective snapshot identity, ProcessingIdentity, scope-local unresolved blocker set, reviewed dispositions, deterministic status/hash, and required acceptance tests 52–56. |
| MIN-01 — closed-period reimbursement policy still described as unresolved | **Addressed:** import now points to Finance's immutable-issued-history + next-open correction policy; full restatement remains deferred/manual. |

### R3 convergence result

Chat 06 R3 was executed on 2026-09-25 after the required Chat 03 and Chat 05 synchronization completed.

Immutable report:

```text
/Projects/Fleet-Management/06-data-import/history/
panel-review-mvp-turo-import-spec__2026-09-25__r3.md
```

Result:

```text
Recommended decision: GREENLIGHT
Critical findings:     0
Significant findings:  0
Minor findings:        0
Human questions:       0
Security recommendation: CLEARED FOR IMPLEMENTATION
```

R3 verified the previously defined narrow convergence scope:

| R3 check | Result |
|---|---|
| prior R2 convergence items remain intact | **PASS** |
| `ReconciledWithQuarantine` remains a valid partial-apply source state | **PASS** |
| `SourceFinancialCompletenessProofV1` blocks relevant/unknown Vehicle+cutoff omissions | **PASS** |
| a quarantine provably isolated to Vehicle B does not block Vehicle A | **PASS** |
| disappearance/regression/reconciliation blockers cannot silently vanish from Finance eligibility | **PASS** |
| reviewed dispositions are finite/auditable and free text cannot clear malformed financial data | **PASS** |
| same authoritative source state produces the same completeness proof/hash | **PASS** |
| Import retains no Finance Refresh, investor-calculation, statement-issue, or generic-accounting authority | **PASS** |
| Chat 03 Domain Revision 8 and Chat 05 Finance Revision 9 are synchronized to the proof contract | **PASS** |
| no regression introduced by CRIT-01 / MIN-01 revision | **PASS** |

Final import Security Findings Register:

```text
SEC-001  RESOLVED — retention-governed raw source / PII purge
SEC-002  RESOLVED — tenant authorization and isolation
SEC-003  RESOLVED — untrusted CSV/resource/output controls
SEC-004  RESOLVED — Tenant/SourceConnection/actor trust context is batch-level fail-closed only
```

R3 is a design/convergence gate, not evidence that implementation-time PostgreSQL/API/E2E tests have already run.

No R4 is required unless triggered by a post-R3 material importer scope change, a newly discovered blocker/conflict, or explicit human request.
---

## 25. Handoff to other chats

### Chat 03 — Domain Model & PostgreSQL

**Synchronization completed:** canonical `mvp-domain-model.md` Revision 8 now defines the minimum persistence/provenance seam needed to derive `SourceFinancialCompletenessProofV1`, including `SourceCurrentSnapshotPointer`, completeness-aware `ImportIssue`, immutable `SourceFinancialCompletenessDisposition`, and deterministic proof status/hash.

The synchronized domain represents:

- connection-agnostic, Tenant-scoped SourceArtifact identity/provenance
- ImportBatch/processing ownership of SourceConnection, mode, CURRENT assertion, and processor versions
- SourceConnection-scoped provider identity
- raw rows with encrypted-retention + long-lived redacted form
- source observation revisions with separate provider chronology and processor-correction provenance/current-pointer rules
- exact semantic-fingerprint contract
- external Reservation reference scoped by SourceConnection
- Turo Vehicle-id/Listing reference scoped by SourceConnection
- VIN-based tenant-bounded Vehicle relation
- current versus historical source observations
- `Tenant + SourceConnection` atomic/current-pointer concurrency contract, independent of profile
- row-vs-batch quarantine/error state
- `SourceFinancialCompletenessProofV1` persistence/read-model inputs:
  - effective CURRENT provider snapshot reference
  - applicable ImportBatch / ProcessingIdentity
  - Vehicle+cutoff-scoped completeness blockers
  - disappearance/regression/reconciliation issue provenance
  - immutable reviewed dispositions
  - deterministic completeness proof hash/status

This document intentionally does not prescribe detailed tables. Domain Revision 8 keeps the proof derived from authoritative import state rather than creating a generic accounting-completeness subsystem.

### Chat 05 — Financial Ledger

**Synchronization completed:** canonical `mvp-investor-calculation-spec.md` Revision 9 consumes the Import-owned proof as an authoritative deterministic currentness input.

Finance owns economic interpretation and statement behavior; Import owns source completeness/provenance.

The synchronized downstream rule is:

```text
Finance source completeness requirement
    = every applicable source proof is COMPLETE

INCOMPLETE or UNKNOWN
    -> affected live economics cannot be CURRENT
    -> statement issue remains blocked
```

Finance must not reconstruct completeness by counting accepted `ReservationEconomicSnapshot` rows. It consumes the Import-owned proof and includes its version/hash/snapshot-processing lineage in the complete-input fingerprint.

Closed-period policy is already Finance-owned and resolved: issued history is immutable; same-owner later corrections use the next-open `CLOSED_PERIOD_CORRECTION` path; cross-owner changes use `CrossOwnershipCorrection`; full historical restatement remains deferred/manual.

This import spec guarantees deterministic source revisions/components, exact revision provenance, and source financial-completeness proof. It does not perform Finance Refresh or investor calculation.
