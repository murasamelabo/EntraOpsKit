# EntraOpsKit

EntraOpsKit is a collection of narrowly scoped, read-only Microsoft Entra operations tools. Each release is produced by an auditable AutoStudio research-to-release cycle and must pass an offline, digest-pinned quality gate before publication.

Version 0.1.3 provides a credential expiry auditor for application registrations and service principals. It inventories credential metadata, classifies expiry risk, and exports JSON or CSV. It does not create, rotate, remove, or update credentials.

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

The live inventory follows Microsoft Graph pagination for both resource types. Only these endpoints are called, using GET:

- /v1.0/applications
- /v1.0/servicePrincipals

Absolute pagination links must use HTTPS, the graph.microsoft.com host, and the same resource path. A response that attempts to redirect pagination elsewhere is rejected before another request is sent.

## Output Safety

Findings contain resource identifiers, credential identifiers, names, types, start and end timestamps, days remaining, and severity. Password or certificate values are never copied into inventory output or reports. Treat identifiers and operational reports as tenant data and store them appropriately.

## Verify

The release gate needs only PowerShell and no network access:

```powershell
pwsh -NoLogo -NoProfile -File ./tests/Run-OfflineTests.ps1
```

The fuller development suite uses Pester 6 and PSScriptAnalyzer, including CSV export safety regression coverage:

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

The first release was selected from three candidates using deterministic impact, urgency, feasibility, and safety scoring. AutoStudio records official Microsoft Learn evidence, five completed lifecycle stages, quality evidence, commit SHA, and GitHub release URL in its local durable program ledger.

See ROADMAP.md for candidate follow-up tools and SECURITY.md for the security boundary.