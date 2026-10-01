# MVP Investor Calculation Specification

**Project:** Rental Asset & Travel Platform  
**Artifact:** `mvp-investor-calculation-spec.md`  
**Canonical path:** `/Projects/Fleet-Management/shared/canonical/mvp-investor-calculation-spec.md`  
**Steward:** `05-financial-ledger` — Chat 05 — Financial Ledger, Accounting & Investors  
**Phase:** 05 — Financial Ledger, Accounting & Investors  
**MVP scope:** Replace the current investor-spreadsheet calculation and payment workflow with a deterministic, auditable investor-economic engine that also consumes canonical manager-incurred operating-cost facts and simple recurring-cost occurrences.  
**Not in MVP:** GAAP accounting, tax accounting, depreciation, lending, general-purpose bookkeeping, full double-entry accounting, bank reconciliation, vendor/AP workflows, tax engines/workpapers, fund waterfalls, or arbitrary investor classes.

**Revision:** 9  
**Previous revision:** 8 — Financial Platform Product Direction Section-18 synchronization  
**Revision status:** Focused complete-MVP package R1 synchronization for `CRIT-01` source financial completeness and `SIG-02` statement-issue compound authorization. This revision preserves the R1–R5 finance baseline and Revision-8 operating-cost/currentness design while consuming the Import-owned `SourceFinancialCompletenessProofV1`, freezing its exact lineage into successful live projections, and making statement draft/issue fail closed when source completeness or required nested authorization cannot be proven.  
**Last changed by:** `05-financial-ledger` — complete-MVP package R1 CRIT-01 / SIG-02 focused synchronization  
**Last material synchronization:** 2026-09-25 — complete-MVP R1 review + `mvp-turo-import-spec.md` focused CRIT-01 revision + `mvp-domain-model.md` Revision 8 + current `mvp-security-scope.md` Revision 5.

## Source artifacts analyzed

| Artifact | Identity / SHA-256 | Role in this specification |
|---|---|---|
| `Aaron 2026.xlsx` | `6b59e91c9db6ee72f578ab7a072f9ce8b2fba1035a04533366b2c74adf5901cc` | `CRV` is the **primary golden historical example** for intended investor-calculation behavior. `Stelvio` is retained only as secondary exceptional-case/anomaly evidence because at least one trip had unusual arrest/incident-related fees. The workbook is **not** the target schema. |
| `trip_earnings_export_20260912.csv` | `186ab6189a4659129ff47b4c444049a3275c4fb15dd16c9271c29c604c813dde` | Current Turo YTD mutable source snapshot used to validate source semantics and prove later revisions. |
| `mvp-turo-import-spec.md` focused CRIT-01 revision | canonical Library artifact | Deterministic provider import contract. Finance consumes provider-neutral canonical economics plus the Import-owned `SourceFinancialCompletenessProofV1`; Finance never infers completeness from accepted-row counts, `ReconciledWithQuarantine`, or provider-specific parser/raw-row state. |
| `financial-platform-product-direction.md` Revision 3 | canonical Library artifact | Greenlit/founder-accepted product direction. Section 18 requires this focused Chat-05 synchronization for canonical operating-cost source facts, recurring costs, fail-closed live currentness, and future-GL separation. |
| `mvp-domain-model.md` Revision 8 | canonical Library artifact | Upstream persistence/currentness contract: operating-cost source facts/projections plus `SourceCurrentSnapshotPointer`, provider-neutral source-completeness lineage, `InvestorEconomicsProjectionSourceProof[]`, and database-enforced correction-scope hardening. |
| `panel-review-mvp-investor-calculation-spec__2026-09-20__r5.md` | historical review artifact | Pre-synchronization finance baseline: `GREENLIGHT_WITH_ACCEPTED_RISKS`, 0 Critical/Significant/Minor findings. All R1–R5 financial-integrity decisions remain preserved unless explicitly superseded by the greenlit product direction. |
| `panel-review-complete-mvp-package__2026-09-25__r1.md` | historical package review | Source of this focused `CRIT-01` / `SIG-02` synchronization. The report requires Finance to consume provider-neutral source financial completeness and expose compound authorization preconditions for issue→refresh nesting without redesigning legacy migration. |
| `mvp-security-scope.md` Revision 5 | canonical Library artifact | Current permission/resource boundary. Security owns concrete permission names; Finance owns the behavioral rule that statement issue cannot bypass authority required by nested refresh/materialization. |

The workbook contains two sheets:

- `CRV` — used range `A1:AD45`; **normative golden example for MVP rule reconstruction and acceptance tests**.
- `Stelvio` — used range `A1:AD19`; **secondary edge-case history only, not a source for general business-rule inference unless independently confirmed**.

Evidence precedence for this specification:

1. Owner-confirmed business rules.
2. CRV workbook formulas/values matched to deterministic Turo source observations.
3. Stelvio only for anomaly/revision robustness tests, never to create a normal rule by itself.

The Turo import specification establishes that the CSV is a mutable YTD snapshot, not an additive transaction feed, and that the complete Turo component set and source revisions must be preserved. This financial specification assumes that import contract.

---

# 1. Evidence labels used throughout

Every rule below is classified as one of:

- **KNOWN FROM FILES** — directly proven by workbook formulas/values or by the deterministic Turo import/source files.
- **INFERRED FROM FILES** — strongly suggested by repeated values, labels, and formula behavior, but not explicitly encoded as a business rule.
- **BUSINESS RULE REQUIRING MY CONFIRMATION** — the files do not establish the intended rule safely enough for deterministic future execution.

The engine must not convert an inference into an authoritative rule without confirmation.

---

# 2. Workbook columns relevant to investor economics

The first 21 columns (`A:U`) are mostly a selected projection of Turo data. The investor calculation begins at `V`.

| Workbook column | Meaning | Classification |
|---|---|---|
| `P` | Guest Paid Delivery (Turo `Delivery`) | Turo-originated component |
| `Q` | Excess distance | Turo-originated component |
| `R` | Extras | Turo-originated component |
| `S` | Tolls & tickets | Turo-originated component |
| `T` | Gas reimbursement | Turo-originated component |
| `U` | Gross earnings (Turo `Total earnings` snapshot) | Turo-originated aggregate |
| `V` | Delivery | Fixed operational charge to investor in workbook |
| `W` | Cleaning | Fixed operational charge to investor in workbook |
| `X` | Management fees | Calculated management-company fee |
| `Y` | Repair | Manual reservation-level investor repair charge |
| `Z` | Ticket Reimbursement / Ticket Reimburstment | Manual investor reimbursement |
| `AA` | Investor earnings | Calculated reservation-level investor net |
| `AB` | Unnamed description column | Manual vehicle-expense label or spreadsheet `Total` label |
| `AC` | Unnamed amount column | Manual vehicle-expense amount or subtotal |
| `AD` | Unnamed amount/status column | Quarter total and/or `Q1/Q2 Total (PAID)` marker |

**KNOWN FROM FILES:** `AB:AD` mix real economic data with spreadsheet layout artifacts. `Total`, `Q1 Total (PAID)`, and `Q2 Total (PAID)` are presentation artifacts and must not become ledger-entry types.

---

# 3. Exact reconstructed reservation formulas

## 3.1 Management-fee formula

The workbook stores the following shared formula:

- `CRV!X2:X40`
- `Stelvio!X2:X11`

```excel
=(Urow-Trow-Srow-Rrow-Prow)*0.3
```

Define:

```text
TuroGross              = U
GuestPaidDelivery      = P
Extras                  = R
TollsAndTickets         = S
GasReimbursement        = T

ManagementFeeBase
  = TuroGross
  - GuestPaidDelivery
  - Extras
  - TollsAndTickets
  - GasReimbursement

ManagementFee
  = ManagementFeeBase * 0.30
```

**KNOWN FROM FILES:** The management fee is **not** `30% × Gross earnings`. It is `30% × (Gross earnings - Guest Paid Delivery - Extras - Tolls & tickets - Gas reimbursement)`.

**KNOWN FROM FILES:** CRV uses the 30% rate and the same four explicit exclusions in every row covered by the shared formula. Stelvio happens to use the same formula, but is corroborative only and is not needed to establish the MVP rule.

**KNOWN FROM FILES:** `Excess distance` is **not** excluded. Example: `CRV!Q32 = 26.20`; `CRV!X32 = 81.675`, which only reconciles if excess-distance revenue remains inside the fee base.

**KNOWN FROM FILES:** Discounts reduce `Gross earnings` and therefore reduce the fee base automatically. They are not separately added back.

**KNOWN FROM FILES:** The formula starts from Turo `Total earnings`, not from a whitelist of workbook-visible Turo columns. Therefore any Turo earning component already present inside `Total earnings` and not one of the four explicit exclusions contributes to the workbook fee base.

**BUSINESS RULE REQUIRING MY CONFIRMATION:** For the future agreement model, should the rule remain **default-include everything except an explicit exclusion set**, or should every Turo component be explicitly classified as feeable/non-feeable? For safety against new Turo component types, this spec recommends explicit, versioned component classification while preserving the historical Aaron rule as an exclusion-set policy.

---

## 3.2 Investor reservation-earnings formula

The workbook stores the following shared formula:

- `CRV!AA2:AA40`
- `Stelvio!AA2:AA11`

```excel
=Urow-(Xrow+Wrow+Vrow+Trow+Srow+Rrow+Prow+Yrow)+Zrow
```

Equivalent deterministic formula:

```text
InvestorReservationEarnings
  = TuroGross
  - ManagementFee
  - FixedCleaningCharge
  - FixedDeliveryCharge
  - GasReimbursement
  - TollsAndTickets
  - Extras
  - GuestPaidDelivery
  - RepairCharge
  + InvestorReimbursement
```

For explanation only, the first part is algebraically equivalent to `70% × ManagementFeeBase` because the observed management-fee rate is 30%. **That algebraic simplification is not the authoritative calculation rule and must not be implemented as a separate 70% investor-share rule.**

The authoritative deterministic sequence for the MVP is the workbook/business sequence:

```text
ManagementFeeBase
  = TuroGross
  - GuestPaidDelivery
  - Extras
  - TollsAndTickets
  - GasReimbursement

ManagementFee
  = ManagementFeeBase * ManagementFeeRate

InvestorReservationEarnings
  = TuroGross
  - ManagementFee
  - FixedCleaningCharge
  - FixedDeliveryCharge
  - GasReimbursement
  - TollsAndTickets
  - Extras
  - GuestPaidDelivery
  - RepairCharge
  + InvestorReimbursement
```

**KNOWN FROM FILES:** This is the formula structure used by the workbook.

**BUSINESS RULE CONFIRMED BY OWNER:** The 70% expression is only a mathematical consequence of the current 30% management fee. It is not a separately configured investor-allocation rule for this MVP. Preserve the explicit component-by-component calculation for auditability and to avoid hiding the treatment of pass-through components and operational charges.

**KNOWN FROM FILES:** Guest Paid Delivery, Extras, Tolls & tickets, and Gas reimbursement do not become investor earnings merely because they are present in Turo `Total earnings`.

**KNOWN FROM FILES:** Repair charges do **not** reduce the management-fee base. They are deducted only after the management fee is calculated.

**KNOWN FROM FILES:** Investor reimbursements do **not** increase the management-fee base. They are added only after the management fee is calculated.

**KNOWN FROM FILES:** Blank `Repair` or `Ticket Reimbursement` cells behave as zero in the Excel formula.

**MVP OWNERSHIP DECISION:** The canonical domain model resolves this ambiguity: MVP requires exactly one applicable 100% `OwnershipInterest` per Vehicle at a time. The Aaron workbook represents that owner’s residual economics after the management agreement. Multi-owner allocation/waterfalls are explicitly deferred.

---

# 4. Revenue-component classification and canonical finance boundary

## 4.1 Turo-originated workbook evidence

The current workbook and CSV prove the historical Turo component behavior below. The integration/import layer remains authoritative for raw/provider source facts and revisions, but **finance does not consume Turo component names directly**. A deterministic provider-to-canonical projection produces `ReservationEconomicSnapshot` + `ReservationEconomicComponent[]`; management agreements and investor calculations consume those canonical codes. Workbook columns remain evidence only.

| Component | Workbook behavior | Economic classification for MVP | Evidence |
|---|---|---|---|
| Trip price | Included through `Gross earnings` | Qualifying Turo revenue | **KNOWN FROM FILES** |
| Boost price | Included through `Gross earnings`; not explicitly excluded | Qualifying Turo revenue | **KNOWN FROM FILES** |
| Duration discounts | Reduce `Gross earnings`; not added back | Reduction of qualifying Turo revenue | **KNOWN FROM FILES** |
| Non-refundable discount | Reduces `Gross earnings`; not added back | Reduction of qualifying Turo revenue | **KNOWN FROM FILES** |
| Excess distance | Remains in fee base | Qualifying Turo revenue | **KNOWN FROM FILES** |
| Guest Paid Delivery (`P`) | Explicitly removed from fee base and investor earnings | Non-investor Turo component | **KNOWN FROM FILES** |
| Extras (`R`) | Explicitly removed from fee base and investor earnings | Non-investor Turo component | **KNOWN FROM FILES** |
| Tolls & tickets (`S`) | Explicitly removed from fee base and investor earnings; may be offset by manual investor reimbursement `Z` | Pass-through / non-investor Turo component | **KNOWN FROM FILES** for calculation; recipient semantics require confirmation |
| Gas reimbursement (`T`) | Explicitly removed from fee base and investor earnings | Pass-through / non-investor Turo component | **KNOWN FROM FILES** for calculation; recipient semantics require confirmation |
| Other Turo earnings components included in `Total earnings` | Historically included unless one of the four explicit exclusions | Historically fee-bearing under the workbook formula; future canonical codes require explicit agreement treatment | **KNOWN FROM FILES** for historical arithmetic; **MVP DESIGN DECISION (R2)** requires explicit `FEEABLE`/`EXCLUDED` classification before future calculation |
| Total earnings (`U`) | Starting aggregate for both formulas | Source-reported Turo gross snapshot | **KNOWN FROM FILES** |

**BUSINESS RULE REQUIRING MY CONFIRMATION:** The workbook proves that `P/R/S/T` are excluded from investor residual economics, but it does **not** prove the final economic recipient of each component. The canonical mapping keeps them distinct (`DELIVERY_REVENUE`, `EXTRAS_REVENUE`, `TOLL_TICKET_REIMBURSEMENT`, `FUEL_REIMBURSEMENT`) rather than collapsing them into management-company profit.

**MVP DESIGN DECISION (R2): two independent fail-closed boundaries are required.** Provider-to-canonical mapping must recognize the source component, **and** the applicable management-agreement component policy must explicitly classify every canonical component that contributes a non-zero amount to `CanonicalGross` as `FEEABLE` or `EXCLUDED`. A newly mapped canonical code never becomes fee-bearing merely because it is now included in gross.

---

# 5. Management-company revenue and operational charges

## 5.1 Management fee

```text
ManagementCompanyManagementFee = 30% × ManagementFeeBase
```

**KNOWN FROM FILES:** `X` is an explicit management fee and is deducted from investor earnings.

## 5.2 Fixed delivery charge — `$20`

**KNOWN FROM FILES:** The workbook contains a separate `Delivery` operational-charge column (`V`) whose `$20.00` values are independent from Turo `Guest Paid Delivery` (`P`).

**BUSINESS RULE CONFIRMED BY OWNER:** The fixed management-company delivery charge is `$20.00` only when the reservation/trip location is:

```text
17801 International Boulevard, Seattle, WA 98158
```

This is the SeaTac Airport location.

For the MVP, the deterministic charge rule must resolve from the reservation's source/canonical location, not from whether Turo itself paid a `Guest Paid Delivery` earning component.

```text
FixedDeliveryCharge =
  20.00 when the qualifying trip location == SeaTacAirportAddress
   0.00 otherwise
```

**IMPLEMENTATION NOTE:** The Turo import preserves `Pickup location` and `Return location` separately. The current source artifact happens to have them equal for every row, but that is not a platform invariant. The financial model must therefore bind this rule to an explicitly chosen location field. Until a contrary business rule is supplied, use the trip's pickup location as the charge-location input.

**HISTORICAL AUDIT NOTE:** The workbook did not preserve pickup/return location columns. Therefore its historical `$20` values cannot always be independently re-derived from the workbook alone. A current Turo snapshot must also not be assumed to prove the historical location because Turo reservation fields are mutable. Preserve the workbook charge as historical observed output while separately evaluating intended-rule compliance when a matching historical location revision is available.

## 5.3 Fixed cleaning charge — `$10`

**KNOWN FROM FILES:** The workbook contains a separate `Cleaning` operational-charge column (`W`) that is normally `$10.00` on completed revenue-bearing trips.

**BUSINESS RULE CONFIRMED BY OWNER:** Every completed trip incurs a `$10.00` cleaning charge.

```text
FixedCleaningCharge =
  10.00 when TripStatus == Completed
   0.00 otherwise
```

This charge is independent from Turo's own `Cleaning` earning component.

**HISTORICAL AUDIT NOTE:** CRV Reservation `56653233` is `Completed` in the workbook but has `Cleaning = 0`. Under the confirmed business rule this is not a valid exception rule; it is a historical workbook discrepancy that must be surfaced during migration/reconciliation rather than encoded as a reservation-specific waiver.

## 5.4 Management-company revenue total

For MVP reporting, a useful derived figure is:

```text
ManagementCompanyEarnedCharges
  = ManagementFee
  + FixedDeliveryCharge
  + FixedCleaningCharge
```

**INFERRED FROM FILES:** This is management-company earned revenue/charges. The workbook only shows these as deductions from investor economics; it does not contain a separate management-company P&L.

**BUSINESS RULE REQUIRING MY CONFIRMATION:** Whether excluded Turo components such as Guest Paid Delivery, Extras, Tolls & tickets, and Gas reimbursement should also be counted as management-company revenue or only as pass-through reimbursements.

---

# 6. Repair charges, investor reimbursements, and manager-incurred operating costs

## 6.1 Reservation-level Repair (`Y`)

Observed non-zero examples:

| Sheet / Reservation | Repair | Formula form | Investor effect |
|---|---:|---|---:|
| CRV `55150559` | 200.00 | `=2700-2500` | deducted from investor earnings |
| CRV `56398909` | 430.00 | hardcoded | deducted from investor earnings |
| Stelvio `55038056` | 547.26 | `=547.26` | deducted from investor earnings |

**KNOWN FROM FILES:** `Repair` is deducted at the reservation calculation layer after management fee calculation.

**KNOWN FROM FILES:** A repair can make reservation-level investor earnings negative.

**KNOWN FROM FILES:** The CRV `$200` entry is literally calculated as `2700 - 2500`; the workbook does not document what the two numbers mean.

**BUSINESS RULE REQUIRING MY CONFIRMATION:** Define the semantic source of `Repair`: investor-responsible repair cost, deductible allocation, claim shortfall, or other. The target model must store the calculation/evidence, not only the final amount.

## 6.2 Ticket Reimbursement / Investor Reimbursement (`Z`)

Observed non-zero examples:

- CRV Reservation `47612193`: Turo `Tolls & tickets = 296.80`; Investor reimbursement = `294.00`.
- Stelvio Reservation `54792507`: workbook `Tolls & tickets = 738.77`; Investor reimbursement = `738.77`.

**KNOWN FROM FILES:** `Z` is added to investor earnings after management fee calculation.

**KNOWN FROM FILES:** It is not always equal to Turo `Tolls & tickets`; CRV differs by `$2.80`.

**INFERRED FROM FILES:** `Z` is a manual reimbursement back to the investor when the investor bore some underlying ticket/toll cost represented in Turo earnings.

**BUSINESS RULE REQUIRING MY CONFIRMATION:** Define when an investor reimbursement is created, who authorizes it, whether it must reference a specific Turo component/expense, and whether it can exceed or differ from that source component.

## 6.3 Historical vehicle operating costs (`AB/AC`) and canonical source-fact treatment

Observed labeled costs include:

### CRV

- Tracking Sub — `$8.35`
- Tracking Device — `$99.44`
- Oil leak cleaning — `$40.00`
- Oil + Filter Change — `$92.09`
- Annul Inspection — `$24.99`

### Stelvio — secondary exceptional-case history only

These entries are retained for migration/audit robustness and must not define normal MVP business rules by themselves.

- Lyft for warrenty repair X 2 — `$40.00`
- Tracking Device — `$8.35`
- Tracking Device — `$99.44`
- Tracking — `$8.35`

**KNOWN FROM FILES:** these amounts are not included in the row-level `AA Investor earnings` formula. Instead, they are deducted when a subtotal is calculated.

**KNOWN FROM FILES:** therefore these historical vehicle costs do **not** reduce the reservation management-fee base in the workbook.

**INFERRED FROM FILES:** repeated `$8.35` CRV `Tracking Sub` rows are recurring tracking-subscription costs. `$99.44` is separately labeled as a tracking-device cost.

**GREENLIT PRODUCT-DIRECTION DECISION:** Phase-A manually entered or recurring manager-incurred/advanced Vehicle costs are authored exactly once as canonical `OperatingCostFact` source facts. They are **not** independently authored `EconomicAdjustment(VEHICLE_EXPENSE)` events and are not direct investor-ledger entries.

The finance path is:

```text
real manager-incurred/advanced Vehicle cost
    ↓
OperatingCostFact
    ↓
deterministic applicable OwnershipInterest
+ ManagementAgreementVersion
+ versioned operating-cost projection policy
    ↓
OperatingCostInvestorProjection
    ↓
VEHICLE_EXPENSE-classified EconomicLedgerEntry when investor effect != 0
```

Category alone never determines chargeability. `TRACKING`, `REPAIR`, `TOLL`, or any other category may be manager-borne under one agreement/policy and investor-chargeable under another. Missing or ambiguous chargeability policy fails the live investor projection closed; it never defaults to investor chargeability.

Historical workbook vehicle costs used in already-issued migration are represented as `OperatingCostFact(source_kind = LEGACY_IMPORT)` with exact workbook provenance. A migration-specific deterministic projection policy may reproduce the observed historical investor deduction without asserting that the same category is universally chargeable under current agreements.

The existence of repeated tracking rows no longer creates an unresolved product question about whether recurring costs are supported: simple monthly recurring-cost rules are Phase-A configuration. Exact amount/effective dates for a real Vehicle remain configured business data, not a hard-coded global finance rule.

---

# 7. Period totals and statement calculations

## 7.1 General rule

The historical workbook computes period totals as:

```text
PeriodInvestorPayable
  = SUM(InvestorReservationEarnings assigned to period)
  - SUM(ManualVehicleExpenses assigned to period)
```

**KNOWN FROM FILES:** the workbook's vehicle-cost rows reduce the investor period total but do not alter reservation management fees.

**KNOWN FROM FILES:** the `Total` text in `AB` is only a spreadsheet label. It is not an economic event.

For the canonical Phase-A model, the equivalent concept is not “subtract every expense category.” Statement economics are the sum of immutable investor-economic ledger membership:

```text
PeriodEconomicTotal
  = SUM(statement-member investor-economic ledger entries)
```

Reservation-derived economics come from `ReservationInvestorCalculation`. Manager-incurred operating costs affect the investor only through current deterministic `OperatingCostInvestorProjection` output under the applicable management-agreement/projection policy. A factual `OperatingCostFact` with zero investor effect remains part of operational truth but creates no investor-balance deduction.

The historical CRV vectors below continue to reproduce the workbook because their legacy migration policy explicitly projects the observed historical vehicle costs into the investor subledger.

## 7.2 CRV subtotal formulas and exact values

| Workbook formula | Reservation earnings subtotal | Manual expense deduction | Expected subtotal |
|---|---:|---:|---:|
| `AC14 = SUM(AA2:AA14)` | 536.550 | 0.00 | **536.550** |
| `AC19 = SUM(AA15:AA19)-SUM(AC17:AC18)` | 1,050.696 | 8.35 + 99.44 = 107.79 | **942.906** |
| `AC23 = SUM(AA20:AA23)-SUM(AC20:AC22)` | 18.672 | 8.35 + 40.00 + 92.09 = 140.44 | **-121.768** |
| `AC26 = SUM(AA24:AA26)-AC25` | 61.574 | 8.35 | **53.224** |
| `AC30 = SUM(AA27:AA30)-SUM(AC28:AC29)` | 70.597 | 8.35 + 24.99 = 33.34 | **37.257** |
| `AC36 = SUM(AA31:AA36)-AC35` | 927.655 | 8.35 | **919.305** |

Quarter totals:

```text
CRV Q1 = AC14 + AC19 + AC23 = 536.550 + 942.906 - 121.768 = 1,357.688
CRV Q2 = AC26 + AC30 + AC36 = 53.224 + 37.257 + 919.305 = 1,009.786
```

Workbook formulas:

```excel
AD23 = SUM(AC14+AC19+AC23)   -> 1357.688
AD36 = SUM(AC26+AC30+AC36)   -> 1009.786
```

## 7.3 Stelvio secondary historical edge case (non-normative)

The following values are retained to prove the engine can reproduce unusual historical statements and source revisions. They are **not golden rule-discovery inputs** and do not change normal CRV-derived business rules.

Q1:

```text
SUM(AA2:AA5) = 640.881
Manual expenses = 40.00 + 8.35 + 99.44 = 147.79
AC5 = 640.881 - 147.79 = 493.091
AD5 = AC5 = 493.091
```

Q2:

- `AC6 = -8.35`
- `AC7 = -8.35`
- `SUM(AA8:AA11) = 769.098`
- `AC10 = 8.35` tracking expense
- `AC11 = SUM(AA8:AA11)-AC10 = 760.748`
- `AD11 = AC6 + AC7 + AC11 = 744.048`

**KNOWN FROM FILES:** Stelvio uses two hardcoded `-8.35` month totals in `AC6` and `AC7` rather than representing those months with separate expense rows.

**INFERRED FROM FILES:** Those `-8.35` values represent a tracking subscription in no-revenue months. This should be normalized in the new system into explicit tracking expense entries, not negative `Total` rows.

---

---

# 8. Statement recognition, entitlement date, forecast, and eligibility

## 8.1 Separate current/provisional economics from statement economics

The platform needs two different views that must never be conflated:

```text
Current / provisional economics
    latest deterministic calculation from the current canonical economic snapshot
    useful for operations, forecasting, and investor dashboard previews

Statement-eligible economics
    immutable investor-economic ledger facts
    subject to completion, current-calculation lineage, economic date, cutoff, and close controls
```

**BUSINESS RULE CONFIRMED BY OWNER:** the `$10` cleaning charge exists only for a `Completed` trip. Therefore a Booked/In-progress reservation must not be treated as if the cleaning charge has already been earned/incurred merely because the historical spreadsheet projected `$10`.

For MVP:

```text
Reservation calculation mode:
  PROVISIONAL
    when reservation/trip is not Completed

  EARNED
    when reservation/trip is Completed and all required economic inputs validate
```

A `PROVISIONAL` calculation:

- may be displayed as forecast/current-performance information;
- may show the location-based `$20` delivery estimate when the qualifying location rule is satisfied;
- has `$0` actual cleaning charge until status becomes `Completed`;
- creates **no statement-eligible EconomicLedgerEntry**;
- can never be included in an issued investor statement.

An `EARNED` calculation may create investor-economic ledger output under the current-lineage and posting rules below.

### Historical workbook caveat

The CRV workbook contains calculated Booked/In-progress rows that include `$20` delivery and `$10` cleaning. Those rows are retained as **legacy provisional spreadsheet output**, not as normative evidence that the current system should recognize those charges into an investor statement before completion.

## 8.2 Entitlement date and effective-dated ownership/agreement resolution

**MVP DESIGN DECISION (R2):** use one provider-neutral `EntitlementAt` timestamp to resolve both the applicable `OwnershipInterest` and `ManagementAgreementVersion`.

For the current Turo CSV adapter:

```text
if source status != Completed:
    EntitlementAt = null
    calculation mode = PROVISIONAL

if source status == Completed:
    EntitlementAt = canonicalized source Trip end timestamp
    calculation mode may become EARNED
```

The Turo export does not provide a separate authoritative physical handoff/completion timestamp, so `Trip end` is the deterministic completion-recognition proxy for this MVP. This is an implementation policy, not a claim that the scheduled end is always the literal physical return time. A later channel with an authoritative completion event may map that event into `EntitlementAt` without changing investor-calculation code.

Effective-date resolution uses half-open ranges:

```text
EffectiveFrom <= EntitlementAt < EffectiveTo
```

with null `EffectiveTo` meaning open-ended. Calculation fails closed unless exactly one 100% `OwnershipInterest` and exactly one `ManagementAgreementVersion` apply at `EntitlementAt`.

## 8.3 New-statement recognition policy — `ECONOMIC_DATE_V1`

The R1 `EXPLICIT_ASSIGNMENT_V1` wording left the automatic candidate-selection step undefined. For **new deterministic statements**, MVP therefore adopts:

```text
recognition_policy_code    = ECONOMIC_DATE
recognition_policy_version = ECONOMIC_DATE_V1
```

Every investor-economic ledger line has a deterministic `EconomicDate`:

```text
FULL_CURRENT reservation line
    = local calendar date of EntitlementAt in the managing Organization timezone

initial/current VEHICLE_EXPENSE operating-cost effect
    = OperatingCostInvestorProjection.EconomicDate
    = OperatingCostFact.IncurredDate when no prior issued investor effect exists

post-issue operating-cost projection correction/delta
    = Organization-local date on which the corrected projection is accepted by Finance Refresh

CLOSED_PERIOD_CORRECTION reservation line
    = local calendar date on which the revised EARNED calculation/correction is accepted

CROSS_OWNERSHIP_CORRECTION
    = approved correction-recognition date

DISTRIBUTION_PAYMENT
    = settlement only; never candidate investor earnings for a statement
```

A source-fact `REVERSAL`/`REPLACEMENT` is its own immutable operating-cost fact and receives its own deterministic projection. If the related investor effect has already been issued, the resulting correction effect uses the current correction-recognition date so it can enter the next valid open statement without rewriting the closed period.

A new statement candidate set is deterministic:

```text
same Tenant + Organization + OwnershipInterest + currency
AND PeriodStart <= EconomicDate <= PeriodEnd
AND CreatedAt <= CalculationCutoffAt
AND not already included in another incompatible issued statement
AND reservation-derived rows belong to the current applicable EARNED calculation lineage
```

The exact selected rows are then frozen through `InvestorStatementEntry`. The candidate rule determines what may enter; explicit membership remains authoritative after issue.

## 8.4 Legacy issued-statement recognition

Historical CRV statements do **not** get reconstructed from `EconomicDate`. Their membership came from the workbook itself and is migrated under:

```text
recognition_policy_code    = LEGACY_EXPLICIT_MEMBERSHIP
recognition_policy_version = LEGACY_EXPLICIT_MEMBERSHIP_V1
```

This preserves historical Q1/Q2 membership even when it does not line up cleanly with a modern date rule. New policy versions never rewrite issued legacy membership.

## 8.5 Live investor economics currentness versus issued statements

`ReservationInvestorCalculationCurrent` answers only which reservation calculation is current. The live Vehicle/OwnershipInterest economics view is broader: it also depends on source financial completeness, operating-cost facts/projections, recurring-cost requirements, agreement/policy versions, and every other deterministic input through the requested cutoff.

Phase A therefore uses an immutable `InvestorEconomicsProjectionSnapshot` lineage envelope with:

```text
Tenant / Organization / Vehicle / OwnershipInterest
AsOfDate / CutoffDate
Organization financial timezone
FingerprintPolicyCode / Version
CompleteInputFingerprint
ProjectionEngineVersion
ProjectionResultHash
InvestorEconomicsProjectionSourceProof[]
```

Finance **consumes but does not reimplement** the Import-owned provider-neutral completeness contract:

```text
SourceFinancialCompletenessProofV1(
    TenantId,
    SourceConnectionId,
    VehicleId,
    CutoffAt
)
  -> COMPLETE | INCOMPLETE | UNKNOWN
  -> proof_version + proof_hash
  -> exact effective provider snapshot / ImportBatch / ProcessingIdentity lineage
```

Finance must never infer source completeness from accepted `ReservationEconomicSnapshot` counts, `ImportBatch` state such as `ReconciledWithQuarantine`, Turo-specific parser details, or `RawImportRecord` inspection.

Authoritative currentness is derived:

```text
CURRENT
iff
for every applicable external source scope:
    SourceFinancialCompletenessProofV1.status == COMPLETE
AND the successful projection records exactly one matching
    InvestorEconomicsProjectionSourceProof for that applicable source scope
AND stored CompleteInputFingerprint
      == ComputeAuthoritativeInvestorInputFingerprintV1(scope, cutoff)
AND every other required deterministic input and recurring occurrence is present,
    unambiguous, authorized, and valid
```

`ComputeAuthoritativeInvestorInputFingerprintV1` includes at minimum:

1. scope/as-of/cutoff identity, financial timezone, recognition/fingerprint versions;
2. for every applicable external source scope, the exact `SourceFinancialCompletenessProofV1` proof version/hash/status, `SourceConnectionId`, effective provider snapshot/`SourceArtifact` identity, effective `SourceCurrentSnapshotPointer.ImportBatchId`, and applicable `ProcessingIdentity` hash/profile/parser/mapping lineage;
3. every relevant current `ReservationEconomicSnapshot` plus provider/current-source lineage needed to prove it current;
4. applicable OwnershipInterest/effective-date resolution;
5. applicable ManagementAgreementVersion, component-treatment policy, and operating-cost projection-policy identity/hash;
6. all effective investor-specific `EconomicAdjustment` / reversal / fixed-charge override inputs through cutoff;
7. every effective `OperatingCostFact` correction lineage and deterministic operating-cost projection inputs through cutoff;
8. every `RecurringExpenseRule` / applicable RuleVersion plus the complete expected due-occurrence set through cutoff, with every due occurrence materialized exactly once to an `OperatingCostFact`;
9. calculation/projection/fingerprint engine and policy versions that can change the result.

The source-completeness part is **scope-local**, not a global batch flag. A blocker deterministically proven to affect only Vehicle B does not block Vehicle A. If Vehicle/cutoff relevance cannot be proven, Import returns `UNKNOWN` and Finance fails closed; uncertainty is never treated as out of scope.

Canonical ordering/serialization is versioned and byte-stable. The same complete input set, including identical source proof version/hash/lineage, must reproduce the same deterministic projection result/hash.

A successful `InvestorEconomicsProjectionSnapshot` persists one `InvestorEconomicsProjectionSourceProof` for every applicable external source scope, binding the live result to the exact `COMPLETE` proof and effective ImportBatch it consumed. Missing, duplicate, extra, foreign, or mismatched source-proof provenance invalidates successful-current projection state.

`CURRENT` is fail-closed. Any required proof that is `INCOMPLETE`, `UNKNOWN`, absent, or lineage/hash mismatched; any unresolved financially relevant quarantine/disappearance/regression/reconciliation blocker; any required input change; any missing due recurring occurrence; any absent/ambiguous policy; or any refresh authorization/failure leaves the live result `BLOCKED`, `UNKNOWN`, `STALE`, or equivalent non-CURRENT state. A cached stale/current flag is never authoritative.

A later `SourceCurrentSnapshotPointer`, completeness blocker/disposition, effective ImportBatch/ProcessingIdentity, source/cost/rule, ownership/agreement/override, or other authoritative input change automatically changes the freshly derived proof/fingerprint comparison. An old projection cannot remain `CURRENT` merely because a separate stale-marker write did not occur.

An issued `InvestorStatement` is different: its exact ledger membership and totals remain immutable. A newer live projection may become current, stale, blocked, or corrected without silently mutating issued history. Any authoritative statement draft refresh and statement issue must prove both source financial completeness and complete-input currentness through the relevant cutoff before financial totals/membership can advance.

---

# 9. Distribution/payment semantics, settlement invariants, and negative balances

## 9.1 Statement obligation and payment are separate

```text
InvestorStatement
    = exact issued economic obligation / debit-carry result

DistributionPayment
    = settlement of a positive obligation
```

Payment never changes earned economics.

Historical CRV workbook markers:

| Period | Exact workbook payable | Marker |
|---|---:|---|
| Q1 2026 | 1,357.688 | `Q1 Total (PAID)` |
| Q2 2026 | 1,009.786 | `Q2 Total (PAID)` |

**KNOWN FROM FILES:** the workbook does not preserve bank amount, bank transaction ID, transfer method, or payment date.

Therefore a migrated `PAID` marker may establish that the exact statement obligation was considered settled, but it must not invent missing bank evidence.

## 9.2 Exact settlement amount versus cash amount

Investor economics preserve fractional cents while actual money movement is normally cent-denominated. The model separates:

```text
settlement_amount       numeric(19,6)  // exact statement obligation extinguished/restored
cash_amount?            numeric(19,2)  // actual external cash movement, only when known
cash_rounding_variance? numeric(19,6)
```

When `cash_amount` is known:

```text
cash_rounding_variance = cash_amount - settlement_amount
```

Outstanding balance uses exact settlement, not cash evidence:

```text
NetSettledAmount
  = SUM(PAID NORMAL settlement_amount)
  - SUM(PAID REVERSAL settlement_amount)

OutstandingStatementBalance
  = InvestorStatement.InvestorPayableTotal
  - NetSettledAmount
```

## 9.3 DistributionPayment invariants

**MVP DESIGN DECISION (R2):** no negative payments and no cross-currency settlement.

```text
PaymentKind = NORMAL | REVERSAL
SettlementAmount > 0
Currency == InvestorStatement.Currency
```

For `NORMAL`:

- the statement must have positive outstanding payable;
- transition to `PAID` fails if `SettlementAmount > OutstandingStatementBalance`;
- `PENDING -> PAID | FAILED | VOIDED`;
- `PAID` is terminal; a paid record is never rewritten/voided to undo history.

To undo a posted paid settlement, create a new `REVERSAL` payment:

```text
ReversesDistributionPaymentId = prior PAID NORMAL payment
same Tenant / Organization / OwnershipInterest / Statement / currency
same SettlementAmount for MVP full reversal
```

A `PAID REVERSAL` restores that amount to the statement's outstanding balance and posts the exact opposite settlement ledger effect. MVP permits at most one effective full reversal per paid normal payment. Partial settlement reversal and FX settlement are deferred.

### Historical `PAID` migration

For a workbook-only paid marker with no independent bank evidence:

```text
PaymentKind        = NORMAL
Status             = PAID
SettlementAmount   = exact historical statement payable
CashAmount         = null
CashRoundingVariance = null
PaidAt             = null
PaymentReference   = null
EvidenceKind       = LEGACY_WORKBOOK_PAID_MARKER
```

This means “the historical workbook treated this obligation as settled”; it does **not** assert how many cents actually moved through a bank account.

## 9.4 Negative investor balance — debit carry-forward and statement chain

CRV proves that period/reservation economics can be negative even though the two paid quarter totals are positive.

**MVP DESIGN DECISION (R2, completed by R3):** a negative issued-period result becomes an investor debit carry-forward; MVP does not create a negative `DistributionPayment` or an investor receivable/collections workflow. Debit carry is propagated only through a deterministic statement predecessor chain.

Statement math is:

```text
PeriodEconomicTotal
  = SUM(statement-member investor-balance-impacting economic ledger entries)

NetBeforeSettlement
  = PeriodEconomicTotal
  - OpeningInvestorDebitCarryForward

InvestorPayableTotal
  = max(NetBeforeSettlement, 0)

ClosingInvestorDebitCarryForward
  = max(-NetBeforeSettlement, 0)
```

`OpeningInvestorDebitCarryForward` and `ClosingInvestorDebitCarryForward` are positive magnitudes. For deterministic statements, carry-forward is chained per:

```text
Tenant + Organization + OwnershipInterest + Currency
+ RecognitionPolicyCode + RecognitionPolicyVersion
```

Every deterministic statement after the first records `CarryForwardPredecessorStatementId`. Its opening debit must equal that predecessor's closing debit exactly. New deterministic statements must be issued in strictly increasing, contiguous, non-overlapping period order for the chain: `PeriodStart = predecessor.PeriodEnd + 1 day`. No active later-period statement may already exist. This prevents one debit balance from being consumed twice.

Legacy migrated statements retain their observed historical membership/periods. When an unambiguous chronological predecessor exists, migration records it; migration must not invent debit carry that is not evidenced by the historical statement sequence.

A positive unpaid payable remains an obligation of its original statement and is **not** folded into the next period's economic total. Only a debit carry-forward offsets later investor earnings.

---

# 10. Precision and rounding

Examples from the workbook include:

- management fee `35.721`;
- investor earnings `53.349`;
- CRV Q1 `1357.688`;
- CRV Q2 `1009.786`.

**KNOWN FROM FILES:** the workbook does not round management fees or investor earnings to cents per reservation.

MVP numeric contract:

```text
canonical provider amounts          numeric(19,4) or upstream canonical contract
calculation/ledger/statement amounts numeric(19,6)
settlement_amount                    numeric(19,6)
actual cash_amount                   numeric(19,2)
```

Rules:

1. use base-10 decimal arithmetic only;
2. do not use binary floating point for financial calculations;
3. do not round per reservation to cents;
4. exact historical workbook economics must remain reproducible to their stored precision;
5. any rounding to cash precision occurs only at the payment boundary and is separately recorded.

---

# 11. Workbook exceptions and data-quality findings

## 11.1 CRV Reservation `56653233` — historical fixed-charge discrepancy

Workbook observation:

```text
Gross earnings       475.87
Guest Paid Delivery   27.00
Delivery charge        0.00
Cleaning charge        0.00
Management fee       134.661
Investor earnings    314.209
```

Owner-confirmed intended rule:

```text
Completed trip       -> Cleaning = 10.00
SeaTac pickup        -> Delivery = 20.00
```

The current Turo snapshot is `Completed` and uses the SeaTac address. Under the current intended rule, if that source revision were the calculation input:

```text
Fee base             = 448.87
Management fee       = 134.661
Delivery             = 20.00
Cleaning             = 10.00
Corrected investor   = 284.209
```

**MIGRATION RULE:** preserve historical issued/paid workbook economics (`314.209`) as legacy evidence; do not create a permanent reservation-specific waiver. A current deterministic calculation may legitimately differ because it uses the confirmed rule and a canonical source revision.

**IMPORTANT:** because Q2 includes this historical row, CRV Q2 `1009.786` is a **legacy statement migration golden value**, not the expected result of recomputing all Q2 reservations under today's corrected fixed-charge rules.

## 11.2 CRV Reservation `52812744` — mixed/stale workbook source projection

Workbook:

```text
Trip price             130.50
3-day discount         -13.05
Guest Paid Delivery     27.00
Visible component sum  144.45
Gross earnings         117.45
```

The current Turo source reports `Delivery = 0.00` and `Total earnings = 117.45`.

**KNOWN FROM FILES:** this workbook row does not represent one internally reconciled Turo snapshot.

**MIGRATION RULE:** reproduce its historical issued workbook economic result only through `LEGACY_ISSUED_IMPORT`; never fabricate a matching provider revision. New calculations use a reconciled canonical `ReservationEconomicSnapshot` only.

## 11.3 CRV future/provisional rows

The formula region includes non-completed reservations such as:

```text
58352788  In-progress
56441542  Booked
58900385  Booked
```

The workbook projects both `$20` delivery and `$10` cleaning for them. Because the owner-confirmed cleaning rule requires `Completed`, these rows are classified as `LEGACY_PROVISIONAL_FORECAST`, not normative rule fixtures.

## 11.4 Stelvio remains non-normative

Stelvio is retained only for unusual source-revision/incident robustness. It must not create general business rules unless independently confirmed.

---

# 12. Minimum financial model for this MVP

This specification aligns to the canonical domain model. Finance is **provider-neutral**: Turo is an adapter/source, not a finance aggregate.

## 12.1 Existing upstream canonical economic object — `ReservationEconomicSnapshot`

Owned by Commerce/Economics, produced deterministically from provider source observations.

Finance-visible contract:

```text
Id
TenantId
OrganizationId
ReservationId
VehicleId
SourceObservationId?
MappingPolicyVersion
InputHash
TripStatus
PickupLocation
ReturnLocation
EntitlementAt?                  // required for EARNED; see Section 8.2
Currency
CanonicalGross
ReservationEconomicComponent[]
CreatedAt
```

`ReservationEconomicComponent` uses canonical codes, not Turo column names. Every provider-derived canonical component retains exact source-component provenance upstream.

Provider mapping and agreement fee treatment are separate controls:

```text
provider component
  -> versioned provider-to-canonical mapping
  -> canonical component code
  -> versioned agreement component treatment
```

Both boundaries fail closed independently.

## 12.2 `OwnershipInterest`

Ownership is a first-class calculation scope.

For MVP:

```text
Vehicle
  -> exactly one applicable 100% OwnershipInterest at EntitlementAt
  -> owner Party
```

Investor economics attach to the `OwnershipInterest`, not directly to a User name, spreadsheet investor name, or Vehicle-only relation. The managing `OrganizationId` is retained historically on all financially meaningful records.

## 12.3 `ManagementAgreementVersion` + explicit component treatment

```text
Id
TenantId
ManagingOrganizationId
OwnershipInterestId
EffectiveFrom
EffectiveTo?
ManagementFeeRate                  // Aaron: 0.30
FeeBaseMode                        // EXPLICIT_COMPONENT_CLASSIFICATION
ComponentPolicyVersion
ComponentPolicyHash
DeliveryChargeAmount               // current Aaron rule: 20.00
DeliveryLocationField              // pickup location
DeliveryLocationMatch              // exact SeaTac address
DeliveryRuleVersion
CleaningChargeAmount               // current Aaron rule: 10.00
CleaningRuleVersion
Currency
SupersedesVersionId?
CreatedAt
CreatedBy
```

Agreement ranges for one OwnershipInterest may not overlap. Economic fields are immutable once used by a calculation.

The component policy is an explicit versioned universe:

```text
ManagementAgreementComponentTreatment
  ManagementAgreementVersionId
  CanonicalComponentCode
  FeeTreatment                    // FEEABLE | EXCLUDED
```

**MVP DESIGN DECISION (R2):** every canonical component that contributes a non-zero amount to `CanonicalGross` must have explicit treatment in the applicable agreement policy. Missing treatment fails calculation closed. A newly introduced canonical component never inherits `FEEABLE` by default.

The historical Aaron policy is represented explicitly so that the following four codes are `EXCLUDED`:

```text
DELIVERY_REVENUE
EXTRAS_REVENUE
TOLL_TICKET_REIMBURSEMENT
FUEL_REIMBURSEMENT
```

Every other canonical code in the approved historical/current taxonomy version is explicitly classified `FEEABLE` where that matches the workbook formula. The calculation is then equivalent to the historical exclusion formula without depending on an unsafe future default.

Operating-cost investor treatment is a **separate agreement/projection policy** from reservation component fee treatment. Expense category alone is not a chargeability rule. For each `OperatingCostFact`, Finance Refresh resolves the applicable OwnershipInterest and ManagementAgreementVersion at the fact's Organization-local `IncurredDate`, then applies the versioned operating-cost projection policy identified by code/version/hash.

The policy must deterministically return an investor-perspective target signed amount (including explicit zero when manager-borne). Missing/ambiguous policy or ownership/agreement resolution blocks current investor economics; no category inherits investor chargeability by default.

## 12.3A `OperatingCostFact` — canonical manager-incurred source fact

Finance consumes the canonical domain source fact; it does not author a parallel expense event:

```text
Id
TenantId
OrganizationId
VehicleId
ReservationId?
IncurredDate                    // Organization-local financial date
Category
Amount                          // positive source magnitude
Currency
Description / BusinessPurpose?
IncurredByKind                  // Phase A: MANAGING_ORGANIZATION
SourceKind                      // MANUAL | RECURRING_RULE | LEGACY_IMPORT | CORRECTION
RecurringExpenseOccurrenceId?
FactKind                        // ORIGINAL | REVERSAL | REPLACEMENT
ReversalOfOperatingCostFactId?
ReplacementForOperatingCostFactId?
IdempotencyKey?
CreatedAt / CreatedBy
```

The source-fact sign is deterministic: ORIGINAL/REPLACEMENT represent positive manager cost; REVERSAL exactly negates the referenced source effect. The fact itself does not assert investor chargeability, payment settlement, GL account, tax treatment, or tax deductibility.

One real manager-incurred cost is authored once. Phase A must never create an `EconomicAdjustment(VEHICLE_EXPENSE)` for the same event.

## 12.3B Recurring rule / occurrence participation

`RecurringExpenseRule` and immutable RuleVersion rows are configuration, not financial truth. During an authorized Finance/Statement Refresh, every due monthly occurrence through cutoff is deterministically enumerated in the Organization financial timezone and materialized idempotently:

```text
RecurringExpenseRule/Version
  -> RecurringExpenseOccurrence
  -> exactly one OperatingCostFact(source_kind = RECURRING_RULE)
  -> OperatingCostInvestorProjection
```

The same source-fact/projection path is used whether the cost was entered manually or generated from a recurring occurrence. Rules never post directly to the investor ledger.

Phase-A monthly occurrence semantics come from the canonical product/domain contract: EffectiveFrom anchor day, last-day fallback when needed, Organization financial timezone, no proration, prospective version edits, and no autonomous scheduler/SYSTEM materializer.

## 12.3C `OperatingCostInvestorProjection`

One immutable projection interprets one canonical cost fact for one OwnershipInterest under exact policy inputs:

```text
Id
TenantId
OrganizationId
OwnershipInterestId
VehicleId
OperatingCostFactId
ManagementAgreementVersionId?
ProjectionPolicyCode
ProjectionPolicyVersion
ProjectionPolicyHash
ProjectionInputFingerprint
EconomicDate
InvestorSignedAmount            // current target effect for this fact + owner
CalculatedAt
SupersedesProjectionId?
```

`InvestorSignedAmount` is the **current target investor effect**, not necessarily the ledger amount to post after prior issued recognition.

Projection currentness is derived per source fact + affected OwnershipInterest. An unstated projection/ledger row is current only when its `ProjectionInputFingerprint` matches the authoritative current fact/ownership/agreement/policy inputs and it is the current unsuperseded projection for that scope. Zero or multiple provable current projections fail closed.

Before any issued recognition for that fact + owner:

```text
ledger SignedAmount = current target InvestorSignedAmount
EconomicDate        = OperatingCostFact.IncurredDate
```

After an investor effect for that fact + owner has already been frozen into an issued statement:

```text
RecognizedIssuedOperatingCost
  = cumulative issued VEHICLE_EXPENSE-classified amount
    for that OperatingCostFact + OwnershipInterest

OperatingCostCorrectionDelta
  = CurrentTargetInvestorSignedAmount
  - RecognizedIssuedOperatingCost
```

A non-zero delta is the only new `VEHICLE_EXPENSE`-classified ledger amount sourced by the current projection, with `EconomicDate` equal to the accepted correction-recognition date. Issued membership remains immutable.

If a projection is superseded before its ledger output is stated, its unstated row remains immutable but becomes ineligible. If it was already issued, it remains recognized history and participates in the next target-minus-recognized calculation.

Source-fact REVERSAL/REPLACEMENT correction lineage remains explicit: each correction fact receives its own deterministic projection. This means an issued original may be offset by a later reversal projection and, when applicable, replaced by a new replacement-fact projection without rewriting either source history or the issued statement.

If corrected ownership/policy requires a formerly recognized owner to reach target zero and another owner to receive the current target, Finance Refresh must compute target-minus-issued-recognized separately for every affected OwnershipInterest under the shared Vehicle lock. Authorization must cover all affected OwnershipInterests. Missing authority or ambiguous target resolution blocks refresh; it never silently reallocates issued economics.

## 12.3D `InvestorEconomicsProjectionSnapshot`

The immutable live-view lineage envelope is the authoritative proof of complete-input currentness described in Section 8.5. It does not replace reservation calculations, cost projections, statements, or payments; it proves that the live Vehicle/OwnershipInterest result through a cutoff was derived from the complete authoritative deterministic input set **and from financially complete effective external-source state**.

Each successful snapshot has immutable `InvestorEconomicsProjectionSourceProof[]` provenance, one row per applicable external source scope, recording at least:

```text
SourceConnectionId
EffectiveImportBatchId
ProofVersion
ProofHash
Status = COMPLETE
```

The effective ImportBatch/ProcessingIdentity supplies the exact provider snapshot/SourceArtifact and processing lineage included in the complete fingerprint. Finance does not duplicate Import's blocker logic; it verifies and freezes the provider-neutral proof output. A snapshot cannot be successful/current if the required source-proof set is missing, duplicated, extra, foreign, `INCOMPLETE`, `UNKNOWN`, or mismatched to the fingerprint inputs.

## 12.4 `InvestorReimbursement`

A reimbursement has a workflow because evidence/approval is not the same thing as financial effect.

Minimum MVP fields:

```text
Id
TenantId
OrganizationId
OwnershipInterestId
VehicleId
ReservationId
Category
RequestedAmount
Currency
EffectiveDate
Description
Status                          // DRAFT | SUBMITTED | APPROVED | REJECTED | CANCELLED
SubmittedAt?/By?
ApprovedAt?/By?
RejectedAt?/By?
RejectionReason?
ApprovedEconomicAdjustmentId?
IdempotencyKey?
CreatedAt
CreatedBy
UpdatedAt
```

Approval creates exactly one `EconomicAdjustment(INVESTOR_REIMBURSEMENT)` in the same idempotent transaction. Receipt/evidence upload alone has no financial effect.

## 12.5 `EconomicAdjustment` — investor-specific contractual/manual inputs only

`EconomicAdjustment` remains a separate immutable investor-economic input for semantics that are **not** the authoritative source of an ordinary manager-incurred operating cost.

Minimum Phase-A fields remain:

```text
Id
TenantId
OrganizationId
OwnershipInterestId
VehicleId
ReservationId
AdjustmentType
Category
Amount?                           // positive magnitude for Repair/Reimbursement
Currency
EffectiveDate
Description
TargetChargeType?                 // DELIVERY | CLEANING for fixed-charge override
OverrideAction?                   // REPLACE | WAIVE
ReplacementChargeAmount?          // required for REPLACE; null for WAIVE
InvestorReimbursementId?
EvidenceDocumentId? / source artifact reference?
ReversalOfAdjustmentId?
IdempotencyKey?
CreatedAt
CreatedBy
```

Phase-A types:

```text
FIXED_OPERATIONAL_CHARGE_OVERRIDE
REPAIR_CHARGE
INVESTOR_REIMBURSEMENT
```

There is **no authorable `EconomicAdjustment(VEHICLE_EXPENSE)` path** after the Financial Platform Product Direction synchronization.

The distinction is semantic, not merely storage:

```text
actual manager-incurred repair bill / oil change / toll / tracking cost
    -> OperatingCostFact
    -> agreement/policy-driven OperatingCostInvestorProjection

investor-specific contractual RepairCharge
    -> EconomicAdjustment(REPAIR_CHARGE)
    -> ReservationInvestorCalculation

approved reimbursement owed back to investor
    -> InvestorReimbursement
    -> EconomicAdjustment(INVESTOR_REIMBURSEMENT)
    -> ReservationInvestorCalculation

delivery/cleaning contractual override
    -> EconomicAdjustment(FIXED_OPERATIONAL_CHARGE_OVERRIDE)
    -> ReservationInvestorCalculation
```

An actual operating cost and an investor-specific repair charge can coexist only when they represent demonstrably different economic semantics. The system must never manufacture an EconomicAdjustment merely to make an OperatingCostFact affect the investor ledger.

### Fixed-charge override semantics

`FIXED_OPERATIONAL_CHARGE_OVERRIDE` is **absolute**, never a delta:

```text
OverrideAction = REPLACE
  -> resolved charge = ReplacementChargeAmount (>= 0)

OverrideAction = WAIVE
  -> resolved charge = 0
```

An override never means “default + amount.” For one reservation + target charge, more than one simultaneously effective non-reversed override is invalid and calculation fails closed. A zero charge should use `WAIVE`, not an ambiguous zero delta.

### Reversal rule

A reversal is a new immutable adjustment whose economic effect removes/negates one non-reversal original. Scope/type/currency and the complete semantic payload (including target charge/action/replacement amount for an override) must match. Replacement is a separate new normal adjustment after the reversal.

All Phase-A EconomicAdjustment types are reservation-level calculation inputs. They do **not** directly create EconomicLedgerEntry rows. Their effect is owned by `ReservationInvestorCalculation`, preventing a second direct-posting path.

`InvestorReimbursement` remains explicitly separate from manager-incurred OperatingCostFact. An investor-paid/reimbursable item must not be disguised as a manager-incurred operating cost merely because both may reference the same Vehicle or Reservation.

## 12.6 `ReservationInvestorCalculation`

```text
Id
TenantId
OrganizationId
OwnershipInterestId
ReservationId
ReservationEconomicSnapshotId?
LegacySourceArtifactId?
LegacySourceLocator?
ManagementAgreementVersionId?
Origin                              // DETERMINISTIC_ENGINE | LEGACY_ISSUED_IMPORT
CalculationMode                     // PROVISIONAL | EARNED | LEGACY_ISSUED
PostingDisposition                  // NO_LEDGER | FULL_CURRENT | CLOSED_PERIOD_DELTA | CROSS_OWNERSHIP_CORRECTION_REQUIRED | LEGACY_ISSUED
CalculationEngineVersion
CalculationInputHash
EntitlementAt?
CalculatedAt

CanonicalGross
ExcludedDelivery
ExcludedExtras
ExcludedTollsTickets
ExcludedFuelReimbursement
ManagementFeeBase
ManagementFee
FixedDeliveryCharge
FixedCleaningCharge
RepairCharge
InvestorReimbursement
InvestorBaseShare
InvestorReservationEarnings

RecognizedReservationAmount?        // CLOSED_PERIOD_DELTA only
ClosedPeriodDelta?                  // target - recognized
SupersedesCalculationId?
```

Calculated monetary columns use `numeric(19,6)`.

For deterministic execution, `CalculationInputHash` is a **complete reservation-scoped deterministic fingerprint**, not a hash of convenient inputs. It includes at minimum:

- exact `ReservationEconomicSnapshot` identity/input hash plus provider/current-source lineage needed to prove that snapshot current;
- the exactly applicable OwnershipInterest and ManagementAgreementVersion at `EntitlementAt`;
- component-treatment policy identity/hash;
- every effective reservation-scoped investor-specific EconomicAdjustment/reversal/override used by the calculation;
- calculation/fingerprint policy versions and engine version;
- any other deterministic reservation-scoped input that can change `InvestorReservationEarnings`.

OperatingCostFact effects are deliberately **not duplicated** inside `ReservationInvestorCalculation`; they use the separate source-fact → OperatingCostInvestorProjection path and are included in the complete Vehicle/OwnershipInterest projection fingerprint.

Exactly one valid provenance path applies:

```text
DETERMINISTIC_ENGINE
  -> complete reservation input fingerprint described above

LEGACY_ISSUED_IMPORT
  -> legacy workbook SourceArtifact
  -> exact sheet/cell/row locator
  -> no fabricated historical provider revision
```

A changed deterministic input creates a new immutable calculation. Old monetary values and old ledger rows are never rewritten.

## 12.7 `ReservationInvestorCalculationCurrent`

A tiny mutable reservation-level pointer/projection makes “current applicable calculation” explicit without mutating old monetary facts and remains valid when `EntitlementAt` moves across an ownership boundary:

```text
TenantId
ReservationId
VehicleId
CalculationId
CurrentOwnershipInterestId
UpdatedAt
```

Primary/unique key:

```text
(TenantId, ReservationId)
```

The pointer is advanced atomically under `VehicleInvestorEconomicLock`. `SupersedesCalculationId` preserves immutable lineage. Statement eligibility for reservation-derived rows always joins through this single reservation-level current pointer, so a reservation cannot remain simultaneously current for two OwnershipInterests.

## 12.8 `InvestorStatement`

```text
Id
TenantId
OrganizationId
OwnershipInterestId
PeriodStart
PeriodEnd
Version
Status                          // DRAFT | ISSUED | SUPERSEDED
RecognitionPolicyCode
RecognitionPolicyVersion
CalculationCutoffAt
Currency
ReservationEarningsTotal       numeric(19,6)
OperatingCostTotal             numeric(19,6)   // signed investor-perspective sum of VEHICLE_EXPENSE-classified entries
PeriodEconomicTotal            numeric(19,6)
OpeningInvestorDebitCarryForward numeric(19,6)   // positive magnitude
CarryForwardPredecessorStatementId?
InvestorPayableTotal           numeric(19,6)     // never negative
ClosingInvestorDebitCarryForward numeric(19,6)   // positive magnitude
Origin                          // DETERMINISTIC | LEGACY_ISSUED_IMPORT
LegacySourceArtifactId?
LegacySourceLocator?
IssuedAt?
SupersedesStatementId?
IssueIdempotencyKey?
CreatedAt
CreatedBy
```

`PAID` is **not** an `InvestorStatement.Status`. Settlement is derived from `DistributionPayment`.

## 12.9 `InvestorStatementEntry`

```text
TenantId
InvestorStatementId
EconomicLedgerEntryId
CreatedAt
```

Issued statement membership is explicit and immutable.

## 12.10 `DistributionPayment`

```text
Id
TenantId
OrganizationId
InvestorStatementId
OwnershipInterestId
PaymentKind                      // NORMAL | REVERSAL
ReversesDistributionPaymentId?
SettlementAmount                 numeric(19,6) > 0
CashAmount?                      numeric(19,2)
CashRoundingVariance?            numeric(19,6)
Currency
Status                           // PENDING | PAID | FAILED | VOIDED
EvidenceKind
PaidAt?
PaymentReference?
Notes?
IdempotencyKey?
CreatedAt
CreatedBy
```

Historical workbook paid markers create `NORMAL/PAID` settlement records with exact settlement amount but unknown cash/date/reference. A paid normal settlement is reversed only by a new `REVERSAL` record, never by destructive status mutation.

---

# 13. Minimal investor-economic ledger requirements

This is an immutable investor-economic **subledger**, not a general double-entry accounting journal.

## 13.1 Ledger scope

Every entry contains:

```text
Id
TenantId
OrganizationId
OwnershipInterestId
VehicleId
ReservationId?
EntryType
SignedAmount                     numeric(19,6)
Currency
EconomicDate
ReservationCalculationId?
OperatingCostInvestorProjectionId?
DistributionPaymentId?
CrossOwnershipCorrectionId?
CreatedAt
```

Exactly one generating source must be present.

Phase A intentionally has **no `EconomicAdjustmentId` direct-ledger source**. Investor-specific EconomicAdjustment effects flow through a reservation calculation. Ordinary manager-incurred operating costs flow through `OperatingCostInvestorProjection`.

## 13.2 Authoritative investor-balance line types

From investor/owner perspective:

```text
INVESTOR_BASE_SHARE            +
FIXED_DELIVERY_CHARGE          -
FIXED_CLEANING_CHARGE          -
REPAIR_CHARGE                  -
INVESTOR_REIMBURSEMENT         +
VEHICLE_EXPENSE                -
CLOSED_PERIOD_CORRECTION       signed (+ or -)
CROSS_OWNERSHIP_CORRECTION      signed (+ or -)
DISTRIBUTION_PAYMENT           settlement only: NORMAL -, REVERSAL +
```

**CRITICAL R2 FIX:** `MANAGEMENT_FEE` is **not** an investor-balance-impacting ledger line because `InvestorBaseShare = ManagementFeeBase - ManagementFee` already deducts it. `ManagementFee` remains a first-class calculation/audit value and management-company entitlement; a future management-company/accounting projection may post it separately, but the investor subledger must not deduct it twice.

## 13.3 Reservation posting decomposition invariant

For a `FULL_CURRENT` EARNED calculation:

```text
SUM(all investor-balance-impacting ledger entries
    generated by that ReservationInvestorCalculation)
=
InvestorReservationEarnings
```

For example, the first CRV row posts:

```text
+272.160 INVESTOR_BASE_SHARE
 -20.000 FIXED_DELIVERY_CHARGE
 -10.000 FIXED_CLEANING_CHARGE
--------------------------------
+242.160 investor result
```

No `-116.640 MANAGEMENT_FEE` line is posted to the investor balance.

This invariant must pass for every normal CRV formula-region fixture.

## 13.4 Closed-period delta posting

If the reservation already has economics frozen into an issued statement **and the newly resolved OwnershipInterest is the same ownership scope already recognized**, a later EARNED calculation does **not** post another full decomposition.

```text
RecognizedReservationAmount
  = SUM(investor-balance-impacting reservation economic entries
        for this reservation + OwnershipInterest
        that are members of ISSUED statements)

ClosedPeriodDelta
  = CurrentCalculation.InvestorReservationEarnings
  - RecognizedReservationAmount
```

If the delta is non-zero, the current calculation creates exactly one:

```text
CLOSED_PERIOD_CORRECTION = ClosedPeriodDelta
```

with `EconomicDate` equal to the correction-recognition date. That line is eligible for the next open statement under `ECONOMIC_DATE_V1`.

If issued reservation economics exist under a **different** OwnershipInterest than the newly resolved current owner, ordinary same-owner delta posting is prohibited. The calculation is retained as current truth, but posting disposition becomes `CROSS_OWNERSHIP_CORRECTION_REQUIRED` and no automatic investor-balance line is posted. Section 15.4 defines the approval workflow.

## 13.5 Posting ownership

```text
ReservationInvestorCalculation(FULL_CURRENT)
  -> INVESTOR_BASE_SHARE / fixed charges / repair / reimbursement lines

ReservationInvestorCalculation(CLOSED_PERIOD_DELTA)
  -> exactly one CLOSED_PERIOD_CORRECTION line when delta != 0

OperatingCostInvestorProjection
  -> zero or one current VEHICLE_EXPENSE-classified ledger line
  -> full current target before issued recognition
  -> target-minus-issued-recognized delta after issued recognition

CrossOwnershipCorrection(APPROVED/APPLIED)
  -> one signed CROSS_OWNERSHIP_CORRECTION line per affected OwnershipInterest delta

DistributionPayment
  -> settlement ledger line: NORMAL negative, REVERSAL positive
```

`EconomicAdjustment` owns **no direct ledger posting path** in Phase A.

This prevents management-fee double counting, source-fact/adjustment double posting, stale operating-cost projection duplication, and full-economic reposting after a closed period.

## 13.6 Operating-cost projection/currentness invariant

For one `OperatingCostFact` + affected OwnershipInterest, at most one unstated projection lineage may be statement-eligible for the authoritative current inputs.

Derived currentness:

```text
OperatingCostProjectionCurrent
iff
ProjectionInputFingerprint
  == ComputeAuthoritativeOperatingCostProjectionFingerprint(
       OperatingCostFact current source lineage,
       applicable OwnershipInterest,
       applicable ManagementAgreementVersion,
       operating-cost projection policy code/version/hash,
       projection engine/policy versions)
and the projection is the current unsuperseded projection for that fact + owner
```

If currentness cannot be proven uniquely, the affected live economics are BLOCKED/non-current.

Ledger output is target-based:

```text
Target(O) = current OperatingCostInvestorProjection.InvestorSignedAmount

RecognizedIssued(O)
  = cumulative issued VEHICLE_EXPENSE-classified ledger amount
    for this OperatingCostFact + OwnershipInterest

if RecognizedIssued(O) == 0 and no prior issued effect exists:
    CurrentLedgerAmount(O) = Target(O)
    EconomicDate = OperatingCostFact.IncurredDate
else:
    CurrentLedgerAmount(O) = Target(O) - RecognizedIssued(O)
    EconomicDate = accepted correction-recognition date
```

A zero target with non-zero recognized history therefore creates the exact opposite correction delta needed to return that owner to zero.

Supersession rules mirror the reservation/cross-owner guarantees already reviewed:

- if a projection is superseded before its ledger row is issued, the old row remains immutable but becomes statement-ineligible;
- if the old row was already issued, it remains recognized history and the new projection posts only `target - issued recognized`;
- source-fact REVERSAL/REPLACEMENT facts remain distinct immutable inputs and each receives its own deterministic projection;
- repeated refresh/retry with the same projection input fingerprint is idempotent and creates no duplicate projection/ledger effect;
- changing agreement/policy never mutates the OperatingCostFact itself.

A `VEHICLE_EXPENSE` ledger row must reference exactly one `OperatingCostInvestorProjection`. No authorable EconomicAdjustment can produce the same line type.

---

# 14. Deterministic Finance Refresh / calculation pipeline

Phase A has one application-level authorized Finance Refresh / Statement Refresh orchestration. Source Ingestion does not own Investor Finance, and there is no autonomous scheduler/SYSTEM materializer.

Before creating or advancing authoritative investor-economic output, Finance obtains the Import-owned `SourceFinancialCompletenessProofV1` for **every applicable external source scope** for the Vehicle/cutoff. The refresh blocks before successful-current publication when any required proof is absent, `INCOMPLETE`, `UNKNOWN`, or cannot be matched to the effective source pointer/processing lineage.

```text
authorized Finance/Statement Refresh(scope, cutoff)
    ↓
acquire VehicleInvestorEconomicLock(Tenant, Vehicle)
    ↓
re-read authoritative resource/configuration state
    ↓
for every applicable external SourceConnection:
    obtain SourceFinancialCompletenessProofV1(Tenant, SourceConnection, Vehicle, cutoff)
    require status = COMPLETE
    retain exact proof version/hash + effective provider snapshot / ImportBatch /
      ProcessingIdentity lineage for fingerprint + projection provenance
    ↓
resolve Organization financial timezone
    ↓
enumerate every due RecurringExpenseOccurrence through cutoff
    ↓
materialize each missing occurrence idempotently
    -> exactly one OperatingCostFact(source_kind = RECURRING_RULE)
    ↓
resolve every relevant canonical OperatingCostFact correction lineage
    ↓
resolve applicable OwnershipInterest + ManagementAgreementVersion
+ operating-cost projection policy for each fact
    ↓
create/reuse deterministic OperatingCostInvestorProjection rows
and current VEHICLE_EXPENSE ledger output/deltas
    ↓
for every relevant reservation:
    current provider/source lineage
      -> ReservationEconomicSnapshot + canonical components + EntitlementAt?
      -> PROVISIONAL if not Completed
      -> otherwise exactly one OwnershipInterest + ManagementAgreementVersion
      -> explicit canonical component treatment
      -> effective investor-specific EconomicAdjustment inputs/overrides
      -> complete reservation CalculationInputHash
      -> immutable ReservationInvestorCalculation
      -> reservation-level current pointer
      -> FULL_CURRENT / CLOSED_PERIOD_DELTA /
         CROSS_OWNERSHIP_CORRECTION_REQUIRED behavior already defined
    ↓
ComputeAuthoritativeInvestorInputFingerprintV1(
    scope,
    cutoff,
    exact COMPLETE source-proof version/hash/lineage set,
    all other deterministic inputs
)
    ↓
require every source proof, due occurrence, and other material input valid and complete
    ↓
create immutable InvestorEconomicsProjectionSnapshot
+ exactly matching InvestorEconomicsProjectionSourceProof[]
with CompleteInputFingerprint + ProjectionResultHash
    ↓
live economics may report CURRENT only if fresh proof/fingerprint comparison succeeds
```

`ReconciledWithQuarantine` is not a Finance completeness verdict. An in-scope financially relevant quarantine, unresolved disappearance/regression/reconciliation review, unknown Vehicle/cutoff relevance, absent proof, or proof-lineage mismatch blocks successful currentness even when accepted rows themselves reconcile internally. A blocker deterministically proven by Import to be out of scope for the Vehicle/cutoff does not block that Vehicle.

A successful import, OperatingCostFact command, recurring-rule edit, or source-completeness disposition/current-pointer change may commit independently before Finance Refresh. If refresh is denied or fails, that valid upstream mutation remains committed, but the old live projection automatically fails source-proof/fingerprint currentness on the next read. No second best-effort “mark stale” write is required.

Statement Refresh uses the same deterministic refresh steps before candidate selection and issue. It must not draft authoritative totals/membership or issue from whatever ledger rows happen to exist when source financial completeness or the complete current input set cannot be proven.

The reservation-only deterministic path remains provider-neutral:

```text
provider artifact/revision
  -> normalized source observation
  -> ReservationEconomicSnapshot
  -> ReservationInvestorCalculation
```

The operating-cost path is likewise source-fact driven:

```text
manual or recurring manager-incurred cost
  -> OperatingCostFact
  -> OperatingCostInvestorProjection
  -> investor subledger when policy produces non-zero effect
```

No LLM participates in source economic values, canonical mapping at execution time, agreement/policy application, recurring occurrence identity, deterministic fingerprints, arithmetic, current-lineage selection, statement membership/totals, close, correction delta, or settlement determination.

AI may later explain already-calculated structured results within the caller's authorization scope.

---

# 15. Statement close, recalculation lineage, concurrency, and idempotency

## 15.1 Shared Vehicle investor-economic lock

R3 replaces the OwnershipInterest-scoped lock with a Vehicle-scoped lock so serialization survives an ownership transition. Every transaction that can create investor-economic ledger output for a Vehicle, advance the current reservation calculation pointer, apply a cross-owner correction, or issue a statement acquires the same transaction-scoped advisory lock:

```text
VehicleInvestorEconomicLockKey =
  hash('vehicle-investor-economics', TenantId, VehicleId)
```

Required users:

- EARNED reservation calculation/recalculation posting;
- reservation-level current-calculation pointer advancement;
- OperatingCostFact projection/correction work that creates investor-economic effects;
- recurring-occurrence materialization during authorized Finance/Statement Refresh;
- statement issuance for an OwnershipInterest on the Vehicle;
- same-owner closed-period delta posting;
- cross-ownership correction approval/application.

Serialization rule:

```text
ledger/current-lineage transaction commits before statement lock
  -> its current eligible row may be considered for that close

statement issue obtains vehicle lock first
  -> CalculationCutoffAt is fixed
  -> later rows/pointer changes are post-cutoff
  -> they cannot mutate that issued statement
```

Issued membership is frozen through `InvestorStatementEntry`. One Vehicle lock is acceptable at MVP scale and prevents an X→Y owner transition from racing statement issue under X.

## 15.2 Pre-statement recalculation/current-lineage semantics

**CRITICAL R3 FIX:** only one deterministic calculation is current for one `(Tenant, Reservation)`, regardless of which OwnershipInterest the latest `EntitlementAt` resolves.

Under the Vehicle lock:

```text
A = reservation-level current calculation, owner X
B = newly calculated changed-input version, owner X or Y

B.SupersedesCalculationId = A.Id
advance ReservationInvestorCalculationCurrent from A -> B atomically
A and A's ledger rows remain immutable history
```

If no economics for the reservation have entered an issued statement:

- B uses `PostingDisposition = FULL_CURRENT`;
- A's full ledger rows become statement-ineligible because A is no longer reservation-current, even if A belonged to a different OwnershipInterest;
- B's full ledger rows are the only reservation-derived rows eligible for a future statement.

The ledger rows themselves are not mutated with an `eligible` flag; eligibility is derived by joining through the reservation-level `ReservationInvestorCalculationCurrent` pointer.

## 15.3 Post-statement recalculation — same owner

If reservation economics have already entered an issued statement and the newly resolved OwnershipInterest is the same recognized owner:

- B becomes the current calculation for dashboard/current truth;
- B uses `PostingDisposition = CLOSED_PERIOD_DELTA`;
- B does not post a second full decomposition;
- `RecognizedReservationAmount` is derived from issued statement membership for that reservation + OwnershipInterest;
- B posts only `InvestorReservationEarnings - RecognizedReservationAmount` as `CLOSED_PERIOD_CORRECTION` when non-zero.

If B is superseded by C before B's correction line is issued, B's correction line becomes ineligible through the same reservation-current lineage rule; C calculates its delta against the still-recognized issued amount. If B's correction has already been issued, it becomes part of the recognized amount and a later C delta naturally calculates from that updated recognized total.

## 15.4 Post-statement recalculation — cross-ownership correction

**MVP DESIGN DECISION (R3 / owner-policy resolution):** latest validated `EntitlementAt` may automatically re-resolve ownership before any issued recognition. After issued recognition, a newly resolved different OwnershipInterest does **not** automatically transfer already-issued investor entitlement. It fails closed to a Finance/Admin correction workflow.

When issued economics exist under owner X but current calculation B resolves owner Y:

```text
B becomes ReservationInvestorCalculationCurrent
B.PostingDisposition = CROSS_OWNERSHIP_CORRECTION_REQUIRED
no ordinary CLOSED_PERIOD_CORRECTION is posted
create/idempotently resolve CrossOwnershipCorrection case
```

Minimum correction case:

```text
Id
TenantId
OrganizationId
VehicleId
ReservationId
CurrentCalculationId
Status                 // REQUIRED | APPROVED | APPLIED | REJECTED
ReasonCode             // ENTITLEMENT_OWNERSHIP_CHANGED
CreatedAt / CreatedBy
ApprovedAt? / ApprovedBy?
AppliedAt?
IdempotencyKey?
```

The case derives its affected owners from immutable calculations/issued membership; client-supplied owner IDs are never trusted. Approval requires Finance/Admin authorization against the managing Organization and **every affected OwnershipInterest**.

At application time under the Vehicle lock, compute for each affected OwnershipInterest O:

```text
TargetEntitlement(O) =
  CurrentCalculation.InvestorReservationEarnings
    if O == CurrentCalculation.OwnershipInterestId
  0
    otherwise

RecognizedIssued(O)
  = cumulative issued investor-balance reservation economics for O

CrossOwnerDelta(O)
  = TargetEntitlement(O) - RecognizedIssued(O)
```

For every non-zero delta, create exactly one signed `CROSS_OWNERSHIP_CORRECTION` ledger entry sourced by the correction case and dated on the approved correction-recognition date. Example: X previously recognized `+100`, current owner Y target `+120` -> X `-100`, Y `+120`. The entries flow to each owner's next valid open statement under `ECONOMIC_DATE_V1`; previously issued statements remain immutable.

**CRITICAL R4 FIX — correction currentness is derived from reservation current lineage.** An unstated cross-owner correction row is statement-eligible only while:

```text
CrossOwnershipCorrection.CurrentCalculationId
  == ReservationInvestorCalculationCurrent.CalculationId
```

for the same Tenant + Reservation. The correction case and its ledger rows remain immutable even after supersession; currentness is derived, not stored as a mutable `statement_eligible` flag.

When a newer calculation C supersedes the calculation referenced by an APPLIED correction C1 before all C1 rows are issued:

- every still-unstated C1 ledger row becomes statement-ineligible automatically;
- already-issued C1 rows remain frozen history and continue to count in `RecognizedIssued(O)`;
- a new correction case C2 for the new current calculation is computed against **issued recognized economics only**;
- applying/approving a stale correction whose `CurrentCalculationId` no longer matches the reservation current pointer fails closed.

This makes repeated and partially-issued correction sequences deterministic. For example:

```text
X +100 already issued
C1 for Y=120 -> X -100, Y +120

if neither C1 row is issued and Y changes to 130:
  C1 rows become ineligible
  C2 computes against issued X +100 / Y 0
  -> X -100, Y +130

if only C1 X -100 is issued and Y changes to 130:
  issued recognized X = 0, Y = 0
  old unstated Y +120 becomes ineligible
  C2 -> Y +130 only

if both C1 rows are issued and Y changes to 130:
  issued recognized X = 0, Y = 120
  C2 -> Y +10 only
```

This correction path is auditable and generalizes repeated corrections without assuming the aggregate delta alone is sufficient.

## 15.5 Statement candidate selection and debit-carry chain under `ECONOMIC_DATE_V1`

Statement draft refresh and statement issue are **completeness/currentness gates**. Finance owns the behavioral command contract; Security owns the concrete permission names.

`IssueInvestorStatement` has its own high-risk issue authorization, but that authority does **not** imply, bypass, or temporarily acquire the separate authority required by any authoritative Statement Refresh operations that issue depends on. Before the first protected financial mutation of the issue attempt, the server must establish and revalidate all authorities required for:

1. the statement issue action itself;
2. authoritative Finance/Statement Refresh/recalculation/currentness advancement;
3. recurring occurrence / `OperatingCostFact` materialization when the requested cutoff has missing due occurrences; and
4. every applicable Tenant/Organization/Vehicle/OwnershipInterest relationship and recent-step-up requirement owned by Security.

If any required nested authority is absent/stale, source financial completeness is not proven, or any nested refresh/materialization step fails, the protected issue attempt fails as one unit. It may not partially materialize recurrences, partially advance calculation/projection/currentness state, partially refresh DRAFT totals/membership, freeze a cutoff, or mark a statement `ISSUED`. An existing DRAFT shell may remain, but it is not authoritative/current and cannot be issued from stale membership/totals.

While holding the Vehicle lock:

1. validate statement scope/currency/recognition-policy lineage;
2. resolve the latest active predecessor statement in the same chain;
3. require strictly increasing contiguous non-overlapping dates (`PeriodStart = predecessor.PeriodEnd + 1 day`) unless this is the first statement in the chain;
4. reject issue if an active later-period statement already exists or an incompatible active period overlaps;
5. run/require the fully authorized Finance/Statement Refresh through `PeriodEnd`/statement cutoff, including due recurring occurrence materialization and deterministic operating-cost projections; nested authority is preconditioned as above and is never implied by issue authority;
6. require `SourceFinancialCompletenessProofV1.status = COMPLETE` for every applicable external source scope and require the exact proof version/hash/effective ImportBatch/ProcessingIdentity lineage to match the successful `InvestorEconomicsProjectionSourceProof[]` + `CompleteInputFingerprint` used for the statement scope/cutoff; any absent/`INCOMPLETE`/`UNKNOWN`/mismatched proof blocks draft refresh/issue;
7. require the `InvestorEconomicsProjectionSnapshot` complete input fingerprint to prove `CURRENT` for the statement scope/cutoff; if source completeness or any other currentness input cannot be proven, block issue rather than infer completeness from existing ledger rows;
8. set `CalculationCutoffAt`;
9. select same-scope/currency rows whose `EconomicDate` is within the statement dates;
10. require reservation-derived full/delta rows to belong to `ReservationInvestorCalculationCurrent`;
11. require every unstated `VEHICLE_EXPENSE` row to reference the current deterministic `OperatingCostInvestorProjection` for its OperatingCostFact + affected OwnershipInterest; superseded unstated projection rows are ineligible, while already-issued rows remain recognized history;
12. require every **unstated** `CROSS_OWNERSHIP_CORRECTION` row's correction `CurrentCalculationId` to equal that Reservation's `ReservationInvestorCalculationCurrent.CalculationId`; already-issued correction rows remain historical recognized economics even after supersession;
13. require `CreatedAt <= CalculationCutoffAt`;
14. exclude rows already frozen into another incompatible issued statement;
15. set `CarryForwardPredecessorStatementId` and require `OpeningInvestorDebitCarryForward == predecessor.ClosingInvestorDebitCarryForward` (or zero for a first deterministic statement);
16. calculate explanatory reservation/operating-cost totals plus authoritative `PeriodEconomicTotal`/debit carry;
17. insert exact `InvestorStatementEntry` membership;
18. mark statement `ISSUED`.

Concurrent Finance Refresh, operating-cost projection, reservation recalculation, and statement issue serialize on the same Vehicle lock. No unstated backend rule may infer “for the intended period,” and no statement may issue from a stale/incomplete live projection.

## 15.6 Idempotency keys / duplicate guards

Minimum deterministic guards:

| Boundary | Idempotency / uniqueness |
|---|---|
| Manual OperatingCostFact command | `(tenant_id, idempotency_key)` when supplied; source-fact correction lineage forbids duplicate effective reversal |
| Recurring occurrence | unique `(tenant_id, recurring_expense_rule_id, occurrence_date)` |
| Recurring occurrence → OperatingCostFact | exactly one ORIGINAL recurring cost fact per occurrence |
| Operating-cost projection | deterministic uniqueness by OperatingCostFact + OwnershipInterest + ProjectionInputFingerprint |
| Operating-cost projection ledger line | one `VEHICLE_EXPENSE` line per current projection output; superseded unstated line is ineligible, never duplicated |
| Manual investor-specific adjustment command | `(tenant_id, idempotency_key)` |
| Reimbursement approval → adjustment | one approved adjustment per reimbursement |
| Investor calculation | `(ownership_interest_id, reservation_id, calculation_input_hash)` |
| Current calculation pointer | unique `(tenant_id, reservation_id)` |
| Cross-owner correction case | unique `(tenant_id, reservation_id, current_calculation_id)` + command idempotency |
| Cross-owner correction ledger line | at most one `(tenant_id, cross_ownership_correction_id, ownership_interest_id, entry_type)` |
| Calculation ledger line | `(calculation_id, entry_type)` |
| Payment command | `(tenant_id, idempotency_key)` |
| Payment ledger line | one per `distribution_payment_id` |
| Payment reversal | at most one effective full reversal per paid normal payment |
| Statement version | `(ownership_interest_id, period_start, period_end, version)` plus non-overlap/chain invariant |
| Statement issue command | `(tenant_id, issue_idempotency_key)` |
| Live projection snapshot | same complete input fingerprint + engine/policy version reproduces same projection result/hash |

Retrying any command after timeout/crash must not duplicate source cost facts, recurring occurrences, projections, ledger effects, calculations, current-pointer advancement, statements, corrections, or payments.

---

# 16. Authorization and evidence isolation

Tenant isolation alone is insufficient because one Tenant may contain multiple Organizations and multiple investors.

## 16.1 Host finance/admin write scope

Every server-side command that creates/changes authoritative investor-finance state must authorize through the existing relationship boundary:

```text
authenticated User
  -> active Membership
  -> required finance permission
  -> current recent step-up when required
  -> target Organization
  -> target Vehicle / OwnershipInterest / Reservation relationship
```

Covered commands include:

- `ManagementAgreementVersion` / operating-cost projection-policy configuration;
- `CreateOperatingCost` / `CorrectOperatingCost`;
- `Create/Edit/DisableRecurringCostRule`;
- `InvestorReimbursement`;
- investor-specific `EconomicAdjustment`;
- Finance Refresh / recalculation;
- Statement Refresh / issue/restatement;
- `DistributionPayment`;
- `CrossOwnershipCorrection` approval/application.

Phase-A product-direction default:

- operating-cost and recurring-rule mutations use the current `finance.adjustment.write` boundary plus recent step-up/resource authorization unless the Security steward deliberately defines a more specific permission;
- Finance/Statement Refresh requires `finance.calculation.write`;
- if refresh must materialize missing recurring OperatingCostFacts, the initiating actor must also satisfy the operating-cost mutation authority; no SYSTEM privilege is substituted;
- cross-owner corrections and any operating-cost correction that affects multiple OwnershipInterests require authorization for **every affected OwnershipInterest**.

For statement issuance, Finance defines a **compound authorization precondition** rather than a new permission name: the caller must satisfy the Security-owned issue authorization **and** every Security-owned authority required by the authoritative Statement Refresh actually needed for that issue. If recurrence materialization is required, the caller must also satisfy the cost-mutation authority used by that materialization path. Issue authorization alone never delegates those nested authorities. All checks are revalidated inside the protected Vehicle-scoped transaction before any nested mutation; failure aborts issue/refresh/materialization atomically.

Client-supplied `OrganizationId`, `OwnershipInterestId`, `VehicleId`, `ReservationId`, statement ID, reimbursement ID, adjustment ID, OperatingCostFact ID, recurring-rule ID, or evidence ID is never trusted without relationship validation.

A valid OperatingCostFact or recurring-rule mutation may commit even when follow-on Finance Refresh is not authorized. In that case live economics must fail closed to non-current state from fingerprint mismatch; authorization failure is never hidden by stale cached results.

## 16.2 Investor read scope

MVP investors are read-only for these finance workflows unless a later explicit command surface is added.

Investor visibility derives from:

```text
User
  -> PartyAccessGrant
  -> Party
  -> OwnershipInterest
  -> authorized Vehicle / statement / reimbursement projection
```

Investor access to one OwnershipInterest must not expose another investor's statements, evidence, host-private finance data, or customer contact PII.

## 16.3 EvidenceDocument scope

Reimbursement/adjustment evidence must be Organization-owned and relationship-authorized.

Required invariant:

```text
EvidenceDocument.OrganizationId
  == InvestorReimbursement.OrganizationId
  == EconomicAdjustment.OrganizationId (when linked)
```

Direct-ID access to evidence must re-run authorization; possession of an object ID is not authorization.

## 16.4 Required negative security tests

At minimum:

1. Tenant A cannot read/write Tenant B finance records.
2. Same-tenant Organization A Finance user cannot mutate Organization B investor economics.
3. Investor A cannot fetch Investor B statement by guessed ID.
4. Investor A cannot fetch reimbursement evidence belonging to Investor B.
5. Host employee without Finance/Admin permission cannot issue statements or payments.
6. Revoked PartyAccessGrant immediately removes investor read visibility without rewriting historical economics.
7. Background jobs carry explicit Tenant + Organization/OwnershipInterest context and fail closed when missing.

---

# 17. Audit and provenance requirements

## 17.1 Deterministic provider-derived reservation amount

```text
InvestorStatement
→ InvestorStatementEntry
→ EconomicLedgerEntry
→ ReservationInvestorCalculation
→ ReservationEconomicSnapshot
→ ReservationEconomicComponent
→ exact SourceObservation / source-component provenance
→ RawImportRecord
→ ImportBatch
→ SourceArtifact
```

Finance remains provider-neutral while exact provider provenance remains recoverable according to upstream retention rules.

## 17.2 Agreement-derived reservation amount

```text
EconomicLedgerEntry
→ ReservationInvestorCalculation
→ ManagementAgreementVersion
→ component-treatment policy hash
→ OwnershipInterest
→ owner Party
→ managing Organization / Vehicle
```

## 17.3 Canonical manager-incurred operating-cost amount

```text
InvestorStatement / live economics
→ EconomicLedgerEntry(VEHICLE_EXPENSE)
→ OperatingCostInvestorProjection
→ projection policy code/version/hash + input fingerprint
→ OperatingCostFact
→ manual actor/provenance
   OR RecurringExpenseOccurrence
      → RecurringExpenseRuleVersion
      → RecurringExpenseRule
→ correction REVERSAL/REPLACEMENT lineage when applicable
```

The source fact is the factual manager-incurred/advanced cost. The projection is the investor-contract interpretation. Neither is a general-ledger posting, tax deduction, or proof that bank cash cleared.

## 17.4 Investor-specific manual/reimbursement amount

```text
ReservationInvestorCalculation
→ CalculationAdjustment
→ EconomicAdjustment
→ actor + timestamp + investor-specific type + amount/reason
→ optional EvidenceDocument/source artifact
→ reversal/replacement lineage
```

Approved `InvestorReimbursement` has its own workflow/evidence and produces one `EconomicAdjustment(INVESTOR_REIMBURSEMENT)`. It is not collapsed into OperatingCostFact.

## 17.5 Complete live-projection currentness provenance

A live Vehicle/OwnershipInterest result must trace to:

```text
InvestorEconomicsProjectionSnapshot
→ CompleteInputFingerprint
→ exact current reservation/source lineages
→ applicable ownership/agreement/component + operating-cost projection policies
→ effective investor-specific adjustments/overrides
→ effective OperatingCostFact correction lineages
→ expected recurring-rule occurrence set through cutoff
→ actual materialized occurrences/cost facts
→ deterministic engine/fingerprint versions
```

A UI status string is not proof of currentness; this lineage/fingerprint comparison is.

## 17.6 Legacy issued workbook amount

When exact historical provider revision cannot be proven:

```text
InvestorStatement / ReservationInvestorCalculation
→ Origin = LEGACY_ISSUED_IMPORT
→ Aaron workbook SourceArtifact hash
→ sheet + row/cell locator
→ migration version / migration batch
```

Historical workbook vehicle-cost rows are separately preserved as `OperatingCostFact(source_kind = LEGACY_IMPORT)` with workbook provenance rather than fabricated EconomicAdjustment(VEHICLE_EXPENSE) rows.

Never create a fake `SourceObservation` merely to satisfy a foreign key or make the audit chain look complete.

## 17.7 Statement provenance

An issued statement records/fixes:

- Tenant + Organization + OwnershipInterest;
- period dates;
- recognition policy code/version;
- exact ledger-entry membership;
- calculation cutoff;
- the complete-currentness proof required for issue through the statement cutoff;
- statement version;
- origin and legacy locator if applicable;
- issue actor/time/idempotency key.

## 17.8 Payment provenance

A paid state requires an explicit `DistributionPayment`. Legacy workbook settlement may have `cash_amount`, date, and reference unknown. The system must distinguish “historically marked settled” from “bank-verified cash transfer.”

Settlement does not mutate OperatingCostFact, OperatingCostInvestorProjection, reservation earnings, or the complete-input economics fingerprint; it settles an already-issued obligation.

---

# 18. Exhaustive CRV historical calculation fixture

This fixture covers **every CRV row in the workbook formula region (`X2:X40` / `AA2:AA40`)**, not only hand-picked examples. Values are the observed workbook outputs. They serve two different purposes:

1. normal completed/reconciled rows are strong rule-regression examples;
2. known anomalies/provisional rows are **legacy reproduction** fixtures and must not override owner-confirmed rules.

| Reservation | Status | Gross | Guest delivery | Extras | Tolls | Gas | Fixed delivery | Cleaning | Mgmt fee | Repair | Investor reimb. | Investor earnings |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 51109624 | Completed | 388.80 | 0.00 | 0.00 | 0.00 | 0.00 | 20.00 | 10.00 | 116.640 | 0.00 | 0.00 | 242.160 |
| 51448194 | Completed | 161.42 | 0.00 | 0.00 | 4.50 | 32.18 | 20.00 | 10.00 | 37.422 | 0.00 | 0.00 | 57.318 |
| 52037133 | Guest cancellation | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.000 | 0.00 | 0.00 | 0.000 |
| 52639319 | Completed | 116.10 | 27.00 | 0.00 | 0.00 | 0.00 | 20.00 | 10.00 | 26.730 | 0.00 | 0.00 | 32.370 |
| 50815692 | Guest cancellation | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.000 | 0.00 | 0.00 | 0.000 |
| 51104930 | Guest cancellation | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.000 | 0.00 | 0.00 | 0.000 |
| 52812744 | Completed | 117.45 | 27.00 | 0.00 | 0.00 | 0.00 | 20.00 | 10.00 | 27.135 | 0.00 | 0.00 | 33.315 |
| 52321680 | Completed | 108.54 | 0.00 | 0.00 | 0.00 | 0.00 | 20.00 | 10.00 | 32.562 | 0.00 | 0.00 | 45.978 |
| 52380930 | Guest cancellation | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.000 | 0.00 | 0.00 | 0.000 |
| 52734073 | Completed | 119.07 | 0.00 | 0.00 | 0.00 | 0.00 | 20.00 | 10.00 | 35.721 | 0.00 | 0.00 | 53.349 |
| 53406779 | Completed | 145.80 | 0.00 | 0.00 | 0.00 | 0.00 | 20.00 | 10.00 | 43.740 | 0.00 | 0.00 | 72.060 |
| 53097477 | Guest cancellation | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.000 | 0.00 | 0.00 | 0.000 |
| 53234358 | Guest cancellation | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.000 | 0.00 | 0.00 | 0.000 |
| 53646541 | Completed | 124.74 | 0.00 | 0.00 | 0.00 | 0.00 | 20.00 | 10.00 | 37.422 | 0.00 | 0.00 | 57.318 |
| 52904615 | Completed | 135.71 | 0.00 | 0.00 | 1.25 | 0.00 | 20.00 | 10.00 | 40.338 | 0.00 | 0.00 | 64.122 |
| 53410147 | Completed | 166.32 | 0.00 | 0.00 | 0.00 | 0.00 | 20.00 | 10.00 | 49.896 | 0.00 | 0.00 | 86.424 |
| 52600109 | Completed | 279.72 | 0.00 | 27.00 | 0.00 | 0.00 | 20.00 | 10.00 | 75.816 | 0.00 | 0.00 | 146.904 |
| 47612193 | Completed | 940.84 | 27.00 | 0.00 | 296.80 | 0.00 | 20.00 | 10.00 | 185.112 | 0.00 | 294.00 | 695.928 |
| 55101055 | Completed | 195.80 | 0.00 | 0.00 | 0.00 | 0.00 | 20.00 | 10.00 | 58.740 | 0.00 | 0.00 | 107.060 |
| 54946809 | Completed | 205.53 | 27.00 | 0.00 | 8.70 | 0.00 | 20.00 | 10.00 | 50.949 | 0.00 | 0.00 | 88.881 |
| 55150559 | Completed | 102.33 | 0.00 | 27.00 | 0.00 | 0.00 | 20.00 | 10.00 | 22.599 | 200.00 | 0.00 | -177.269 |
| 55480012 | Guest cancellation | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.000 | 0.00 | 0.00 | 0.000 |
| 56043455 | Host cancellation | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.000 | 0.00 | 0.00 | 0.000 |
| 55451127 | Guest cancellation | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.000 | 0.00 | 0.00 | 0.000 |
| 56416128 | Completed | 157.82 | 27.00 | 0.00 | 0.00 | 0.00 | 20.00 | 10.00 | 39.246 | 0.00 | 0.00 | 61.574 |
| 56563892 | Completed | 285.21 | 27.00 | 0.00 | 0.00 | 0.00 | 20.00 | 10.00 | 77.463 | 0.00 | 0.00 | 150.747 |
| 55271537 | Guest cancellation | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.000 | 0.00 | 0.00 | 0.000 |
| 56398909 | Completed | 368.82 | 27.00 | 0.00 | 0.00 | 0.00 | 20.00 | 10.00 | 102.546 | 430.00 | 0.00 | -220.726 |
| 53551954 | Completed | 300.48 | 27.00 | 27.00 | 2.80 | 0.00 | 20.00 | 10.00 | 73.104 | 0.00 | 0.00 | 140.576 |
| 56693654 | Completed | 280.08 | 27.00 | 0.00 | 0.00 | 0.00 | 20.00 | 10.00 | 75.924 | 0.00 | 0.00 | 147.156 |
| 56413841 | Completed | 299.25 | 27.00 | 0.00 | 0.00 | 0.00 | 20.00 | 10.00 | 81.675 | 0.00 | 0.00 | 160.575 |
| 58272888 | Completed | 284.72 | 27.00 | 40.50 | 0.00 | 0.00 | 20.00 | 10.00 | 65.166 | 0.00 | 0.00 | 122.054 |
| 56653233 | Completed | 475.87 | 27.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 134.661 | 0.00 | 0.00 | 314.209 |
| 56453779 | Guest cancellation | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.000 | 0.00 | 0.00 | 0.000 |
| 55389678 | Completed | 332.23 | 27.00 | 0.00 | 0.00 | 0.00 | 20.00 | 10.00 | 91.569 | 0.00 | 0.00 | 183.661 |
| 58352788 | In-progress | 512.54 | 27.00 | 0.00 | 0.00 | 0.00 | 20.00 | 10.00 | 145.662 | 0.00 | 0.00 | 309.878 |
| 56441542 | Booked | 266.40 | 27.00 | 0.00 | 0.00 | 0.00 | 20.00 | 10.00 | 71.820 | 0.00 | 0.00 | 137.580 |
| 58900385 | Booked | 369.43 | 27.00 | 0.00 | 0.00 | 0.00 | 20.00 | 10.00 | 102.729 | 0.00 | 0.00 | 209.701 |
| 56446376 | Guest cancellation | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.000 | 0.00 | 0.00 | 0.000 |

### Fixture classifications

- `52812744` → `LEGACY_SOURCE_MISMATCH`.
- `56653233` → `LEGACY_FIXED_CHARGE_DISCREPANCY`.
- `58352788`, `56441542`, `58900385` → `LEGACY_PROVISIONAL_FORECAST`.
- Remaining normal completed rows and zero cancellation rows may be used as rule-regression fixtures, provided the deterministic test supplies a reconciled canonical economic snapshot and the confirmed fixed-charge rules.

### Workbook rows outside the historical formula region

Rows 41–45 have source/workbook evidence but no historical management/investor calculation. Migration must not invent one:

| Worksheet row | Reservation | Status | Gross | Historical management fee | Historical investor earnings | Migration expectation |
|---:|---|---|---:|---:|---:|---|
| 41 | 58872162 | Guest cancellation | 0.00 | blank | blank | Preserve evidence; do not invent historical calculation |
| 42 | 55126068 | Booked | 1557.76 | blank | blank | Preserve evidence; do not invent historical calculation |
| 43 | 58963002 | Booked | 426.29 | blank | blank | Preserve evidence; do not invent historical calculation |
| 44 | 56688235 | Booked | 271.53 | blank | blank | Preserve evidence; do not invent historical calculation |
| 45 | 55188029 | Booked | 386.28 | blank | blank | Preserve evidence; do not invent historical calculation |

---

# 19. Exact CRV statement-period migration vectors

These are **legacy statement migration** tests. They verify exact reproduction of what was issued/marked paid in the workbook; they do not imply every historical reservation row reflects today's intended rules.

```text
Period 1:
SUM(AA2:AA14) = 536.550
Manual expenses = 0
Subtotal = 536.550

Period 2:
SUM(AA15:AA19) = 1,050.696
Tracking Sub = 8.35
Tracking Device = 99.44
Subtotal = 942.906

Period 3:
SUM(AA20:AA23) = 18.672
Tracking Sub = 8.35
Oil leak cleaning = 40.00
Oil + Filter Change = 92.09
Subtotal = -121.768

Q1 legacy issued payable
= 536.550 + 942.906 - 121.768
= 1,357.688
Marker = PAID
```

```text
Period 4:
SUM(AA24:AA26) = 61.574
Tracking Sub = 8.35
Subtotal = 53.224

Period 5:
SUM(AA27:AA30) = 70.597
Tracking Sub = 8.35
Annual Inspection = 24.99
Subtotal = 37.257

Period 6:
SUM(AA31:AA36) = 927.655
Tracking Sub = 8.35
Subtotal = 919.305

Q2 legacy issued payable
= 53.224 + 37.257 + 919.305
= 1,009.786
Marker = PAID
```

Required migration assertions:

1. Q1 exact `settlement_amount = 1357.688000`.
2. Q2 exact `settlement_amount = 1009.786000`.
3. `cash_amount` remains unknown unless separate payment evidence exists.
4. Q2 preserves historical membership/output including `56653233 = 314.209`; the migration does not silently “correct” the issued statement.
5. A separate current deterministic calculation for `56653233`, using a Completed SeaTac canonical snapshot and current agreement, expects `284.209`.

---

# 20. Legacy workbook migration contract

The historical workbook is evidence of previously issued investor economics and historical manager-incurred vehicle costs. It is not a substitute provider source feed, accounting journal, bank ledger, or tax record.

## 20.1 Migration identity

One migration execution is identified by at least:

```text
TenantId
WorkbookSHA256 = 6b59e91c9db6ee72f578ab7a072f9ce8b2fba1035a04533366b2c74adf5901cc
SheetName      = CRV
MigrationVersion
```

Every imported historical object carries a deterministic source locator such as:

```text
CRV!row:2
CRV!AA2
CRV!AD23
```

## 20.2 Source-backed, legacy-issued, and historical operating-cost classification

For each historical reservation calculation:

```text
if an exact valid historical canonical economic snapshot can be proven
    -> DETERMINISTIC_ENGINE/source-backed history may be linked
else
    -> LEGACY_ISSUED_IMPORT
       + workbook artifact
       + precise locator
```

The September 2026 Turo snapshot must not be retroactively presented as the source revision that produced an earlier Q1/Q2 statement merely because some values happen to match.

Historical workbook lines that represent actual manager-incurred vehicle costs—such as tracking subscription/device, cleaning, inspection, or maintenance expense—migrate through the canonical operating-cost source-fact path:

```text
OperatingCostFact
  SourceKind = LEGACY_IMPORT
  + workbook artifact/hash
  + exact sheet/row/cell locator
  + manager-incurred responsibility where supported by the accepted migration contract
        ↓
OperatingCostInvestorProjection
  under the historical/legacy investor-projection policy
        ↓
VEHICLE_EXPENSE-classified investor subledger effect when chargeable
```

They are **not** migrated as `EconomicAdjustment(VEHICLE_EXPENSE)`. If a workbook value is instead an investor-specific reimbursement, contractual repair charge, or fixed-charge override, it stays on the corresponding explicit investor-specific path rather than being relabeled as a manager-incurred operating cost.

Migration must fail closed when the evidence is insufficient to distinguish those meanings without a reviewed legacy mapping rule. It must never manufacture a generic expense/adjustment merely to make totals reconcile.

## 20.3 Dry run

Before apply, migration dry-run must report:

- workbook hash and migration version;
- CRV formula-region reservation count;
- rows with no historical calculation;
- planned `LEGACY_ISSUED_IMPORT` reservation rows;
- anomaly classifications (`52812744`, `56653233`, provisional rows);
- historical manager-incurred operating-cost facts, their workbook locators, projected investor effects, and totals;
- any investor-specific reimbursement/repair/override inputs separately from operating-cost facts;
- Q1 expected `1357.688`;
- Q2 expected `1009.786`;
- planned legacy payment/settlement records;
- duplicate/already-migrated source facts, projections, calculations, statements, and settlement records.

Apply is blocked if dry-run statement totals do not reconcile exactly or if one historical real-world cost would be represented through more than one authoritative source path.

## 20.4 Idempotent apply

Re-running the same workbook hash + sheet + migration version:

- creates no duplicate `OperatingCostFact`;
- creates no duplicate `OperatingCostInvestorProjection`;
- creates no duplicate reservation calculation;
- creates no duplicate ledger line;
- creates no duplicate statement/version;
- creates no duplicate legacy settlement;
- returns the same reconciliation result.

A new migration version may supersede a prior imported interpretation only through explicit immutable lineage. It never destructively rewrites an issued historical statement or re-authors the same historical operating cost as an independent `EconomicAdjustment`.

## 20.5 Complete-MVP package R1 legacy-cutover disposition — no Finance redesign

The complete-MVP R1 `SIG-01` finding is an **implementation scheduling/cutover gap**, not a missing Finance migration contract. Sections 20.1–20.4 remain authoritative and unchanged in substance for:

- `LEGACY_ISSUED_IMPORT` when authentic historical provider revision is unavailable;
- Aaron workbook hash + exact sheet/row/cell provenance;
- historical manager-incurred cost migration through `OperatingCostFact(source_kind = LEGACY_IMPORT)` + deterministic investor projection;
- migration dry-run and anomaly classification;
- exact CRV Q1 `1357.688` and Q2 `1009.786` reconciliation;
- legacy statement settlement/payment records using the existing exact-settlement semantics;
- idempotent apply by workbook hash + sheet + migration version;
- no generalized XLSX import product and no fabricated source observations.

Chat 02 must schedule this narrow deterministic cutover path in architecture/implementation planning. Finance does not add a generalized spreadsheet-import framework or redesign historical statement/payment semantics to resolve `SIG-01`.

# 21. Reconciliation requirements

## 21.1 Per-reservation deterministic calculation

For `DETERMINISTIC_ENGINE` + `EARNED` reservation calculations:

```text
ManagementFeeBase
  = sum(canonical gross components explicitly classified FEEABLE)

ManagementFee
  = ManagementFeeBase × ManagementFeeRate

InvestorBaseShare
  = ManagementFeeBase - ManagementFee

InvestorReservationEarnings
  = InvestorBaseShare
  - FixedDeliveryCharge
  - FixedCleaningCharge
  - RepairCharge
  + InvestorReimbursement
```

For the Aaron component-policy version, this reproduces:

```text
CanonicalGross
- DeliveryRevenue
- ExtrasRevenue
- TollTicketReimbursement
- FuelReimbursement
```

The engine persists/emits all intermediate values, component-policy hash, and the **complete reservation-scoped deterministic input fingerprint**. The fingerprint includes the exact current source/snapshot lineage, applicable ownership/agreement and component policy, effective investor-specific adjustments/reversals/overrides, and calculation/fingerprint policy versions. It is not a hash of only convenient monetary inputs.

For `FULL_CURRENT` posting:

```text
SUM(investor-balance-impacting ledger output from calculation)
= InvestorReservationEarnings
```

`ManagementFee` is **not** subtracted again in the investor ledger.

Manager-incurred vehicle operating costs are intentionally excluded from `ReservationInvestorCalculation`; they reconcile through Section 21.2 so one factual cost cannot also become a reservation adjustment.

## 21.2 Manager-incurred operating-cost projection reconciliation

For each effective canonical `OperatingCostFact` and affected OwnershipInterest:

```text
OperatingCostFact
  -> resolve applicable ownership at OperatingCostFact.IncurredDate
  -> resolve applicable ManagementAgreementVersion
  -> resolve explicit versioned operating-cost projection policy
  -> OperatingCostInvestorProjection.TargetInvestorSignedAmount
```

The projection policy—not `OperatingCostFact.Category`—determines chargeability.

For an ORIGINAL/REPLACEMENT manager-incurred cost, source magnitude is positive. A REVERSAL deterministically negates the referenced source effect. The investor projection may be zero or signed according to agreement/policy.

Before any issued recognition for that source-fact/owner economic lineage:

```text
CurrentOperatingCostLedgerEffect
  = TargetInvestorSignedAmount
```

If an earlier effect is already in an ISSUED statement:

```text
RecognizedIssuedOperatingCost
  = SUM(issued VEHICLE_EXPENSE-classified ledger membership
        attributable to this operating-cost economic lineage + OwnershipInterest)

CurrentOperatingCostCorrection
  = TargetInvestorSignedAmount
  - RecognizedIssuedOperatingCost
```

Only the current deterministic projection for an **unstated** source-fact/owner lineage may be a statement candidate. A superseded unstated projection/ledger line remains immutable audit history but is ineligible. Already-issued rows remain recognized history and feed the next `target - issued-recognized` computation.

A correction that changes the applicable owner or agreement treatment must reconcile each affected OwnershipInterest independently under the shared Vehicle lock:

```text
Delta(O) = TargetInvestorEffect(O) - RecognizedIssuedOperatingCost(O)
```

and fail closed unless all affected ownership/agreement/policy relationships and required authorization can be resolved. Issued history is never transferred by mutating a prior statement.

A zero target with prior issued chargeability therefore produces an offsetting later correction; a zero target with no issued recognition produces no investor-balance ledger entry.

## 21.3 Live investor-economics complete-input reconciliation

The authoritative current live projection is represented by `InvestorEconomicsProjectionSnapshot`, not by a mutable `is_current` flag.

```text
CURRENT
iff
for every applicable external source scope:
    SourceFinancialCompletenessProofV1.status == COMPLETE
AND InvestorEconomicsProjectionSourceProof[] exactly matches
    the fresh COMPLETE proof version/hash/effective ImportBatch lineage
AND StoredCompleteInputFingerprint
      == ComputeAuthoritativeInvestorInputFingerprintV1(scope, cutoff)
AND every other required deterministic input is present and valid
AND every due recurring occurrence through cutoff is materialized exactly once
```

At minimum, the complete fingerprint includes:

- Tenant + Organization + Vehicle + OwnershipInterest + cutoff/as-of + Organization financial timezone;
- every applicable provider-neutral source-completeness proof version/hash/status + SourceConnection + effective provider snapshot/SourceArtifact + effective ImportBatch/ProcessingIdentity lineage;
- current reservation economic snapshot/current-source lineage;
- ownership/effective-date resolution;
- applicable ManagementAgreementVersion, reservation component treatment, and operating-cost projection policy identity/hash;
- effective investor-specific `EconomicAdjustment` lineage;
- complete effective `OperatingCostFact` correction lineage and cost-projection inputs;
- all recurring rule/version inputs plus the expected occurrence-date set through cutoff;
- calculation/projection/fingerprint engine and policy versions.

Canonical ordering/serialization is versioned and byte-stable. Finance consumes the Import-owned source proof and does not reconstruct it from accepted canonical rows or batch status.

Source completeness is scope-local: a blocker deterministically proven to belong only to Vehicle B does not block Vehicle A; an unresolved/unknown Vehicle-or-cutoff relationship blocks the requested scope. `ReconciledWithQuarantine` may therefore coexist with `COMPLETE` for one Vehicle and `INCOMPLETE`/`UNKNOWN` for another.

If a source pointer/proof/blocker/disposition, source import, cost fact, recurring rule, ownership/agreement/override, or other authoritative input changes and refresh does not complete, the previous snapshot cannot prove equality and must read `STALE`, `BLOCKED`, or `UNKNOWN`—never `CURRENT`. This requires no second best-effort stale-marker mutation.

A successful snapshot must have exactly one matching source-proof provenance row for every applicable external SourceConnection and no foreign/extra/mismatched proof lineage.

## 21.4 Reservation current-lineage / closed-period reconciliation

Before any issued reservation recognition:

```text
only reservation-derived full/delta ledger entries generated by the single reservation-level ReservationInvestorCalculationCurrent
are eligible for statement selection
```

After issued recognition:

```text
RecognizedReservationAmount
  = SUM(issued reservation economic ledger membership)

ClosedPeriodDelta
  = Current InvestorReservationEarnings
  - RecognizedReservationAmount
```

This formula is valid only when current and recognized ownership are the same. A cross-owner change uses Section 15.4's per-owner target-minus-recognized correction.

Only the current calculation's same-owner delta line may be selected. Superseded unstated full/delta lines remain immutable audit history but are not statement candidates.

## 21.5 Statement reconciliation and debit carry

A deterministic statement may issue only after the **compound-authorized** Finance/Statement Refresh through the statement cutoff has materialized every due recurring occurrence, established `SourceFinancialCompletenessProofV1.status = COMPLETE` for every applicable external source scope, persisted exactly matching `InvestorEconomicsProjectionSourceProof[]`, and produced a complete `InvestorEconomicsProjectionSnapshot` that proves `CURRENT`. Existing ledger rows alone are not proof that the period is complete. Missing/`INCOMPLETE`/`UNKNOWN` source proof, proof-lineage mismatch, or missing nested refresh/materialization authority blocks authoritative DRAFT refresh and issue with no partial financial mutation.

```text
ReservationEarningsTotal
  = SUM(statement-member reservation/correction investor-economic entries)

OperatingCostTotal
  = SUM(statement-member VEHICLE_EXPENSE-classified entries
        sourced only by current eligible OperatingCostInvestorProjection rows)

PeriodEconomicTotal
  = SUM(all statement-member investor-economic ledger entries)

NetBeforeSettlement
  = PeriodEconomicTotal
  - OpeningInvestorDebitCarryForward

InvestorPayableTotal
  = max(NetBeforeSettlement, 0)

ClosingInvestorDebitCarryForward
  = max(-NetBeforeSettlement, 0)
```

`InvestorStatementEntry` enumerates every economic member. `CarryForwardPredecessorStatementId` identifies the exact source of opening debit, and deterministic statements form a contiguous non-overlapping chain. There are no spreadsheet `Total` rows in the domain model.

Once issued, those entries/totals and the statement's complete-currentness/cutoff provenance are immutable even if later source facts or projections change.

## 21.6 Settlement reconciliation

```text
NetSettledAmount
  = SUM(PAID NORMAL settlement_amount)
  - SUM(PAID REVERSAL settlement_amount)

OutstandingStatementBalance
  = InvestorStatement.InvestorPayableTotal
  - NetSettledAmount
```

`cash_amount` is external-money evidence and does not replace exact settlement arithmetic. `OutstandingStatementBalance` may never become negative through a NORMAL settlement.

Settlement changes only obligation settlement state. It does not mutate `OperatingCostFact`, `OperatingCostInvestorProjection`, reservation calculations, issued statement membership, or the live complete-input economics fingerprint.
# 22. Manual financial-input and operating-cost rules

1. A real manager-incurred/advanced Vehicle operating cost is authored once as `OperatingCostFact`; it is never independently authored as an investor ledger event.
2. `OperatingCostFact.Category` describes the real-world cost and does **not** itself imply investor chargeability, general-ledger account, tax treatment, payment status, or proof of settlement.
3. Investor effect from an OperatingCostFact is created only by deterministic `OperatingCostInvestorProjection` under applicable OwnershipInterest + `ManagementAgreementVersion` + versioned projection policy.
4. There is no Phase-A `EconomicAdjustment(VEHICLE_EXPENSE)` authoring or direct-posting path. Schema/API/command design must reject recreating it.
5. Manual and recurring manager-incurred costs use the **same** OperatingCostFact path; recurrence changes provenance/materialization identity, not financial semantics.
6. `RecurringExpenseRule` is configuration, not financial truth. A due occurrence materializes exactly one canonical OperatingCostFact before projection.
7. `REPAIR_CHARGE`, `INVESTOR_REIMBURSEMENT`, and `FIXED_OPERATIONAL_CHARGE_OVERRIDE` remain explicit investor-specific reservation calculation inputs through `EconomicAdjustment`; none directly posts an independent ledger line.
8. An actual manager-incurred repair bill belongs in `OperatingCostFact`; a contractual/manual investor `REPAIR_CHARGE` belongs in `EconomicAdjustment`. If both legitimately exist, their separate business meanings/provenance must be explicit; they must not be two representations of the same event.
9. `InvestorReimbursement` remains a first-class approval/evidence workflow. Approval creates exactly one `EconomicAdjustment(INVESTOR_REIMBURSEMENT)`. It is not silently converted into a manager-incurred operating cost.
10. `FIXED_OPERATIONAL_CHARGE_OVERRIDE` uses absolute `REPLACE` or `WAIVE` semantics, never additive/delta semantics. At most one effective non-reversed override may target one charge type on one reservation; ambiguity fails closed.
11. `EconomicAdjustment` correction uses exact immutable reversal + separate replacement. Operating-cost correction independently uses immutable `OperatingCostFact` REVERSAL/REPLACEMENT lineage. Neither correction mechanism may mutate the other's source truth.
12. OperatingCostFact ORIGINAL/REPLACEMENT amounts are positive source magnitudes; a REVERSAL references one eligible prior fact and deterministically negates that source effect. One original may not have multiple effective reversals.
13. A recurring rule correction never rewrites a materialized occurrence. Correct the resulting OperatingCostFact lineage; prospective rule changes use new effective-dated versions.
14. Evidence is private and relationship-authorized; evidence alone has no financial effect.
15. `REPAIR_CHARGE` claim/deductible semantics remain manual/contract-specific in MVP; no automatic formula is inferred from historical numbers.
16. Future Books/Tax logic may project independently from canonical source facts. It must not treat the investor subledger or an investor cost projection as general-ledger/tax truth.
# 23. Statement, calculation, operating-cost projection, and live-currentness lifecycle

## 23.1 Reservation calculation lifecycle

Calculations are immutable snapshots; reservation-level currentness lives in `ReservationInvestorCalculationCurrent`:

```text
PROVISIONAL
  -> no investor-balance ledger
  -> may be replaced as current dashboard forecast

EARNED / FULL_CURRENT
  -> full investor-balance decomposition exactly once
  -> eligible only while it is the current calculation and no issued recognition exists

EARNED / CLOSED_PERIOD_DELTA
  -> same-owner current target economics after prior issued recognition
  -> one signed correction line equal to target minus recognized amount

EARNED / CROSS_OWNERSHIP_CORRECTION_REQUIRED
  -> current target owner differs from owner(s) with issued recognition
  -> no automatic ordinary delta
  -> Finance/Admin correction case required

LEGACY_ISSUED
  -> frozen imported historical evidence
```

A changed reservation-scoped deterministic input creates a new immutable calculation and atomically advances the current pointer under the shared Vehicle lock.

## 23.2 Operating-cost source and investor-projection lifecycle

`OperatingCostFact` is immutable source history:

```text
ORIGINAL
  -> positive manager-incurred source fact

REVERSAL
  -> immutable exact negation of one eligible prior source fact

REPLACEMENT
  -> separate corrected positive source fact after explicit correction
```

`OperatingCostInvestorProjection` is deterministic derived investor interpretation, not authorable source truth:

```text
current projection input fingerprint for source fact + owner + policy
  -> zero investor effect
  OR
  -> VEHICLE_EXPENSE-classified investor ledger effect

changed source lineage / ownership / agreement / policy
  -> new immutable projection supersedes prior projection for that source-fact/owner interpretation
```

If the prior projection's ledger output is unstated, only the current projection remains eligible. If prior output is already issued, it remains recognized history; current target minus issued recognized effect becomes the next-open correction effect. A source reversal/replacement creates its own source-fact/projection lineage and never destructively rewrites the original.

## 23.3 Live projection currentness lifecycle

`InvestorEconomicsProjectionSnapshot` is immutable:

```text
successful authorized Finance Refresh
  -> obtain SourceFinancialCompletenessProofV1 for every applicable source scope
  -> require every proof COMPLETE and retain exact proof/effective processing lineage
  -> materialize every due recurrence through cutoff
  -> resolve all other required deterministic inputs
  -> compute complete authoritative input fingerprint including source proofs
  -> compute deterministic projection result/hash
  -> persist new snapshot + exact InvestorEconomicsProjectionSourceProof[]
```

Read state is derived:

```text
CURRENT
  -> every applicable fresh source proof is COMPLETE
     AND recorded source-proof provenance exactly matches those proofs
     AND stored fingerprint equals freshly computed authoritative fingerprint
     AND all other required inputs/occurrences validate

STALE / BLOCKED / UNKNOWN
  -> source completeness, proof lineage, equality, or other completeness cannot be proven
```

An authoritative source pointer/blocker/disposition, source/cost/rule/agreement/etc. mutation may commit even when subsequent refresh fails. That makes the old live snapshot non-current by source-proof/fingerprint comparison without mutating or deleting it.

## 23.4 Statement lifecycle

```text
DRAFT
  -> ISSUED
  -> SUPERSEDED   // only by an explicit future restatement workflow
```

There is no `PAID` statement status.

Derived settlement view:

```text
NO_PAYABLE_DEBIT_CARRIED   // payable 0, closing debit > 0
UNPAID
PARTIALLY_SETTLED
SETTLED
```

based on `InvestorPayableTotal`, debit carry, and effective paid NORMAL/REVERSAL settlement records.

Statement issue fails closed unless the compound-authorized Finance/Statement Refresh proves every applicable Import-owned source-completeness proof `COMPLETE`, exact proof provenance matches the projection, and complete `CURRENT` live investor economics are proven through the requested period/cutoff. Missing nested authority or incomplete/unknown source proof aborts before partial refresh/materialization/membership/issue mutation. Once issued, membership/totals are immutable.

## 23.5 Closed-period reservation revision — supported MVP recovery path

**MVP DESIGN DECISION (R2/R3/R4 retained):** support **adjust-next-open-statement** as the deterministic closed-period recovery path. Full historical restatement remains deferred/manual.

For same-owner reservation economics:

```text
issued statement remains immutable
    ↓
create new current EARNED calculation B
    ↓
derive RecognizedReservationAmount from issued statement membership
    ↓
ClosedPeriodDelta = B investor earnings - recognized amount
    ↓
post one CLOSED_PERIOD_CORRECTION line when delta != 0
    ↓
EconomicDate = correction recognition date
    ↓
ECONOMIC_DATE_V1 includes current correction in the next applicable open statement
```

Cross-owner changes retain the approved `CrossOwnershipCorrection` workflow. Superseded unstated reservation/correction lines are ineligible; issued rows remain recognized history.

## 23.6 Closed-period operating-cost correction — supported MVP recovery path

When a manager-incurred operating cost or its chargeability policy changes after its investor effect has been issued:

```text
issued statement remains immutable
    ↓
preserve/correct OperatingCostFact through immutable source lineage as applicable
    ↓
create current OperatingCostInvestorProjection under current deterministic inputs
    ↓
for each affected OwnershipInterest:
    RecognizedIssuedOperatingCost
      = cumulative issued VEHICLE_EXPENSE-classified economics for that lineage
    Delta
      = CurrentTargetInvestorEffect - RecognizedIssuedOperatingCost
    ↓
post current non-zero projection correction effect
    ↓
EconomicDate = accepted correction-recognition date
    ↓
next valid statement may include the current eligible correction
```

If a newer projection supersedes an unstated correction effect, the old unstated row is ineligible. If a prior correction was already issued, it remains in `RecognizedIssuedOperatingCost` for the next delta. This is the operating-cost analogue of current-vs-issued correction semantics and prevents double posting across repeated corrections.

## 23.7 Settlement lifecycle

Settlement remains downstream of the issued statement. A PAID NORMAL settlement is immutable/terminal; undo is a separate full REVERSAL payment under the existing R5-greenlit rules. Settlement never rewrites live or issued economics.
# 24. Unresolved business decisions

Only decisions that still do **not** block deterministic investor-payable implementation remain here.

1. **Repair-charge business semantics/evidence**  
   Define what an investor-specific contractual `REPAIR_CHARGE` represents (deductible allocation, investor-responsible damage/repair, claim shortfall, etc.) and minimum evidence/approval. MVP supports manual Finance/Admin-approved charges without automating claim semantics. A real manager-incurred repair bill is independently an `OperatingCostFact`; these meanings must not be conflated.

2. **Economic recipient of excluded canonical reservation components**  
   `DELIVERY_REVENUE`, `EXTRAS_REVENUE`, `TOLL_TICKET_REIMBURSEMENT`, and `FUEL_REIMBURSEMENT` are excluded from investor residual under the Aaron agreement. Determine which become management-company earned revenue versus pass-through reimbursement for future management-company reporting. This does not block investor payable.

3. **Actual historical cash amounts**  
   Workbook `PAID` proves settlement intent/status but not bank cash/date/reference. If bank evidence is later recovered, attach it without changing historical exact statement economics.

The following are **resolved MVP design decisions** and are not asserted as workbook facts unless separately labeled:

- effective reservation ownership/agreement resolution uses `EntitlementAt`; current Turo maps Completed `Trip end` to that timestamp;
- reservation canonical component treatment is explicit and fail-closed;
- new deterministic statements use `ECONOMIC_DATE_V1`; legacy workbook statements use `LEGACY_EXPLICIT_MEMBERSHIP_V1`;
- fixed operational overrides are absolute `REPLACE`/`WAIVE` actions;
- closed-period reservation revisions use next-open-statement signed delta corrections;
- negative investor economics carry forward as investor debit rather than negative payment/collections;
- `MANAGEMENT_FEE` is not separately deducted in the investor subledger;
- only the single reservation-level current calculation lineage is statement-eligible, including across ownership changes;
- pre-issue ownership re-resolution is automatic, while post-issue ownership changes require Finance/Admin cross-owner correction;
- debit carry-forward uses a strict contiguous statement predecessor chain;
- one manager-incurred real-world operating cost is one canonical `OperatingCostFact`; there is no authorable `EconomicAdjustment(VEHICLE_EXPENSE)` path;
- operating-cost investor chargeability is determined by applicable ownership + management-agreement/projection policy, never category alone;
- investor reimbursement remains an explicit separate workflow/adjustment semantic;
- monthly recurring costs materialize through the same canonical OperatingCostFact path during authorized Finance/Statement Refresh; recurrence is no longer an open/deferred Phase-A question;
- live investor-economics `CURRENT` is fail-closed from both Import-owned source financial-completeness proof(s) and the complete deterministic input fingerprint through cutoff, not a mutable stale flag or accepted-row subset;
- a deterministic statement may issue only after compound-authorized refresh proves source financial completeness plus complete-currentness through its period/cutoff;
- investor-economic subledger remains separate from any future general ledger, tax engine, bank reconciliation, AP, or bookkeeping projection.
# 25. Implementation acceptance criteria

The MVP is implementation-ready only when all of these pass.

## 25.1 Calculation/rule tests

1. Management fee uses canonical gross minus the four configured exclusions; it is never `30% × gross` blindly.
2. No standalone “investor gets 70%” rule exists.
3. Excess distance remains fee-bearing under the historical Aaron policy.
4. Completed trip cleaning is exactly `$10`; non-completed current/provisional calculation cleaning is `$0`.
5. SeaTac pickup address resolves fixed delivery to `$20`; nonmatching pickup resolves `$0`.
6. Repairs are after management-fee calculation; investor reimbursements are added after management-fee calculation.
7. Decimal calculations reproduce fractional-cent expected values without line-level cent rounding.

## 25.2 Exhaustive CRV tests

8. Every CRV formula-region row in Section 18 is represented in the fixture dataset.
9. Normal completed/zero-cancellation rows reproduce their observed workbook values when supplied equivalent canonical inputs and applicable manual adjustments.
10. `52812744` is explicitly classified legacy source mismatch; test must not fabricate a reconciled source snapshot.
11. `56653233` preserves historical `314.209` under legacy migration while a current Completed SeaTac deterministic test returns `284.209`.
12. Booked/In-progress formula rows are legacy provisional fixtures and never become statement-eligible under current rules.
13. Rows 41–45 do not gain invented historical management/investor calculations.

## 25.3 Statement/migration tests

14. Historical Q1 migrates exactly to `1357.688` and Q2 exactly to `1009.786`.
15. Historical `PAID` markers create exact legacy settlement amounts but no fabricated bank cash/date/reference.
16. Statement membership is explicit and frozen; it is not reconstructed from current trip dates.
17. Same legacy migration rerun is a no-op with identical reconciliation output.
18. Changed current provider snapshots never mutate legacy issued statement membership/totals.

## 25.4 Provider-neutral integration tests

19. Finance accepts `ReservationEconomicSnapshot`, not `SourceEarningComponent`/Turo column names directly.
20. Every provider-derived canonical component has traceable source provenance.
21. Unknown/unmapped economically material component blocks finance calculation until mapping policy is versioned.
22. A future non-Turo channel can produce the same canonical component set without changing investor calculation code.

## 25.5 Ownership/authorization/security tests

23. Calculation fails closed unless exactly one applicable 100% OwnershipInterest exists.
24. Organization + Vehicle + OwnershipInterest on agreement, reservation calculation, OperatingCostFact projection, ledger, statement, payment, reimbursement, adjustment, and evidence are relationship-consistent.
25. Cross-tenant, same-tenant cross-Organization, and cross-investor direct-ID negative tests all fail closed.
26. Investor read APIs enforce PartyAccessGrant → Party → OwnershipInterest.
27. Host finance writes enforce Membership + Finance/Admin permission + Organization/resource relationship.
28. Evidence access uses the same Organization/OwnershipInterest relationship and cannot be fetched by guessed ID.

## 25.6 Close/concurrency/idempotency tests

29. Statement issue and every investor-economic transaction for the Vehicle share the same Vehicle-scoped transaction lock, including owner-changing recalculation, operating-cost projection/correction, recurring occurrence materialization, and cross-owner correction.
30. A ledger write committed before close may enter the statement; a write ordered after `CalculationCutoffAt` cannot.
31. Concurrent statement issue attempts with the same idempotency key create one issued version.
32. Reservation calculation, operating-cost projection/materialization, adjustment, statement, and payment retries do not duplicate source facts, projections, or ledger entries.
33. Issued statement contents are immutable.

## 25.7 Determinism / AI boundary

34. Given the same complete deterministic input fingerprint and policy/engine versions, reservation calculations, operating-cost projections, and live investor projection results are byte-for-byte/decimal-for-decimal deterministic.
35. No LLM participates in component mapping at execution time, arithmetic, statement membership/totals, close, or settlement determination.


## 25.8 R2 financial-integrity and recovery tests

36. For every normal CRV formula-region fixture, the sum of investor-balance-impacting ledger entries generated by `FULL_CURRENT` equals `InvestorReservationEarnings` exactly.
37. No `MANAGEMENT_FEE` investor-balance ledger line is created when `INVESTOR_BASE_SHARE` already equals fee base minus management fee.
38. EARNED calculation A (unstated) → changed input → EARNED B → issue statement: statement includes B economics exactly once and never A+B.
39. If A was already issued, EARNED B creates no second full decomposition; it creates only `B investor earnings - recognized issued reservation amount` as the current closed-period correction.
40. B closed-period correction → changed input → C before B is stated: only C's current correction is eligible; B remains immutable audit history.
41. After a correction is issued, a later revision computes its delta against cumulative recognized issued economics, including prior issued correction lines.
42. OwnershipInterest and ManagementAgreementVersion boundary tests resolve by `EntitlementAt` using half-open effective ranges and fail closed on zero/multiple matches.
43. A provider component may be successfully mapped to a new canonical code while finance still fails closed because the applicable agreement component policy has not explicitly classified that code.
44. `FIXED_OPERATIONAL_CHARGE_OVERRIDE(REPLACE, 5)` replaces a `$20` default with `$5`; `WAIVE` produces `$0`; neither adds a delta to the default.
45. New statement candidate selection under `ECONOMIC_DATE_V1` is deterministic from `EconomicDate`, current lineage, cutoff, scope/currency, and prior membership; no unstated “intended period” rule exists.
46. A negative period result creates `InvestorPayableTotal = 0` plus positive `ClosingInvestorDebitCarryForward`; no negative `DistributionPayment` is allowed.
47. A later positive statement consumes opening debit before producing investor payable.
48. NORMAL settlement must be positive, same-currency, and cannot exceed outstanding payable.
49. A `PAID` payment is terminal; undo uses one same-scope/same-currency full `REVERSAL` record that restores outstanding balance with opposite ledger effect.
50. Closed-period provider revision end-to-end: issued statement unchanged → current recalculation → signed correction → next open statement membership → resulting cumulative recognized economics equal latest current investor earnings.


## 25.9 R3 convergence tests

51. Unstated owner transition: current A resolves OwnershipInterest X → source revision moves `EntitlementAt` → current B resolves Y → only B/Y economics are statement-eligible; X/A remains immutable history and cannot enter any statement.
52. Issued owner transition: X economics already issued → current B resolves Y → ordinary `CLOSED_PERIOD_DELTA` is rejected → `CROSS_OWNERSHIP_CORRECTION_REQUIRED` case exists with no automatic investor-balance posting.
53. Approved cross-owner correction: X recognized `+100`, current Y target `+120` → correction application posts X `-100` and Y `+120`; cumulative per-owner recognized economics reconcile to targets after both corrections issue.
54. Cross-owner authorization: correction approval/application fails unless Finance/Admin actor is authorized for the managing Organization and all affected OwnershipInterests.
55. X statement issue racing X→Y recalculation serializes under the Vehicle lock; no stale X full economics can slip into a statement after B becomes current.
56. Debit chain: Jan closing debit `100` → attempt to issue a non-contiguous Mar statement before Feb → rejected.
57. Debit chain arithmetic: Jan close `100`; Feb economic `60` → Feb closing debit `40`; Mar economic `100` → Mar payable `60`, closing debit `0`, with explicit predecessor pointers.
58. Overlapping active statement periods are rejected; concurrent attempts to issue successive periods serialize so only the valid chronological chain commits.

## 25.10 R4 scoped convergence tests

59. Repeated unstated correction: X `+100` issued → B/Y target `120` → C1 APPLIED (`X -100`, `Y +120`) but neither row stated → C/Y target `130` → C2 APPLIED → C1 unstated rows are ineligible by current-calculation lineage → final issued recognized amounts are exactly X `0`, Y `130`.

60. Partially issued correction: same setup, but only C1 `X -100` is issued before C arrives → C2 derives issued recognized X `0`, Y `0` → C2 posts only `Y +130`; stale unstated C1 `Y +120` is ineligible.

61. Fully issued correction then revision: both C1 rows are issued before C arrives → issued recognized X `0`, Y `120` → C2 posts only `Y +10`.

62. Cross-owner correction persistence negatives: database/API reject same-tenant correction rows whose Reservation, Vehicle, Organization, CurrentCalculation, or affected OwnershipInterest relationships do not match; correction-sourced ledger rows reject any EntryType other than `CROSS_OWNERSHIP_CORRECTION`; duplicate per-owner lines for one correction are rejected.

63. Document/schema consistency gate: `PostingDisposition`, later-provider-revision flow, statement candidate rules, DDL constraints, and implementation tests all encode the same same-owner vs cross-owner branch and current-correction-lineage rule.

---

## 25.11 Financial Platform Product Direction Section-18 synchronization tests

64. Manual manager-incurred cost single-source path: `CreateOperatingCost` creates exactly one `OperatingCostFact`; it cannot also create `EconomicAdjustment(VEHICLE_EXPENSE)` and there is no API/schema path for that adjustment type.

65. Category-not-chargeability: the same `TRACKING` or `REPAIR` OperatingCostFact category under two different ManagementAgreement/projection-policy versions may produce different investor effects; missing or ambiguous cost-projection policy fails closed rather than defaulting from category.

66. Zero-chargeability: a valid OperatingCostFact whose applicable policy returns zero remains authoritative factual history but creates no investor-balance VEHICLE_EXPENSE deduction.

67. Investor reimbursement separation: an approved investor reimbursement creates exactly one `EconomicAdjustment(INVESTOR_REIMBURSEMENT)` consumed by the reservation calculation and does not create a manager-incurred OperatingCostFact unless a separately evidenced real-world manager cost legitimately exists.

68. Actual repair-vs-contractual charge distinction: an actual manager-incurred repair bill may exist as OperatingCostFact while an independently justified contractual `REPAIR_CHARGE` may exist as EconomicAdjustment; tests prove neither is mechanically cloned from the other and the same event cannot be double-authored through both paths.

69. Monthly recurring materialization: EffectiveFrom anchor, last-day fallback, no proration, Organization financial timezone, EffectiveTo, prospective edit/disable/re-enable, and same-month retry/concurrency all produce exactly one occurrence and one OperatingCostFact per due rule/date.

70. No-import recurring refresh: authorized Finance/Statement Refresh with no new Turo import still materializes all due recurring occurrences through cutoff and includes their deterministic investor projections in the complete live result.

71. Recurrence authority fail-closed: refresh that lacks current operating-cost mutation authority or finance calculation authority creates no partial occurrence/source fact and does not report the affected live projection CURRENT.

72. Complete-input currentness: mutation of current reservation/source lineage, OperatingCostFact correction, recurring rule/version/expected occurrence set, ownership, agreement, adjustment/override, or relevant engine/policy version changes the authoritative fingerprint; an old snapshot can no longer read CURRENT even if a stale-marker write never occurred.

73. Missing due recurrence: if a required occurrence through cutoff is absent, duplicated, or ambiguously versioned, `ComputeAuthoritativeInvestorInputFingerprintV1` cannot validate completeness and live economics are BLOCKED/non-current.

74. Refresh crash after valid source mutation: a committed Turo CURRENT import or committed OperatingCostFact correction remains valid if follow-on refresh fails; prior `InvestorEconomicsProjectionSnapshot` fails CURRENT by fingerprint comparison and issued statements remain unchanged.

75. Operating-cost pre-issue supersession: projection P1 creates an unstated VEHICLE_EXPENSE-classified line; changed source/agreement/policy creates current P2 before issue; only P2's current target effect is statement-eligible and P1 remains immutable audit history.

76. Operating-cost post-issue correction: issued recognized cost effect R followed by current target T produces only `T - R` as the next-open current projection correction; issued membership is never rewritten.

77. Repeated operating-cost correction: if correction projection P2 is superseded before its line is stated, P2's unstated line becomes ineligible; a later projection computes against cumulative **issued** recognized economics only, preventing double posting.

78. Operating-cost owner/policy boundary: cost correction that changes affected OwnershipInterest computes `Target(O) - IssuedRecognized(O)` independently for every affected owner under `VehicleInvestorEconomicLock`; authorization/resource predicates for every affected ownership scope fail closed.

79. Statement completeness gate: Statement Refresh materializes due recurrences, refreshes all required reservation/cost projections, recomputes the complete fingerprint, and refuses issue unless `InvestorEconomicsProjectionSnapshot` proves CURRENT through `PeriodEnd`/cutoff. Existing ledger rows alone cannot satisfy this gate.

80. Statement operating-cost membership: every statement-member `VEHICLE_EXPENSE` line references an eligible `OperatingCostInvestorProjection`, never an EconomicAdjustment; superseded unstated projection rows are excluded while previously issued rows remain frozen recognized history.

81. Settlement isolation: NORMAL/REVERSAL DistributionPayment changes only exact settlement/outstanding balance; it does not mutate OperatingCostFact, cost projection lineage, reservation calculations, issued statement membership, or complete-input currentness.

82. Future-ledger boundary: Phase-A schema/services generated from this specification contain no AccountingBook, JournalEntry/Posting, chart-of-accounts, bank reconciliation, AP/vendor, TaxAsset/depreciation, or tax-workpaper implementation; future books/tax projections consume canonical source facts independently of the investor subledger.

83. Legacy vehicle-cost migration: CRV historical manager-incurred cost lines migrate idempotently as `OperatingCostFact(LEGACY_IMPORT)` + deterministic historical investor projection and are never duplicated as `EconomicAdjustment(VEHICLE_EXPENSE)`.

84. Cross-document consistency gate: product direction Revision 3, domain model Revision 7, and Finance Revision 8 encode the same operating-cost source-fact, recurring materialization, agreement-policy chargeability, complete-currentness, issued-statement immutability, and future-GL separation contracts.

---

## 25.12 Complete-MVP package R1 CRIT-01 / SIG-02 focused tests

85. In-scope invalid-money quarantine: CURRENT import may commit valid rows and finish `ReconciledWithQuarantine`, but Vehicle A proof is `INCOMPLETE`; Vehicle A live economics cannot be `CURRENT`, authoritative DRAFT refresh is blocked, and statement issue is rejected with no partial membership/totals/issue mutation.

86. Deterministic resolution/reprocess: resolving/reprocessing the blocked Vehicle A row advances the applicable source/ProcessingIdentity lineage; proof becomes `COMPLETE`; the Finance fingerprint/source-proof provenance advances exactly once and retry is idempotent.

87. Other-Vehicle isolation: Vehicle B-only quarantine is deterministically `OUT_OF_SCOPE` for Vehicle A; Vehicle A may be `CURRENT` when all other inputs pass, while Vehicle B remains `INCOMPLETE`. Batch-level `ReconciledWithQuarantine` is never used as a global Finance boolean.

88. Unknown scope: unresolved Vehicle/cutoff relevance yields `SourceFinancialCompletenessProofV1 = UNKNOWN`; Finance blocks CURRENT, authoritative DRAFT refresh, and issue for that requested scope.

89. Disappearance/regression/reconciliation blocker: unresolved financially relevant disappearance, regression review, or reconciliation issue remains in the proof and blocks Finance until deterministic reprocessing or an allowed reviewed disposition resolves it.

90. Source proof replay: identical effective source pointer/provider snapshot, ImportBatch/ProcessingIdentity, issues/dispositions, Vehicle and cutoff produce identical proof status/hash; `computed_at` does not affect Finance fingerprint input.

91. Completeness changes after projection: source pointer, blocker/disposition, processing lineage, proof version/hash, or status changes after a successful projection; the old `InvestorEconomicsProjectionSnapshot` becomes non-CURRENT by source-proof/fingerprint comparison without any stale-marker side write.

92. Projection proof provenance: successful current projection has exactly one `InvestorEconomicsProjectionSourceProof` for every applicable SourceConnection, each status `COMPLETE` and matching the exact effective ImportBatch/proof version/hash; missing, duplicate, foreign, extra, or mismatched provenance rejects successful-current state.

93. Statement source-completeness gate: statement DRAFT refresh/issue fails when any applicable proof is absent, `INCOMPLETE`, `UNKNOWN`, or mismatched to the projection/fingerprint provenance; issued historical statements remain unchanged.

94. Compound authorization — missing refresh authority: actor satisfies Security's statement-issue authorization but lacks the authority Security requires for authoritative Statement Refresh; `IssueInvestorStatement` fails before protected financial mutation and does not implicitly elevate/borrow refresh authority.

95. Compound authorization — missing recurrence materialization authority: actor satisfies issue + recalculation authority but the requested cutoff has missing due recurring occurrences and the actor lacks the Security-owned cost-mutation authority; issue fails atomically with no new occurrence, OperatingCostFact, projection, DRAFT membership/totals, cutoff freeze, or ISSUED state.

96. Compound authorization — no recurrence materialization required: if the authoritative refresh needs no cost/configuration mutation, Finance does not invent an extra authority beyond what Security defines for the actual nested operations; issue still requires all issue + refresh + resource/step-up predicates and source completeness.

97. Compound authorization race/rollback: Membership, permission, step-up, or resource relationship changes between initial request and protected Vehicle-lock revalidation cause the entire issue/refresh attempt to fail with no partial materialization/currentness/membership/issue mutation.

98. Legacy migration regression: Sections 20.1–20.4 still reproduce `LEGACY_ISSUED_IMPORT`, workbook provenance, historical OperatingCostFact migration, dry-run, Q1/Q2 totals, legacy settlement/payment, and idempotent apply without a generalized XLSX-import path.

# 26. R1 panel-review resolution record

R1 decision was `REVISE_PLAN`. This revision addresses the review findings as follows.

| R1 finding | Revision disposition | Verification |
|---|---|---|
| CRIT-01 legacy CRV provenance could fabricate source revision | **Addressed:** `LEGACY_ISSUED_IMPORT` origin + workbook artifact/locator; source-backed only with proven historical canonical snapshot | migration tests 10, 15, 17, 18 |
| CRIT-02 statement recognition/membership ambiguous | **Addressed in R1 for historical membership:** explicit `InvestorStatementEntry`; historical workbook membership imported directly. **Superseded for new deterministic statements by R2:** `ECONOMIC_DATE_V1` supplies the candidate-selection rule while legacy migration remains explicit membership. | tests 16, 30, 45 |
| CRIT-03 exact fractional obligation vs cent cash conflated | **Addressed:** `settlement_amount(19,6)` + optional `cash_amount(19,2)` + variance | tests 14–15 |
| CRIT-04 server-side resource authorization unspecified | **Addressed:** Organization/Membership host writes + PartyAccessGrant/OwnershipInterest investor reads; direct-ID fail-closed | tests 23–28 |
| SIG-01 finance coupled to Turo snapshot/component names | **Addressed:** provider-neutral `ReservationEconomicSnapshot/Component`; canonical codes; fail closed mapping | tests 19–22 |
| SIG-02 economics scoped by InvestorId/Vehicle instead of OwnershipInterest/Organization | **Addressed:** all financial aggregates use `OrganizationId + OwnershipInterestId` | tests 23–24 |
| SIG-03 close race / frozen membership insufficient | **Addressed:** shared OwnershipInterest advisory lock + immutable cutoff + explicit membership | tests 29–33 |
| SIG-04 forecast/provisional economics mixed with statement economics | **Addressed:** `PROVISIONAL` vs `EARNED`; only Earned posts statement-eligible ledger | tests 4, 12 |
| SIG-05 golden tests were selective | **Addressed:** exhaustive CRV formula-region fixture plus rows without formulas | tests 8–13 |
| SIG-06 legacy migration idempotency/provenance underspecified | **Addressed:** workbook hash + sheet/locator + migration version + dry-run + idempotent apply | tests 14–18 |
| MIN-01 stale `StatementPeriodId` on adjustment | **Addressed:** removed; downstream explicit statement membership owns period inclusion | schema review |
| MIN-02 statement lifecycle mixed with Paid | **Addressed:** statement statuses only Draft/Issued/Superseded; settlement-derived view separate | test 15 |
| MIN-03 precision underspecified | **Addressed:** `numeric(19,6)` for investor economics/ledger/statements/settlement | precision tests |
| MIN-04 stale import-spec filename | **Addressed:** canonical `mvp-turo-import-spec.md` dependency | document check |
| SEC-001 finance commands lacked server-side relationship authorization | **Addressed in plan:** explicit host/investor authorization paths and negative tests | tests 25–28; Security must re-review implementation plan |
| SEC-002 evidence could leak across same-tenant relationships | **Addressed in plan:** Organization-owned evidence + relationship authorization + direct-ID negatives | test 28 |

R2 should verify these controls and remaining human-policy decisions; it should not treat the four remaining business decisions in Section 24 as silently resolved.

---

# 27. R2 panel-review resolution record

R2 decision was `REVISE_PLAN` with 2 Critical and 6 Significant findings. This revision provides the following plan-level dispositions for the R3 convergence gate.

| R2 finding | Revision disposition | Verification |
|---|---|---|
| CRIT-R2-01 management fee deducted twice | **Addressed:** remove `MANAGEMENT_FEE` from investor-balance ledger; management fee remains calculation/management entitlement; full-posting invariant equals investor earnings | tests 36–37 + exhaustive CRV |
| CRIT-R2-02 superseding EARNED calculations can both post | **R2 same-owner fix retained; R3 residual addressed:** reservation-level current pointer survives owner changes; post-issue cross-owner transitions fail closed to correction workflow | tests 38–41, 51–55 |
| SIG-R2-01 ownership/agreement applicability date undefined | **Addressed:** provider-neutral `EntitlementAt`; current Turo Completed mapping uses source Trip end; half-open effective-date resolution | test 42 |
| SIG-R2-02 `EXPLICIT_ASSIGNMENT_V1` automatic selection undefined | **Addressed:** new deterministic statements use `ECONOMIC_DATE_V1`; legacy migration keeps explicit workbook membership | test 45 |
| SIG-R2-03 provider mapping fail-closed did not protect fee treatment | **Addressed:** separate agreement component-policy universe; every non-zero gross component requires explicit `FEEABLE/EXCLUDED` treatment | test 43 |
| SIG-R2-04 fixed operational override semantics undefined | **Addressed:** absolute `REPLACE` / `WAIVE`, never delta; ambiguity fails closed | test 44 |
| SIG-R2-05 closed-period correction had containment but no recovery | **Addressed:** signed `CLOSED_PERIOD_CORRECTION` delta into next open statement; restatement deferred | tests 39–41, 50 |
| SIG-R2-06 settlement/negative payable invariants incomplete | **R2 arithmetic retained; R3 residual addressed:** explicit predecessor pointer + contiguous/non-overlapping statement chain; settlement rules unchanged | tests 46–49, 56–58 |

R2 confirmed all R1 findings and `SEC-001` / `SEC-002` resolved at plan level; R3 subsequently found the two residual issues recorded in Section 28 and no new security findings.

---

# 28. R3 panel-review resolution record

R3 decision was `REVISE_PLAN` with 1 Critical, 1 Significant, 0 Minor, and 1 explicit human-policy question. This revision adopts the R3-recommended MVP policy and closes both plan-level gaps.

| R3 finding | Revision disposition | Verification |
|---|---|---|
| CRIT-R2-02 residual — owner-changing current lineage | **Addressed:** current pointer is reservation-level `(Tenant, Reservation)` with `CurrentOwnershipInterestId`; Vehicle-scoped finance lock survives owner changes; pre-issue re-resolution automatically replaces current owner; post-issue cross-owner change creates `CROSS_OWNERSHIP_CORRECTION_REQUIRED` and no ordinary delta; approved correction posts per-owner `target - recognized` signed entries | tests 51–55 |
| SIG-R2-06 residual — debit carry has no deterministic predecessor | **Addressed:** `CarryForwardPredecessorStatementId`; chain keyed by Tenant + Organization + OwnershipInterest + Currency + recognition-policy lineage; contiguous increasing non-overlapping issue order; predecessor closing debit must equal successor opening debit | tests 56–58 |
| Human policy — may earned reservation change owner after later source revision? | **Resolved for MVP:** automatic re-resolution before issued recognition; after issued recognition fail closed to Finance/Admin correction workflow; never auto-transfer issued entitlement from a late provider snapshot | tests 51–55 |

R3 reconfirmed the R2 management-fee, `ECONOMIC_DATE_V1`, component-classification, override, same-owner delta, settlement, evidence-isolation, authorization, and deterministic-AI-boundary decisions. They are not reopened here. Any subsequent R4 is scoped only to verification of these R3 changes unless a new blocker is discovered.

---

# 29. R4 scoped panel-review resolution record

R4 decision was `REVISE_PLAN` with 1 Critical, 2 Significant, 0 Minor, and no human-policy questions. This revision is intentionally limited to the named R4 convergence gaps.

| R4 finding | Revision disposition | Verification |
|---|---|---|
| CRIT-R4-01 — applied-but-unstated cross-owner correction can survive a newer revision | **Addressed:** unstated correction rows are eligible only when their correction's `CurrentCalculationId` equals the reservation-level current calculation; superseded unstated rows remain immutable but ineligible; new corrections calculate only from issued recognized economics, so partial issuance is handled correctly | tests 59–61 |
| SIG-R4-01 — domain model contains contradictory pre-R3 posting/revision text | **Addressed by narrow synchronization:** posting disposition includes `CROSS_OWNERSHIP_CORRECTION_REQUIRED`; later-provider-revision flow branches same-owner vs cross-owner; statement selection carries the correction-currentness rule | test 63 + domain consistency check |
| SIG-R4-02 / SEC-003 — correction persistence lacks relationship-integrity constraints | **Addressed by narrow synchronization:** tenant/resource composite FKs bind correction to current calculation + Reservation + Vehicle + Organization; ledger correction source gets same-tenant FK, source/type constraint, and per-owner uniqueness; same-tenant mismatch negative tests required | test 62 |
| R3 debit-carry chain | **R4 confirmed resolved; unchanged** | tests 56–58 |

R4 reconfirmed prior authorization/evidence isolation findings and did not reopen the R3 owner-change policy. Chat 06 import semantics are not changed by this revision.

`Investor R4 SEC-003` is **PLAN ADDRESSED / REVIEW FOR RESOLUTION** after the synchronized domain-model FK/constraint changes. Do not label the new cross-owner persistence path security-cleared until a narrow R5 or implementation-level verification confirms the constraints and negative tests.

Any subsequent R5 is a narrow exception/convergence review of only these R4 changes unless implementation discovers a new blocker.

---

# 30. R5 baseline and Financial Platform Product Direction Section-18 synchronization record

## 30.1 R5 pre-synchronization reviewed baseline

`panel-review-mvp-investor-calculation-spec__2026-09-20__r5.md` reviewed the Revision-7 investor-finance design and returned:

```text
GREENLIGHT_WITH_ACCEPTED_RISKS
Critical:    0
Significant: 0
Minor:       0
Human-policy questions: 0
```

R5 closed the R4 correction-lineage/domain-synchronization/security findings at the plan/design level. This Section-18 synchronization **preserves** those reviewed decisions. R5 did not review the later Financial Platform Product Direction operating-cost/currentness additions, so this record does not retroactively claim that it did.

Preserved R1–R5 financial-integrity contracts include at least:

- no management-fee double deduction;
- exact decimal/fractional-cent economics;
- provider-neutral canonical reservation economics;
- explicit agreement component treatment/fail-closed unknown codes;
- reservation-level current calculation lineage across owner changes;
- same-owner next-open closed-period deltas;
- approved cross-owner correction semantics and current-correction lineage;
- immutable issued statement membership;
- strict debit-carry predecessor chain;
- explicit settlement records/reversals separate from earnings;
- relationship-aware authorization/evidence isolation;
- deterministic/no-LLM authoritative calculation, statement, or settlement logic.

## 30.2 Section-18 synchronization source

Source decision:

```text
/Projects/Fleet-Management/shared/canonical/
financial-platform-product-direction.md
Revision 3
Status: R3 GREENLIGHT; founder + Chat 00 accepted
```

Required target:

```text
/Projects/Fleet-Management/shared/canonical/
mvp-investor-calculation-spec.md
Steward: 05-financial-ledger
```

Upstream domain synchronization consumed:

```text
mvp-domain-model.md Revision 7
```

## 30.3 Focused synchronization disposition

| Section-18 requirement | Chat-05 disposition |
|---|---|
| Investor economics consumes canonical manager-incurred operating-cost source facts | **Synchronized:** `OperatingCostFact` is the one factual manager-incurred/advanced cost source; investor effect comes only through deterministic `OperatingCostInvestorProjection`. |
| Chargeability from agreement/projection policy, not category | **Synchronized:** ownership + applicable ManagementAgreementVersion + explicit versioned projection policy determines zero/non-zero/signed investor effect; missing/ambiguous policy fails closed. |
| Prevent double posting with EconomicAdjustment | **Synchronized:** authorable `EconomicAdjustment(VEHICLE_EXPENSE)` and direct adjustment-ledger path are removed; all Phase-A EconomicAdjustment types remain reservation-specific calculation inputs only. |
| Preserve investor reimbursement separately | **Synchronized:** approved `InvestorReimbursement` still creates exactly one `EconomicAdjustment(INVESTOR_REIMBURSEMENT)`; it is not silently treated as manager-incurred operating cost. |
| Recurring costs use same canonical source-fact path | **Synchronized:** due deterministic monthly occurrence → exactly one recurring OperatingCostFact → same cost projection path. |
| Live vs issued semantics | **Synchronized:** live state uses immutable `InvestorEconomicsProjectionSnapshot` with complete fingerprint; issued statement membership/totals remain immutable. |
| Cost correction/reversal after calculation/statement use | **Synchronized:** immutable OperatingCostFact reversal/replacement + current projection; unstated superseded projection effects become ineligible; issued effects remain recognized; later target-minus-issued delta flows next-open. |
| Complete deterministic input fingerprint/currentness | **Synchronized:** complete scope/source/ownership/agreement/adjustment/cost/recurrence/engine input set is versioned and byte-stably hashed. |
| Fail-closed CURRENT | **Synchronized:** `CURRENT` exists only on proven fingerprint equality + complete valid due-occurrence set; otherwise STALE/BLOCKED/UNKNOWN. |
| Statement/settlement behavior | **Synchronized:** statement issue requires complete CURRENT proof through cutoff before freezing membership; settlement remains explicit downstream obligation settlement only. |
| Investor subledger separate from future GL | **Synchronized:** no GL/bookkeeping/tax/bank/AP implementation is added; future projections independently consume canonical facts rather than treating investor ledger as accounting truth. |

## 30.4 Cross-context conflict disposition

No Chat-00 escalation is required by this synchronization. The greenlit product direction explicitly assigns these investor-finance semantics to Chat 05, and canonical domain Revision 7 supplies compatible persistence/domain seams. No accepted project-level ADR or bounded-context ownership rule had to be overridden.

If implementation later reveals that the same OperatingCostFact cannot support investor economics and future accounting projections without changing project-wide source-fact ownership or module boundaries, that would be a new Chat-00 escalation condition; this revision does not make that change.

## 30.5 Verification status

Tests 64–84 are the focused implementation/convergence gates introduced by this synchronization. Passing the prior R5 review is not a substitute for executing these new tests against implementation. A new broad finance redesign is not implied; review should reopen only if these additions expose a new Critical/Significant architecture, security, persistence, or financial-integrity decision.

# 30.6 Complete-MVP package R1 CRIT-01 / SIG-02 synchronization record

Source contracts:

- `/Projects/Fleet-Management/00-masterplan/history/panel-review-complete-mvp-package__2026-09-25__r1.md` — `CRIT-01`, `SIG-02`, and legacy-cutover `SIG-01` context;
- `/Projects/Fleet-Management/shared/canonical/mvp-turo-import-spec.md` focused CRIT-01 revision — Import-owned `SourceFinancialCompletenessProofV1`;
- `/Projects/Fleet-Management/shared/canonical/mvp-domain-model.md` Revision 8 — `SourceCurrentSnapshotPointer`, `InvestorEconomicsProjectionSourceProof[]`, source-proof persistence/fingerprint seam, and SIG-03/SEC-002 persistence hardening;
- `/Projects/Fleet-Management/shared/canonical/mvp-security-scope.md` Revision 5 — current named permission/resource boundaries; Security remains owner of exact permission names;
- `/Projects/Fleet-Management/03-domain-model/working/handoff-complete-mvp-r1-source-financial-completeness__2026-09-25__chat05.md` — focused Chat 03 → Chat 05 handoff.

Focused disposition:

| Complete-MVP R1 item | Chat-05 disposition |
|---|---|
| `CRIT-01` accepted subset may fingerprint as complete | **Addressed:** Finance now requires Import-owned provider-neutral `SourceFinancialCompletenessProofV1 = COMPLETE` for every applicable source scope, includes exact proof/effective source-processing lineage in the complete fingerprint, and freezes matching `InvestorEconomicsProjectionSourceProof[]` provenance. |
| Scope-local completeness | **Preserved:** Import decides `IN_SCOPE` / `OUT_OF_SCOPE` / `UNKNOWN`; Finance blocks `UNKNOWN` but does not let an unrelated Vehicle B blocker poison Vehicle A when Import proves it out of scope. |
| Live currentness after source blocker/pointer/disposition changes | **Addressed:** changed proof/fingerprint inputs make old live projection non-CURRENT without a separate stale-marker write. |
| Statement completeness | **Addressed:** authoritative DRAFT refresh and issue require all applicable source proofs COMPLETE + matching projection provenance + full complete-input CURRENT state. |
| `SIG-02` issue/refresh authorization contradiction | **Addressed at Finance behavioral boundary:** issue authority never implies nested refresh/materialization authority; all Security-owned authorities required by actual nested operations are preconditions/revalidated before mutation, and failure aborts issue/refresh/materialization atomically. Exact permission names remain Security-owned. |
| Legacy migration / package `SIG-01` | **No Finance redesign:** Sections 20.1–20.4 remain authoritative; Chat 02 must schedule the narrow deterministic cutover rather than build generalized XLSX import. |
| Prior Finance R1–R5 + Revision-8 decisions | **Preserved:** reservation math/precision, management-fee treatment, operating-cost source-fact projection, recurring rules, current-lineage/cross-owner correction, statement immutability/debit carry, settlement isolation, and future-GL separation are unchanged except where source completeness/compound authorization explicitly strengthens the gate. |

No new Chat-00 decision is required: the package review and updated Import/Domain contracts already define the cross-context behavior. The remaining actions are steward synchronization in Chat 04 and Chat 02, captured by focused handoffs.

# 31. MVP decision summary

## Decision — Investor subledger, not full accounting

**Decision:** use an immutable investor-economic subledger sufficient to explain entitlements and settlement; do not build a general chart of accounts in this MVP.

**Rationale:** the immediate business outcome is replacing the investor spreadsheet safely.

**Tradeoffs:** no GAAP statements, tax basis, depreciation, debt accounting, bank reconciliation, or company-wide P&L yet.

**Revisit:** when the platform begins replacing company-wide accounting rather than this investor workflow.

## Decision — Finance consumes canonical economics

**Decision:** finance consumes `ReservationEconomicSnapshot/Component`, never provider-specific earnings columns directly.

**Rationale:** Turo must remain an adapter; exact provider provenance is still retained upstream.

**Tradeoffs:** requires one deterministic canonical mapping layer.

**Revisit:** extend canonical taxonomy/mappings; do not put provider names back into finance rules.

## Decision — OwnershipInterest is the investor-economic scope

**Decision:** agreement, calculation, ledger, statement, and settlement are scoped to `Organization + OwnershipInterest`; MVP permits one applicable 100% owner at a time.

**Rationale:** ownership drives entitlement and authorization and is already part of the canonical domain model.

**Tradeoffs:** true co-ownership/waterfalls are deferred.

**Revisit:** only with explicit multi-owner allocation semantics.

## Decision — Issued statements are immutable explicit membership snapshots

**Decision:** issue under the shared `VehicleInvestorEconomicLock`, freeze exact ledger membership and `CalculationCutoffAt`, and never silently recalculate issued history.

**Rationale:** source observations and calculations can change after period close.

**Tradeoffs:** later corrections require an explicit adjustment/restatement workflow.

**Revisit:** recognition policy may evolve; immutability does not.

## Decision — Historical workbook migration is allowed to be legacy-native

**Decision:** use `LEGACY_ISSUED_IMPORT` when an exact historical provider revision is unavailable rather than inventing source provenance.

**Rationale:** audit honesty is more important than creating an artificial perfect lineage.

**Tradeoffs:** some historical issued calculations point to workbook evidence rather than canonical source snapshots.

**Revisit:** if older authentic provider exports are later recovered, add provenance/corroboration without rewriting the historical statement.

## Decision — Exact entitlement and actual cash are separate

**Decision:** preserve exact economics/settlement at six decimal places and actual cash separately at cents when known.

**Rationale:** historical workbook economics contain fractional cents; cash systems do not necessarily move fractional cents.

**Tradeoffs:** settlement and cash evidence can differ by an explicit rounding variance.

**Revisit:** define a default cash-rounding/carry policy when automated payouts are implemented; never rewrite historical exact economics.

## Decision — Investor subledger posts residual share, not management fee twice

**Decision:** `InvestorBaseShare = ManagementFeeBase - ManagementFee` is the positive reservation base posted to the investor subledger. `ManagementFee` is retained as an explicit calculation/audit/management entitlement but is not also an investor-balance deduction.

**Rationale:** this makes subledger sum equal workbook investor earnings and removes the R2 double-counting defect.

**Tradeoffs:** management-company P&L remains a separate future projection.

**Revisit:** never reintroduce double counting; a future ledger decomposition may start from fee base instead, but only one decomposition can be authoritative.

## Decision — Current calculation lineage controls statement eligibility

**Decision:** one reservation-level current calculation pointer exists per Tenant + Reservation and records its current OwnershipInterest. Superseded unstated versions remain immutable but cannot enter a statement even when the owner changes. Same-owner post-issue revisions post signed deltas; cross-owner post-issue revisions fail closed to an approved correction workflow.

**Rationale:** mutable marketplace snapshots can move `EntitlementAt` across ownership boundaries; ownership-scoped pointers can leave two owners simultaneously current.

**Tradeoffs:** one mutable reservation pointer, Vehicle-scoped serialization, and a narrow cross-owner correction workflow are required.

**Revisit:** implementation may represent the pointer differently, but one reservation may never be economically current for multiple owners.

## Decision — `ECONOMIC_DATE_V1` for new statements; explicit membership for legacy

**Decision:** current deterministic statements use `EconomicDate` candidate selection followed by immutable membership. Historical workbook statements retain explicit migrated membership.

**Rationale:** automated statement generation needs a deterministic candidate rule, while historical workbook boundaries cannot be safely inferred from dates.

**Tradeoffs:** the current Turo adapter uses Completed `Trip end` as the entitlement/recognition proxy.

**Revisit:** introduce a new recognition-policy version when a better provider-neutral completion/payout event becomes authoritative.

## Decision — Closed-period corrections default to next-open-statement delta

**Decision:** issued statements stay frozen; same-owner later current economics generate a signed reservation correction equal to latest target economics minus cumulative issued recognized economics. Cross-owner later economics require the approved per-owner correction workflow.

**Rationale:** this supplies an implementable recovery path without building full restatement infrastructure.

**Tradeoffs:** a later statement may contain a correction for an earlier trip.

**Revisit:** add explicit restatement when business/legal reporting requires it.

## Decision — Negative investor economics carry forward as debit

**Decision:** a negative net statement result creates debit carry-forward, not a negative payment or investor collections workflow.

**Rationale:** simplest deterministic MVP behavior and sufficient to offset future investor earnings.

**Tradeoffs:** platform does not actively collect investor receivables in MVP.

**Revisit:** add receivable/collection semantics if investor contracts require cash collection.


## Decision — Debit carry follows an explicit statement predecessor chain

**Decision:** deterministic statements for one Tenant + Organization + OwnershipInterest + Currency + recognition-policy lineage issue in contiguous, strictly increasing, non-overlapping order and record `CarryForwardPredecessorStatementId`. Opening debit must exactly equal predecessor closing debit.

**Rationale:** ordering by dates alone cannot prevent the same debit from being consumed twice when statements are created out of order.

**Tradeoffs:** MVP does not support arbitrary gaps or out-of-order issuance in a debit-carry chain.

**Revisit:** a future generalized period/calendar aggregate may relax contiguous issuance only if carry consumption remains single-use and auditable.

## Decision — Manager-incurred operating costs are canonical source facts, not investor adjustments

**Decision:** one real manager-incurred/advanced Vehicle operating cost is authored once as `OperatingCostFact`. Investor economics consumes it only through deterministic `OperatingCostInvestorProjection`; Phase A has no authorable `EconomicAdjustment(VEHICLE_EXPENSE)` or direct adjustment-ledger path.

**Rationale:** factual cost history must remain reusable for investor economics and future books/tax projections without parallel records that can diverge or double count.

**Tradeoffs:** finance refresh must project source facts before the investor subledger can reflect them, so valid cost entry and current investor projection are distinct states.

**Revisit:** richer vendor/AP/payment workflows may expand source-fact relationships, but they must not recreate a second authoritative cost event.

## Decision — Operating-cost chargeability is agreement/policy driven and fail-closed

**Decision:** `OperatingCostFact.Category` never determines investor chargeability by itself. The applicable OwnershipInterest, `ManagementAgreementVersion`, and explicit versioned operating-cost projection policy determine zero/non-zero/signed investor effect. Missing or ambiguous policy blocks the affected projection/currentness.

**Rationale:** the same factual category can be investor-chargeable under one management agreement and management-company-borne under another.

**Tradeoffs:** every supported cost treatment needs explicit policy/version provenance instead of a convenient category default.

**Revisit:** extend the projection-policy vocabulary when real agreements require allocations, percentages, thresholds, caps, or other treatment; never silently default unknown treatment.

## Decision — Recurring costs materialize through the same canonical cost path

**Decision:** Phase-A monthly recurring rules are configuration. An authorized Finance/Statement Refresh deterministically materializes each due occurrence exactly once into `OperatingCostFact`, then uses the same investor-projection path as manual costs.

**Rationale:** tracking/subscription costs are required for cutover, while one source-fact path avoids a special recurring ledger mechanism and future reconciliation problems.

**Tradeoffs:** without an autonomous scheduler, live economics becomes/remains non-current until an authorized refresh materializes due occurrences. This is intentional Phase-A behavior.

**Revisit:** add other frequencies, proration, or autonomous scheduling only when a concrete workflow justifies them and authorization/currentness remains explicit.

## Decision — Live investor economics proves currentness from complete deterministic lineage

**Decision:** an immutable `InvestorEconomicsProjectionSnapshot` may be presented as `CURRENT` only when every applicable Import-owned `SourceFinancialCompletenessProofV1` is `COMPLETE`, its exact proof/effective source-processing lineage is frozen in matching projection provenance and included in the complete fingerprint, the fingerprint exactly matches the authoritative current input set through the stated cutoff, and all other required deterministic inputs/recurring occurrences are present and valid. Otherwise state is non-current (`STALE`, `BLOCKED`, or `UNKNOWN`).

**Rationale:** accepted source subsets can be internally consistent while financially relevant rows remain quarantined/disappeared/regressed/unresolved; source/cost/rule mutations may also commit while a later refresh fails. A mutable stale flag or accepted-row fingerprint alone cannot safely prove current financial truth.

**Tradeoffs:** reads/refresh need deterministic fingerprint computation and explicit cutoff semantics; a source mutation can be valid while the live investor view is temporarily non-current.

**Revisit:** the storage/read-model implementation may change, but CURRENT may never become an optimistic flag disconnected from complete authoritative input lineage.

## Decision — Investor subledger and future general ledger are independent projections

**Decision:** the Phase-A investor-economic subledger explains investor entitlement, operating-cost chargeability, statements, and settlement. It is not the future bookkeeping/general ledger or tax ledger. Future Books/Tax systems independently project from canonical business/source facts and their own versioned policies.

**Rationale:** investor contract economics, accounting classification, tax treatment, and payment/reconciliation are different models even when they share source facts.

**Tradeoffs:** future accounting work cannot simply promote investor subledger lines into JournalEntry truth; it must implement its own deterministic posting/reconciliation policies.

**Revisit:** never collapse the conceptual boundary. Revisit only the integration/projection mechanics when Books V1 is actually implemented.

