BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..' 'src' 'EntraOpsKit' 'EntraOpsKit.psd1'
    Import-Module $modulePath -Force
}

Describe 'Get-EntraCredentialExpiryFinding' {
    It 'classifies and orders application and service-principal credentials deterministically' {
        $fixturePath = Join-Path $PSScriptRoot 'fixtures' 'credentials.json'
        $inventory = Get-Content -LiteralPath $fixturePath -Raw | ConvertFrom-Json -Depth 20
        $now = [DateTimeOffset]::Parse('2026-07-14T00:00:00Z')

        $findings = @(
            $inventory |
                Get-EntraCredentialExpiryFinding -Now $now -WarningDays 30 -CriticalDays 7
        )

        $findings.Severity | Should -Be @(
            'expired',
            'critical',
            'critical',
            'warning',
            'healthy'
        )
        $findings.CredentialId | Should -Be @(
            'app-expired',
            'app-critical',
            'sp-critical',
            'app-warning',
            'sp-healthy'
        )
        $findings[0].PSObject.Properties.Name | Should -Not -Contain 'secretText'
        $findings[0].PSObject.Properties.Name | Should -Not -Contain 'value'
    }

    It 'rejects a critical window larger than the warning window' {
        {
            [pscustomobject]@{
                ResourceType = 'application'
                PasswordCredentials = @()
                KeyCredentials = @()
            } | Get-EntraCredentialExpiryFinding -WarningDays 7 -CriticalDays 8
        } | Should -Throw '*cannot exceed*'
    }
}

Describe 'Get-EntraCredentialInventory' {
    It 'follows Graph pagination using GET and strips credential values immediately' {
        $requests = [System.Collections.Generic.List[string]]::new()
        $responses = @{
            '/v1.0/applications?$select=id,appId,displayName,passwordCredentials,keyCredentials' = @{
                value = @(
                    @{
                        id = 'app-object-1'
                        appId = 'app-client-1'
                        displayName = 'App One'
                        passwordCredentials = @(
                            @{ keyId = 'safe-id'; secretText = 'must-not-copy' }
                        )
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
            $Method | Should -Be 'GET'
            $requests.Add($Uri)
            return $responses[$Uri]
        }

        $inventory = @(Get-EntraCredentialInventory -Request $request)

        $inventory.ResourceType | Should -Be @(
            'application',
            'application',
            'servicePrincipal'
        )
        $requests.Count | Should -Be 3
        $inventory[0].PasswordCredentials[0].PSObject.Properties.Name |
            Should -Not -Contain 'secretText'
    }

    It 'rejects pagination outside the expected Graph host before another request' {
        $requests = [System.Collections.Generic.List[string]]::new()
        $request = {
            param([string]$Uri, [string]$Method)
            $Method | Should -Be 'GET'
            $requests.Add($Uri)
            if ($Uri.StartsWith('/v1.0/applications')) {
                return @{ value = @(); '@odata.nextLink' = 'https://example.invalid/collect' }
            }
            return @{ value = @() }
        }

        { Get-EntraCredentialInventory -Request $request } |
            Should -Throw '*pagination URI is outside*'
        $requests.Count | Should -Be 1
    }
}

Describe 'Export-EntraCredentialExpiryReport' {
    It 'writes machine-readable JSON without credential secret values' {
        $fixturePath = Join-Path $PSScriptRoot 'fixtures' 'credentials.json'
        $outputPath = Join-Path $TestDrive 'report.json'
        $inventory = Get-Content -LiteralPath $fixturePath -Raw | ConvertFrom-Json -Depth 20
        $now = [DateTimeOffset]::Parse('2026-07-14T00:00:00Z')
        $findings = @($inventory | Get-EntraCredentialExpiryFinding -Now $now)

        Export-EntraCredentialExpiryReport -Finding $findings -Path $outputPath -Format Json

        $raw = Get-Content -LiteralPath $outputPath -Raw
        $raw | Should -Not -Match 'fixture-secret-value'
        $report = $raw | ConvertFrom-Json -Depth 20
        $report.schemaVersion | Should -Be 1
        $report.summary.total | Should -Be 5
        $report.findings.Count | Should -Be 5
    }

    It 'honors WhatIf without creating a report' {
        $outputPath = Join-Path $TestDrive 'what-if.json'

        Export-EntraCredentialExpiryReport -Finding @() -Path $outputPath -WhatIf

        $outputPath | Should -Not -Exist
    }
}