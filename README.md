# EntraOpsKit

EntraOpsKit is a collection of narrowly scoped, read-only Microsoft Entra operations tools. Version-pinned CI dependencies, offline project tests, Pester, and PSScriptAnalyzer provide release checks before publication.

Version 0.1.11 provides a credential expiry auditor for application registrations and service principals. It inventories credential metadata, classifies expiry risk, and exports JSON or CSV. It does not create, rotate, remove, or update credentials. When `TenantId` is supplied for built-in live collection, the active Microsoft Graph context must identify that tenant before collection begins. Repeated pagination links are rejected before another request is issued, including equivalent relative and absolute Global Graph links. Relative and absolute pagination links containing fragments are rejected before callback invocation.

## Requirements

- PowerShell 7.2 or later.
- Microsoft.Graph.Authentication 2.x for live Microsoft Graph collection.
- The delegated or application permission Application.Read.All.
- A Microsoft Entra work or school tenant; combined application and service-principal inventory is not supported for personal Microsoft accounts.

Application.Read.All is the least-privileged permission documented for listing both applications and service principals. The module requests it when establishing a connection. A reused operator context can contain additional scopes, but the module still limits its built-in requests to the documented GET endpoints.

## Use

```powershell
Import-Module ./src/EntraOpsKit/EntraOpsKit.psd1 -Force
$inventory = Get-EntraCredentialInventory -TenantId '<tenant-guid>'
$findings = @($inventory | Get-EntraCredentialExpiryFinding -WarningDays 30 -CriticalDays 7)
$findings | Where-Object Severity -ne 'healthy'
Export-EntraCredentialExpiryReport -Finding $findings -Path ./reports/credential-expiry.json -Format Json
```

The built-in live inventory follows pagination for these GET-only endpoints:

- /v1.0/applications
- /v1.0/servicePrincipals

Absolute pagination links must use HTTPS, the graph.microsoft.com host, the default port, no user information or fragment, and the same resource path. Relative links must remain on the same resource path and cannot contain fragments. Pagination links are canonicalized only for cycle tracking without reordering query parameters. Equivalent relative and absolute pagination links are treated as repeated and rejected before another request. National-cloud hosts are not currently supported. Placeholder `agentIdentityBlueprint` and `agentIdentityBlueprintPrincipal` values are ignored.

If `TenantId` is supplied, built-in live collection compares it with the active context's tenant before issuing an inventory request. The optional `Request` scriptblock is an operator-supplied test seam that bypasses module-managed authentication and context validation. URI and GET method arguments are validated before callback invocation, but unrelated callback behavior cannot be constrained. Use only trusted callback code.

The default 30-day warning window is operationally similar to Microsoft's expiring application-credential recommendation, but this tool is not an implementation of that recommendation. It also covers service-principal credentials, reports already expired credentials, and permits configurable thresholds.

## Output Safety

Findings contain resource and credential identifiers, names, types, timestamps, days remaining, and severity. Password or certificate values are never copied. Treat reports as tenant data.

## Verify

```powershell
pwsh -NoLogo -NoProfile -File ./tests/Run-OfflineTests.ps1
Invoke-Pester -Path ./tests/CredentialExpiry.Tests.ps1 -Output Detailed
```

The fuller suite uses Pester 6 and PSScriptAnalyzer. Installing those modules can require access to the configured PowerShell repository.

## Provenance

Release metadata and quality results should be retained by the release process. Repository-visible CI uses version-pinned PowerShell modules and a commit-pinned checkout action; it does not claim network isolation or a digest-pinned build container.

See ROADMAP.md and SECURITY.md for follow-up candidates and the security boundary.