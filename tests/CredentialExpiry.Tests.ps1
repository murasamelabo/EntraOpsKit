BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..' 'src' 'EntraOpsKit' 'EntraOpsKit.psd1'
    Import-Module $modulePath -Force
}

Describe 'Get-EntraCredentialExpiryFinding' {
    It 'classifies and orders credentials deterministically' {
        $fixturePath = Join-Path $PSScriptRoot 'fixtures' 'credentials.json'
        $inventory = Get-Content -LiteralPath $fixturePath -Raw | ConvertFrom-Json -Depth 20
        $now = [DateTimeOffset]::Parse('2026-07-14T00:00:00Z')
        $findings = @($inventory | Get-EntraCredentialExpiryFinding -Now $now -WarningDays 30 -CriticalDays 7)
        $findings.Severity | Should -Be @('expired', 'critical', 'critical', 'warning', 'healthy')
        $findings.CredentialId | Should -Be @('app-expired', 'app-critical', 'sp-critical', 'app-warning', 'sp-healthy')
        $findings[0].PSObject.Properties.Name | Should -Not -Contain 'secretText'
        $findings[0].PSObject.Properties.Name | Should -Not -Contain 'value'
    }

    It 'rejects a critical window larger than the warning window' {
        {
            [pscustomobject]@{ ResourceType = 'application'; PasswordCredentials = @(); KeyCredentials = @() } |
                Get-EntraCredentialExpiryFinding -WarningDays 7 -CriticalDays 8
        } | Should -Throw '*cannot exceed*'
    }
}

Describe 'Get-EntraCredentialInventory' {
    It 'skips agent identity placeholder objects returned by Graph' {
        $responses = @{
            '/v1.0/applications?$select=id,appId,displayName,passwordCredentials,keyCredentials' = @{ value = @(
                @{ '@odata.type' = '#microsoft.graph.application'; id = 'app-object-1'; appId = 'app-client-1'; displayName = 'App One'; passwordCredentials = @(); keyCredentials = @() },
                @{ '@odata.type' = '#microsoft.graph.agentIdentityBlueprint'; id = 'ignored'; passwordCredentials = @(); keyCredentials = @() }
            ) }
            '/v1.0/servicePrincipals?$select=id,appId,displayName,passwordCredentials,keyCredentials' = @{ value = @(
                @{ '@odata.type' = '#microsoft.graph.servicePrincipal'; id = 'sp-object-1'; appId = 'app-client-1'; displayName = 'SP One'; passwordCredentials = @(); keyCredentials = @() },
                @{ '@odata.type' = '#microsoft.graph.agentIdentityBlueprintPrincipal'; id = 'ignored'; passwordCredentials = @(); keyCredentials = @() }
            ) }
        }
        $request = {
            param([string]$Uri, [string]$Method)
            $Method | Should -Be 'GET'
            return $responses[$Uri]
        }
        $inventory = @(Get-EntraCredentialInventory -Request $request)
        $inventory.ResourceType | Should -Be @('application', 'servicePrincipal')
        $inventory.Count | Should -Be 2
    }

    It 'rejects a repeated pagination URI before invoking it again' {
        $requests = [System.Collections.Generic.List[string]]::new()
        $pageTwo = 'https://graph.microsoft.com/v1.0/applications?page=2'
        $request = {
            param([string]$Uri, [string]$Method)
            $Method | Should -Be 'GET'
            $requests.Add($Uri)
            if ($Uri -eq $pageTwo) {
                return @{ value = @(); '@odata.nextLink' = $pageTwo }
            }
            return @{ value = @(); '@odata.nextLink' = $pageTwo }
        }
        { Get-EntraCredentialInventory -Request $request } | Should -Throw '*pagination URI was repeated*'
        $requests | Should -Be @(
            '/v1.0/applications?$select=id,appId,displayName,passwordCredentials,keyCredentials',
            $pageTwo
        )
    }

    It 'rejects equivalent relative and absolute pagination URIs before a duplicate request' {
        $requests = [System.Collections.Generic.List[string]]::new()
        $absoluteInitial = 'https://graph.microsoft.com/v1.0/applications?$select=id,appId,displayName,passwordCredentials,keyCredentials'
        $request = {
            param([string]$Uri, [string]$Method)
            $Method | Should -Be 'GET'
            $requests.Add($Uri)
            return @{ value = @(); '@odata.nextLink' = $absoluteInitial }
        }
        { Get-EntraCredentialInventory -Request $request } | Should -Throw '*pagination URI was repeated*'
        $requests | Should -Be @('/v1.0/applications?$select=id,appId,displayName,passwordCredentials,keyCredentials')
    }

    It 'rejects <Name> before invoking another request' -TestCases @(
        @{ Name = 'a non-HTTPS URI'; NextLink = 'http://graph.microsoft.com/v1.0/applications?page=2' },
        @{ Name = 'an unexpected host'; NextLink = 'https://example.invalid/v1.0/applications?page=2' },
        @{ Name = 'a non-default port'; NextLink = 'https://graph.microsoft.com:444/v1.0/applications?page=2' },
        @{ Name = 'URI user information'; NextLink = 'https://user@graph.microsoft.com/v1.0/applications?page=2' },
        @{ Name = 'a URI fragment'; NextLink = 'https://graph.microsoft.com/v1.0/applications?page=2#fragment' },
        @{ Name = 'an absolute resource-path escape'; NextLink = 'https://graph.microsoft.com/v1.0/applications/extra?page=2' },
        @{ Name = 'a relative resource-path escape'; NextLink = '/v1.0/applications/extra?page=2' }
    ) {
        param($Name, $NextLink)
        $requests = [System.Collections.Generic.List[string]]::new()
        $request = {
            param([string]$Uri, [string]$Method)
            $Method | Should -Be 'GET'
            $requests.Add($Uri)
            return @{ value = @(); '@odata.nextLink' = $NextLink }
        }
        { Get-EntraCredentialInventory -Request $request } | Should -Throw '*outside*'
        $requests.Count | Should -Be 1
    }

    It 'rejects a null Graph response without issuing another request' {
        $requests = [System.Collections.Generic.List[string]]::new()
        $request = {
            param([string]$Uri, [string]$Method)
            $Method | Should -Be 'GET'
            $requests.Add($Uri)
            return $null
        }
        { Get-EntraCredentialInventory -Request $request } | Should -Throw '*returned no response*'
        $requests.Count | Should -Be 1
    }

    It 'rejects a malformed tenant identifier before invoking a callback' {
        $called = $false
        $request = { $called = $true }
        { Get-EntraCredentialInventory -Request $request -TenantId 'not-a-guid' } | Should -Throw
        $called | Should -BeFalse
    }
}

Describe 'Active Graph context validation' {
    InModuleScope EntraOpsKit {
        It 'accepts a matching requested tenant' {
            $context = [pscustomobject]@{ Scopes = @('Application.Read.All'); TenantId = '11111111-2222-3333-4444-555555555555' }
            { Assert-EntraReadContext -Context $context -TenantId '11111111-2222-3333-4444-555555555555' } | Should -Not -Throw
        }

        It 'rejects a mismatched requested tenant' {
            $context = [pscustomobject]@{ Scopes = @('Application.Read.All'); TenantId = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' }
            { Assert-EntraReadContext -Context $context -TenantId '11111111-2222-3333-4444-555555555555' } | Should -Throw '*does not match*'
        }

        It 'rejects a context without a valid tenant when TenantId is requested' {
            $context = [pscustomobject]@{ Scopes = @('Application.Read.All'); TenantId = $null }
            { Assert-EntraReadContext -Context $context -TenantId '11111111-2222-3333-4444-555555555555' } | Should -Throw '*does not identify a valid tenant*'
        }
    }
}

Describe 'Export-EntraCredentialExpiryReport' {
    It 'writes JSON without credential secret values' {
        $fixturePath = Join-Path $PSScriptRoot 'fixtures' 'credentials.json'
        $outputPath = Join-Path $TestDrive 'report.json'
        $inventory = Get-Content -LiteralPath $fixturePath -Raw | ConvertFrom-Json -Depth 20
        $findings = @($inventory | Get-EntraCredentialExpiryFinding -Now ([DateTimeOffset]::Parse('2026-07-14T00:00:00Z')))
        Export-EntraCredentialExpiryReport -Finding $findings -Path $outputPath -Format Json
        $raw = Get-Content -LiteralPath $outputPath -Raw
        $raw | Should -Not -Match 'fixture-secret-value'
        ($raw | ConvertFrom-Json -Depth 20).summary.total | Should -Be 5
    }

    It 'writes CSV without credential secret values' {
        $fixturePath = Join-Path $PSScriptRoot 'fixtures' 'credentials.json'
        $outputPath = Join-Path $TestDrive 'report.csv'
        $inventory = Get-Content -LiteralPath $fixturePath -Raw | ConvertFrom-Json -Depth 20
        $findings = @($inventory | Get-EntraCredentialExpiryFinding -Now ([DateTimeOffset]::Parse('2026-07-14T00:00:00Z')))
        Export-EntraCredentialExpiryReport -Finding $findings -Path $outputPath -Format Csv
        $raw = Get-Content -LiteralPath $outputPath -Raw
        $raw | Should -Not -Match 'fixture-secret-value'
        $raw | Should -Not -Match 'secretText'
        (Import-Csv -LiteralPath $outputPath).Count | Should -Be 5
    }

    It 'honors WhatIf without creating a report' {
        $outputPath = Join-Path $TestDrive 'what-if.json'
        Export-EntraCredentialExpiryReport -Finding @() -Path $outputPath -WhatIf
        $outputPath | Should -Not -Exist
    }
}

Describe 'Module metadata and documentation' {
    It 'keeps version and security-boundary documentation aligned' {
        $modulePath = Join-Path $PSScriptRoot '..' 'src' 'EntraOpsKit' 'EntraOpsKit.psd1'
        $readmePath = Join-Path $PSScriptRoot '..' 'README.md'
        $securityPath = Join-Path $PSScriptRoot '..' 'SECURITY.md'
        $moduleData = Import-PowerShellDataFile $modulePath
        $readme = Get-Content -LiteralPath $readmePath -Raw
        $security = Get-Content -LiteralPath $securityPath -Raw
        $moduleData.ModuleVersion | Should -Be '0.1.10'
        $readme | Should -BeLike '*Version 0.1.10*'
        $readme | Should -BeLike '*Application.Read.All*'
        $readme | Should -BeLike '*operator-supplied test seam*'
        $readme | Should -BeLike '*Equivalent relative and absolute pagination links are treated as repeated*'
        $security | Should -BeLike '*EntraOpsKit 0.1.10 is read-only*'
        $security | Should -BeLike '*requested TenantId*'
        $security | Should -BeLike '*GET endpoints for applications and service principals*'
    }
}