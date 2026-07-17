# Security Policy

## Supported Version

The latest release is supported. Source and release artifacts are publicly inspectable; tenant use and generated reports remain the operator's responsibility.

## Security Boundary

EntraOpsKit 0.1.24 is tenant-read-only in its built-in live Graph behavior. Its live collector calls only Microsoft Graph GET endpoints for applications and service principals and requires `Application.Read.All`. Offline regression coverage verifies the approved connection scope, process scope for module-created connections, tenant forwarding, rejection of missing scopes before and after connection, requested-tenant context rejection before Graph requests, GET method, approved endpoints, and preservation of formula-leading text in CSV output without contacting Microsoft Graph.

The combined collector supports Microsoft Entra work or school tenants, not personal Microsoft accounts. Microsoft documents the underlying list APIs as available in national clouds, but the toolkit currently accepts only the Global Graph host `graph.microsoft.com`; national-cloud hosts are unsupported.

The collector accepts at most `MaximumPageCount` pages per resource, defaulting to 1000. A nextLink beyond the maximum page count is rejected before callback invocation. It also rejects pagination outside the expected Global Microsoft Graph host and exact case-sensitive resource path, non-HTTPS links, non-default ports, user information, fragments, case-variant resource paths, and repeated links after canonicalizing equivalent relative and absolute Global Graph forms. It ignores documented agent-identity placeholder objects.

Tenant-read-only does not mean filesystem-read-only. `Export-EntraCredentialExpiryReport` creates local directories and report files when requested.

Built-in inventory and finding generation copy credential metadata but not password secret text, certificate key material, or credential values. The exporter serializes caller-supplied properties and does not sanitize arbitrary objects. Export only reviewed objects containing no secrets.

When the module establishes a connection, it imports Microsoft.Graph.Authentication 2.0 or later and requests `Application.Read.All` with process-scoped context. Existing contexts can contain broader scopes, but they must include `Application.Read.All`, and built-in collection remains restricted to the documented GET endpoints. A reused context is not required to have been created with process scope; its lifetime is controlled by the operator. When a requested `TenantId` is supplied, the active context must identify the same valid tenant. Without `TenantId`, the module does not independently validate the active context's tenant identifier.

The optional `Request` callback is operator-supplied code for tests or controlled integration. It bypasses module-managed authentication and context validation. The module validates URI and GET arguments but cannot prevent unrelated callback side effects. Use only trusted callbacks.

Reports contain tenant identifiers and operational metadata. Store and remove them according to approved policy. CSV reports preserve tenant-controlled text, including formula-leading values, and do not neutralize spreadsheet formulas; prefer JSON or import CSV columns as text.

Mocked tests verify invocation behavior and do not establish live Microsoft Graph compatibility or publication gating. Repository-visible CI installs pinned packages from a configured network repository.

## Reporting a Vulnerability

Use GitHub private vulnerability reporting. Do not include tenant identifiers, tokens, credential values, or exported reports in public issues.

## Explicit Non-Goals

- Credential creation, rotation, or deletion.
- Role assignment or permission consent.
- Tenant configuration changes.
- Token collection or persistence.
- Arbitrary Graph endpoints or HTTP hosts.
- Personal Microsoft account support.
- National-cloud compatibility in the current Global Graph implementation.
