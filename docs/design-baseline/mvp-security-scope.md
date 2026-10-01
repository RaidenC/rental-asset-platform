# MVP Identity, Tenant Isolation & Security Scope

**Project:** Rental Asset & Travel Platform  
**Artifact:** `mvp-security-scope.md`  
**Canonical path:** `/Projects/Fleet-Management/shared/canonical/mvp-security-scope.md`  
**Steward:** `04-identity-security` — Chat 04 — Identity, Multi-Tenancy & Security  
**Status:** Security R3 `GREENLIGHT` and prior R4/R5 decisions retained; Revision 6 is the complete-MVP R1 focused SEC-001 synchronization. `IssueInvestorStatement` now has explicit compound authorization for issue + refresh + conditional recurrence materialization; SEC-002 is verified satisfied by the current Domain persistence contract without reopening the broader Security design.  
**Revision:** 6  
**Previous revision:** 5  
**Last changed by:** `04-identity-security` — focused complete-MVP R1 SEC-001 statement-issuance authorization synchronization  
**Last material synchronization:** 2026-09-25 — explicit compound statement-issue authorization, atomic denial semantics, focused negative tests, and SEC-002 persistence-defense verification  
**Primary inputs:**
- `/Projects/Fleet-Management/shared/canonical/financial-platform-product-direction.md`
- `/Projects/Fleet-Management/shared/canonical/mvp-domain-model.md`
- `/Projects/Fleet-Management/shared/canonical/mvp-investor-calculation-spec.md`
- `/Projects/Fleet-Management/shared/canonical/mvp-architecture.md`
- `/Projects/Fleet-Management/shared/canonical/mvp-implementation-plan.md`
- `/Projects/Fleet-Management/shared/canonical/mvp-turo-import-spec.md`
- `full-system-flow.md` from the existing `tai-portal` POC, used only as a noncanonical implementation reference
- `/Projects/Fleet-Management/04-identity-security/history/panel-review-mvp-security-scope__2026-09-20__r1.md`
- `/Projects/Fleet-Management/04-identity-security/history/panel-review-mvp-security-scope__2026-09-23__r2.md`
- `/Projects/Fleet-Management/04-identity-security/history/panel-review-mvp-security-scope__2026-09-24__r3.md`
- `/Projects/Fleet-Management/00-masterplan/history/panel-review-complete-mvp-package__2026-09-25__r1.md`

---

## 1. Purpose and scope

This document defines the **minimum identity, tenant-isolation, authorization, and security architecture required to implement the current investor-management MVP safely**.

It does not redefine domain, finance, or import semantics. The three canonical source contracts above remain authoritative for:

- Tenant/Organization ownership;
- provider/source identity and import semantics;
- OwnershipInterest and investor-economic relationships;
- cross-owner correction behavior;
- statement/ledger semantics;
- evidence and raw-source retention semantics.

The security design exists to enforce those contracts.

The initial product is expected to be operated primarily by the founder. Therefore the MVP intentionally avoids building a general-purpose customer/investor identity platform, dynamic authorization product, or support organization before there is a real user population requiring them.

### MVP security principle

```text
Authenticate the actor
→ derive Tenant server-side
→ derive Organization/resource scope server-side
→ require explicit permission
→ validate every target relationship
→ set transaction-local Tenant context
→ let PostgreSQL RLS enforce Tenant isolation
→ audit sensitive actions
```

No client-supplied ID, role, Tenant, Organization, Party, OwnershipInterest, SourceConnection, statement, evidence, or object-storage key is authorization by itself.

---

## 2. Source-contract boundaries that MUST remain unchanged

The following are fixed upstream/downstream contracts and are not reopened by this security design.

### Host access

```text
User
→ Membership
→ Organization
```

Host operational and finance authorization starts from an active Organization Membership.

### Investor access

```text
User
→ PartyAccessGrant
→ Party
→ OwnershipInterest
```

Ownership does not reference User directly. `PartyAccessGrant` is the identity-to-economic-party bridge.

### Finance/Admin writes

Finance/Admin commands must authorize through Organization plus the actual target resource relationship, including OwnershipInterest / Vehicle / Reservation / statement relationships.

### Cross-owner correction

A post-issue owner reassignment/correction is authorized against:

```text
managing Organization
+ Finance/Admin permission
+ every affected OwnershipInterest
```

Affected owners come from stored calculations/issued membership. Client-supplied source/target owner IDs are never authoritative.

### Source/import boundary

```text
Tenant
+ Organization
+ SourceConnection
```

is the authorization boundary for importing/managing one provider-source namespace.

Provider identity remains `Tenant + SourceConnection + external provider ID`.

`SourceArtifact` remains connection-agnostic within a Tenant; the processing attempt (`ImportBatch`) supplies SourceConnection/Organization context.

### Direct-ID access

All direct-ID access fails closed. Possession of a UUID/object ID never proves authorization.

### Same-Tenant cross-Organization isolation

Tenant isolation alone is insufficient. A user authorized for Organization A must not gain Organization B finance, evidence, source-management, or other Organization-owned data merely because both live in the same Tenant.

### Sensitive source/evidence access

Raw/source PII and `EvidenceDocument` access require separate sensitive-data authorization in addition to normal Organization/resource authorization.

### Worker/service context

Background work carries explicit Tenant plus relevant resource context. Queue/job IDs are input to authorization, not authorization themselves.

---

# 3. MVP scope decision

## In scope

The MVP requires:

- one production-grade human authentication path;
- MFA for privileged production access plus recent step-up for high-risk finance/source-PII/maintenance actions;
- server-side session rotation, timeout, and revocation controls;
- a platform-global `User` identity mapped from the identity provider subject;
- Organization-scoped `Membership`;
- fixed role templates mapped to named permissions;
- server-side resource/relationship authorization;
- the existing `PartyAccessGrant` relationship contract, but no investor-facing login surface;
- SourceConnection authorization;
- finance/statement/correction authorization;
- separate raw-source PII and EvidenceDocument authorization;
- transaction-scoped Tenant context;
- PostgreSQL RLS for Tenant-owned tables before production;
- explicit internal worker/service-principal identity and Tenant/resource context;
- security/audit events for sensitive operations;
- private object storage and secret management;
- untrusted CSV controls and safe future XLSX posture;
- negative authorization and RLS integration tests.

## Explicitly out of scope

The MVP does **not** require:

- investor login or investor portal;
- customer login/consumer identity;
- investor invitations, password recovery, MFA enrollment UX, or account onboarding;
- tenant-customizable roles;
- a Zanzibar/SpiceDB/OPA-style external authorization service;
- ABAC policy language;
- user-managed API keys;
- public third-party API/OAuth clients;
- a support-agent impersonation UI;
- arbitrary cross-tenant admin browsing;
- storing provider API credentials in `SourceConnection`;
- driver-license/DOB/address identity-verification storage;
- a full enterprise privileged-access-management system.

**Investor statement generation/review by an authorized host Finance/Admin user is sufficient for MVP.** Statements may be exported/delivered outside the product initially.

---

# 4. Minimal identity model

## 4.1 `User`

`User` is platform-global identity, not a Tenant role container.

Minimum shape:

```text
User
  id
  oidc_issuer
  external_subject       // stable OIDC sub
  email?                  // convenience/display only; not authorization identity
  status                  // ACTIVE | DISABLED
  created_at
  updated_at
```

Required persistence invariants:

- `(oidc_issuer, external_subject)` is unique;
- the OIDC issuer is canonicalized/validated against the configured trusted issuer, not accepted from request data;
- email is not used as a durable authorization key;
- `User` remains platform-global and is not protected by Tenant RLS;
- disabling the User blocks interactive access but does not rewrite historical financial/audit records.

Duplicate issuer+subject persistence must fail closed.

## 4.2 `Membership`

Host access remains:

```text
User → Membership → Organization
```

The MVP uses **one durable Membership row per User + Organization**, with audited status transitions rather than multiple overlapping effective-dated rows.

Minimum shape:

```text
Membership
  id
  tenant_id
  organization_id
  user_id
  status                  // ACTIVE | SUSPENDED | REVOKED
  effective_from
  effective_to?
  authorization_version   // incremented on status/role authorization changes
  created_at
  created_by
  updated_at
  updated_by
```

Required constraints:

- Membership is Tenant-owned;
- `user_id` has an explicit FK to the platform-global `User.id`;
- `(tenant_id, organization_id)` references an Organization in the same Tenant;
- `UNIQUE (tenant_id, organization_id, user_id)`;
- `effective_to > effective_from` when `effective_to` is present;
- `ACTIVE` requires `effective_to IS NULL`;
- MVP does **not** rely on scheduled future activation: a Membership is currently effective only when `status = ACTIVE`, `effective_from <= now()`, and `effective_to IS NULL`;
- every bootstrap and ordinary authorization predicate re-checks current effectivity, so even a malformed/future-dated `ACTIVE` row cannot authorize early;
- the Membership activation command rejects an `ACTIVE` transition whose `effective_from` is still in the future;
- `REVOKED`/ended Membership cannot authorize commands;
- authorization-relevant Membership or role changes increment `authorization_version`;
- revocation takes effect server-side without waiting for a long-lived authorization token to expire.

Historical Membership changes are preserved through the security audit trail; authorization uses the durable row's current state.

## 4.3 Fixed MVP roles and named permissions

Do not build tenant-customizable roles in MVP.

Use fixed role codes assigned through a durable join:

```text
MembershipRole
  tenant_id
  membership_id
  role_code
  status                  // ACTIVE | REVOKED
  created_at
  created_by
  updated_at
  updated_by
```

Persistence requirements:

- `(tenant_id, membership_id)` composite-FKs to Membership;
- `UNIQUE (tenant_id, membership_id, role_code)`;
- role changes occur only through an authorized Membership-management path and increment the parent Membership's `authorization_version`;
- unknown role or permission codes fail closed;
- fixed role → permission mapping lives in reviewed code/config for MVP.

Initial role templates:

```text
ORG_ADMIN
FINANCE
SOURCE_MANAGER
```

The founder can initially hold only `ORG_ADMIN`; the other templates exist so authorization policies are not hard-coded to “the owner user.”

Named permissions are the application contract. Minimum set:

```text
organization.admin
security.audit.read

source.connection.manage
source.import.execute
source.current.apply
source.raw.read
source.pii.read

finance.read
finance.calculation.write
finance.adjustment.write
finance.statement.issue
finance.payment.write
finance.cross_owner_correct

evidence.read
evidence.write
```

Sensitive permissions (`source.raw.read`, `source.pii.read`, evidence access) remain explicit even if `ORG_ADMIN` currently receives them.

### Suggested role templates

```text
ORG_ADMIN
  all Organization-scoped MVP permissions
  security.audit.read

FINANCE
  finance.read
  finance.calculation.write
  finance.adjustment.write
  finance.statement.issue
  finance.payment.write
  finance.cross_owner_correct
  evidence.read
  evidence.write
  // no raw/source PII by default

SOURCE_MANAGER
  source.connection.manage
  source.import.execute
  source.current.apply
  // raw/source PII remains separately controlled
```

Adding a second employee should not require changing authorization semantics; it should only require creating a Membership and assigning a role.

## 4.4 Authenticated identity → Tenant/Organization bootstrap

### ADR-04-MVP-000 — Use a dedicated transaction-scoped RLS-constrained Membership bootstrap path

**Decision**  
A platform-global authenticated User enters the Tenant-scoped authorization world through a deliberately narrow bootstrap path, not by trusting a Tenant header and not by resolving arbitrary business-resource IDs.

Use a dedicated PostgreSQL role/path:

```text
identity_bootstrap
  NO BYPASSRLS
  NOINHERIT
  does not own Tenant tables
  cannot SET ROLE to app_runtime or maintenance_admin
  cannot be assumed/SET ROLE by app_runtime
  no read access to Vehicle/finance/import/evidence/business tables
  may resolve only the minimal platform-global User identity projection
  may SELECT only the authenticated User's currently effective Membership tuples
```

The platform-global User lookup is part of the same identity bootstrap module. It exposes only the minimal identity projection needed to map a verified OIDC identity:

```text
user_id
status
```

by exact trusted `(oidc_issuer, external_subject)` (or by `User.id` after that resolution). The bootstrap role does not receive a general business-data read path and does not use email as identity.

`Membership` has a role-scoped bootstrap SELECT policy. The bootstrap query always runs inside a short transaction and uses transaction-local authenticated-User context:

```sql
BEGIN;

SET LOCAL app.authenticated_user_id = '<verified platform User uuid>';

SELECT
    id,
    tenant_id,
    organization_id,
    authorization_version
FROM identity.membership
WHERE status = 'ACTIVE'
  AND effective_from <= CURRENT_TIMESTAMP
  AND effective_to IS NULL;

COMMIT;
```

The corresponding RLS policy is explicitly limited to the bootstrap role:

```sql
CREATE POLICY membership_authenticated_user_bootstrap
ON identity.membership
FOR SELECT
TO identity_bootstrap
USING (
    user_id = current_setting('app.authenticated_user_id', true)::uuid
    AND status = 'ACTIVE'
    AND effective_from <= CURRENT_TIMESTAMP
    AND effective_to IS NULL
);
```

The normal Tenant policy is separately scoped to `app_runtime`; its predicate is based on `app.tenant_id`. The bootstrap policy must never be an unqualified permissive policy that can OR into `app_runtime` access.

The BFF/application sets `app.authenticated_user_id` only from the `User` resolved by a verified trusted `(oidc_issuer, sub)` pair. It must use `SET LOCAL`, never session-scoped `SET`, so pooled bootstrap connections cannot retain User A's identity when reused for User B. No request DTO, header, query string, Tenant ID, Organization ID, Membership ID, or resource ID may set this value.

Bootstrap flow:

```text
1. validate OIDC issuer + subject
2. resolve the unique platform-global User through the narrow identity lookup path
3. if User is disabled → deny
4. BEGIN bootstrap transaction
5. SET LOCAL app.authenticated_user_id = verified User.id
6. query only that User's currently effective Membership tuples through identity_bootstrap
7. COMMIT/ROLLBACK; authenticated-user GUC disappears with the transaction
8. zero contexts → authenticated but no application access
9. one context → server may auto-select it
10. multiple contexts → client-selected Tenant/Organization is an untrusted selector
    and must exactly match one returned Membership tuple
11. create server-side ActorContext / session context
12. ordinary business authorization begins only after ActorContext exists
```

Minimum `ActorContext`:

```text
user_id
membership_id
tenant_id
organization_id
authentication_assurance
authenticated_at
session_id
membership_authorization_version_at_bootstrap
```

The bootstrap result is **not** a general authorization cache. Every sensitive read and every protected mutation rebinds the full Membership tuple under Tenant context:

```text
Membership.id == actor.membership_id
Membership.user_id == actor.user_id
Membership.tenant_id == actor.tenant_id
Membership.organization_id == actor.organization_id
Membership.status == ACTIVE
Membership.effective_from <= now()
Membership.effective_to IS NULL
```

and then validates current roles/permissions/resource relationships. A valid User plus a foreign Membership ID must fail closed.

Direct business-resource IDs never participate in Tenant discovery. A request that has not established an ActorContext cannot use `/evidence/{id}`, `/statements/{id}`, `/source-connections/{id}`, or similar direct IDs to discover a Tenant.

Normal `app_runtime` continues to require `SET LOCAL app.tenant_id` and receives no bootstrap exception. `identity_bootstrap` is the only pre-Tenant access path to Tenant-owned data, and its only Tenant-owned target is Membership.

**Rationale**  
This closes the R2 residual around pool/GUC leakage and permissive policy scope while preserving the narrow solution to R1's circular dependency. The pre-Tenant path can enumerate only the authenticated User's own currently effective Membership tuples and cannot read arbitrary Tenant business data.

**Tradeoffs**  
The application has a small second database role/pool or equivalent narrowly scoped data-access path. Tenant/Organization switching becomes an explicit server-side context operation, and RLS tests must cover both role families.

**What would cause us to revisit it**  
A separate identity service/database becomes the authoritative Membership directory, or a managed identity platform supplies an equivalent cryptographically trusted Organization membership assertion. Normal business-resource access must still never use a general cross-Tenant lookup.

---

# 5. Authentication architecture and tai-portal reuse

## ADR-04-MVP-001 — Reuse tai-portal as the authentication foundation, not as the rental-domain authorization source

**Decision**  
Reuse economically valuable parts of the existing `tai-portal` identity POC: ASP.NET Identity/OpenIddict, OIDC Authorization Code + PKCE support, application/client registration, security headers/CSP/Trusted Types patterns, audit/correlation patterns, and related hardening. Treat `tai-portal` as the shared authentication/identity foundation. The rental platform maps the OIDC subject to its local `User` and resolves Membership/resource authorization itself.

For the web MVP, prefer a same-origin ASP.NET BFF/session pattern so Angular holds an HttpOnly Secure session cookie while OAuth access/refresh credentials remain server-side. The BFF is registered as a confidential OIDC client with tai-portal/OpenIddict.

Do **not** treat the current POC `tenant_id` claim or token-embedded privilege list as authoritative rental-platform authorization. Do not require the POC's DPoP/dual REST-WebSocket design to ship the MVP unless it is already operationally cheaper than the BFF path.

**Rationale**  
Authentication is already partially solved, while the new security-critical work is Membership/resource authorization and Tenant isolation. Reusing the POC avoids rebuilding login, OIDC, user/session infrastructure, and web hardening. Keeping authorization local avoids coupling domain relationships to the identity provider and supports a user participating in multiple Organizations later.

**Tradeoffs**  
A BFF introduces server-side session state and requires adapting the current POC's browser-token pattern. Running our own OpenIddict-based identity service still carries operational responsibility for authentication security.

**What would cause us to revisit it**  
A managed IdP becomes materially cheaper than operating authentication ourselves; native/mobile/public-API clients require direct OAuth tokens; or multiple independent products need a more mature centralized identity control plane. The rental domain must remain dependent on OIDC identity, not OpenIddict internals.

### Minimum web controls

- HTTPS only outside local development;
- Secure + HttpOnly session cookie;
- appropriate SameSite policy for the OIDC flow;
- every unsafe state-changing cookie-authenticated request requires a valid anti-forgery mechanism; SameSite and strict Origin validation are defense in depth, not substitutes;
- strict CSP and Trusted Types based on the tai-portal hardening work;
- no third-party analytics/scripts on authenticated finance/source-PII surfaces unless explicitly reviewed;
- rate limits on login, upload, and other abuse-sensitive endpoints;
- no hard-coded/fallback production secrets.

### Privileged authentication/session baseline

MFA is required by **privilege**, not merely by the `ORG_ADMIN` label.

Every production session for the current privileged role templates requires MFA at session establishment:

```text
ORG_ADMIN
FINANCE
SOURCE_MANAGER
```

The same rule applies to any future Membership that is granted a privileged/sensitive permission even if it uses a different role label. For MVP, the privileged/sensitive permission set includes Organization administration, source-management/import mutation, provider-current assertion, finance mutation/issue/payment/correction, raw/source PII access, and evidence write.

The MVP may use the strongest practical tai-portal-supported factor (for example WebAuthn/passkey or TOTP); self-service enrollment UX is not required, but single-factor privileged production access is not accepted.

High-risk actions require a **recent step-up** (initial MVP target: MFA within the previous 15 minutes):

```text
finance.calculation.write
finance.adjustment.write
finance.statement.issue
finance.payment.write
finance.cross_owner_correct
source.current.apply
source.raw.read
source.pii.read
maintenance/break-glass entry
```

`source.current.apply` is explicitly in the step-up set because it is an operator assertion that advances provider-current state.

Server-side BFF session controls:

- rotate the session identifier on login, MFA/step-up, and privilege-context changes;
- idle timeout: 30 minutes;
- absolute session lifetime: 12 hours;
- User disable, Membership suspension/revocation, or explicit logout/revoke invalidates the server session;
- Membership/role changes invalidate or refresh cached authorization state; no long-lived permission claims remain authoritative.

These values are operational defaults, not protocol constants; tightening/loosening them requires an explicit security review.

---

# 6. Authorization evaluation model

Authorization is intentionally local and explicit.

## 6.1 Host/Organization path

Authorization has two stages:

```text
AuthenticatedIdentity
→ ActorContext bootstrap
→ Tenant-scoped ResourceAuthorization
```

For ordinary reads:

```text
1. require a server-created ActorContext
2. begin a Tenant-scoped DB transaction when data access occurs
3. SET LOCAL app.tenant_id from ActorContext
4. load target only within that Tenant
5. derive Organization/resource relationships from stored data
6. require current active Membership in ActorContext.Organization
7. require named permission
8. return only purpose-specific authorized projection
```

For **mutating commands**, preflight/UI authorization is advisory only. The authoritative authorization check is transactionally coupled to the mutation:

```text
BEGIN
  SET LOCAL app.tenant_id from ActorContext
  load + lock the actor Membership authorization row
  validate ACTIVE Membership + current authorization_version/roles
  acquire the canonical domain lock when required
    (Tenant + SourceConnection for CURRENT import;
     Vehicle-scoped finance lock for statement/correction paths)
  re-load authoritative target relationships/currentness
  validate named permission + resource policy
  mutate
  persist audit outcome with the business transaction where appropriate
COMMIT
```

Authorization-affecting Membership/role mutation paths must take a conflicting lock on the Membership row, so a revoke/role change cannot race through an already-authorized high-risk command.

The application must never accept a request-provided Tenant/Organization/resource tuple as authority. Tenant/Organization selection is confined to the bootstrap service and validated against the authenticated User's Membership tuples.

## 6.2 Direct-ID behavior

A direct endpoint such as:

```text
GET /evidence/{id}
POST /statements/{id}/issue
POST /source-connections/{id}/imports
```

must resolve the resource under Tenant scope and re-run Organization/resource authorization.

Recommended API behavior:

- target missing or outside authorized Tenant/Organization/resource scope → `404`;
- target is in the actor's authorized Organization/resource scope but permission is missing → `403`;
- missing authentication → `401`.

This reduces ID-enumeration/oracle leakage while keeping permission errors diagnosable.

## 6.3 Investor path contract

If investor login is later enabled, authorization is **not** Membership-based merely because the investor belongs to the same Tenant.

```text
User
→ active PartyAccessGrant
→ Party
→ applicable/historical OwnershipInterest
→ explicitly investor-authorized projection
```

One OwnershipInterest must not expose:

- another owner's statements/evidence;
- host-private finance data;
- Customer contact PII;
- raw source PII;
- unrelated current Vehicles.

Closed OwnershipInterest may continue to authorize the historical statement/payment/performance history associated with that ownership period, as required by the canonical domain contract.

---

# 7. Investor login/portal decision

## ADR-04-MVP-002 — Investor login and investor portal are OUT OF SCOPE

**Decision**  
Do not build investor authentication/onboarding or an investor-facing portal in the initial MVP. `PartyAccessGrant` remains the canonical future authorization relationship and schema contract, but no production investor login/API surface is required. Host Finance/Admin users generate, review, issue, export, and manually deliver investor statements initially.

**Rationale**  
The immediate business problem is replacing the founder's investor spreadsheet with deterministic, auditable calculations and statements. Investor self-service does not improve correctness of the financial engine and adds authentication recovery, invitations, access-management UX, privacy surface, and support obligations before there is enough user demand.

**Tradeoffs**  
Investors cannot independently log in to inspect live performance/statements. Statement delivery and questions remain an operational process.

**What would cause us to revisit it**  
Enough external investors require self-service access that manual statement delivery/support becomes material; investor acquisition depends on portal visibility; or participating hosts require delegated investor access. Before enabling any investor endpoint, activate and test the PartyAccessGrant authorization path and its negative direct-ID cases.

---

# 8. Import and SourceConnection authorization

## ADR-04-MVP-003 — Import authorization is Organization + SourceConnection scoped and fail-closed before parsing/apply

**Decision**  
An interactive import request requires:

```text
authenticated User
→ active Membership in SourceConnection.Organization
→ source.import.execute
→ same Tenant
→ target SourceConnection is ACTIVE and belongs to that Organization
```

A CURRENT import additionally requires `source.current.apply` because CURRENT freshness is an explicit operator assertion with authority to advance provider-current state.

Managing/creating/disabling a SourceConnection requires `source.connection.manage`.

The full trust context is validated before a batch is eligible to parse/normalize/apply against the SourceConnection. Failure is batch-blocking: zero rows apply.

**Rationale**  
The import contract makes SourceConnection part of provider identity and CURRENT mutation serialization. Allowing a valid Tenant user to choose an arbitrary same-Tenant SourceConnection would violate Organization isolation and could corrupt canonical/current provider state.

**Tradeoffs**  
Every import command must resolve several relationships before processing begins; background retries must preserve and revalidate this context.

**What would cause us to revisit it**  
A future provider account legitimately spans multiple Organizations. That requires an explicit source-account authorization model; the Organization boundary must not simply be removed.

### SourceArtifact access nuance

`SourceArtifact` is identified by `Tenant + SHA-256` and is intentionally not owned by one SourceConnection/Organization.

Therefore direct raw-artifact access must require:

```text
Tenant match
+ source.raw.read
+ source.pii.read when readable payload contains guest PII
+ at least one authorized ImportBatch → SourceConnection → Organization relationship for that artifact
```

An artifact ID by itself is never enough.

---

# 9. Finance authorization

## ADR-04-MVP-004 — Finance writes require Membership + permission + stored Organization/resource relationships

**Decision**  
Every command that creates or changes authoritative finance/source-fact state requires current active Membership in the target managing Organization, the named permission, recent step-up when required, and server-derived target-resource relationship validation.

Phase-A keeps the existing permission model; no new role or permission is introduced merely for operating costs:

```text
finance.adjustment.write
  → CreateOperatingCost
  → CorrectOperatingCost
  → CreateRecurringCostRule
  → EditRecurringCostRule
  → DisableRecurringCostRule
  → existing investor-specific adjustment/reimbursement mutation paths

finance.calculation.write
  → authoritative Finance Refresh / Statement Refresh
  → authoritative investor recalculation/currentness refresh
  → ReservationInvestorCalculationCurrent advancement
  → deterministic OperatingCostInvestorProjection / investor-ledger target refresh
  → correction-required state derivation
```

The architecture may expose persistence-oriented recurring-rule command names such as `CreateRecurringExpenseRule`, `CreateRecurringExpenseRuleVersion`, or prospective disable/retirement operations. Those are the same Security authority boundary as the product-facing `Create/Edit/DisableRecurringCostRule` commands.

Both `finance.adjustment.write` and `finance.calculation.write` are high-risk privileged mutations and require the existing recent-step-up rule.

### Operating-cost and recurring-rule mutation predicate

For `CreateOperatingCost`, `CorrectOperatingCost`, `CreateRecurringCostRule`, `EditRecurringCostRule`, and `DisableRecurringCostRule`, the authoritative command path must establish and revalidate:

```text
actor has current ACTIVE Membership in target Organization
actor has finance.adjustment.write
actor has current recent step-up

actor.TenantId == target Tenant
actor.OrganizationId == target managing Organization

Vehicle.TenantId == target Tenant
Vehicle.managing_organization_id == target Organization

optional Reservation:
  Reservation.TenantId == target Tenant
  Reservation.OrganizationId == target Organization
  Reservation.VehicleId == target Vehicle

referenced OperatingCostFact / RecurringExpenseRule / RuleVersion:
  belongs to the same Tenant + Organization + Vehicle

every affected OwnershipInterest that is server-derived as financially affected:
  same Tenant
  same Vehicle
  Vehicle is managed by actor.Organization
  actor is authorized for that OwnershipInterest through the host Finance relationship
```

The server derives the affected ownership/resource set from persisted facts, current/corrected lineage, applicable ownership, and agreement relationships. Client-supplied Vehicle, OwnershipInterest, Reservation, OperatingCostFact, recurring-rule, or RuleVersion IDs are only requested references and never authority.

`CorrectOperatingCost` must authorize the original fact plus every server-derived affected OwnershipInterest before inserting any reversal/replacement lineage. A relationship/authorization failure aborts the entire correction.

### Authoritative Finance / Statement Refresh predicate

Authoritative investor recalculation/currentness refresh requires:

```text
current ACTIVE Membership
+ finance.calculation.write
+ current recent step-up
+ target Tenant/Organization/Vehicle authorization
+ authoritative revalidation of applicable OwnershipInterest(s), agreement/currentness,
  and other target relationships under the canonical Vehicle-scoped finance lock
```

`finance.read` is strictly non-mutating. It may read an already-materialized projection but cannot invoke a hidden refresh, advance current calculation lineage, materialize recurring costs, create/supersede investor ledger effects, or derive/write correction-required state.

### Dual authority for recurring materialization inside refresh

Finance/Statement Refresh may discover missing due recurring occurrences. If the command will materialize any `RecurringExpenseOccurrence` or canonical `OperatingCostFact(source_kind = RECURRING_RULE)`, the same initiating actor must satisfy **both** authorities before the first materialization write:

```text
finance.calculation.write
AND
finance.adjustment.write
AND current recent step-up
AND current Tenant + Organization + Vehicle + affected OwnershipInterest/resource authorization
```

Required transaction behavior:

```text
BEGIN
SET LOCAL app.tenant_id from ActorContext
lock/revalidate actor Membership authorization state
acquire canonical VehicleInvestorEconomicLock
re-read Tenant/Organization/Vehicle/ownership/agreement/rule/currentness relationships
authorize finance.calculation.write + recent step-up
determine whether any due occurrence is missing
if materialization is required:
    authorize finance.adjustment.write
    revalidate every affected resource relationship
    only then insert any occurrence or OperatingCostFact
materialize all authorized missing occurrences idempotently
refresh authoritative investor projections/currentness
audit
COMMIT
```

If either permission, step-up, Membership, or any affected resource predicate fails, the protected refresh fails closed. **No partial recurrence materialization is allowed:** zero new due occurrences and zero new recurring OperatingCostFacts are committed by that failed refresh. Existing previously committed source facts remain unchanged, and the affected live projection remains non-current/blocked according to the canonical complete-input fingerprint.

### No SYSTEM/autonomous finance authority

Phase A does **not** permit `SYSTEM`, maintenance, source-ingestion, or an autonomous worker capability to substitute for either `finance.calculation.write` or `finance.adjustment.write`.

Specifically, a SYSTEM/service principal may not:

- create/correct an OperatingCostFact;
- create/edit/disable a recurring cost rule;
- materialize recurring expense occurrences or recurring OperatingCostFacts;
- perform authoritative Finance/Statement Refresh;
- advance investor-calculation current pointers;
- create/supersede investor-economic projection/ledger state merely because the computation is deterministic.

The normal Phase-A Finance Refresh path is synchronous and user-authorized. If asynchronous finance mutation is introduced later, it must use the already-approved `USER_DELEGATED` model and revalidate the initiating User's current permissions, recent step-up semantics, and target relationships at execution; it must not be reclassified as SYSTEM merely to make automation easier.

**Rationale**  
The existing permission split already expresses the two different authorities: `finance.adjustment.write` controls authoritative cost/configuration mutation, while `finance.calculation.write` controls authoritative investor-economic refresh. Reusing them avoids role proliferation while preventing `finance.read`, Source Ingestion, or SYSTEM automation from gaining hidden write authority.

**Tradeoffs**  
A Finance Refresh that must materialize recurrence requires two permission checks and may fail even when ordinary recalculation authority is present. This is intentional: creating canonical operating-cost facts is a separate authority from calculating their investor-economic effects.

**What would cause us to revisit it**  
A real operational need emerges for a separately delegated cost-entry role, a separately delegated recurring-configuration role, or asynchronous finance refresh at scale. Any such change requires a focused Security/Architecture review rather than broadening SYSTEM implicitly.

## Statement finalization

`finance.statement.issue` is a high-risk permission, but it is **not** an implicit grant of authoritative Finance/Statement Refresh authority.

### Compound authorization for `IssueInvestorStatement`

Phase-A statement issue always depends on authoritative Statement Refresh/currentness verification through the requested cutoff. Therefore the initiating actor must satisfy, under the protected Vehicle-scoped transaction/lock and before the first authoritative mutation:

```text
finance.statement.issue
AND finance.calculation.write
AND current recent step-up
AND current Tenant + Organization + Vehicle + OwnershipInterest + statement relationships
```

If that required refresh discovers any missing due recurring occurrence and would create a `RecurringExpenseOccurrence` and/or `OperatingCostFact(source_kind = RECURRING_RULE)`, the same initiating actor must additionally satisfy:

```text
finance.adjustment.write
```

`finance.statement.issue` never implies, borrows, elevates to, or substitutes for `finance.calculation.write` or `finance.adjustment.write`. The nested refresh/materialization authorities remain the same authorities they require when invoked independently.

The authoritative issue sequence is:

```text
BEGIN
SET LOCAL app.tenant_id from ActorContext
lock/revalidate actor Membership authorization state
acquire canonical VehicleInvestorEconomicLock
re-read statement + Tenant/Organization/Vehicle/OwnershipInterest/currentness relationships
authorize finance.statement.issue
authorize finance.calculation.write
validate current recent step-up
run/require Statement Refresh through statement cutoff
if refresh requires recurrence materialization:
    authorize finance.adjustment.write
    revalidate affected cost/rule/resource relationships
only after every required permission/predicate succeeds:
    materialize any required recurring source facts
    advance authoritative recalculation/current-lineage/projection state
    recompute exact statement membership/totals/review fingerprint
    freeze cutoff/membership
    mark statement ISSUED
audit
COMMIT
```

All permissions, Membership state, and server-derived resource predicates are revalidated under the lock before the first authoritative mutation of the issue attempt. Client-supplied statement, Vehicle, Organization, or OwnershipInterest IDs are requested references only and never authority.

Failure is atomic for the protected issue attempt. If any required permission, Membership, step-up, resource relationship, completeness/currentness precondition, or nested refresh/materialization authorization fails:

- no new recurring occurrence or recurring OperatingCostFact is committed;
- no partial authoritative recalculation/current-pointer/projection/ledger advancement is committed;
- no partial DRAFT membership/totals/cutoff freeze is committed by the issue attempt;
- the statement is not marked `ISSUED`.

If no recurrence materialization is required, `finance.adjustment.write` is not an additional requirement merely because statement issue performs refresh; the required authorities are `finance.statement.issue + finance.calculation.write` plus the common step-up/resource predicates.

MVP flow:

```text
calculate/review DRAFT
→ revalidate compound issue + refresh authorities under Vehicle lock
→ conditionally revalidate cost-mutation authority if recurrence must materialize
→ authoritative refresh/currentness proof succeeds
→ exact membership/cutoff frozen
→ issued statement immutable
```

No second-human approval is required in MVP because the founder is expected to be the primary operator. The issue action must record actor, timestamp, Organization, OwnershipInterest, statement ID, trace/correlation ID, and result.

A later two-person approval workflow may be added without changing the statement domain model.

## Cross-owner correction

Use a named host-side policy:

```text
AuthorizeHostOwnershipInterestForFinance(
    ActorContext actor,
    OrganizationId correctionOrganization,
    VehicleId correctionVehicle,
    OwnershipInterestId affectedOwnershipInterest,
    Permission finance.cross_owner_correct)
```

For **every** affected OwnershipInterest derived from stored calculation/issued-statement lineage, the policy requires:

```text
actor.TenantId == correction.TenantId
actor.OrganizationId == correction.OrganizationId
actor has current ACTIVE Membership in correction.Organization
actor has finance.cross_owner_correct

OwnershipInterest.TenantId == correction.TenantId
OwnershipInterest.VehicleId == correction.VehicleId
Vehicle.managing_organization_id == correction.OrganizationId
OwnershipInterest is one of the server-derived affected interests
```

`PartyAccessGrant` is **never** host Finance mutation authority.

Approval/application runs inside the canonical Vehicle-scoped finance transaction/lock. After the lock is acquired, the server re-derives the affected OwnershipInterest set and re-runs the predicate for every affected interest before posting any correction line.

If any relationship fails, the entire correction fails closed. Partial authorization must never post a partial cross-owner correction.

---

# 10. Sensitive data authorization

## ADR-04-MVP-005 — Raw/source PII and EvidenceDocument require separate permissions

**Decision**  
Normal import/finance permission does not automatically grant access to sensitive underlying payloads.

Use explicit sensitive-data permissions:

```text
source.raw.read
source.pii.read
evidence.read
evidence.write
```

`source.import.execute` allows an authorized import to process encrypted/raw bytes through deterministic server code but does not imply that the human user may browse or download the raw file or raw row values.

`finance.read` or `finance.adjustment.write` does not automatically grant raw Turo guest PII.

Evidence access requires:

```text
Tenant match
+ Organization/resource relationship
+ evidence.read
+ authorized domain link to the EvidenceDocument
```

**Rationale**  
The canonical model explicitly separates investor/finance access from Customer/source PII and requires Organization-owned private evidence. Processing data and viewing its sensitive contents are different privileges.

**Tradeoffs**  
The founder may hold all permissions initially, so the separation is not visible in daily MVP use, but it creates auditable boundaries before staff is added.

**What would cause us to revisit it**  
More granular purpose-based access becomes necessary for support, claims, legal, or customer-service roles.

### Turo guest PII

During approved retention:

- exact source bytes/raw strings are encrypted;
- authorized troubleshooting can follow an issue to the encrypted RawImportRecord;
- normal import screens/logs use redacted/minimized values;
- raw CSV rows, guest names, exact trip locations, and full source payloads never enter ordinary application logs.

After retention expiry:

- exact readable guest PII is destroyed/disabled according to the canonical retention contract;
- economic/provenance hashes and redacted representations remain;
- authorization does not provide a way to reconstruct purged PII.

Customer contact or investor ownership must never implicitly authorize raw source guest PII.

---

# 11. Tenant ownership of records

## ADR-04-MVP-006 — Every tenant-owned operational/import/financial record carries `tenant_id`

**Decision**  
Follow the canonical domain contract: every tenant-owned table stores `tenant_id` directly even when it is inferable from a parent.

This includes, at minimum:

```text
Organization
Membership
Party
PartyAccessGrant
EvidenceDocument
Vehicle
OwnershipInterest
Listing / external bindings
SourceConnection
SourceArtifact
ImportBatch
RawImportRecord
ImportIssue
ExternalReservationBinding
SourceObservation
SourceEarningComponent
Reservation
Trip
ReservationEconomicSnapshot / components / provenance links
ManagementAgreementVersion
OperatingCostFact
RecurringExpenseRule
RecurringExpenseRuleVersion
RecurringExpenseOccurrence
OperatingCostInvestorProjection
InvestorEconomicsProjectionSnapshot
InvestorReimbursement
EconomicAdjustment
ReservationInvestorCalculation
ReservationInvestorCalculationCurrent
CrossOwnershipCorrection
EconomicLedgerEntry
InvestorStatement / entries
DistributionPayment
```

Platform/reference concepts such as the Channel catalog are not Tenant-owned. `User` is platform-global identity.

Tenant-aware composite FKs must be used for important cross-resource relationships so same-Tenant/cross-resource mismatches are rejected structurally where practical.

**Rationale**  
Explicit tenant ownership makes RLS possible, improves debugging/auditability, prevents accidental global joins, and creates defense in depth against application mistakes.

**Tradeoffs**  
More repeated Tenant columns and composite constraints.

**What would cause us to revisit it**  
Only a deliberate move to physically isolated tenant databases or an equivalent stronger isolation model. Do not remove `tenant_id` merely to reduce duplication.

---

# 12. PostgreSQL RLS

## ADR-04-MVP-007 — PostgreSQL RLS is an MVP production requirement, not a post-MVP enhancement

**Decision**  
Implement Tenant RLS for Tenant-owned tables in the MVP and enable `FORCE ROW LEVEL SECURITY` before production data is considered security-cleared.

Use the canonical database-role split synchronized with the domain model:

```text
schema_owner / migration role
  owns schema/tables
  never used by application runtime

app_runtime
  ordinary Tenant-scoped DML
  NO BYPASSRLS
  does not own Tenant tables
  cannot assume identity_bootstrap or maintenance_admin

identity_bootstrap
  narrow pre-Tenant identity path
  NO BYPASSRLS
  NOINHERIT
  does not own Tenant tables
  no ordinary Tenant business-table privileges
  may resolve only minimal platform-global User identity
  may SELECT only authenticated User's currently effective Membership tuples
  cannot assume app_runtime or maintenance_admin

maintenance_admin
  explicit privileged operational role/path
  never used by normal web/API/worker connection strings
```

Every **ordinary Tenant business-data** DB operation executes inside a transaction:

```sql
BEGIN;
SET LOCAL app.tenant_id = '<server-validated tenant uuid>';
-- queries / commands
COMMIT;
```

Missing Tenant context must fail closed for ordinary Tenant business tables.

The only pre-Tenant Tenant-owned-table exception is the §4.4 Membership bootstrap:

```sql
BEGIN;
SET LOCAL app.authenticated_user_id = '<verified platform User uuid>';
-- SELECT only this User's currently effective Membership tuples
COMMIT;
```

That exception is role-scoped to `identity_bootstrap`; it does not apply to `app_runtime` and does not authorize any other Tenant-owned table.

RLS enforces **Tenant isolation only**. Same-Tenant cross-Organization authorization remains an application + relationship/composite-FK responsibility.

Deployment sequence:

```text
schema with tenant_id + tenant-safe FKs
→ code uses transaction-scoped Tenant context for ordinary access
→ identity bootstrap uses transaction-scoped authenticated-User context
→ PostgreSQL tenant + bootstrap role/pool tests pass
→ enable/force RLS
→ verify web + worker/import + bootstrap paths
→ production gate
```

Production rollback rule:

- normal incident response does **not** disable RLS;
- rollback application/schema changes to a version that remains compatible with the RLS contract;
- startup/health checks verify `app_runtime` and `identity_bootstrap` are `NO BYPASSRLS`, do not own Tenant tables, have no role-escalation path between them, and required Tenant tables have RLS enabled/forced;
- failure of these checks is a deployment/security failure, not a reason to fall back to an owner/BYPASSRLS connection.

**Rationale**  
Cross-tenant leakage is the highest-impact multi-tenant failure. The canonical domain contract already requires RLS and transaction-local context. Deferring it until after data exists invites an expensive retrofit and leaves the MVP's strongest isolation invariant unenforced.

**Tradeoffs**  
Transaction discipline is required; tests must run against real PostgreSQL; local development must not accidentally use a table-owner/BYPASSRLS connection.

**What would cause us to revisit it**  
A stronger physical isolation architecture replaces shared-table RLS. Application-level Tenant/resource authorization remains required either way.

---

# 13. Background workers and service principals

## ADR-04-MVP-008 — Workers use explicit authorization modes plus workload identity

**Decision**  
Internal workers are not fake Users and do not receive broad Tenant rights merely because they run trusted code.

Every job has one immutable authorization mode:

```text
USER_DELEGATED
COMMITTED_COMMAND
SYSTEM
```

Queue payloads cannot change mode after enqueue.

### `USER_DELEGATED`

Use when the worker is performing a privileged action that was requested by a User but **was not yet authoritatively committed**.

Execution must revalidate the initiating User's current:

```text
User status
Membership
permission
Tenant + Organization
resource relationship
authentication/step-up requirement when applicable
```

If the initiating User was revoked or lost authority before execution, the job fails closed with a **terminal authorization outcome**. That job is not automatically retried merely because authority might later be restored; a new authorized command must create a new job. Only transient infrastructure failures use retry policy.

MVP examples:

- asynchronous import apply/CURRENT mutation, if import apply is deferred to a worker rather than performed synchronously;
- any future deferred finance mutation that represents a new privileged user decision.

### `COMMITTED_COMMAND`

Use only when the authoritative privileged domain mutation was fully authorized and durably committed synchronously. The worker may perform the already-accepted continuation/side effect but may not reinterpret it as a new user-authorized mutation.

MVP examples:

- generate/export a PDF for an already-issued immutable statement;
- send/deliver a notification for an already-committed action;
- publish an outbox event.

The worker validates the committed command/event identity, Tenant/resource linkage, and idempotency. It does not require the initiating User to remain authorized merely to finish the already-committed side effect.

### `SYSTEM`

Use for deterministic system-owned operations whose authority is the service-principal capability, not a User delegation.

MVP examples:

- source-PII retention purge;
- orphan-object/quarantine sweep;
- outbox dispatch for already-committed non-finance side effects;
- constrained security-audit retention purge.

A SYSTEM job must have a narrowly named capability; `SYSTEM` is not a general Tenant-admin role.

**Phase-A finance exclusion:** deterministic computation does not by itself make a finance mutation SYSTEM-authorized. SYSTEM/service-principal authority may not materialize recurring operating-cost facts, perform Finance/Statement Refresh, advance investor calculation/currentness state, or create/supersede investor-economic projection/ledger state. Those remain user-authorized `finance.calculation.write` / `finance.adjustment.write` operations. A future deferred finance mutation must use `USER_DELEGATED` authorization unless a later reviewed contract explicitly changes this boundary.

### Job envelope

```text
job_id
authorization_mode
actor_service_principal_id
initiated_by_user_id?       // required for USER_DELEGATED; provenance for COMMITTED_COMMAND
committed_command_id?       // required when mode == COMMITTED_COMMAND
requested_capability

tenant_id
organization_id
source_connection_id?       // import/source jobs
vehicle_id? / ownership_interest_id? / statement_id? as applicable
correlation_id
```

Execution contract for all modes:

```text
1. authenticate/identify worker workload
2. validate capability is permitted for that worker type
3. validate immutable job mode
4. begin Tenant-scoped transaction and SET LOCAL app.tenant_id
5. re-resolve Organization/resource relationships from DB
6. apply mode-specific authorization:
     USER_DELEGATED → reauthorize initiating User
     COMMITTED_COMMAND → validate committed command/event and continuation scope
     SYSTEM → validate service-principal capability
7. acquire canonical domain lock/currentness guard when the operation mutates protected state
8. revalidate target relationships/currentness
9. execute idempotently
10. audit service principal + initiating User/committed command as applicable
```

Queue payload IDs are never trusted by themselves.

Workers use the normal `app_runtime` RLS-constrained DB role. Cross-Tenant maintenance is a separate privileged path.

**Rationale**  
A delayed user command and a continuation of an already-committed command have different revocation semantics. Explicit modes prevent both stale delegated authority and accidental cancellation of accepted system work.

**Tradeoffs**  
Job definitions carry more metadata and tests must prove mode-specific behavior.

**What would cause us to revisit it**  
A mature workflow engine/cloud authorization layer can provide equivalent immutable delegation/commit/system semantics and provenance.

---

# 14. Raw uploaded file and object-storage security

## ADR-04-MVP-009 — Object storage is private, application-mediated, and evidence content is validated before activation

**Decision**  
Use private object storage for `SourceArtifact` and `EvidenceDocument` bytes.

For MVP, prefer server-mediated upload/download because file sizes are modest and this keeps authorization, hashing, validation, PII handling, malware scanning, and auditing in one path.

Common storage rules:

- object-storage bucket/container is private;
- no durable public URLs;
- object keys are server-generated opaque values, never user-controlled paths;
- do not expose storage list operations to users;
- raw source and evidence metadata live in PostgreSQL with Tenant/resource ownership;
- object read occurs only after DB authorization succeeds;
- source bytes are encrypted according to the retention/key-destruction contract;
- evidence bytes use encryption at rest and private access;
- downloads of raw source/evidence are audited;
- purge/delete is idempotent and retryable;
- DB failure after object upload leaves a sweepable orphan rather than silently adopting an untracked object.

### EvidenceDocument untrusted-content boundary

Evidence is untrusted active content, not merely a private blob.

Initial MVP allowlist:

```text
application/pdf
image/jpeg
image/png
```

Initial configurable maximum:

```text
20 MiB per EvidenceDocument
```

Upload flow:

```text
receive into non-public temporary/quarantine object
→ enforce byte-size limit
→ determine content type from bytes/magic, not filename alone
→ require extension/type consistency
→ reject HTML, SVG, executable/archive formats, Office/macro formats and unknown types
→ malware scan
→ if scan passes, generate final server-owned object key
→ create/activate EvidenceDocument metadata and immutable object
→ delete temporary object
```

If validation/scanning fails or the scanner is unavailable, the upload fails closed and no active EvidenceDocument is created.

Operational scanner/quarantine rules:

- malware scanning has a bounded timeout (initial operational target: 60 seconds for the current 20 MiB limit);
- timeout/unavailable/scan-error is a failed upload, never an implicit allow;
- temporary/quarantine objects have a bounded TTL (initial target: no more than 24 hours) and are removed by an idempotent SYSTEM sweeper;
- scanner availability, timeout rate, quarantine backlog, and sweeper failures emit operator-visible health metrics/alerts;
- a scanner outage may create temporary quarantined objects, but must not create active EvidenceDocument rows.

Download/serve rules:

- authorize Tenant + Organization + domain relationship + `evidence.read` first;
- serve as attachment by default with `Content-Disposition: attachment`;
- send `X-Content-Type-Options: nosniff`;
- never reflect the user filename into HTML without normal output encoding;
- no authenticated-origin inline HTML/SVG/Office execution;
- rich inline preview is out of scope; any future preview requires an isolated/sandboxed rendering path.

**Rationale**  
Private storage does not make malicious content safe. The canonical domain model already requires type/size/malware validation; this makes that boundary implementation-visible and testable.

**Tradeoffs**  
A scanner/quarantine step adds an operational dependency and MVP supports fewer evidence types.

**What would cause us to revisit it**  
A real workflow requires additional document formats or inline preview. New types require reviewed parsing/rendering isolation rather than simply expanding the MIME list.

---

# 15. CSV/XLSX as untrusted input

## ADR-04-MVP-010 — Spreadsheet input is data, never executable content

**Decision**  
Preserve the canonical Turo CSV rules:

- current Turo import accepts CSV under the configured limits;
- parser streams data;
- file/row/column/field maxima are enforced before canonical apply;
- CSV text is never executed as formulas/code;
- raw source is preserved exactly while retained and is not mutated merely to make it safe;
- logs/diagnostics are redacted;
- spreadsheet-oriented preview/export escapes leading `=`, `+`, `-`, and `@` as literal text at the rendering/export boundary.

Current initial limits remain:

```text
max file size       25 MiB
max data rows       50,000
max columns         256
max field length    64 KiB
```

For future XLSX support, treat OOXML as an untrusted archive/document format:

- do not evaluate formulas;
- do not execute macros;
- do not follow external links/data connections;
- reject macro-enabled/legacy executable spreadsheet formats in MVP unless a dedicated reviewed parser is added;
- enforce archive decompression and worksheet/cell limits to prevent zip/decompression bombs;
- retain original cell text/provenance separately from any safe preview/export rendering.

**Rationale**  
CSV/XLSX is attacker-controlled input and spreadsheet formula injection can become code execution when exported/reopened. Preserving raw source and making output safe must be separate operations.

**Tradeoffs**  
Some convenient spreadsheet features are intentionally unsupported.

**What would cause us to revisit it**  
A real workflow needs formulas/macros/external workbook features; that requires an isolated, explicitly sandboxed ingestion design rather than enabling them in the ordinary importer.

---

# 16. Secrets

## ADR-04-MVP-011 — Secrets are deployment/runtime secrets, not domain records

**Decision**  
Do not store production secrets in source control, appsettings checked into the repo, logs, `SourceConnection`, or ordinary business tables.

MVP secret material includes at least:

- database credentials or workload identity;
- OIDC client credentials/signing keys as applicable;
- object-storage credentials or workload identity;
- encryption/KMS/key-encryption material;
- keyed-HMAC secrets used for PII lookup where required by the domain model.

Production uses the deployment platform's secret manager / workload identity. Local development uses developer-secret mechanisms/environment injection.

`SourceConnection` contains provider namespace metadata only; live provider credentials remain deferred as required by the canonical domain model.

**Rationale**  
Secrets have different lifecycle/rotation/access requirements from domain data. Keeping them out of the ordinary database reduces accidental disclosure and preserves SourceConnection's domain meaning.

**Tradeoffs**  
Deployment needs secret injection/rotation configuration.

**What would cause us to revisit it**  
Provider integrations require tenant-managed credentials; add a separate encrypted credential/secret-reference resource, not token columns on SourceConnection.

---

# 17. Audit logging

## ADR-04-MVP-012 — Security/business audit is durable, DB-append-only, PII-minimized, and monitored

**Decision**  
Persist an append-oriented security/business audit trail for sensitive actions. Operational application logs remain separate.

Minimum audit envelope:

```text
audit_event_id
timestamp
tenant_id?
organization_id?
actor_kind              // USER | SERVICE_PRINCIPAL | MAINTENANCE
actor_id
initiated_by_user_id?
action
resource_type
resource_id?
result                   // SUCCESS | DENIED | FAILED
reason_code?
correlation_id / trace_id
request/source metadata as appropriate
```

### Audit transaction semantics

Success and denial/failure events use different durability paths.

**Successful sensitive mutation**

```text
BEGIN protected business transaction
  authorize under current Tenant/resource state
  mutate business state
  INSERT SUCCESS audit event
COMMIT
```

The SUCCESS event is commit-coupled to the business mutation (or to a same-transaction durable outbox whose consumer preserves the same actor/action/result semantics). If the business transaction rolls back, no SUCCESS audit may survive.

**Denied or failed protected operation**

```text
BEGIN protected business transaction
  authorization / protected operation fails
ROLLBACK

BEGIN separate minimal audit transaction
  append DENIED or FAILED event through audit_writer
COMMIT
```

A denial/failure discovered inside a rolled-back transaction is therefore appended **after rollback** through a separate minimal audit-writer path. That path cannot mutate business state and receives only the sanitized audit envelope needed for attribution/alerting.

If the separate denial/failure audit append itself fails, the protected operation remains denied/failed and an operational high-severity logging/alert path must surface the audit-write failure; the system must never retry/allow the protected command merely to obtain an audit row.

### Database-enforced append-only contract

Use least-privilege database roles/grants:

```text
app_runtime
  may INSERT success audit events as part of protected transactions
  no UPDATE/DELETE on security audit rows

audit_writer
  dedicated minimal path for post-rollback DENIED/FAILED append
  INSERT only
  no business-table mutation
  no UPDATE/DELETE on security audit rows
  cannot SET ROLE to app_runtime or maintenance_admin

audit_retention
  SYSTEM/maintenance capability for retention only
  may invoke the constrained expired-audit purge path
  no arbitrary historical rewrite
```

Defense in depth:

- revoke ordinary `UPDATE`/`DELETE` on audit tables from application and audit-writer roles;
- use an immutability trigger or equivalent DB guard so ordinary code cannot rewrite an existing audit row;
- no ordinary API exposes audit update/delete;
- retention deletion occurs only through an explicit constrained purge operation that verifies the configured retention cutoff;
- `security.audit.read` is required for Organization-scoped human audit reads;
- cross-Tenant maintenance/security audit reads use the separate maintenance path.

MVP retention class: `SECURITY_AUDIT`, default minimum 365 days unless a longer project/legal retention policy applies.

Audit records are not a substitute for finance/import deterministic provenance and do not shorten those records' retention.

Never copy raw CSV rows, guest names, full evidence contents, access tokens, secrets, or contact ciphertext into audit/log text.

High-value events include:

- login/logout/MFA/session/security events;
- Membership/role changes;
- SourceConnection changes;
- import start/apply/failure and CURRENT assertion;
- raw source/raw-row read/download;
- evidence upload/read/download/purge;
- EconomicAdjustment create/approve/reverse/replace;
- statement issue/restatement;
- DistributionPayment changes;
- CrossOwnershipCorrection create/approve/apply;
- maintenance/break-glass use;
- sensitive authorization denials.

Minimum alerts without requiring a full SIEM:

- every maintenance/break-glass use → immediate operator-visible alert;
- repeated sensitive authorization denials → alert (initial threshold: 5 within 10 minutes for the same actor/session/IP grouping);
- source-PII/evidence retention or purge failure → immediate operational alert;
- audit append failure → immediate operational alert;
- failed MFA/step-up bursts should use the authentication platform's abuse monitoring/rate-limit path.

**Rationale**  
Financial corrections, sensitive-file reads, privileged maintenance, and denied privilege probes must be attributable even when the protected business transaction rolls back. DB-enforced append-only grants make that guarantee depend on more than API convention.

**Tradeoffs**  
There is an additional minimal audit-writer path and retention capability to operate/test, and denial auditing is not atomic with the transaction that was rolled back. Correlation IDs link the two paths.

**What would cause us to revisit it**  
Compliance or scale requires tamper-evident external archival/SIEM retention, longer mandatory periods, cryptographically chained audit records, or dedicated security operations.

---

# 18. Support, platform admin, and impersonation

## ADR-04-MVP-013 — No user impersonation in MVP; privileged maintenance is separate, MFA-protected, short-lived, and audited

**Decision**  
Do not implement “login as user” or support impersonation in MVP.

The founder's normal operational work uses the founder's real User + Organization Membership.

Cross-Tenant/platform maintenance uses a separate `maintenance_admin`/break-glass path that:

- is not used by the ordinary web/API/worker connection string;
- uses a distinct operator identity/credential path;
- requires MFA/step-up for every maintenance entry;
- requires explicit operator intent/reason;
- uses short-lived credentials/session elevation where practical (initial target: <= 30 minutes);
- is narrowly scoped to the maintenance operation;
- emits an immediate operator-visible alert;
- is audited distinctly as `MAINTENANCE`;
- does not create fake end-user audit records;
- has an explicit disable/revoke procedure;
- is never available to normal `app_runtime`, web sessions, or worker service principals.

Prefer CLI/operations tooling to a general cross-Tenant admin UI initially. Standing shared break-glass passwords are prohibited.

**Rationale**  
There is no support team to justify impersonation, and a standing cross-Tenant credential would have disproportionate blast radius. Separate short-lived privileged maintenance preserves accountability without normalizing Tenant bypass.

**Tradeoffs**  
Some support scenarios require explicit operational tooling and MFA rather than clicking through a Tenant UI.

**What would cause us to revisit it**  
A real support team needs user-context reproduction. Any future support session must preserve both actual actor and effective context, be time-limited, reason-bound, MFA-protected, and read-only by default.

---

# 19. Financial-data exposure rules

Minimum exposure boundaries:

```text
Operations/source role
  may import/process source data
  does not automatically read investor statements or raw PII

Finance role
  may read authorized Organization investor economics
  may perform specifically permitted financial commands
  does not automatically read raw source PII

ORG_ADMIN
  may hold both permission sets in the initial founder-operated MVP
  but actions are still evaluated/audited through the named permissions

Investor (future)
  only PartyAccessGrant → Party → OwnershipInterest projections
  never host-private finance/customer/source data by Tenant visibility alone
```

Financial DTOs must be purpose-specific. Do not return entire persistence entities with hidden columns and rely on frontend display filtering.

---

# 20. Required negative security tests

These tests are part of MVP implementation acceptance, not optional post-launch hardening. The original R1 test themes are preserved and extended.

## Authentication / bootstrap / Membership

1. unauthenticated finance/import command → denied;
2. disabled User → denied;
3. duplicate `(oidc_issuer, external_subject)` persistence → rejected;
4. authenticated User with zero active Memberships cannot establish ActorContext;
5. one active Membership may auto-select exactly that context;
6. multi-Tenant/multi-Organization selector must exactly match one bootstrap Membership tuple;
7. invalid Tenant/Organization selector fails closed and cannot enumerate available foreign contexts;
8. direct business-resource ID before ActorContext establishment cannot discover Tenant;
9. `identity_bootstrap` can read only the authenticated User's active Membership tuples and cannot query business tables;
10. normal `app_runtime` cannot use the bootstrap exception/path;
11. duplicate User+Organization Membership persistence is rejected;
12. future-dated `ACTIVE` Membership cannot bootstrap or authorize before `effective_from`;
13. duplicate/cross-Tenant MembershipRole persistence is rejected;
14. unknown role/permission code fails closed;
15. revoked/suspended Membership is denied immediately;
16. client-supplied Tenant/Organization ID cannot switch context without a matching Membership.

## Privileged authentication / session

17. `ORG_ADMIN`, `FINANCE`, and `SOURCE_MANAGER` production sessions without MFA cannot establish privileged access;
18. stale/no recent step-up cannot issue statement, apply cross-owner correction, apply `source.current.apply`, or read raw/source PII;
19. successful step-up rotates/refreshes the server session and establishes recent assurance;
20. disabled User or revoked Membership invalidates/rejects the server session;
21. idle and absolute session expiry are enforced;
22. CSRF: unsafe cookie-authenticated request without anti-forgery proof is denied even when Origin/SameSite are otherwise valid.

## Tenant / RLS

23. Tenant A cannot read Tenant B rows;
24. Tenant A cannot insert/update Tenant B rows;
25. missing `app.tenant_id` cannot read/write ordinary Tenant business rows;
26. pooled connection reused from Tenant A to Tenant B does not leak Tenant A context;
27. normal `app_runtime` cannot bypass RLS;
28. runtime connection is not Tenant-table owner/BYPASSRLS;
29. worker uses the same RLS contract as web/API;
30. startup/health check fails when runtime role owns Tenant tables, has BYPASSRLS, or required FORCE RLS is absent;
31. rollback/runbook test preserves RLS rather than disabling it;
32. maintenance path is separate and normal runtime cannot acquire/invoke it.

## Same-Tenant cross-Organization

33. Organization A member cannot operate on Organization B SourceConnection;
34. Organization A Finance user cannot mutate Organization B investor economics;
35. Organization A user cannot fetch Organization B EvidenceDocument by guessed ID;
36. same-Tenant mismatched Organization/resource composite relationships are rejected.

## Transactional authorization / race conditions

37. Membership revocation racing a finance mutation cannot allow the mutation after authoritative in-transaction authorization;
38. role removal racing a sensitive command cannot allow the command after authorization state changes;
39. SourceConnection disable/reassignment/status change between preflight and CURRENT apply is rechecked under the protected transaction/lock and fails closed;
40. finance currentness/OwnershipInterest change between preflight and statement/correction apply is rechecked under the Vehicle lock;
41. preflight success alone never authorizes a mutation.

## SourceConnection/import

42. foreign-Tenant SourceConnection → batch-blocking, zero rows applied;
43. same-Tenant foreign-Organization SourceConnection → batch-blocking, zero rows applied;
44. inactive SourceConnection → denied;
45. actor lacks `source.import.execute` → batch-blocking before apply;
46. actor lacks `source.current.apply` → CURRENT assertion denied;
47. worker job missing Tenant/Organization/SourceConnection context → fail closed;
48. worker queue payload with tampered SourceConnection ID fails revalidation;
49. same external Reservation ID in two SourceConnections remains isolated;
50. unknown VIN does not create a production Vehicle through import.

## Worker authorization modes

51. `USER_DELEGATED` import worker with initiating User revoked before execution → denied with zero protected mutation and terminal job outcome;
52. `USER_DELEGATED` worker with permission removed before execution → denied terminally; later authority restoration does not revive the old job;
53. `COMMITTED_COMMAND` continuation still completes idempotently after initiating User later loses Membership, but cannot perform a new privileged mutation;
54. `SYSTEM` job succeeds only with its named service-principal capability and explicit Tenant/resource context;
55. queue payload cannot change authorization mode or upgrade USER_DELEGATED to SYSTEM;
56. worker audit records service principal and initiating User/committed command as applicable.

## Finance / statement / correction

57. employee without `finance.adjustment.write` cannot create/approve an investor-specific adjustment;
58. employee without `finance.statement.issue` cannot issue statement;
59. guessed statement ID in another Organization fails closed;
60. direct OwnershipInterest/Vehicle/Reservation ID mismatch is rejected;
61. host cross-owner policy succeeds only when every affected OwnershipInterest belongs to the correction Vehicle managed by the actor's authorized Organization;
62. wrong Organization/Vehicle/OwnershipInterest relationship fails cross-owner correction;
63. PartyAccessGrant-only actor cannot perform host Finance correction;
64. caller cannot choose source/target correction owners by supplying IDs;
65. cross-owner correction does not partially apply when one affected relationship fails authorization;
66. issued statement remains immutable after later source revision;
67. actor with `finance.read` but without `finance.calculation.write` may read an existing calculation/reconciliation projection but cannot invoke authoritative recalculation/draft refresh or advance current calculation/ledger/correction state;
68. stale/no recent step-up denies `finance.calculation.write` before any protected financial mutation;
69. Membership/permission removal racing authoritative recalculation is rechecked under the Vehicle lock and fails closed with no current-pointer/ledger mutation.

### Financial Platform Product Direction Section-18 authorization tests

118. `CreateOperatingCost` / `CorrectOperatingCost` / recurring-rule mutation with wrong Tenant is denied with zero source/configuration mutation;
119. same-Tenant actor targeting a Vehicle/rule/cost in another Organization is denied with zero mutation;
120. wrong Vehicle/OwnershipInterest/Reservation/OperatingCostFact/recurring-rule relationship is denied; when a correction affects multiple OwnershipInterests, failure of any server-derived affected relationship aborts the whole command;
121. revoked/suspended Membership or removed `finance.adjustment.write` denies cost/rule mutation, including when revocation races the protected transaction;
122. stale/missing recent step-up denies `CreateOperatingCost`, `CorrectOperatingCost`, `Create/Edit/DisableRecurringCostRule`, and authoritative Finance/Statement Refresh before protected mutation;
123. `finance.read`-only actor cannot trigger hidden OperatingCostFact creation, recurring materialization, authoritative recalculation/currentness advancement, investor projection/ledger mutation, or correction-required state;
124. Finance/Statement Refresh with `finance.calculation.write` but without current `finance.adjustment.write` may not materialize a missing recurring occurrence/OperatingCostFact; if materialization is required, the refresh fails closed/non-current;
125. any authorization/resource failure discovered before or during recurring materialization commits **zero new occurrences and zero new recurring OperatingCostFacts** for that failed refresh; partial materialization is prohibited;
126. SYSTEM/service principal, maintenance capability, Source Ingestion actor, or worker capability cannot bypass `finance.calculation.write` / `finance.adjustment.write` to materialize recurrence or perform authoritative finance refresh; a future deferred finance mutation must be USER_DELEGATED and reauthorized.

### Complete-MVP R1 SEC-001 statement-issue compound authorization tests

127. actor has `finance.statement.issue` but lacks `finance.calculation.write` → `IssueInvestorStatement` is denied under the protected Vehicle lock before any refresh/currentness/statement mutation; issue authority cannot implicitly invoke privileged refresh;
128. actor has `finance.statement.issue + finance.calculation.write` but lacks `finance.adjustment.write`, and the requested cutoff has a missing due recurring occurrence → issue fails atomically with zero new occurrence, zero new OperatingCostFact, zero recalculation/current-lineage advancement, and no `ISSUED` state;
129. actor has `finance.statement.issue + finance.calculation.write + finance.adjustment.write`, valid recent step-up and all current resource relationships, and no recurrence materialization is needed → authoritative refresh/currentness verification and issue may succeed without creating any recurrence/source fact;
130. Membership suspension/revocation or removal of any permission required for the actual issue path racing `IssueInvestorStatement` is rechecked under the Vehicle lock and fails the entire issue attempt before authoritative mutation;
131. wrong Tenant, same-Tenant wrong Organization, or mismatched statement/OwnershipInterest/Vehicle relationship fails closed before refresh/materialization/issue mutation;
132. any authorization/resource/currentness denial during `IssueInvestorStatement` commits no partial recurrence materialization, no partial recalculation/current-pointer/projection/ledger advancement, no partial DRAFT membership/totals/cutoff freeze, and no statement issue;
133. when no recurrence materialization is required, an actor with valid `finance.statement.issue + finance.calculation.write` but without `finance.adjustment.write` is not denied solely for lacking adjustment authority; adjustment authority is conditional on an actual cost-materialization mutation.

## Sensitive source/evidence

67. `source.import.execute` without `source.raw.read` cannot download raw artifact;
68. `source.raw.read` without required Organization/ImportBatch relationship cannot access artifact by guessed ID;
69. user without `source.pii.read` receives redacted/minimized diagnostics only;
70. Finance permission alone cannot expose Turo guest PII;
71. evidence ID possession without Organization/domain relationship is denied;
72. investor relationship (when later enabled) does not expose Customer/source PII;
73. purged source PII cannot be recovered through replay/support endpoints.

## EvidenceDocument untrusted content

74. filename/MIME spoof does not bypass byte/magic type validation;
75. HTML and SVG evidence are rejected;
76. Office/macro/archive/executable/unknown evidence types are rejected;
77. evidence over the configured size limit is rejected before activation;
78. malware-positive evidence never creates an active EvidenceDocument and temporary object is removed/quarantined per failure policy;
79. scanner unavailable or scan timeout → upload fails closed;
80. evidence download uses `Content-Disposition: attachment` and `X-Content-Type-Options: nosniff`;
81. evidence filename is safely encoded and cannot create HTML/script execution;
82. no rich authenticated-origin inline preview exists in MVP.

## Untrusted spreadsheet/import input

83. CSV cells beginning `=`, `+`, `-`, or `@` are preserved as data and never executed;
84. spreadsheet preview/export renders formula-like content as literal text;
85. oversized file/row/column/field fails deterministically before canonical apply;
86. invalid schema/new economic column fails according to canonical import rules;
87. object-storage key/path is server-generated; attempted traversal/arbitrary-key input is ignored/rejected;
88. raw source/evidence values are absent from normal logs and audit text.

## Maintenance/audit

89. maintenance entry without MFA/reason fails;
90. maintenance credential/session expires according to short-lived policy;
91. every maintenance use creates an audit record and immediate alert;
92. ordinary app/runtime/worker credentials cannot obtain `maintenance_admin`;
93. `app_runtime` and `audit_writer` cannot UPDATE/DELETE security audit rows;
94. user without `security.audit.read` cannot query Organization security audit;
95. repeated sensitive authorization denials trigger configured alert;
96. source-PII/evidence purge failure triggers operational alert.

## Investor future activation gate

Investor portal is out of scope, so no investor endpoint should be registered in MVP. Before enabling one later, add/activate:

97. revoked PartyAccessGrant immediately removes read scope;
98. Investor A cannot fetch Investor B statement/evidence by guessed ID;
99. historical OwnershipInterest grants only the appropriate historical scope, not unrelated current assets.

## R2 convergence additions

100. bootstrap uses `SET LOCAL app.authenticated_user_id`; pooled connection reused User A → User B cannot expose User A Membership tuples;
101. bootstrap Membership policy is `FOR SELECT TO identity_bootstrap`; `app_runtime` cannot benefit from it even if application code attempts to set `app.authenticated_user_id`;
102. `identity_bootstrap` cannot read ordinary Tenant business tables and cannot `SET ROLE`/escalate to `app_runtime` or `maintenance_admin`;
103. `app_runtime` cannot assume/`SET ROLE` to `identity_bootstrap`;
104. bootstrap global User resolution exposes only the minimal identity projection and exact trusted issuer+subject lookup path;
105. ActorContext with valid User plus foreign `membership_id` fails full tuple rebind;
106. Membership User/Tenant/Organization mismatch with ActorContext fails closed;
107. `Membership.user_id` without an existing global User is rejected by FK;
108. `FINANCE` without MFA-backed production session is denied;
109. `SOURCE_MANAGER` without MFA-backed production session is denied;
110. stale/no recent step-up denies `source.current.apply`;
111. an authorization denial discovered inside the protected transaction survives rollback as exactly one durable DENIED audit event;
112. a failed/rolled-back business mutation cannot leave a false SUCCESS audit event;
113. `app_runtime`/`audit_writer` cannot UPDATE or DELETE audit rows even through direct SQL;
114. audit retention worker can purge only records past the configured retention cutoff through its explicit capability;
115. `USER_DELEGATED` authorization denial is terminal and is not automatically retried; a new authorized command is required;
116. evidence scan timeout/unavailability leaves no active EvidenceDocument and temporary object is TTL/sweeper eligible;
117. scanner health/quarantine backlog/sweeper failure produces operator-visible health signal/alert.

---

# 21. Minimum implementation sequence

```text
1. Reuse/generalize tai-portal authentication enough to issue stable OIDC identity.
2. Add local User mapping with `UNIQUE(oidc_issuer, external_subject)` and the narrow global User lookup path.
3. Implement durable Membership + MembershipRole invariants, explicit User FK, current-effectivity checks, and `authorization_version`.
4. Implement the dedicated `identity_bootstrap` role/policy with transaction-scoped `SET LOCAL app.authenticated_user_id`, NOINHERIT/no-role-escalation rules, and full ActorContext tuple binding.
5. Keep the focused bootstrap exception synchronized with the canonical domain-model RLS contract.
6. Add BFF MFA/session/anti-forgery controls for ORG_ADMIN/FINANCE/SOURCE_MANAGER and privileged permissions; add recent step-up including `source.current.apply`.
7. Implement authorization policies that consume ActorContext, never arbitrary Tenant authority.
8. Make mutation authorization authoritative inside the protected DB transaction/lock.
9. Wire SourceConnection import policies and CURRENT permission.
10. Wire finance authorization for operating-cost/rule mutations (`finance.adjustment.write`), authoritative Finance/Statement Refresh (`finance.calculation.write`), dual-authority recurring materialization, compound statement issue (`finance.statement.issue + finance.calculation.write` plus conditional `finance.adjustment.write`), cross-owner policies, and no-SYSTEM-finance enforcement.
11. Wire separate raw/source-PII and evidence permissions.
12. Implement worker service principals + immutable USER_DELEGATED/COMMITTED_COMMAND/SYSTEM modes, including terminal authorization-denial classification.
13. Add private object storage, evidence staging/type/size/malware validation, scanner timeout/health, quarantine TTL, and sweepers.
14. Implement commit-coupled SUCCESS audit plus rollback-safe DENIED/FAILED audit writer and DB-enforced append-only/retention roles.
15. Ensure every ordinary Tenant DB operation uses transaction-scoped Tenant context.
16. Run real PostgreSQL RLS/bootstrap/pool/worker/race-condition/audit rollback tests.
17. Enable FORCE RLS in the production migration sequence.
18. Complete the full negative-security suite before importing real investor/guest data.
19. Preserve the completed Security R3 `GREENLIGHT`; execute focused Financial Platform Product Direction tests 118–126 together with the existing negative-security suite before production security clearance.
```

Do not block the MVP on:

```text
investor portal
customer login
custom role editor
impersonation UI
external authorization service
public API
provider OAuth credential management
rich evidence preview
full PAM/SIEM platform
```

---

# 22. Authorization API shape

Keep Tenant bootstrap separate from ordinary resource authorization.

Conceptually:

```csharp
IIdentityBootstrapService.ResolveAuthenticatedUser(
    AuthenticatedIdentity identity);

IIdentityBootstrapService.GetAvailableContexts(
    AuthenticatedUser user);

IIdentityBootstrapService.EstablishActorContext(
    AuthenticatedUser user,
    RequestedOrganizationContext? untrustedSelector);

IAuthorizationService.AuthorizeOrganization(
    ActorContext actor,
    OrganizationId requestedOrganization,
    Permission permission);

IAuthorizationService.AuthorizeSourceConnection(
    ActorContext actor,
    SourceConnectionId sourceConnectionId,
    Permission permission);

IAuthorizationService.AuthorizeFinanceResource(
    ActorContext actor,
    FinanceResourceRef resource,
    Permission permission);

IAuthorizationService.AuthorizeHostOwnershipInterestForFinance(
    ActorContext actor,
    OrganizationId organizationId,
    VehicleId vehicleId,
    OwnershipInterestId ownershipInterestId,
    Permission permission);

IAuthorizationService.AuthorizeSensitiveDocument(
    ActorContext actor,
    EvidenceDocumentId documentId,
    Permission permission);
```

Ordinary authorization APIs do **not** accept a raw `TenantId`. Tenant comes from the server-created ActorContext.

Handlers/controllers pass requested resource IDs into policy methods; policy methods resolve authoritative relationships under the ActorContext Tenant. For mutating commands, the same policies are re-evaluated inside the authoritative protected transaction/lock.

Avoid authorization based only on claims such as:

```text
role=Admin
privilege=Finance.Write
```

without current Membership/resource validation.

---

# 23. Security invariants summary

1. Authentication identity is not Tenant authorization.
2. Tenant/Organization context is established only through a transaction-scoped, role-scoped authenticated-User Membership bootstrap using `SET LOCAL app.authenticated_user_id`.
3. The resulting ActorContext must rebind the full User + Membership + Tenant + Organization tuple; normal `app_runtime` never performs cross-Tenant bootstrap discovery and never bypasses RLS.
4. Host access is `User → Membership → Organization`.
5. Investor access, if later activated, is `User → PartyAccessGrant → Party → OwnershipInterest`.
6. Tenant isolation does not imply same-Tenant Organization access.
7. Every tenant-owned record carries `tenant_id`.
8. RLS is enabled for MVP production and uses transaction-local server-derived Tenant context.
9. No normal web/API/worker DB role owns Tenant tables or bypasses RLS.
10. Preflight authorization never replaces in-transaction authorization for protected mutations.
11. Source imports are authorized at Tenant + Organization + SourceConnection before apply.
12. CURRENT import is a separately permissioned operator assertion.
13. Finance reads are non-mutating; operating-cost/recurring-rule mutations require `finance.adjustment.write` + recent step-up + current Tenant/Organization/Vehicle/affected-OwnershipInterest/resource relationships; authoritative Finance/Statement Refresh requires `finance.calculation.write` + recent step-up + equivalent resource reauthorization; refresh that materializes recurring cost facts requires both permissions before any materialization write; `IssueInvestorStatement` requires `finance.statement.issue + finance.calculation.write` and additionally `finance.adjustment.write` only when its required refresh will materialize recurring cost facts, with all actual-path authorities revalidated under the Vehicle lock before the first mutation.
14. Cross-owner correction uses the host managing-Organization/Vehicle/OwnershipInterest predicate for every server-derived affected OwnershipInterest; PartyAccessGrant is not host mutation authority.
15. Raw source/PII and evidence require separate sensitive-data permissions.
16. ORG_ADMIN, FINANCE, SOURCE_MANAGER, and any Membership with privileged/sensitive permissions require MFA-backed production sessions; specified high-risk actions including `source.current.apply` require recent step-up.
17. Object IDs, job IDs, queue messages, filenames, and storage keys never grant access by possession.
18. Worker authorization mode is immutable and explicitly USER_DELEGATED, COMMITTED_COMMAND, or SYSTEM; USER_DELEGATED authorization denial is terminal; Phase-A finance refresh/recurring materialization is never SYSTEM-authorized.
19. Raw source/evidence storage is private; object paths are server-controlled.
20. Evidence content is type/size/malware validated before activation, scanning is bounded/fail-closed with quarantine cleanup/health monitoring, and content is served as safe attachment by default.
21. CSV/XLSX content is never executable input.
22. Audit SUCCESS is commit-coupled; DENIED/FAILED is appended after rollback through a separate insert-only writer; audit rows are DB-enforced append-only, PII-minimized, access-controlled, retained, and minimally alerted.
23. Maintenance/break-glass is separate, MFA-protected, short-lived, reason-bound, audited, and alerted.
24. No investor portal or impersonation UI exists in the MVP.
25. Production rollback preserves RLS; disabling RLS is not an ordinary outage workaround.

---

# 24. Review findings convergence record

## 24.1 R1 outcome

R1 decision was `REVISE_PLAN` with 1 Critical, 6 Significant, 2 Minor, and one explicit MFA human-risk decision. Revision 2 materially addressed the R1 architecture and reduced the bootstrap Critical to a bounded residual.

R2 confirmed the following R1 findings resolved at plan/design level and they remain preserved:

```text
SEC-002  transaction-coupled mutation authorization
SEC-003  worker authorization modes
SEC-005  cross-owner host Finance OwnershipInterest policy
SEC-006  EvidenceDocument untrusted-content boundary
MIN-R1-01 anti-forgery requirement
MIN-R1-02 audit governance direction
```

R2 reopened residuals in SEC-001, SEC-004, and SEC-007 and added SEC-008; Revision 3 supersedes the older R1 disposition text for those items.

## 24.2 R2 outcome

R2 decision was `REVISE_PLAN` with 0 Critical, 4 Significant, 2 Minor, and no human-decision questions.

| Finding | R3-plan disposition | Verification |
|---|---|---|
| `SEC-001` bootstrap DB context/policy + canonical mismatch | **PLAN ADDRESSED:** bootstrap runs in a transaction with `SET LOCAL app.authenticated_user_id`; policy is role-scoped `FOR SELECT TO identity_bootstrap`; app/runtime and bootstrap roles cannot assume each other; full User+Membership+Tenant+Organization tuple is rebound; domain-model RLS contract is synchronously updated | tests 100–106 plus Tenant/RLS tests |
| `SEC-004` privilege-wide MFA | **PLAN ADDRESSED:** ORG_ADMIN, FINANCE, SOURCE_MANAGER and future privileged/sensitive permission holders require MFA-backed production sessions; `source.current.apply` explicitly requires recent step-up | tests 17–22, 108–110 |
| `SEC-007` Membership current-effectivity / identity binding | **PLAN ADDRESSED:** explicit `Membership.user_id -> User.id`; current effectivity requires `ACTIVE + effective_from <= now() + effective_to IS NULL`; future ACTIVE row cannot bootstrap/authorize; full tuple rebind required | tests 12, 105–107 |
| `SEC-008` audit durability/immutability | **PLAN ADDRESSED:** SUCCESS audit is commit-coupled; DENIED/FAILED is appended after rollback through insert-only `audit_writer`; DB grants/immutability block ordinary UPDATE/DELETE; explicit constrained retention purge capability | tests 111–114 plus 91–96 |
| `MIN-R2-01` worker retry classification | **ADDRESSED:** USER_DELEGATED authorization denial is terminal; transient infrastructure failures only are retryable | tests 51–52, 115 |
| `MIN-R2-02` scanner operational cleanup | **ADDRESSED:** bounded scan timeout, fail-closed behavior, quarantine TTL/SYSTEM sweeper, health/backlog/failure alerts | tests 79, 116–117 |
| Architect/Data minor global User lookup/FK details | **ADDRESSED:** narrow platform-global User resolver is named; Membership has explicit User FK and full tuple binding | tests 3, 104–107 |

These are **plan-level** dispositions only. They are not implementation clearance.

Per R2, the next gate is a **narrow R3 convergence review** limited to SEC-001, SEC-004, SEC-007, SEC-008, the two R2 Minor findings, and regressions introduced by these changes.

---

# 24.3 Chat 02 R2 focused synchronization

Chat 02 system-architecture R2 identified a semantic authorization gap: deterministic recalculation was being exposed as `finance.read` even though the command can mutate authoritative `ReservationInvestorCalculationCurrent`, investor-economic ledger lineage, or correction-required state.

Revision 4 closes that gap narrowly:

```text
finance.read
  = non-mutating finance projections only

finance.calculation.write
  = authoritative calculation/recalculation/current-lineage/ledger-producing refresh
  = privileged FINANCE/ORG_ADMIN capability
  = recent step-up required
  = in-transaction resource reauthorization under the Vehicle lock
```

No other Security R3 decision is reopened. Chat 02 R3 must verify the synchronized permission is used consistently in architecture, implementation plan, API tests, and UI step-up behavior.

---

# 24.4 Financial Platform Product Direction Section-18 Security synchronization

The accepted Financial Platform Product Direction and synchronized Domain, Investor Finance, Architecture, and Implementation Plan introduce canonical manager-incurred operating-cost facts, prospective recurring-cost rules, synchronous Finance/Statement Refresh materialization, and complete-input currentness.

Security verification result: **FOCUSED CHANGE REQUIRED AND APPLIED.**

The existing Phase-A permission split is retained:

```text
CreateOperatingCost
CorrectOperatingCost
Create/Edit/DisableRecurringCostRule
    → finance.adjustment.write
    → recent step-up
    → current Tenant + Organization + Vehicle + affected OwnershipInterest/resource authorization

Authoritative Finance / Statement Refresh
    → finance.calculation.write
    → recent step-up
    → current resource reauthorization under Vehicle lock

Refresh that materializes missing recurring cost facts
    → BOTH finance.calculation.write AND finance.adjustment.write
    → recent step-up
    → all applicable resource predicates
    → zero partial materialization on authorization failure
```

No cleaner permission split is justified for Phase A because the existing two permissions already correspond to the two authoritative mutation classes. No new roles are introduced.

One prior Revision-4 worker example required correction: generic deterministic downstream recalculation could be read as permitting SYSTEM finance refresh. Revision 5 removes that ambiguity. Phase-A Finance Refresh, currentness advancement, recurring materialization, and investor-economic projection/ledger-producing refresh are not SYSTEM operations. Future asynchronous finance mutation, if introduced, must use `USER_DELEGATED` reauthorization unless a later focused review changes the contract.

Focused negative tests 118–126 cover wrong Tenant, same-Tenant wrong Organization, resource/ownership mismatch, revoked Membership, stale/missing step-up, `finance.read` hidden mutation, refresh lacking cost-mutation authority, zero-partial-materialization, and SYSTEM/service-principal bypass.

At Revision 5, this synchronization matched the then-current Chat 02 Architecture/Implementation contract and required no handoff for the Financial Platform Product Direction changes themselves. The later complete-MVP R1 review identified a separate statement-issuance compound-authorization contradiction. That narrow statement-issue conclusion is superseded by §24.5, which requires a focused Chat 02 reconciliation handoff; all other Revision-5 alignment remains preserved.


---

# 24.5 Complete-MVP R1 focused Security synchronization

The complete-MVP R1 package review identified two focused Security findings. Revision 6 changes Security semantics only for `SEC-001`; `SEC-002` is verified against the updated Domain persistence contract.

## `SEC-001` — Statement issue compound authorization

**Disposition: RESOLVED AT PLAN/DESIGN LEVEL.**

Normative Phase-A composition:

```text
IssueInvestorStatement
  → finance.statement.issue
  AND finance.calculation.write
  AND recent step-up
  AND current Tenant / Organization / Vehicle / OwnershipInterest / statement relationships

if required Statement Refresh will materialize missing recurrence:
  ALSO finance.adjustment.write
  AND current cost/rule/affected-resource relationships
```

`finance.statement.issue` is never an alternate route to privileged Finance Refresh or cost mutation. All permissions and resource predicates required by the actual issue path are revalidated under the canonical Vehicle lock before the first authoritative mutation. Any denial aborts the entire protected issue attempt with zero partial recurrence materialization, recalculation/current-lineage advancement, DRAFT membership/totals/cutoff freeze, or issue. Tests 127–133 are the focused verification contract.

## `SEC-002` — OperatingCostFact correction persistence defense in depth

**Disposition: VERIFIED SATISFIED BY CURRENT DOMAIN CONTRACT; NO SECURITY MODEL CHANGE REQUIRED.**

The updated canonical Domain model now makes correction scope a persistence invariant rather than application prose only. It provides strengthened OperatingCostFact target unique keys/composite foreign keys for Tenant + Organization + Vehicle + category/currency/amount as applicable, Reservation relationship constraints, single-reversal/replacement uniqueness, plus a mandatory database guard for the remaining cross-row conditions including Reservation null parity, referenced fact kind/state, reversal-before-replacement, and same-scope lineage. The Domain persistence test matrix requires real PostgreSQL negatives for cross-Organization, cross-Vehicle, Reservation mismatch/null parity, currency/category/amount mismatch, and duplicate reversal even when normal API validation is bypassed.

Security continues to require the protected Finance transaction/Vehicle lock and relationship authorization; the database controls are defense in depth and do not replace application authorization.

## Chat 02 reconciliation completed

Chat 02 has completed the focused reconciliation. The current canonical Architecture and Implementation Plan now encode the same compound statement-issue contract defined here: `finance.statement.issue + finance.calculation.write`, with conditional `finance.adjustment.write` only when the required Statement Refresh will materialize missing recurring costs; all actual-path permissions/resource predicates are revalidated under the Vehicle lock before the first authoritative mutation. The synchronized Architecture/Implementation Plan also carry the corresponding atomic-denial and negative-test requirements. No further Chat 02 reconciliation is required for `SEC-001` unless a later change reopens this contract.


---

# 25. Consolidated MVP decision

**Decision**  
Ship the first investor-management MVP with one strong founder/operator OIDC+BFF authentication path; MFA for privileged production use and step-up for high-risk actions; a dedicated authenticated Membership bootstrap into a server-side ActorContext; Organization-scoped Membership and fixed permission templates; in-transaction relationship/resource authorization; SourceConnection-specific import authorization; Finance/Admin authorization for operating-cost/rule mutations, authoritative recalculation/currentness refresh, compound statement issuance, adjustments/corrections; private separately authorized and content-validated raw/evidence access; explicit worker/service-principal authorization modes; PostgreSQL RLS enabled before production; separate short-lived break-glass maintenance; and a required negative-security integration suite. Reuse tai-portal's authentication/security foundation where it saves work, but do not reuse its current tenant/privilege claims as the rental platform's domain authorization model. Investor login/portal and user impersonation remain out of scope.

**Rationale**  
This is the smallest design that closes the R2 residual bootstrap, privilege-assurance, Membership-effectivity, and audit-durability gaps while preserving the current canonical import/finance/domain contracts. It protects real guest PII and investor financial data without expanding the MVP into a general identity product.

**Tradeoffs**  
The MVP carries more security plumbing than a single-user internal tool: a narrow bootstrap DB role, MFA/step-up, server-side sessions, transaction-coupled authorization, job-mode semantics, evidence scanning, RLS health checks, and security alerts. These controls address boundaries that become much more expensive to retrofit after multiple Organizations, employees, or automated jobs exist.

**What would cause us to revisit it**  
Real external investor/customer self-service demand; multiple support employees; cross-Organization provider accounts; public/mobile/API clients; tenant-customizable roles; provider credentials/live API integrations; compliance requirements needing stronger audit/PAM controls; a separate authoritative identity directory; or scale that makes application-mediated object transfer/RLS shared-database tenancy economically inappropriate.
