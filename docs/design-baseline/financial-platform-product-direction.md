# Financial Platform Product Direction — Investor MVP to Tax-Ready Fleet Accounting

**Project:** Rental Asset & Travel Platform / Fleet Management Project  
**Artifact:** `financial-platform-product-direction.md`  
**Canonical path:** `/Projects/Fleet-Management/shared/canonical/financial-platform-product-direction.md`  
**Steward:** `01-product-strategy`  
**Status:** R3 `GREENLIGHT`; founder accepted and Chat 00 project-integration accepted; promoted for ordered Section 18 canonical synchronization  
**Revision:** 3  
**Previous revision:** 2  
**Date:** 2026-09-25  
**Last changed by:** `01-product-strategy`; canonical promotion recorded during ordered downstream synchronization with product semantics unchanged  
**R1 review:** `/Projects/Fleet-Management/01-product-strategy/history/panel-review-financial-platform-product-direction__2026-09-25__r1.md`  
**R2 review:** `/Projects/Fleet-Management/01-product-strategy/history/panel-review-financial-platform-product-direction__2026-09-25__r2.md`  

**Primary current canonical inputs:**

- `/Projects/Fleet-Management/shared/canonical/mvp-turo-import-spec.md`
- `/Projects/Fleet-Management/shared/canonical/mvp-investor-calculation-spec.md`
- `/Projects/Fleet-Management/shared/canonical/mvp-domain-model.md`
- `/Projects/Fleet-Management/shared/canonical/mvp-security-scope.md`
- `/Projects/Fleet-Management/shared/canonical/mvp-architecture.md`
- `/Projects/Fleet-Management/shared/canonical/mvp-implementation-plan.md`

**Canonical status:** This is the accepted cross-context product direction after R3 convergence and founder/Chat 00 acceptance. Downstream steward-owned canonical artifacts are synchronized in the dependency order defined in Section 18. This artifact defines product direction and extension seams; it does not itself replace the detailed domain, finance, security, architecture, or implementation specifications.

---

# 1. Purpose

This artifact defines the product and system direction for the financial side of the Rental Asset & Travel Platform.

It exists to resolve a tension that has become explicit during MVP review:

- the immediate business need is narrow and operational: replace the founder's recurring Turo-export-to-investor-spreadsheet workflow;
- the long-term product is not an isolated investor spreadsheet replacement;
- the same system is expected to become the authoritative bookkeeping, tax-readiness, asset-accounting, investor-economic, and vehicle-economic platform for the fleet;
- the system should eventually eliminate the majority of bookkeeping reconstruction and tax-preparation work currently performed manually or by a CPA, while preserving professional review for judgment, elections, unusual transactions, and final compliance where economically appropriate.

The resulting design principle is:

> **Implement the smallest useful financial vertical slice now, but make the underlying financial facts, provenance, ownership, asset history, evidence relationships, calculation boundaries, and module boundaries durable enough that bookkeeping, tax, valuation, labor, and AI capabilities can be added without replacing the MVP financial model.**

This artifact is not a detailed accounting schema, tax-law specification, or implementation plan. Those remain stewarded by the relevant bounded-context artifacts.

---

# 2. Founder-approved product direction

The founder's requirements are now:

1. At any time, the owner can download the latest cumulative Turo CSV and upload it to the platform.
2. The platform should safely merge that mutable cumulative snapshot and make the current platform state reflect the newest valid Turo numbers.
3. For the founder/authorized finance user, investor calculations should refresh from the newly current canonical economic state without spreadsheet work. The import path must not silently grant finance-mutation authority to users who do not already have it.
4. The Investor / Vehicle Economics experience must contain at least the economically relevant information and calculations currently maintained in the Aaron CR-V workbook, while replacing spreadsheet transcription and recalculation.
5. The owner must be able to manually enter itemized expenses such as refueling, tolls, tickets, oil changes, repairs, and similar costs.
6. The owner must be able to define simple scheduled/recurring costs such as tracking subscriptions.
7. Receipt/file upload and receipt extraction are important future capabilities, but they do not need to be part of the first MVP UI.
8. The platform must eventually provide the major capabilities expected from paid bookkeeping and tax applications, specialized for rental assets/fleet economics rather than remaining a lightweight investor calculator.
9. The platform should eventually reduce the majority of bookkeeping cleanup, fixed-asset tracking, depreciation work, reconciliation, tax workpaper preparation, and supporting-document organization currently requiring manual work or CPA effort.
10. Vehicle economics should eventually include real market value, real economic depreciation, tax depreciation, true ROI/ROIC, labor cost, financing cost, and asset-level operating metrics.
11. AI agents should help collect evidence, classify data, estimate market value, investigate anomalies, explain results, and prepare analysis, but deterministic systems remain authoritative for accounting, tax calculations, investor entitlements, authorization, and immutable financial history.
12. The platform remains a multi-tenant rental-asset operating system. These financial capabilities must fit that larger architecture rather than creating a standalone bookkeeping application beside it.

---

# 3. Product framing

## 3.1 Immediate MVP outcome

The MVP should be understood as:

> **A production-safe, continuously refreshable investor-financial operating slice of the future fleet accounting platform.**

The MVP is successful when the founder can repeatedly perform this loop:

```text
Download latest Turo cumulative CSV
        ↓
Upload to platform
        ↓
Preview / validate / resolve exceptions
        ↓
Commit current snapshot
        ↓
Canonical reservation/economic state becomes current
        ↓
Investor calculations refresh deterministically
        ↓
Investor / Vehicle Economics page shows current numbers
        ↓
Owner adds any non-Turo expenses or recurring costs
        ↓
Current investor economics and statement readiness update
```

The workflow must not require rebuilding or manually updating an investor spreadsheet after import.

## 3.2 Long-term outcome

The long-term financial product should become the authoritative financial operating layer for the rental-asset business, combining:

```text
operational source facts
+ bookkeeping
+ investor economics
+ fixed-asset accounting
+ tax basis and depreciation
+ vehicle valuation / economic depreciation
+ labor and financing costs
+ reconciliation and close
+ tax-ready reporting / workpapers
+ AI-assisted analysis and preparation
```

The objective is not to imitate a generic small-business bookkeeping product feature-for-feature for its own sake.

The objective is to provide the financial capabilities the rental-asset business actually needs, while using asset-, trip-, vehicle-, ownership-, and marketplace-aware source data that generic accounting products do not natively understand.

---

# 4. Current canonical contracts that remain valid

This direction does **not** overturn the following reviewed foundations.

## 4.1 Turo remains an adapter, not the system of record

The current Turo export is correctly treated as a cumulative mutable YTD snapshot. Re-importing overlapping data must not append duplicate revenue. Unchanged rows are no-ops; legitimate revisions create new source revisions/current snapshots.

The product-level UX should make this complexity simple:

> upload the newest export → inspect exceptions/differences → commit → current numbers are current.

## 4.2 Investor economics remains a specialized subledger

The current investor finance design deliberately uses an immutable investor-economic subledger rather than pretending it is a general accounting ledger.

That decision remains correct.

The future general ledger must not be created by simply renaming or expanding the investor subledger until it serves incompatible purposes.

## 4.3 Finance consumes canonical economics

Investor economics, future accounting, and future tax calculations should consume canonical business/economic facts rather than provider-specific Turo columns directly.

Provider provenance remains available for auditability and reconciliation.

## 4.4 Modular monolith remains the preferred initial architecture

The broader future financial scope does not justify premature microservices, distributed transactions, or a message broker in the MVP.

Strong bounded contexts and dependency direction inside a modular monolith are sufficient until a demonstrated scaling/reliability/ownership reason exists to extract a module.

## 4.5 Multi-tenancy, authorization, auditability, and provenance remain system-level requirements

This is not a disposable single-user spreadsheet utility.

Financial records, investor data, tax facts, receipts/evidence, bank data, identity data, and valuation information will become increasingly sensitive. System-level tenancy, resource authorization, provenance, auditability, and safe background processing remain justified architectural foundations even when only a subset is surfaced in the initial founder UI.

---

# 5. Critical architectural separation: one set of facts, multiple financial projections

The platform should converge around a shared set of canonical business facts with separate deterministic financial projections.

```text
                    CANONICAL BUSINESS FACTS

Reservation / Trip / Source Economics / Vehicle / Ownership
Operating Cost / Acquisition / Payment / Loan / Labor / Disposition
Evidence / Source Provenance / Effective-Dated Agreements
                              │
            ┌─────────────────┼──────────────────────┐
            │                 │                      │
            ▼                 ▼                      ▼
      INVESTOR           ACCOUNTING             TAX
      ECONOMICS          / BOOKS                ENGINE

 Entitlements         Double-entry GL       Tax basis
 Mgmt fees            Period close           Elections
 Statements           P&L / balance sheet    Depreciation
 Settlements          Reconciliation         Workpapers
            │                 │                      │
            └─────────────────┼──────────────────────┘
                              │
                              ▼
                    ECONOMIC / ASSET ANALYSIS

                    Market valuation
                    Economic depreciation
                    True ROI / ROIC
                    Cost per mile
                    Labor burden
                    Financing burden
                    Acquisition intelligence
                              │
                              ▼
                         AI ANALYSIS

                    Explanations
                    Classification suggestions
                    Anomaly investigation
                    Market-value research
                    Forecasts / recommendations
```

The key invariant is:

> **Investor economics, book accounting, tax accounting, and economic performance are related but not interchangeable models. They may derive from the same source facts, but each must preserve its own rules, versioning, and audit trail.**

## 5.1 Projection-lineage and currentness invariant

Every deterministic financial projection added to the platform must preserve enough lineage to reproduce and explain its result without copying mutable source values into an opaque derived record.

Normative invariant:

```text
ProjectionResult
  → references the complete deterministic input set/fingerprint
      including every source-fact identity/version and every other
      deterministic input that can influence the result
  → identifies deterministic rule/policy version(s)
  → identifies applicable ownership/agreement/configuration version(s)
  → records the relevant effective/accounting/tax/as-of date or period semantics
  → includes deterministic recurring-occurrence requirements through the
      projection cutoff/as-of period when recurrence affects the result
  → is idempotent for the same complete deterministic input fingerprint
  → uses explicit reversal/supersession/correction lineage
  → never silently rewrites a closed or issued historical result
```

A live projection is `CURRENT` only when its recorded input fingerprint matches the complete authoritative current input set required for the projection at its stated as-of/cutoff period. Any mismatch, inability to prove the match, newly due recurring occurrence not represented in the projection, or failed/incomplete refresh makes the projection `STALE`, `BLOCKED`, or `UNKNOWN`—never `CURRENT`.

A cached freshness/status field may exist for UI/performance, but it is not an independent source of truth unless its invalidation is transaction-coupled to every relevant authoritative input mutation. The product requirement is fail-closed currentness from lineage, not a best-effort “mark stale” side write.

The exact persistence/fingerprint shape belongs to the stewarding domain. This requirement does **not** require JournalEntry, TaxAsset, close-period, or other future tables to be implemented in Phase A.

---

# 6. MVP requirements

These are the minimum product capabilities now considered required for the first useful financial MVP.

## 6.1 Repeated current Turo upload

The owner must be able to upload the newest Turo CSV at any time.

Required product behavior:

- treat the file as a cumulative mutable snapshot, not an append-only feed;
- detect new, unchanged, revised, invalid, and unresolved rows;
- show a concise preview of material differences/exceptions;
- commit idempotently and atomically under the current import contract;
- preserve source/revision provenance;
- update canonical current state;
- make every affected live investor-economic projection fail closed to a non-current state unless its complete authoritative input fingerprint still matches;
- never duplicate existing reservations or earnings because the same/overlapping CSV was uploaded again;
- never rewrite immutable already-issued investor statements merely because the current Turo snapshot changes later;
- surface stale/unresolved vehicle/ownership/agreement configuration rather than silently calculating with guesses.

For the founder's normal path, the same application workflow may continue into finance recalculation after import **only if the initiating actor is currently authorized for `finance.calculation.write`, has the required recent step-up, and still satisfies resource authorization**. Import success and finance-refresh success remain distinct outcomes.

If the importer lacks finance-recalculation authority, CURRENT import may still succeed, but affected investor economics must read as non-current (`STALE`/`REFRESH_REQUIRED`/`BLOCKED`, exact enum/name owned by downstream design) because their stored input fingerprint no longer matches authoritative current inputs. This must not depend on a second best-effort stale-marker write succeeding. The system must never elevate a source-ingestion actor through SYSTEM authority merely to satisfy the product desire for automatic refresh.

If asynchronous finance refresh is introduced later, it must use the project's approved user-delegated worker authorization model and revalidate current authorization rather than becoming an implicit privileged back door.

## 6.2 Live Investor / Vehicle Economics page

The MVP needs a primary finance surface that replaces the Aaron CR-V spreadsheet as the founder's working financial view.

At minimum it should expose the economically relevant source and calculation information represented by that workbook, including the current canonical investor calculation components.

The exact field parity should be verified against the current CR-V workbook during review/synchronization rather than reconstructed from memory.

The page should conceptually contain:

```text
Vehicle identity
Investor / ownership
Applicable management agreement

Current reservation/trip rows
Turo/canonical earning components
Management-fee base
Management fee
Cleaning / delivery costs where applicable
Repair charges
Investor reimbursements
Manual vehicle operating costs
Recurring/scheduled cost occurrences
Investor reservation earnings
Period totals
Projection freshness / blocker state
Current payable / settled status as supported by MVP
Statement history
Calculation/provenance drill-down
```

The important product distinction is:

- **Live Vehicle/Investor Economics** is a continuously recalculated current operational view and must disclose whether it is current or stale relative to accepted source facts.
- **Issued InvestorStatement** is immutable historical output for a defined close/issue event.

New Turo data or operating-cost corrections may make the live view stale/current as calculations advance, but must never silently mutate previously issued statements.

## 6.3 Manual itemized operating costs — authoritative source-fact decision

The owner must be able to enter a real operating cost manually without uploading a receipt or document.

**Product decision:** a manually entered oil change, toll, repair, refueling charge, ticket, or similar real-world cost is **one canonical operating-cost source fact with stable identity and provenance**. Investor economics consumes that source fact through deterministic projection rules where applicable. The source fact is not itself a general-ledger posting, tax deduction, or investor-ledger row.

The exact domain type/table name (`Expense`, `OperatingCostFact`, or another steward-approved name) belongs to `03-domain-model`; the semantic contract above is normative. Phase A must not create an independent “expense record” and separate investor `EconomicAdjustment` that can diverge or double count. If compatibility with the existing `EconomicAdjustment` model is retained, it must be a deterministic projection/reference relationship from the one source fact rather than a second independently authored economic event.

MVP UI fields can remain deliberately small:

```text
Vehicle
Date incurred
Category
Amount
Description / business-purpose note
Optional reservation/trip link when useful
Economic actor/responsibility: managing Organization (fixed/default in Phase A UI)
```

Initial categories may include:

```text
REFUELING
TOLL
TICKET
OIL_CHANGE
MAINTENANCE
TRACKING
CLEANING
REPAIR
REGISTRATION
OTHER
```

The category taxonomy may evolve, but historical facts and prior calculation lineage must remain explainable.

### Phase-A economic-actor meaning

For Phase A, a canonical operating-cost entry represents a **real Vehicle-related cost incurred or advanced by the managing Organization** in operating/managing the Vehicle. It is not itself proof that a bank/credit-card settlement has cleared, and it is not automatically a tax deduction or general-ledger posting.

The source fact must preserve the minimum party/responsibility meaning needed to distinguish this manager-incurred/advanced cost from an investor-paid or otherwise differently borne cost. The simplest Phase-A invariant may be `incurred_by = MANAGING_ORGANIZATION` (exact field/name owned by `03-domain-model`). If the UI later needs more than one economic actor, that can become an explicit constrained actor/reference rather than an AP subsystem.

**Investor chargeability is not inferred from expense category alone.** Whether and how a source cost reduces investor economics is determined by the applicable versioned management agreement/projection policy. The same category can therefore have different investor treatment under different agreements without changing the underlying source fact.

Investor-paid/reimbursable cases must use the existing explicit reimbursement/other approved financial path or another steward-approved source-fact subtype; they must not be silently entered as manager-incurred operating costs. Phase A does not add vendor, accounts-payable, bank-settlement, or generic payer workflows to support this distinction.

Corrections use explicit correction/reversal/replacement semantics once the fact has affected financial results; do not destructively edit away history after statement/closed-period use.

The MVP source fact must preserve only the minimum durable semantics needed to avoid future reconstruction: tenant/organization scope, stable identity, incurred date, amount/currency, category, vehicle, optional reservation/trip relationship, manager-incurred/advanced economic-actor responsibility, description/business-purpose note, source/provenance, creator, and correction lineage. Vendor/AP/payment/evidence/tax-account mapping workflows remain deferred.

## 6.4 Simple recurring/scheduled expenses — Phase A requirement

Simple recurring costs such as vehicle tracking subscriptions remain part of the founder's Phase A cutover requirement; they are **not** deferred to Phase A.1. The implementation must stay deliberately small.

**Product decision:** `RecurringExpenseRule` (name illustrative) is configuration, not financial truth. A due rule occurrence materializes through the **same canonical operating-cost source-fact path** used by manual entry. It must not write directly to the investor ledger or future GL.

Minimum rule inputs:

```text
Vehicle or applicable scope
Category
Description
Amount
Frequency = MONTHLY initially
EffectiveFrom
EffectiveTo optional
Status
Economic actor/responsibility = managing Organization for Phase A
```

Minimum deterministic semantics:

- each occurrence has stable identity equivalent to `RuleId + OccurrencePeriod/OccurrenceDate`;
- materializing/rerunning the same due occurrence is idempotent and cannot create a second cost fact;
- a generated cost fact records the originating rule/occurrence and `SourceKind = RECURRING_RULE` (exact names non-normative);
- rule edits are effective-dated and apply prospectively; they do not silently rewrite already-materialized occurrences;
- disabling a rule stops future occurrences and never erases historical ones;
- correcting a historical occurrence uses the same correction/reversal semantics as a manual cost;
- materialization represents the configured recurring business/economic cost, not proof of bank payment, tax deductibility, or receipt evidence; future accounting/bank reconciliation may match/reclassify it without replacing its historical identity.

### Phase-A materialization trigger and authority

Phase A does **not** introduce an autonomous scheduler, broker, or privileged SYSTEM worker for recurring-cost generation.

Due monthly occurrences are materialized synchronously inside an explicit **authorized Finance Refresh / Statement Refresh** command, before calculation candidate selection:

```text
Authorized Finance Refresh / Statement Refresh
  → determine due recurring occurrences through the requested cutoff/as-of period
     in the Organization's financial timezone
  → materialize each missing occurrence idempotently through the canonical
     operating-cost command path
  → project applicable investor-economic effects
  → recalculate current investor economics
```

This command path must work even when no new Turo import occurred in the month, so a finance/statement refresh can bring recurring costs current independently of source ingestion.

`CreateOperatingCost`, `CorrectOperatingCost`, and `Create/Edit/DisableRecurringCostRule` are privileged finance mutations. The Phase-A default is to protect them with the existing `finance.adjustment.write` + required recent step-up + current Organization/Vehicle/ownership/resource relationships, unless `04-identity-security` deliberately defines a more appropriate permission during synchronization. Recurring materialization inherits the authority of the initiating authorized Finance/Statement Refresh command and must re-check all relevant resource predicates; it does not gain SYSTEM authority. If materialization creates canonical operating-cost facts, the refresh path must also satisfy the current operating-cost mutation authority (`finance.adjustment.write` under the Phase-A default) in addition to `finance.calculation.write`. If that authorization is absent or stale, no occurrence is materialized and the affected projection remains non-current/blocked rather than partially refreshing.

Phase A chooses one deliberately simple monthly occurrence-date rule:

```text
first occurrence date = EffectiveFrom
subsequent monthly occurrence date = same day-of-month as EffectiveFrom
if a month has no such day = last calendar day of that month
timezone = Organization financial timezone
no proration
```

Each occurrence belongs to the financial/statement period containing that occurrence date. `EffectiveTo`, when present, prevents occurrence dates after it. Changing the rule later is prospective unless an explicit correction is created.

Do not turn this into a generic subscription billing engine, proration engine, accounts-payable system, arbitrary scheduler, or background finance service.

## 6.5 Investor calculation automation and fail-closed freshness

After a successful Turo CURRENT import, canonical operating-cost mutation, recurring-rule change, ownership/agreement change, or other deterministic-input mutation, affected live investor calculations must be evaluated against the **complete authoritative input fingerprint** defined in §5.1.

For an actor with current finance recalculation authority, the application should synchronously continue to an authorized Finance Refresh in the normal founder workflow so the user experience remains:

```text
upload latest CSV → commit → authorized finance refresh
                  → materialize due recurring costs through cutoff
                  → current investor numbers
```

This is application orchestration, not Source Ingestion directly calling Investor Finance. Each authoritative finance command retains its own permission, recent-step-up, resource-authorization, transaction, idempotency, and audit requirements.

Currentness is fail-closed:

- a projection may display `CURRENT` only if its recorded complete deterministic input fingerprint matches all authoritative inputs required at its stated as-of/cutoff period;
- source/current-pointer, operating-cost, recurring-rule/occurrence requirement, ownership, agreement, override, or other deterministic-input changes invalidate the match by definition;
- inability to prove the match, an authorization/blocker failure, or a refresh crash results in `STALE`, `BLOCKED`, or `UNKNOWN`, never `CURRENT`;
- a cached UI freshness flag is only a performance/read-model aid unless invalidation is transaction-coupled to every relevant mutation.

Therefore a Turo import or cost mutation can commit successfully even if subsequent finance refresh fails; on the next read the old projection must still fail the `CURRENT` test from authoritative lineage and cannot look current merely because a separate stale-marker update failed.

If recalculation cannot run because authorization is missing/stale or another finance blocker exists:

- the independently valid source/cost/rule mutation may remain committed;
- the UI must clearly show the affected live economics as non-current;
- an explicitly authorized finance action must complete the refresh;
- SYSTEM authority must not be used to bypass the user's finance permission.

Any calculation displayed as authoritative must expose or be able to explain its source/calculation lineage and as-of/cutoff semantics. Issued statements remain governed by explicit issue/close semantics rather than being a mutable dashboard snapshot.

## 6.6 Simple cost entry now; evidence-ready later

Receipt/photo/file upload is not required in the first MVP UI.

However, the canonical operating-cost identity must be stable enough that evidence can be linked later without rebuilding or replacing the historical financial fact.

The future relationship can conceptually become:

```text
CanonicalOperatingCostFact
  ↓
ExpenseEvidenceLink
  ↓
EvidenceDocument
```

Evidence is supporting documentation/provenance. It does not become the authoritative amount merely because an OCR/AI system extracted a value from it.

---

# 7. What the MVP should NOT implement yet

The following remain deferred unless a concrete current workflow proves they are required for cutover:

- receipt/photo upload UI;
- OCR/document extraction pipeline;
- vendor bill-pay workflow;
- bank/credit-card feeds;
- automated bank reconciliation;
- automated investor payout initiation;
- full general ledger UI;
- GAAP financial statement production;
- federal/state tax return generation;
- tax e-filing;
- payroll engine;
- 1099/W-2 filing engine;
- full fixed-asset tax engine;
- sophisticated loan amortization subsystem;
- automated real-time market scraping/valuation agent;
- AI-generated authoritative tax numbers;
- investor portal/login;
- customer accounting portal;
- multi-marketplace availability/direct-booking/traveler-commerce features solely for this MVP;
- microservices, broker, Redis, or distributed deployment without a demonstrated need.

Deferral means **do not implement the workflow now**. It does not mean **design the current model in a way that prevents the capability later**.

---

# 8. Design-for-extension financial concepts

The domain and architecture reviews should preserve clear future extension points for the following concepts without requiring all of them to be implemented in MVP.

> **Non-normative future-shape rule:** Field lists and entity sketches in Sections 8–11 are illustrative design aids, not instructions to pre-create unused tables/columns. “Design extension point now” means preserve stable identity, provenance, temporal/effective-date semantics, correction lineage, projection boundaries, and relationship seams that would be expensive or impossible to reconstruct later. Add Phase-A persistence only when it protects a concrete current historical/financial invariant.

## 8.1 Expense / operating-cost expansion

Do not persist MVP expenses as an unstructured amount/description blob that will later have to be migrated into a tax/accounting system.

Illustratively, a future richer expense concept could carry or associate:

```text
Expense
  Id
  TenantId
  OrganizationId
  VehicleId?
  ReservationId? / TripId?
  Category
  IncurredAt
  Amount
  Currency
  Description
  BusinessPurpose?
  VendorId?
  PaymentSourceId?
  TaxTreatment / tax classification relationship later
  Evidence state / evidence links later
  SourceKind
  CreatedBy
  CreatedAt
  reversal/correction lineage
```

This list is non-normative. Phase A implements only the minimum canonical operating-cost source-fact contract defined in §6.3.

## 8.2 RecurringExpenseRule

A scheduled cost should have its own rule/identity rather than relying on repeated manual typing.

The design must distinguish:

- the recurring rule (configuration);
- the occurrence for a given period/date (deterministic identity);
- the canonical operating-cost source fact materialized from that occurrence;
- any later accounting/tax projection generated from the source fact.

Phase A semantics are normative in §6.4; future accounting projection shapes are not.

## 8.3 EvidenceDocument

Evidence should remain a first-class future boundary for:

- receipts;
- invoices;
- contracts;
- bank/credit-card statements;
- registration/tax documents;
- purchase documents;
- financing documents;
- maintenance records;
- disposition documents;
- supporting tax documentation.

Future evidence processing may include OCR/document parsing and AI classification, but confirmed structured financial facts remain authoritative.

## 8.4 Asset acquisition and capitalized cost

Vehicle acquisition economics must not be reduced to ordinary expense rows.

The future model needs to represent, either directly or through coherent related concepts:

```text
Vehicle acquisition date
Purchase price
Sales/use tax
Dealer/document fees
Transportation/shipping
Initial capital improvements
Other capitalized basis components
Placed-in-service date
Funding/financing relationships
Ownership/capital relationships
```

The exact accounting/tax treatment is not an MVP concern, but historical source facts must be preserved.

## 8.5 Capital improvements vs repairs/maintenance

The future financial model must support separating:

- operating repair/maintenance expense;
- capital improvement/addition that changes asset basis or economic capital invested.

Do not force every vehicle cost into one undifferentiated `Expense` semantic.

## 8.6 Financing and debt

Future books must support:

- loan liability;
- principal vs interest;
- fees;
- payments;
- payoff;
- refinancing;
- lender/source documents;
- vehicle/collateral association;
- cash-flow effects distinct from expense/economic cost.

Debt accounting must remain separate from asset depreciation and investor economics.

## 8.7 LaborWork / labor allocation

The platform should eventually measure labor consumed by each vehicle, reservation, and operational process.

A future labor fact should be capable of representing:

```text
worker / party
employment or contractor relationship reference
work type
vehicle?
reservation/trip?
date/time or duration
hours/quantity
cost rate or allocated cost
source/provenance
```

Examples include:

- delivery;
- turnaround;
- cleaning;
- maintenance;
- vehicle repositioning;
- fleet administration;
- customer support.

This is required for true vehicle profitability and operational scalability analysis, even if payroll remains external initially.

---

# 9. Accounting / bookkeeping target capability

The eventual platform should be capable of replacing the majority of routine paid bookkeeping work for the rental-asset business.

The accounting bounded context should eventually provide the capabilities normally expected from serious bookkeeping software, including at least:

## 9.1 General ledger

- configurable chart of accounts;
- double-entry journal entries and journal lines;
- deterministic posting rules from canonical business events/facts;
- manual adjusting entries with authorization/provenance;
- immutable/auditable posted history with reversal/correction semantics;
- accounting periods;
- period close/lock/reopen controls;
- opening balances and migration support;
- subledger-to-GL reconciliation.

## 9.2 Cash and bank/credit accounts

- bank accounts;
- credit cards;
- transfers;
- imported bank/credit transactions;
- matching to expenses/revenue/payouts/loan payments;
- reconciliation statements;
- uncleared/unmatched queues;
- duplicate prevention/idempotency;
- support for later financial-data-provider integrations.

## 9.3 Revenue and marketplace clearing

The system should eventually distinguish:

- earned rental revenue;
- marketplace fees;
- taxes collected/withheld/remitted where applicable;
- reimbursements;
- refunds/credits;
- payout batches;
- marketplace clearing/receivable balances;
- settlement timing;
- direct-booking/payment-processor clearing in future channels.

## 9.4 Expenses, vendors, and payables

Future capabilities should support:

- vendor identity;
- bills/expenses;
- payment status;
- recurring costs;
- reimbursements;
- allocation to vehicle/reservation/organization;
- evidence/receipts;
- category/account mapping;
- tax classification;
- business-purpose substantiation.

## 9.5 Owner/equity and related-party flows

Future books should be able to distinguish:

- owner capital contributions;
- owner draws/distributions;
- loans to/from owner;
- investor capital;
- investor distributions;
- intercompany/related-party transactions if the business structure later requires them.

Do not conflate owner equity, investor entitlement, operating expense, and debt.

## 9.6 Financial statements and reports

The eventual accounting engine should support deterministic generation of:

- trial balance;
- general ledger detail;
- profit & loss / income statement;
- balance sheet;
- cash-flow reporting;
- account detail schedules;
- vehicle/business-unit profitability views;
- reconciliation reports;
- year-end adjusting-entry reports;
- audit/provenance exports.

Fleet/economic reporting can add dimensions not normally present in generic bookkeeping products.

---

# 10. Tax-ready target capability

The platform should eventually provide tax-ready records and workpapers sufficient to eliminate most tax-data reconstruction and depreciation spreadsheet work.

This does not mean tax law is encoded casually or that the LLM becomes the tax authority.

## 10.1 Tax configuration and versioning

Tax rules must be:

- versioned by tax year/effective period;
- attributable to a deterministic rule/configuration source;
- separated from ordinary domain entities;
- reproducible for historical years;
- capable of handling elections/choices explicitly rather than hiding them in generic calculations.

Do not hard-code a founder-recalled revenue threshold or CPA shorthand as a universal legal rule. Entity type, tax election, jurisdiction, form, asset type, placed-in-service date, business use, and tax year may change requirements.

## 10.2 Tax asset / fixed-asset register

The future tax system should be able to represent:

```text
TaxAsset
Vehicle / asset identity
PlacedInServiceDate
TaxBasis
BusinessUsePercentage where applicable
Asset classification / recovery treatment
Method / convention
Section 179 election where applicable
Bonus-depreciation treatment where applicable
Current-year depreciation
Accumulated tax depreciation
Remaining tax basis
Disposition data
recapture/gain-loss inputs where applicable
supporting evidence/provenance
```

## 10.3 Tax depreciation is not market depreciation

The system must maintain three distinct concepts:

```text
Market / Economic Depreciation
Book Depreciation
Tax Depreciation
```

They answer different questions and must never be collapsed into one `Vehicle.Depreciation` value.

## 10.4 Tax workpapers and form mappings

The eventual product should prepare structured workpapers/mappings for the forms and schedules applicable to the organization and tax election, including support for:

- revenue and expense classifications;
- asset acquisitions/dispositions;
- fixed-asset/depreciation schedules;
- financing interest/principal separation;
- owner/equity information;
- contractor/payroll supporting totals;
- relevant federal and state/local tax workpapers;
- book-to-tax adjustments;
- prior-year carryovers/elections where required;
- diagnostics for missing/unsupported facts.

The exact form set is entity/jurisdiction dependent and must be defined from authoritative requirements when implemented.

## 10.5 CPA work-reduction objective

The platform should target shifting the CPA engagement from:

```text
collect data
reconstruct books
classify transactions
chase receipts
build fixed-asset schedules
reconcile accounts
recalculate depreciation
prepare workpapers
then review/file
```

toward:

```text
review reconciled books
review exceptions/judgment calls
confirm elections/tax positions
review unusual transactions
review prepared tax workpapers
perform professional compliance/sign-off/filing as appropriate
```

The product goal is **CPA leverage and work elimination**, not an architectural promise that no CPA/professional review will ever be useful.

Direct electronic tax filing can be evaluated much later as a distinct compliance/integration product decision.

---

# 11. Vehicle valuation and true economic performance

Generic bookkeeping/tax software does not answer the founder's central capital-allocation question well enough:

> **What did this vehicle actually earn after real economic depreciation, financing, labor, maintenance, and operating burden, and is it still a good deployment of capital?**

The platform should therefore maintain a separate economic-analysis layer.

## 11.1 VehicleValuationSnapshot

A future valuation observation should be able to represent:

```text
VehicleId
AsOfDate
EstimatedMarketValue
LowEstimate?
HighEstimate?
Method
Data sources / comparable references
Mileage / condition assumptions
Location/market
Model/agent/version provenance
Confidence / uncertainty metadata
Human approval/override where appropriate
```

Valuation history must be time-series data, not merely one mutable `current_value` column.

## 11.2 Economic depreciation

Economic depreciation should be derived from actual capital economics, for example conceptually:

```text
Economic depreciation
≈ economic acquisition basis
- expected net disposition value/current market value
```

Exact calculation policy must be explicit, versioned, and should account for acquisition/disposition costs where material.

## 11.3 True vehicle ROI/ROIC

The long-term vehicle economics engine should support metrics such as:

- gross revenue;
- marketplace/platform fees;
- operating expenses;
- maintenance and repair;
- tires/consumables;
- insurance;
- labor cost;
- financing cost;
- downtime/opportunity cost where policy defines it;
- economic depreciation;
- economic profit;
- cash flow;
- cash-on-cash return;
- ROIC;
- IRR/payback where appropriate;
- revenue/day;
- revenue/mile;
- operating cost/mile;
- depreciation/mile;
- utilization;
- current market value and value trend.

Tax deductions should not be substituted for economic cost when evaluating acquisition quality.

---

# 12. AI role and boundaries

AI is strategically important, but it must sit on top of deterministic financial truth rather than replace it.

## 12.1 Good AI responsibilities

Potential future agents include:

- receipt/document extraction agent;
- expense categorization assistant;
- reconciliation-match suggestion agent;
- anomaly investigator;
- fixed-asset evidence assistant;
- vehicle valuation / comparable-selection agent;
- market-depreciation analyst;
- true-ROI explanation agent;
- tax-workpaper preparation assistant;
- missing-document / missing-fact investigator;
- acquisition analyst;
- natural-language financial analytics agent.

## 12.2 Structured AI outputs

AI outputs that influence calculations should be structured, versioned, and provenance-rich.

Example valuation-agent output:

```text
estimated_value
low_estimate
high_estimate
as_of_date
comparables[]
source references[]
method_version
assumptions
confidence/uncertainty
```

The deterministic economics engine consumes an approved valuation fact/observation rather than an unstructured chatbot statement.

## 12.3 AI must not be authoritative for

- general-ledger posting truth;
- debit/credit balancing;
- bank reconciliation final state;
- investor distribution entitlement;
- tax depreciation arithmetic;
- tax elections;
- authorization;
- immutable historical source data;
- booking availability;
- contractual obligations.

AI may propose, explain, classify, investigate, and prepare. Deterministic services and explicit human approval govern authoritative state changes.

## 12.4 Promotion gate for AI-derived observations

AI never writes authoritative financial truth directly. Any AI result that will be consumed by a deterministic financial engine must cross an explicit promotion gate appropriate to the fact type:

```text
AI proposal / observation
  → schema validation
  → source/model/method provenance retained
  → deterministic validation rules
  → explicit human approval OR an explicitly designed deterministic acceptance command
  → authoritative observation/fact
  → deterministic financial projection
```

The acceptance policy may vary by fact type, but it must be explicit and auditable. Tax elections, investor entitlements, GL truth, and final bank-reconciliation state always remain outside direct AI authority.

---

# 13. Provenance and explainability requirement

Any important financial number should eventually answer:

> **Where did this number come from?**

Example:

```text
True Vehicle ROIC = 17.8%
        │
        ├── Revenue
        │    └── Turo import / ReservationEconomicSnapshot
        │         └── SourceArtifact + revision lineage
        │
        ├── Operating expenses
        │    ├── canonical operating-cost fact
        │    │    └── future receipt/evidence
        │    └── recurring-rule materialized cost fact
        │
        ├── Labor
        │    └── LaborWork / cost allocation
        │
        ├── Financing
        │    └── Loan/payment/accounting facts
        │
        ├── Economic depreciation
        │    └── VehicleValuationSnapshot
        │         └── market data / AI analysis provenance
        │
        └── Capital invested
             └── acquisition/capital-improvement history
```

Likewise, a tax depreciation number should trace to:

```text
acquisition/basis facts
+ placed-in-service facts
+ business-use facts
+ applicable tax-rule version
+ explicit elections
+ deterministic calculation
```

An AI explanation may summarize the lineage, but it must not replace it.

---

# 14. Security, privacy, and audit direction

The future finance/tax platform will handle increasingly sensitive information. Relevant design expectations include:

- tenant isolation remains mandatory;
- resource authorization must support organization and relationship-based access;
- finance/tax/evidence permissions should be narrower than ordinary fleet operations where appropriate;
- receipt/evidence documents may contain PII, account numbers, addresses, tax identifiers, or other sensitive data;
- bank/credit integrations introduce high-sensitivity secrets/tokens and financial transaction data;
- tax documents may require stronger access/audit controls than routine trip operations;
- AI tools must receive only the minimum data necessary for the task and preserve provenance/audit records;
- service-principal/background processing must remain explicitly authorized and tenant-scoped;
- audit history should cover sensitive financial changes, approvals, reversals, period close/reopen, tax elections, and evidence access where justified.

The security steward should determine exactly which controls are required in MVP versus later phases. Product strategy should not use future complexity as a reason to weaken current production handling of real guest/investor/financial data.

---

# 15. Product-scope classification

Future financial capabilities should be classified into three buckets.

| Classification | Meaning | Examples |
|---|---|---|
| **Implement now** | Required to replace the founder's current workflow | repeated current Turo upload, freshness-aware deterministic investor calculations, live investor/vehicle economics, canonical manual operating-cost entry, simple monthly recurring-cost rules/materialization, statement/settlement capability required for actual investor operation |
| **Design extension point now** | Do not build full workflow, but do not create an MVP model that forces destructive migration later | expense identity/provenance, evidence relationship, asset acquisition/basis facts, capital improvements, future GL boundary, valuation history, separate tax/book/economic depreciation, labor costing, debt relationships |
| **Defer implementation** | Implement only when a measured business need justifies it | receipt OCR, bank feeds, automated reconciliation, payroll, full GL UX, fixed-asset tax engine, tax-form generation/e-file, automated valuation agent, advanced AI finance workflows |

This classification should be applied feature-by-feature. “Future-proof” does not justify implementing unused workflows.

---

# 16. Proposed phased financial roadmap

This is product sequencing, not a commitment to exact implementation order. Panel review and Chat 00/02 should validate dependencies.

## Phase A — Investor Financial MVP

Purpose: eliminate the current Turo-export-to-investor-spreadsheet workflow.

Capabilities:

- repeated current Turo import;
- idempotent revision handling;
- canonical current reservation/economic state;
- deterministic investor economics;
- live Investor / Vehicle Economics page;
- canonical manual operating-cost entry;
- simple monthly recurring-cost rules/materialization;
- issued statement history;
- settlement recording required by actual operation;
- audit/provenance sufficient to explain payout numbers.

## Phase B — Books V1

Purpose: replace the majority of routine bookkeeping reconstruction.

Likely capabilities:

- general ledger / chart of accounts;
- deterministic posting rules;
- bank/credit account ingestion;
- matching/reconciliation;
- vendor/expense expansion;
- receipt/evidence capture;
- acquisition and debt accounting;
- owner/equity handling;
- trial balance, P&L, balance sheet, cash-flow/account-detail reporting;
- period close and adjustment workflow.

## Phase C — Tax-Ready V1

Purpose: produce tax-ready books, asset schedules, and workpapers.

Likely capabilities:

- fixed-asset register;
- tax basis;
- placed-in-service history;
- tax depreciation schedules;
- Section 179 / bonus treatment where applicable;
- disposition/gain-loss inputs;
- book-to-tax adjustments;
- year-specific rule configuration;
- contractor/labor supporting reports;
- federal/state/local workpaper mappings applicable to the organization;
- diagnostics for missing tax facts/evidence.

## Phase D — CPA Automation / Financial Intelligence

Purpose: reduce professional/manual effort and improve capital allocation.

Likely capabilities:

- year-end close package;
- CPA review workspace/export;
- exception/judgment queue;
- tax-workpaper generation;
- receipt and document AI;
- reconciliation AI;
- valuation/depreciation agent;
- true-ROI/ROIC analytics;
- acquisition recommendations;
- natural-language analysis with deterministic drill-down.

## Phase E — Tax Product / Filing Integration (optional)

Purpose: evaluate whether direct return generation/filing has enough business value to justify regulatory, testing, maintenance, and liability burden.

This phase is not required to achieve major CPA-work reduction and should not be assumed now.

---

# 17. MVP product success criteria

These criteria are product targets for validation, not claims about current system performance. Financial correctness and auditability are hard gates; the founder-time target is a business target measured after establishing a reproducible baseline.

## 17.1 Current-state freshness

After a valid latest Turo export is committed:

- accepted canonical source state reflects the latest valid snapshot;
- every affected live investor-economic view has an explicit current/stale/blocked freshness state;
- an authorized finance user can complete refresh without spreadsheet re-entry;
- a user lacking finance-recalculation authority cannot cause authoritative finance mutation merely by importing source data.

## 17.2 Safe rerun behavior

- identical file rerun produces no duplicate reservations or duplicate financial effects;
- overlapping newer export updates only legitimate revisions/new reservations;
- retries/double submissions converge to the same final authoritative source state;
- repeated authorized recalculation advances/retains calculation lineage exactly once for the same source+rule inputs;
- historical issued statements are not silently rewritten.

## 17.3 Reconciliation accuracy

- every accepted imported row reconciles to the applicable source financial components under the import contract;
- non-reconciling or unresolved data is blocked/quarantined rather than guessed;
- investor calculations reproduce the accepted golden historical CR-V examples with no unexplained variance.

## 17.4 Spreadsheet elimination

For normal operations, the founder no longer needs to copy Turo rows, maintain recurring tracking charges, or manually reconstruct investor formulas in the Aaron CR-V workbook.

A spreadsheet may remain temporarily as a parallel verification tool during cutover, not as the continuing source of truth.

## 17.5 Manual-entry boundary and operating-cost integrity

- zero manual transcription of Turo-derived financial fields under the normal path;
- manual entry is limited to real facts Turo does not provide authoritatively, such as selected operating costs, reimbursements, and explicit adjustments;
- one manager-incurred/advanced oil-change/toll/repair entry creates one canonical operating-cost source fact and one applicable investor-economic effect, never two independently authored financial events;
- an investor-paid/reimbursable case cannot be silently accepted as a manager-incurred operating cost;
- the same source category under different management-agreement versions can produce different investor treatment without mutating the source fact;
- correcting a financially used operating cost preserves explicit reversal/replacement/correction lineage rather than destructive history;
- unauthorized/stale-step-up/foreign-Organization operating-cost create/correct commands create no partial financial fact;
- the majority of imported reservations require no operator financial editing.

## 17.6 Recurring-cost correctness

For a configured monthly recurring cost:

- an authorized Finance/Statement Refresh materializes all due occurrences through its cutoff/as-of period before calculation candidate selection;
- running the refresh twice for the same month creates exactly one occurrence and one canonical operating-cost fact;
- a month with no Turo import still materializes the due occurrence when an authorized Finance/Statement Refresh runs;
- the Organization financial-timezone/month-boundary policy assigns each occurrence to exactly one deterministic economic date/statement period;
- changing the rule amount/effective terms affects future occurrences only unless an explicit historical correction is created;
- disabling/re-enabling behavior is deterministic and does not erase or duplicate historical occurrences;
- a correction after statement issue never mutates issued statement membership/history silently;
- unauthorized rule create/edit/disable or refresh/materialization, missing `finance.adjustment.write` during materialization, stale step-up, revoked membership, or foreign-Organization Vehicle results in zero partial rule/cost mutation;
- recurring materialization cannot bypass the same authorization/audit/resource rules applied to the initiating finance command and underlying cost-fact command.

## 17.7 Finance-refresh authorization, fail-closed currentness, and failure visibility

Required negative/positive paths:

```text
SOURCE_MANAGER without finance permission
  → CURRENT import may succeed
  → authoritative finance refresh denied
  → old calculation fingerprint no longer matches authoritative inputs
  → affected economics read as non-current without relying on a stale-marker write

ORG_ADMIN / FINANCE with current permission + valid recent step-up
  → CURRENT import may succeed
  → authorized Finance Refresh materializes due recurring occurrences
  → finance recalculation authorized
  → complete input fingerprint/current calculation lineage advances exactly once

finance permission revoked / step-up stale / foreign Organization resource
  → finance recalculation/materialization denied
  → no partial/corrupt finance mutation
  → source import state remains independently correct
  → affected projection cannot pass the CURRENT fingerprint test

CURRENT import or operating-cost correction commits
  → subsequent finance refresh crashes/fails before new calculation commits
  → next read derives stale/non-current from authoritative input mismatch
  → old projection never appears CURRENT because a stale-flag write was missed

ownership/agreement/rule/override/source version changes
  → prior calculation fingerprint no longer matches
  → prior calculation is non-current until authorized deterministic refresh
```

## 17.8 Founder effort reduction

Before cutover, measure at least **three representative normal refresh/close cycles** using the existing process. Record median founder hands-on minutes from “latest Turo export available” to “payout-ready investor numbers,” excluding one-time migration/setup and tracking exception-handling time separately.

Target at least a **70% reduction** in median founder hands-on time after cutover. This is a product/business target, not permission to relax correctness if the percentage is missed.

Normal no-exception investor-vehicle refresh/close should be driven by import, deterministic refresh, and exception review rather than reservation-by-reservation spreadsheet work.

## 17.9 Investor payout confidence

For any issued amount, the system can trace:

```text
source artifact/revision
→ canonical economic/source facts
→ ownership/agreement/rule versions
→ manual/recurring operating-cost facts
→ deterministic calculation/subledger
→ statement
→ settlement record
```

Unresolved reconciliation/configuration/freshness blockers prevent issue rather than generating a plausible but unsupported number.

## 17.10 Operational scalability

Human effort should scale primarily with exceptions, not linearly with reservation count.

The MVP should be capable of handling materially more investor vehicles than the current operation without creating a new spreadsheet/checklist for each vehicle.

---

# 18. Cross-context synchronization requirements after review convergence

Do **not** execute downstream synchronization from this working revision merely because R1 has been addressed. After R2/convergence and founder acceptance, first promote this artifact to the proposed canonical path and register it. Then synchronize in dependency order against the exact current canonical targets.

| Context | Exact target | Disposition after product-direction promotion | Required synchronization / verification |
|---|---|---|---|
| `01-product-strategy` | `/Projects/Fleet-Management/shared/canonical/financial-platform-product-direction.md` | **REQUIRED — promote/register first** | Publish accepted revision; add it to `/Projects/Fleet-Management/shared/PROJECT-ARTIFACTS.md` with steward `01-product-strategy`. |
| `03-domain-model` | `/Projects/Fleet-Management/shared/canonical/mvp-domain-model.md` | **REQUIRED** | Resolve canonical manager-incurred/advanced operating-cost source-fact identity vs existing `EconomicAdjustment`; preserve minimal economic-actor responsibility; model the recurring rule/occurrence/materialization contract and Organization-financial-timezone monthly period rule; define complete-input fingerprint/currentness seams without precreating future accounting/tax tables. |
| `05-financial-ledger` | `/Projects/Fleet-Management/shared/canonical/mvp-investor-calculation-spec.md` | **REQUIRED** | Define agreement-policy-driven investor chargeability from manager-incurred operating-cost facts/recurring occurrences; prevent double posting with existing `EconomicAdjustment`; preserve live-vs-issued semantics and investor subledger separate from future GL; define complete-input fingerprint/currentness and correction interaction. |
| `02-system-architecture` | `/Projects/Fleet-Management/shared/canonical/mvp-architecture.md` | **REQUIRED after 03/05 semantics** | Define application-level import→authorized Finance Refresh orchestration without Source Ingestion owning Investor Finance; materialize due recurring costs synchronously in refresh before calculation; derive currentness fail-closed from complete authoritative input lineage; preserve finance permission/step-up boundary and modular monolith/no-broker/no-autonomous-scheduler default. |
| `02-system-architecture` | `/Projects/Fleet-Management/shared/canonical/mvp-implementation-plan.md` | **REQUIRED after architecture update** | Add manager-incurred operating-cost semantics, recurring monthly finance-refresh materialization, fail-closed input-fingerprint currentness, authorization/resource negative tests, month/timezone tests, crash-after-source-commit tests, and revised Phase-A exit criteria. |
| `04-identity-security` | `/Projects/Fleet-Management/shared/canonical/mvp-security-scope.md` | **REQUIRED VERIFY; FOCUSED UPDATE IF NEEDED** | Verify and explicitly cover `Create/CorrectOperatingCost`, `Create/Edit/DisableRecurringCostRule`, and Finance/Statement Refresh materialization resource predicates. Phase-A default is existing `finance.adjustment.write` for cost/rule mutations plus current recent-step-up/resource relationships, and `finance.calculation.write` for refresh/recalculation, unless Security deliberately chooses otherwise. Confirm no SYSTEM/autonomous-worker escalation and add required negative tests. |
| `06-data-import` | `/Projects/Fleet-Management/shared/canonical/mvp-turo-import-spec.md` | **DEFAULT VERIFY / NO CHANGE** | Confirm CURRENT import still outputs canonical current state + revision provenance and does not own finance refresh. Change only if its owned output contract actually changes. Do not add finance authority or generic accounting import. |
| `00-masterplan` | **No registered canonical masterplan artifact currently** | **HANDOFF REQUIRED** | Create a governance-compliant handoff covering capability map, sequencing (Investor MVP → Books V1 → Tax-Ready V1), dependencies, and major cross-context decision. If durable masterplan synchronization is desired, create/register its canonical artifact first rather than guessing a path. |
| `07-agentic-ai` | **No registered canonical agentic-AI artifact currently** | **HANDOFF REQUIRED** | Handoff future finance/tax/valuation agent opportunities, source-of-truth/approval boundaries, structured-output/provenance requirements, and explicit no-direct-authoritative-mutation rule. Create/register a canonical artifact first if durable synchronization is desired. |

Synchronization order:

```text
1. Promote/register accepted product direction
2. 03 domain semantics
3. 05 investor-finance semantics
4. 02 architecture
5. 02 implementation plan
6. 04 required security verification / focused synchronization if needed
7. 06 import verification / conditional change
8. 00 and 07 handoffs or canonical-artifact creation
```

Before every canonical write, follow `AGENTS.md`: retrieve current governance + registry, resolve exact target path, read current target version, preserve unrelated reviewed decisions, and record a no-change disposition when review shows mutation is unnecessary.

---

# 19. Explicitly unaffected current scope

This direction does not by itself pull the following into the current financial MVP:

- traveler commerce;
- direct booking;
- marketplace distribution network;
- multi-platform availability synchronization;
- public/customer portal;
- investor self-service portal;
- automated tax filing;
- payroll processing;
- bank feeds;
- receipt OCR;
- full general-ledger UI;
- automated valuation scraping;
- microservices/distributed architecture.

Those capabilities must still justify themselves through their own stage-specific ROI and dependencies.

---

# 20. R2 finding disposition and R3 convergence focus

R2 confirmed that all R1 findings remain resolved. Revision 3 addresses the three new narrow Significant findings, `SEC-FPD-002`, and the two R2 Minor hardening items without reopening broader product scope.

| R2 finding | Revision-3 disposition |
|---|---|
| `SIG-R2-001` — operating-cost economic-party meaning | **ADDRESSED:** §6.3 now defines Phase-A operating costs as manager/managing-Organization incurred or advanced Vehicle costs, preserves minimal economic-actor responsibility, routes investor-paid/reimbursable cases through explicit alternate paths, and makes investor chargeability agreement-policy-driven rather than category-driven. |
| `SIG-R2-002` — recurring materialization trigger/authority | **ADDRESSED:** §6.4 now materializes due monthly occurrences synchronously inside explicit authorized Finance/Statement Refresh, before calculation candidate selection; no autonomous scheduler/SYSTEM path; Organization financial timezone + concrete EffectiveFrom-anchored monthly occurrence rule required. |
| `SIG-R2-003` — freshness as mutable flag | **ADDRESSED:** §5.1/§6.5 make `CURRENT` fail-closed from the complete authoritative deterministic input fingerprint; source/cost/rule/agreement changes or refresh failure make prior results non-current without relying on a second stale-marker write. |
| `SEC-FPD-002` — cost/rule mutation authorization | **ADDRESSED AT PRODUCT CONTRACT:** §6.4 identifies cost/rule commands as privileged finance mutations, defaults them to existing `finance.adjustment.write` + recent step-up/resource authorization unless Security deliberately changes it, keeps refresh under `finance.calculation.write`, and prohibits autonomous SYSTEM materialization. §18 now makes Security verification required. |
| `MIN-R2-001` — incomplete idempotence wording | **ADDRESSED:** §5.1 now defines idempotence/currentness against the complete deterministic input set/fingerprint, including all source facts, ownership/agreement/configuration/policy inputs, and due recurrence requirements through cutoff. |
| `MIN-R2-002` — Security matrix disposition | **ADDRESSED:** §18 changes `04-identity-security` from conditional/no-change-biased to required verification with a focused update if the current contract does not explicitly cover the new resources/commands. |

R3 should be a **convergence gate only**, not another broad product review. It should verify:

1. the manager-incurred/advanced Phase-A cost meaning is sufficient to avoid ambiguity/double counting without introducing AP/payment infrastructure;
2. recurring monthly materialization inside authorized Finance/Statement Refresh is deterministic, authorized, idempotent, works without a Turo import, and has an unambiguous Organization-timezone period boundary;
3. `CURRENT` can never survive authoritative input mismatch or refresh failure because currentness is derived from the complete deterministic input fingerprint;
4. `SEC-FPD-002` is closed at the product-contract level and §18 gives `04-identity-security` enough direction for focused synchronization;
5. no Revision-3 fix accidentally expands Phase A into GL, tax, AP, scheduler, broker, bank-feed, receipt, or background-worker scope.

---

# 21. Promotion and handoff contract

This Revision 3 remains a `working/` review candidate. It must not become a source contract for steward-owned canonical changes until the narrow R3 convergence gate and founder acceptance.

**Chosen canonical promotion path:**

`/Projects/Fleet-Management/shared/canonical/financial-platform-product-direction.md`

Promotion workflow:

```text
1. Complete the narrow R3 convergence gate against Revision 3 and the R2 disposition map.
2. Resolve only any remaining material convergence findings in this same working artifact; do not reopen broad product scope without new evidence.
3. Founder accepts the converged direction.
4. Copy/promote the accepted artifact to:
   /Projects/Fleet-Management/shared/canonical/financial-platform-product-direction.md
5. Register that exact path in:
   /Projects/Fleet-Management/shared/PROJECT-ARTIFACTS.md
   Steward: 01-product-strategy
6. Only then execute the §18 synchronization matrix.
```

Post-promotion handoff contract:

```text
Source context: 01-product-strategy
Source canonical artifact:
  /Projects/Fleet-Management/shared/canonical/financial-platform-product-direction.md
Source revision: accepted/promoted revision
Decision/change:
  Investor Financial MVP is the first vertical slice of a broader tax-ready
  fleet accounting platform. Repeated current Turo upload, a live freshness-aware
  investor/vehicle economics view, one canonical operating-cost source-fact path,
  and simple monthly recurring cost materialization are Phase A. General accounting,
  evidence workflows, tax engine, valuation, labor, and finance AI remain future
  capabilities with explicit extension/projection boundaries.

Why it changed:
  Founder clarified that the platform must eventually replace paid bookkeeping
  software capabilities and most CPA preparation work while calculating true asset
  economics. R1 required sharper Phase-A source-fact, recurring-cost, finance-
  authorization/freshness, projection-lineage, and synchronization contracts.
  R2 then narrowed convergence to cost economic-actor meaning, authorized recurring
  materialization, and fail-closed complete-input-fingerprint currentness.

Target contexts:
  See §18 exact matrix.

Explicitly unaffected areas:
  See §19.

Open questions / human decisions:
  Only unresolved findings remaining after the R3 convergence gate; do not re-open
  accepted founder scope without new evidence.

Verification required:
  Each steward must retrieve the current exact canonical target, preserve existing
  reviewed financial-integrity/security/import/concurrency decisions, and record
  no-change dispositions where §18 marks verification/conditional action.

Masterplan update required: yes, through a governance-compliant handoff until a
registered canonical masterplan artifact exists.
```

---

# 22. Decision record

## Decision

Design the current investor-financial MVP as the first production vertical slice of a future tax-ready fleet accounting and asset-economics platform, not as an isolated investor spreadsheet replacement.

## Rationale

The founder needs the MVP immediately to eliminate repetitive Turo-to-investor spreadsheet work, but expects the same platform to become the authoritative system for bookkeeping, evidence, asset accounting, depreciation, tax-ready workpapers, vehicle valuation, labor/financing cost, and true fleet ROI. Establishing clean boundaries now is cheaper and safer than rewriting historical financial facts later.

## Tradeoffs

The platform will carry deliberate module/domain boundaries and some future extension points that are not exposed in MVP. This adds design discipline but should not be allowed to expand MVP implementation into unused workflows. The main risk is overengineering future accounting/tax functionality before the current investor workflow cuts over.

## What would cause us to revisit it

Revisit implementation sequencing or extension-point detail when:

- a proposed future-proofing concept materially delays MVP without protecting a concrete historical or financial invariant;
- real bookkeeping/tax requirements from the business/entity/CPA contradict an assumed future model;
- measured workflow shows a deferred capability such as receipts, bank reconciliation, or fixed-asset tax calculation is required earlier;
- the modular-monolith boundary becomes insufficient due to demonstrated independent scaling, reliability, deployment, compliance, or ownership needs.

The separation among canonical business facts, investor economics, general accounting, tax accounting, and economic valuation should be treated as a durable architectural direction unless a future review produces a stronger model.
