# Changelog

## v0.1.8 - 2026-07-15

- Reject an exact repeated Microsoft Graph pagination URI before invoking another request.
- Add offline Pester coverage proving cyclic pagination stops after the first repeated link.
- Keep GET-only endpoints, Application.Read.All, dependencies, output fields, and the no-secret boundary unchanged.

## v0.1.7 - 2026-07-15

- Validate a supplied TenantId against the active Microsoft Graph context before built-in live collection.
- Reject malformed tenant identifiers and ambiguous or mismatched active contexts.
- Add offline Pester coverage for matching, missing, and mismatched context tenant identifiers.
- Clarify existing-context scopes, callback behavior, Global Graph support, and Microsoft recommendation parity.
- Keep the GET-only endpoints, Application.Read.All requirement, dependencies, and no-secret output boundary unchanged.

## v0.1.6 - 2026-07-14

- Correct release-assurance wording to match the repository-visible CI implementation.
- Clarify that the optional operator-supplied Request callback is outside the built-in Graph behavior boundary.
- Align release metadata and documentation without changing endpoints, permissions, dependencies, or runtime behavior.

## v0.1.5 - 2026-07-14

- Ignore agent identity placeholder objects returned by the Graph list endpoints.
- Refresh release metadata and security wording.
- Keep the read-only Microsoft Graph boundary and no-secret output behavior unchanged.

## v0.1.4 - 2026-07-14

- Refresh release metadata and security wording.
- Add version-alignment regression coverage.

## v0.1.3 - 2026-07-14

- Add a Pester regression test for CSV export safety.
- Update release metadata and documentation.

## v0.1.2 - 2026-07-14

- Docs-only release; CSV export coverage was described but not yet implemented.

## v0.1.1 - 2026-07-14

- Correct repository and vulnerability-reporting language.
- Correct PSScriptAnalyzer examples and align metadata.

## v0.1.0 - 2026-07-14

- Add GET-only application and service-principal credential inventory.
- Add deterministic expiry classification and JSON/CSV reporting.
- Add strict Graph pagination validation and offline quality gates.