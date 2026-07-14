[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Assert-Equal {
    param(
        [object]$Actual,
        [object]$Expected,
        [string]$Message
    )

    $actualJson = ConvertTo-Json @($Actual) -Compress -Depth 20
    $expectedJson = ConvertTo-Json @($Expected) -Compress -Depth 20
    if ($actualJson -ne $expectedJson) {
        throw "$Message Expected $expectedJson, got $actualJson."
    }
}

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

$modulePath = Join-Path $PSScriptRoot '..' 'src' 'EntraOpsKit' 'EntraOpsKit.psd1'
$fixturePath = Join-Path $PSScriptRoot 'fixtures' 'credentials.json'
Import-Module $modulePath -Force

$fixture = Get-Content -LiteralPath $fixturePath -Raw | ConvertFrom-Json -Depth 20
$now = [DateTimeOffset]::Parse('2026-07-14T00:00:00Z')
$findings = @(
    $fixture |
        Get-EntraCredentialExpiryFinding -Now $now -WarningDays 30 -CriticalDays 7
)
Assert-Equal $findings.Severity @('expired', 'critical', 'critical', 'warning', 'healthy') `
    'Expiry classification or ordering changed.'
Assert-Equal $findings.CredentialId @(
    'app-expired',
    'app-critical',
    'sp-critical',
    'app-warning',
    'sp-healthy'
) 'Credential tie-break ordering changed.'
Assert-True ($findings[0].PSObject.Properties.Name -notcontains 'secretText') `
    'A credential secret property escaped into findings.'

$requests = [System.Collections.Generic.List[string]]::new()
$responses = @{
    '/v1.0/applications?$select=id,appId,displayName,passwordCredentials,keyCredentials' = @{
        value = @(
            @{
                id = 'app-object-1'
                appId = 'app-client-1'
                displayName = 'App One'
                passwordCredentials = @(@{ keyId = 'safe-id'; secretText = 'must-not-copy' })
                keyCredentials = @()
            }
        )
        '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/applications?page=2'
    }
    'https://graph.microsoft.com/v1.0/applications?page=2' = @{
        value = @(
            @{
                id = 'app-object-2'
                appId = 'app-client-2'
                displayName = 'App Two'
                passwordCredentials = @()
                keyCredentials = @()
            }
        )
    }
    '/v1.0/servicePrincipals?$select=id,appId,displayName,passwordCredentials,keyCredentials' = @{
        value = @(
            @{
                id = 'sp-object-1'
                appId = 'app-client-1'
                displayName = 'SP One'
                passwordCredentials = @()
                keyCredentials = @()
            }
        )
    }
}
$request = {
    param([string]$Uri, [string]$Method)
    if ($Method -ne 'GET') {
        throw "Unexpected Graph method '$Method'."
    }
    $requests.Add($Uri)
    return $responses[$Uri]
}
$inventory = @(Get-EntraCredentialInventory -Request $request)
Assert-Equal $inventory.ResourceType @('application', 'application', 'servicePrincipal') `
    'Graph pagination changed.'
Assert-Equal $requests.Count 3 'Graph request count changed.'
Assert-True (
    $inventory[0].PasswordCredentials[0].PSObject.Properties.Name -notcontains 'secretText'
) 'A credential secret property escaped into inventory.'

$hostileRequests = [System.Collections.Generic.List[string]]::new()
$hostileRequest = {
    param([string]$Uri, [string]$Method)
    if ($Method -ne 'GET') {
        throw "Unexpected Graph method '$Method'."
    }
    $hostileRequests.Add($Uri)
    if ($Uri.StartsWith('/v1.0/applications')) {
        return @{ value = @(); '@odata.nextLink' = 'https://example.invalid/collect' }
    }
    return @{ value = @() }
}
$hostileRejected = $false
try {
    Get-EntraCredentialInventory -Request $hostileRequest | Out-Null
}
catch {
    $hostileRejected = $_.Exception.Message -match 'pagination URI is outside'
}
Assert-True $hostileRejected 'A hostile Graph pagination URI was not rejected.'
Assert-Equal $hostileRequests.Count 1 'A hostile pagination URI triggered another request.'

$reportPath = Join-Path ([IO.Path]::GetTempPath()) "entra-ops-$([guid]::NewGuid()).json"
try {
    Export-EntraCredentialExpiryReport -Finding $findings -Path $reportPath -Format Json | Out-Null
    $reportText = Get-Content -LiteralPath $reportPath -Raw
    Assert-True ($reportText -notmatch 'fixture-secret-value') `
        'A credential secret value escaped into the report.'
    $report = $reportText | ConvertFrom-Json -Depth 20
    Assert-Equal $report.summary.total 5 'Report summary changed.'
}
finally {
    Remove-Item -LiteralPath $reportPath -Force -ErrorAction SilentlyContinue
}

Write-Output 'PASS: EntraOpsKit offline release gate completed 9 checks.'