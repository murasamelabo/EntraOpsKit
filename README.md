# EntraOpsKit

EntraOpsKit is a collection of narrowly scoped, read-only Microsoft Entra operations tools. Version-pinned CI dependencies, offline project tests, Pester, and PSScriptAnalyzer provide release checks before publication.

Version 0.1.6 provides a credential expiry auditor for application registrations and service principals. It inventories credential metadata, classifies expiry risk, and exports JSON or CSV. It does not create, rotate, remove, or update credentials. This release corrects release-assurance and callback-boundary documentation without changing runtime behavior.

## Requirements

- PowerShell 7.2 or later.
- Microsoft.Graph.Authentication 2.x for live Microsoft Graph collection.
- The delegated or application permission Application.Read.All.

Application.Read.All is the least-privileged permission documented for listing both applications and service principals. Interactive authentication is process-scoped so the module does not persist its own sign-in context across PowerShell sessions.

## Use

```powershell
Import-Module ./src/EntraOpsKit/EntraOpsKit.psd1 -Force

$inventory = Get-EntraCredentialInventory -TenantId '<tenant-guid>'
$findings = @(
    $inventory |
        Get-EntraCredentialExpiryFinding -WarningDays 30 -CriticalDays 7
)

$findings | Where-Object Severity -ne 'healthy'
Export-EntraCredentialExpiryReport `
    -Finding $findings `
    -Path ./reports/credential-expiry.json `
    -Format Json
```

The built-in live inventory follows Microsoft Graph pagination for both resource types. Only these endpoints are called, using GET:

- /v1.0/applications
- /v1.0/servicePrincipals

Microsoft Graph may also return `agentIdentityBlueprint` and `agentIdentityBlueprintPrincipal` placeholder objects from these endpoints; EntraOpsKit ignores those non-resource values before creating inventory rows. Absolute pagination links must use HTTPS, the graph.microsoft.com host, and the same resource path. A response that attempts to redirect pagination elsewhere is rejected before another request is sent.

The optional `Request` scriptblock is an operator-supplied test seam. URI and method arguments are validated before invocation, but the module cannot constrain unrelated actions inside caller-provided code. Use it only with trusted test or integration code.

## Output Safety

Findings contain resource identifiers, credential identifiers, names, types, start and end timestamps, days remaining, and severity. Password or certificate values are never copied into inventory output or reports. Treat identifiers and operational reports as tenant data and store them appropriately.

## Verify

The offline runner itself needs only PowerShell and makes no network requests:

```powershell
pwsh -NoLogo -NoProfile -File ./tests/Run-OfflineTests.ps1
```

The fuller development suite uses Pester 6 and PSScriptAnalyzer. Installing those modules can require access to the configured PowerShell repository.

```powershell
$findings = @(
    Invoke-ScriptAnalyzer -Path ./src -Recurse -Severity Warning
    Invoke-ScriptAnalyzer -Path ./tests -Recurse -Severity Warning
)
if ($findings.Count -gt 0) {
    $findings | Format-Table -AutoSize
    throw 'PSScriptAnalyzer reported findings.'
}
Invoke-Pester -Path ./tests/CredentialExpiry.Tests.ps1 -Output Detailed
```

## Provenance

Release metadata and quality results should be retained by the release process. Repository-visible CI uses version-pinned PowerShell modules and a commit-pinned checkout action; it does not claim network isolation or a digest-pinned build container.

See ROADMAP.md for candidate follow-up tools and SECURITY.md for the security boundary.