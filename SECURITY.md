# Security Policy

## Supported Version

The latest release is supported. Source and release artifacts are publicly inspectable; tenant use and generated reports remain the operator's responsibility.

## Security Boundary

EntraOpsKit 0.1.19 is tenant-read-only in its built-in live Graph behavior. Its live collector calls only Microsoft Graph GET endpoints for applications and service principals and requires `Application.Read.All`. Offline regression coverage verifies the built-in connection scope, process-scoped context, tenant forwarding, GET method, and approved endpoints without contacting Microsoft Graph.

The collector accepts at most `MaximumPageCount` pages per resource, defaulting to 1000. A nextLink beyond the maximum page count is rejected before callback invocation. It also rejects pagination outside the expected Global Microsoft Graph host and exact case-sensitive resource path, non-HTTPS links, non-default ports, user information, fragments, case-variant resource paths, and repeated links after canonicalizing equivalent relative and absolute Global Graph forms. It ignores documented agent-identity placeholder objects.

Tenant-read-only does not mean filesystem-read-only. `Export-EntraCredentialExpiryReport` creates local directories and report files when requested.

Built-in inventory and finding generation copy credential metadata but not password secret text, certificate key material, or credential values. The exporter serializes caller-supplied properties and does not sanitize arbitrary objects. Export only reviewed objects containing no secrets.

When the module establishes a connection, it requests `Application.Read.All` with process-scoped context. Existing contexts can contain broader scopes, but built-in collection remains restricted to the documented GET endpoints. When a requested TenantId is supplied, the active context must identify the same tenant.

The optional `Request` callback is operator-supplied code for tests or controlled integration. It bypasses module-managed authentication and context validation. The module validates URI and GET arguments but cannot prevent unrelated callback side effects. Use only trusted callbacks.

Reports contain tenant identifiers and operational metadata. Store and remove them according to approved policy. CSV reports preserve tenant-controlled text and do not neutralize spreadsheet formulas; prefer JSON or import CSV columns as text.

## Reporting a Vulnerability

Use GitHub private vulnerability reporting. Do not include tenant identifiers, tokens, credential values, or exported reports in public issues.

## Explicit Non-Goals

- Credential creation, rotation, or deletion.
- Role assignment or permission consent.
- Tenant configuration changes.
- Token collection or persistence.
- Arbitrary Graph endpoints or HTTP hosts.
- National-cloud compatibility in the current Global Graph implementation.
