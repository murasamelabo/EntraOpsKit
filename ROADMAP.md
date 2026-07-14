# Roadmap

EntraOpsKit evolves through bounded AutoStudio cycles. A roadmap item is a research candidate, not a
commitment; each item must cite current Microsoft documentation, pass deterministic prioritization,
and remain read-only unless a separately reviewed policy explicitly changes the product boundary.

## Candidate Cycles

1. Application owner auditor: identify applications and service principals without accountable
   owners and produce a review queue.
2. Privileged consent reviewer: inventory high-impact delegated and application permissions with
   clear provenance and severity rules.
3. Workload identity sign-in health: summarize recent service-principal sign-in failures without
   collecting token or credential values.
4. Certificate policy checks: flag weak operational patterns such as missing overlap windows while
   leaving rotation to administrators.

## Release Invariants

- Microsoft Learn evidence is refreshed for every cycle.
- Least privilege is documented and enforced in the tool boundary.
- No tenant mutation is introduced by default.
- Offline quality gates run in a network-disabled, digest-pinned container.
- Implementation and release review remain separate responsibilities.
- A release is traceable to one AutoStudio operation ID and immutable commit.