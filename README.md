# EntraOpsKit

EntraOpsKit is a collection of narrowly scoped, tenant-read-only Microsoft Entra operations tools. Built-in live collection does not mutate Microsoft Entra, but report export writes local files and an operator-supplied callback can have unrelated side effects. Version-pinned CI dependencies, offline project tests, Pester, and PSScriptAnalyzer provide release checks before publication.

Version 0.1.28 strengthens the AST-scoped safety assertion by requiring the approved `Request` callback invocation to receive the validated URI variable and literal `GET` method. Runtime behavior, permissions, dependencies, endpoints, output fields, pagination controls, and the no-secret boundary are unchanged.

Pagination is bounded per resource by `MaximumPageCount`, which defaults to 1000 and accepts values from 1 through 10000. When the limit is reached, a validated nextLink is rejected before invoking the excess request. Repeated, equivalent, malformed, cross-host, fragment-bearing, path-escaping, and case-variant pagination links are also rejected before callback invocation.

## Requirements

- PowerShell 7.2 or later.
- Microsoft.Graph.Authentication 2.0 or later for live collection.
- Delegated or application permission `Application.Read.All`.
- A Microsoft Entra work or school tenant.

Application.Read.All is the least-privileged permission documented for listing both applications and service principals. Delegated access can also require a supported Microsoft Entra role. A reused context can contain additional scopes, but it must include `Application.Read.All`, and built-in requests remain limited to the documented GET endpoints.

The combined collector does not support personal Microsoft accounts. Listing applications for a personal account has an additional `User.Read` requirement, while delegated personal-account access is not supported for listing service principals.

## Use

```powershell
Import-Module ./src/EntraOpsKit/EntraOpsKit.psd1 -Force
$inventory = Get-EntraCredentialInventory -TenantId '<tenant-guid>' -MaximumPageCount 1000
$findings = @($inventory | Get-EntraCredentialExpiryFinding -WarningDays 30 -CriticalDays 7)
$findings | Where-Object Severity -ne 'healthy'
Export-EntraCredentialExpiryReport -Finding $findings -Path ./reports/credential-expiry.json -Format Json
```

The built-in collector follows pagination only for these GET endpoints:

- `/v1.0/applications`
- `/v1.0/servicePrincipals`

Absolute pagination links must use HTTPS, `graph.microsoft.com`, the default port, no user information or fragment, and the exact case-sensitive resource path. Relative and absolute pagination links containing fragments are rejected. Relative paths must remain on the same exact resource path. Equivalent relative and absolute links are treated as repeated.

Microsoft documents both list APIs as available in national clouds, but this toolkit currently validates only the Global Microsoft Graph host. National-cloud hosts are unsupported.

If `TenantId` is supplied, built-in live collection compares it with the active context before issuing an inventory request. When the module creates a connection, it requests process-scoped context. A reused context is not required to have been created with process scope, and its lifetime remains the operator's responsibility.

The optional `Request` scriptblock is an operator-supplied test seam that bypasses module-managed authentication and context validation. URI and GET method arguments are validated before callback invocation, but unrelated callback behavior cannot be constrained. Use only trusted callback code.

The default 30-day warning window is operationally similar to Microsoft's expiring application-credential recommendation, but this tool is not that recommendation. Microsoft's recommendation covers application-registration credentials expiring within 30 days and treats credentials whose expiration has lapsed as completed. This tool also covers service-principal credentials, reports expired credentials, and permits configurable thresholds.

## Output Safety

Module-generated findings contain identifiers, names, types, timestamps, days remaining, and severity. Built-in inventory and finding generation do not copy password or certificate values.

`Export-EntraCredentialExpiryReport` writes a local report and serializes caller-supplied properties. It does not inspect or sanitize arbitrary input properties. Export only reviewed objects that contain no secrets.

CSV preserves tenant-controlled text, including formula-leading tenant text. Spreadsheet software can interpret those values as formulas. Prefer JSON, or import every CSV column as text through an approved process.

## Verify

```powershell
pwsh -NoLogo -NoProfile -File ./tests/Run-OfflineTests.ps1
Invoke-Pester -Path ./tests/CredentialExpiry.Tests.ps1 -Output Detailed
```

The Pester suite uses mocks to verify the approved connection scope, process scope for module-created connections, tenant forwarding, requested-tenant context rejection, GET method, approved endpoints, and CSV formula-text preservation without contacting Microsoft Graph. It also parses module source to inventory Microsoft Graph command references, prove the call operator targets only the Request callback with the validated URI variable and literal GET method, and reject mutation method literals. Static and mocked tests supplement policy validation; they do not establish live Microsoft Graph compatibility. The fuller suite uses Pester 6 and PSScriptAnalyzer. Installing those modules can require access to the configured repository.

## Provenance

Repository-visible CI uses version-pinned PowerShell modules and a commit-pinned checkout action. It does not claim network isolation, a digest-pinned build container, or an automated publication gate.

See ROADMAP.md and SECURITY.md for candidates and security boundaries.
