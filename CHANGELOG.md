# Changelog

## v0.1.16 - 2026-07-16

- Remove existing-context tenant validation from the roadmap because it shipped in v0.1.7.
- Align release metadata and version regression assertions.
- Keep runtime behavior, GET-only endpoints, Application.Read.All, dependencies, output fields, and the no-secret boundary unchanged.

## v0.1.15 - 2026-07-16

- Clarify that the built-in Microsoft Graph behavior is tenant-read-only rather than filesystem-read-only.
- State explicitly that report export writes local files and operator-supplied callbacks can have unrelated side effects.
- Keep runtime behavior, GET-only endpoints, Application.Read.All, dependencies, and output fields unchanged.

## v0.1.14 - 2026-07-16

- Clarify that Microsoft's expiring application-credential recommendation covers application registrations expiring within 30 days and treats lapsed credentials as completed.
- Preserve the distinction that this tool also reports service-principal and already expired credentials with configurable thresholds.
- Keep runtime behavior, GET-only endpoints, Application.Read.All, dependencies, and output fields unchanged.

## v0.1.13 - 2026-07-16

- Clarify that built-in inventory and finding generation omit credential values.
- Document that the report exporter serializes caller-supplied properties and does not sanitize arbitrary objects.
- Keep runtime behavior, GET-only endpoints, Application.Read.All, dependencies, and output fields unchanged.

## v0.1.12 - 2026-07-16

- Document that CSV tenant metadata can be interpreted as spreadsheet formulas.
- Recommend JSON or text-only CSV import when spreadsheet processing is required.
- Keep runtime behavior, GET-only endpoints, Application.Read.All, dependencies, and output fields unchanged.

## v0.1.11 - 2026-07-16

- Reject fragments in relative Microsoft Graph pagination links before callback invocation.
- Add offline Pester coverage proving a relative fragment causes no additional request.
- Keep GET-only endpoints, Application.Read.All, dependencies, output fields, and the no-secret boundary unchanged.

## v0.1.10 - 2026-07-15

- Expand offline Pester coverage for pagination schemes, hosts, ports, user information, fragments, and resource-path escapes.
- Verify invalid pagination and null responses stop with exact callback invocation counts.
- Keep runtime behavior, GET-only endpoints, Application.Read.All, dependencies, output fields, and the no-secret boundary unchanged.

## v0.1.9 - 2026-07-15

- Canonicalize validated Global Graph pagination URIs for cycle tracking.
- Reject equivalent relative and absolute repeated links before invoking another request.
- Add offline Pester coverage for the equivalent-link cycle.
- Keep GET-only endpoints, Application.Read.All, dependencies, output fields, and the no-secret boundary unchanged.

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
