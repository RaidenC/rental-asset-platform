\# AGENTS.md — Fleet Platform Implementation



\## Authority



For implementation decisions, use this order:



1\. docs/design-baseline/mvp-implementation-plan.md

2\. relevant canonical design-baseline specifications

3\. accepted ADRs already encoded in those specifications

4\. existing production code/tests

5\. local implementation judgment



If code and the accepted design baseline disagree, do not silently

change the design. Stop and surface the conflict.



\## Architecture constraints



\- Angular frontend

\- ASP.NET Core modular monolith

\- PostgreSQL

\- private object storage

\- small .NET worker only for explicitly approved SYSTEM tasks

\- no microservices

\- no Kafka/message broker

\- no Redis unless a measured requirement appears

\- Turo is an adapter, never system of record

\- Finance does not depend on Turo-specific types

\- Source Ingestion does not depend on Investor Finance

\- AI/LLMs are not part of authoritative MVP calculations



\## Security invariants



\- TenantId from client input is never authorization

\- use server-derived ActorContext

\- PostgreSQL RLS is defense in depth and must be FORCE enabled

\- privileged mutations reauthorize inside their protected transaction

\- direct object IDs are selectors, not authority

\- finance.read must never cause hidden writes

\- finance SYSTEM authority is prohibited unless explicitly specified

\- statement issue uses the canonical compound authorization contract



\## Financial invariants



\- decimal only; never binary floating point for money

\- issued statements immutable

\- source facts immutable; corrections use explicit lineage

\- OperatingCostFact is not a GL posting

\- EconomicAdjustment is not a duplicate expense channel

\- investor subledger is not accounting GL

\- source financial completeness is required for CURRENT

\- no plausible fallback calculation when authoritative inputs are incomplete



\## Implementation workflow



Work one implementation-plan phase at a time.



For each phase:



1\. read the entire phase

2\. read only the referenced design sections

3\. write/update tests with implementation

4\. run unit tests

5\. run PostgreSQL integration tests where applicable

6\. run frontend tests

7\. run E2E where the phase requires it

8\. report deviations from the canonical design

9\. do not begin the next phase until exit criteria pass



Do not expand scope into features explicitly deferred by the implementation plan.

