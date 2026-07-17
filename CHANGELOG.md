# Changelog

## v0.1.23 - 2026-07-17

- Add offline Pester coverage proving that CSV export preserves formula-leading tenant text rather than neutralizing it.
- Align the manifest, README, security documentation, and version assertions with v0.1.23.
- Keep runtime behavior, permissions, dependencies, GET-only endpoints, output fields, pagination controls, and the no-secret boundary unchanged.

## v0.1.22 - 2026-07-17

- Add offline Pester coverage proving that a newly connected Graph context without `Application.Read.All` fails before Graph requests.
- Clarify that the combined collector does not support personal Microsoft accounts and that national-cloud exclusion is a toolkit limitation.
- Align the manifest, README, security documentation, and version assertions with v0.1.22, and document Microsoft.Graph.Authentication 2.0 or later to match runtime behavior.
- Keep runtime behavior, permissions, dependencies, GET-only endpoints, output fields, pagination controls, and the no-secret boundary unchanged.

## v0.1.21 - 2026-07-17

- Add offline Pester coverage proving that null post-connect, malformed-tenant, and mismatched-tenant Graph contexts fail before Graph requests.
- Align manifest, README, security documentation, and version assertions with v0.1.21.
- Keep runtime behavior, permissions, dependencies, GET-only endpoints, output fields, pagination controls, and the no-secret boundary unchanged.

## v0.1.20 - 2026-07-17

- Add offline Pester coverage proving that a reused Graph context without `Application.Read.All` fails before connection or Graph requests.
- Align manifest, README, security documentation, and version assertions with v0.1.20.
- Keep runtime behavior, permissions, dependencies, GET-only endpoints, output fields, pagination controls, and the no-secret boundary unchanged.

## v0.1.19 - 2026-07-17

- Add network-free Pester coverage for the built-in Microsoft Graph authentication and request path.
- Verify Application.Read.All, process-scoped context, tenant forwarding, GET-only requests, and the two approved endpoints.
- Keep runtime behavior, permissions, dependencies, output fields, pagination controls, and the no-secret boundary unchanged.

## v0.1.18 - 2026-07-17

- Add a configurable per-resource pagination limit, defaulting to 1000 pages.
- Reject a validated excess nextLink before invoking the request callback and add offline callback-count coverage.
- Keep GET-only endpoints, Application.Read.All, dependencies, output fields, and the no-secret boundary unchanged.

## v0.1.17 - 2026-07-16

- Require exact ordinal resource-path matching for absolute and relative Microsoft Graph pagination links.
- Reject case-variant resource paths before invoking the request callback and add offline Pester coverage for exact request counts.
- Keep GET-only endpoints, Application.Read.All, dependencies, output fields, pagination controls, and the no-secret boundary unchanged.

## v0.1.16 - 2026-07-16

- Remove existing-context tenant validation from the roadmap because it shipped in v0.1.7.
- Align release metadata and version regression assertions.
- Keep runtime behavior, GET-only endpoints, Application.Read.All, dependencies, output fields unchanged.

## v0.1.15 - 2026-07-16

- Clarify that built-in Microsoft Graph behavior is tenant-read-only rather than filesystem-read-only.
- State explicitly that report export writes local files and operator-supplied callbacks can have unrelated side effects.
- Keep runtime behavior, GET-only endpoints, Application.Read.All, dependencies, and output fields unchanged.

## v0.1.14 - 2026-07-16

- Clarify Microsoft's 30-day expiring application-credential recommendation and its treatment of lapsed credentials.
- Preserve this tool's broader service-principal, expired-credential, and configurable-threshold behavior.

## v0.1.13 - 2026-07-16

- Clarify that built-in inventory and findings omit credential values.
- Document that report export does not sanitize arbitrary caller-supplied objects.

## v0.1.12 - 2026-07-16

- Document spreadsheet formula risks in tenant-controlled CSV text.
- Recommend JSON or text-only CSV import.

## v0.1.11 - 2026-07-16

- Reject fragments in relative pagination links before callback invocation.

## v0.1.10 - 2026-07-15

- Expand offline pagination validation and callback-count coverage.

## v0.1.9 - 2026-07-15

- Canonicalize Global Graph pagination URIs for cycle tracking.

## v0.1.8 - 2026-07-15

- Reject repeated pagination URIs before another request.

## v0.1.7 - 2026-07-15

- Validate a supplied TenantId against the active Microsoft Graph context.

## v0.1.6 - 2026-07-14

- Correct release-assurance and callback-boundary wording.

## v0.1.5 - 2026-07-14

- Ignore agent identity placeholder objects returned by list endpoints.

## v0.1.4 - 2026-07-14

- Refresh release metadata and add version-alignment coverage.

## v0.1.3 - 2026-07-14

- Add CSV export safety coverage.

## v0.1.2 - 2026-07-14

- Documentation-only release.

## v0.1.1 - 2026-07-14

- Correct repository, vulnerability-reporting, and analyzer documentation.

## v0.1.0 - 2026-07-14

- Add GET-only credential inventory, expiry classification, reporting, pagination validation, and offline gates.
