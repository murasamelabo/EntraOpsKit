BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..' 'src' 'EntraOpsKit' 'EntraOpsKit.psd1'
    Import-Module $modulePath -Force
}

Describe 'Static Graph safety contract' {
    BeforeAll {
        $sourcePath = Join-Path $PSScriptRoot '..' 'src' 'EntraOpsKit' 'EntraOpsKit.psm1'
        $sourceText = Get-Content -LiteralPath $sourcePath -Raw
        $tokens = $null
        $parseErrors = $null
        $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile(
            $sourcePath,
            [ref]$tokens,
            [ref]$parseErrors
        )
    }

    It 'parses without errors and references only approved Graph commands' {
        $parseErrors.Count | Should -Be 0
        $graphCommands = @(
            $sourceAst.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst] -and
                    $node.GetCommandName() -like '*-Mg*'
            }, $true) |
                ForEach-Object { $_.GetCommandName() } |
                Sort-Object -Unique
        )
        $graphCommands | Should -Be @('Connect-MgGraph', 'Get-MgContext', 'Invoke-MgGraphRequest')
    }

    It 'limits call-operator invocation to the approved Request variable' {
        $callOperatorCommands = @(
            $sourceAst.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst] -and
                    $node.InvocationOperator -eq [System.Management.Automation.Language.TokenKind]::Ampersand
            }, $true)
        )
        $callOperatorCommands.Count | Should -Be 1
        $callOperatorCommands[0].CommandElements.Count | Should -BeGreaterOrEqual 1
        $callOperatorCommands[0].CommandElements[0].Extent.Text | Should -Be '$Request'
    }

    It 'keeps the approved scope, GET method, and resource paths' {
        $invokeCommands = @(
            $sourceAst.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst] -and
                    $node.GetCommandName() -eq 'Invoke-MgGraphRequest'
            }, $true)
        )
        $invokeCommands.Count | Should -Be 1
        $invokeElements = @($invokeCommands[0].CommandElements | ForEach-Object { $_.Extent.Text })
        $invokeElements | Should -Contain '-Method'
        $invokeElements | Should -Contain '$Method'

        $sourceText | Should -Match 'Application\.Read\.All'
        $sourceText | Should -Match "Method 'GET'"
        $sourceText | Should -Not -Match "(?i)Method\s+['\"](?:POST|PATCH|PUT|DELETE)['\"]"
        @([regex]::Matches($sourceText, '/v1\.0/(?:applications|servicePrincipals)') |
            ForEach-Object Value |
            Sort-Object -Unique) | Should -Be @('/v1.0/applications', '/v1.0/servicePrincipals')
    }
}

Describe 'Built-in Graph authentication boundary' {
    InModuleScope EntraOpsKit {
        BeforeAll {
            function Get-MgContext {}
            function Connect-MgGraph {
                param([string[]]$Scopes, [switch]$NoWelcome, [string]$ContextScope, [string]$TenantId)
            }
            function Invoke-MgGraphRequest {
                param([string]$Method, [string]$Uri, [string]$OutputType)
            }
        }

        It 'uses the approved scope, process context, tenant, GET method, and endpoints' {
            $tenantId = '11111111-2222-3333-4444-555555555555'
            $script:contextCallCount = 0
            Mock Import-Module {}
            Mock Get-MgContext {
                $script:contextCallCount++
                if ($script:contextCallCount -eq 1) { return $null }
                return [pscustomobject]@{ Scopes = @('Application.Read.All'); TenantId = $tenantId }
            }
            Mock Connect-MgGraph {}
            Mock Invoke-MgGraphRequest { return @{ value = @() } }

            @(Get-EntraCredentialInventory -TenantId $tenantId).Count | Should -Be 0
            Should -Invoke Connect-MgGraph -Times 1 -Exactly -ParameterFilter {
                $Scopes.Count -eq 1 -and $Scopes[0] -eq 'Application.Read.All' -and
                $NoWelcome -and $ContextScope -eq 'Process' -and $TenantId -eq $tenantId
            }
            Should -Invoke Invoke-MgGraphRequest -Times 2 -Exactly -ParameterFilter {
                $Method -eq 'GET' -and $OutputType -eq 'PSObject' -and $Uri -in @(
                    '/v1.0/applications?$select=id,appId,displayName,passwordCredentials,keyCredentials',
                    '/v1.0/servicePrincipals?$select=id,appId,displayName,passwordCredentials,keyCredentials'
                )
            }
        }

        It 'reuses an approved context without creating a connection' {
            Mock Import-Module {}
            Mock Get-MgContext {
                [pscustomobject]@{
                    Scopes = @('Application.Read.All')
                    TenantId = '11111111-2222-3333-4444-555555555555'
                }
            }
            Mock Connect-MgGraph {}
            Mock Invoke-MgGraphRequest { return @{ value = @() } }

            @(Get-EntraCredentialInventory).Count | Should -Be 0
            Should -Invoke Connect-MgGraph -Times 0 -Exactly
            Should -Invoke Invoke-MgGraphRequest -Times 2 -Exactly -ParameterFilter { $Method -eq 'GET' }
        }

        It 'rejects a reused context without the approved scope before Graph requests' {
            Mock Import-Module {}
            Mock Get-MgContext { [pscustomobject]@{ Scopes = @('Directory.Read.All') } }
            Mock Connect-MgGraph {}
            Mock Invoke-MgGraphRequest { return @{ value = @() } }

            { Get-EntraCredentialInventory } | Should -Throw "*must include 'Application.Read.All'*"
            Should -Invoke Connect-MgGraph -Times 0 -Exactly
            Should -Invoke Invoke-MgGraphRequest -Times 0 -Exactly
        }

        It 'rejects a newly connected context without the approved scope before Graph requests' {
            $script:contextCallCount = 0
            Mock Import-Module {}
            Mock Get-MgContext {
                $script:contextCallCount++
                if ($script:contextCallCount -eq 1) { return $null }
                return [pscustomobject]@{ Scopes = @('Directory.Read.All') }
            }
            Mock Connect-MgGraph {}
            Mock Invoke-MgGraphRequest { return @{ value = @() } }

            { Get-EntraCredentialInventory } | Should -Throw "*must include 'Application.Read.All'*"
            Should -Invoke Connect-MgGraph -Times 1 -Exactly
            Should -Invoke Invoke-MgGraphRequest -Times 0 -Exactly
        }

        It 'rejects a null context after connection before any Graph request' {
            Mock Import-Module {}
            Mock Get-MgContext { return $null }
            Mock Connect-MgGraph {}
            Mock Invoke-MgGraphRequest { return @{ value = @() } }

            { Get-EntraCredentialInventory } | Should -Throw '*did not produce a context*'
            Should -Invoke Connect-MgGraph -Times 1 -Exactly
            Should -Invoke Invoke-MgGraphRequest -Times 0 -Exactly
        }

        It 'rejects <Name> before any Graph request' -TestCases @(
            @{ Name = 'a malformed active tenant'; ContextTenantId = 'not-a-guid'; ExpectedMessage = '*does not identify a valid tenant*' },
            @{ Name = 'a mismatched active tenant'; ContextTenantId = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'; ExpectedMessage = '*does not match requested TenantId*' }
        ) {
            param($Name, $ContextTenantId, $ExpectedMessage)
            $tenantId = '11111111-2222-3333-4444-555555555555'
            Mock Import-Module {}
            Mock Get-MgContext { [pscustomobject]@{ Scopes = @('Application.Read.All'); TenantId = $ContextTenantId } }
            Mock Connect-MgGraph {}
            Mock Invoke-MgGraphRequest { return @{ value = @() } }

            { Get-EntraCredentialInventory -TenantId $tenantId } | Should -Throw $ExpectedMessage
            Should -Invoke Connect-MgGraph -Times 0 -Exactly
            Should -Invoke Invoke-MgGraphRequest -Times 0 -Exactly
        }
    }
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
    It 'skips documented agent identity placeholder objects' {
        $responses = @{
            '/v1.0/applications?$select=id,appId,displayName,passwordCredentials,keyCredentials' = @{ value = @(
                @{ '@odata.type' = '#microsoft.graph.application'; id = 'app-1'; passwordCredentials = @(); keyCredentials = @() },
                @{ '@odata.type' = '#microsoft.graph.agentIdentityBlueprint'; id = 'ignored'; passwordCredentials = @(); keyCredentials = @() }
            ) }
            '/v1.0/servicePrincipals?$select=id,appId,displayName,passwordCredentials,keyCredentials' = @{ value = @(
                @{ '@odata.type' = '#microsoft.graph.servicePrincipal'; id = 'sp-1'; passwordCredentials = @(); keyCredentials = @() },
                @{ '@odata.type' = '#microsoft.graph.agentIdentityBlueprintPrincipal'; id = 'ignored'; passwordCredentials = @(); keyCredentials = @() }
            ) }
        }
        $request = { param([string]$Uri, [string]$Method); $Method | Should -Be 'GET'; return $responses[$Uri] }
        $inventory = @(Get-EntraCredentialInventory -Request $request)
        $inventory.ResourceType | Should -Be @('application', 'servicePrincipal')
    }

    It 'rejects repeated pagination before invoking it again' {
        $requests = [System.Collections.Generic.List[string]]::new()
        $pageTwo = 'https://graph.microsoft.com/v1.0/applications?page=2'
        $request = { param([string]$Uri, [string]$Method); $requests.Add($Uri); return @{ value = @(); '@odata.nextLink' = $pageTwo } }
        { Get-EntraCredentialInventory -Request $request } | Should -Throw '*pagination URI was repeated*'
        $requests.Count | Should -Be 2
    }

    It 'rejects equivalent relative and absolute pagination before a duplicate request' {
        $requests = [System.Collections.Generic.List[string]]::new()
        $absoluteInitial = 'https://graph.microsoft.com/v1.0/applications?$select=id,appId,displayName,passwordCredentials,keyCredentials'
        $request = { param([string]$Uri, [string]$Method); $requests.Add($Uri); return @{ value = @(); '@odata.nextLink' = $absoluteInitial } }
        { Get-EntraCredentialInventory -Request $request } | Should -Throw '*pagination URI was repeated*'
        $requests.Count | Should -Be 1
    }

    It 'rejects an excess page before invoking the request' {
        $requests = [System.Collections.Generic.List[string]]::new()
        $request = {
            param([string]$Uri, [string]$Method)
            $requests.Add($Uri)
            $nextLink = if ($requests.Count -eq 1) { 'https://graph.microsoft.com/v1.0/applications?page=2' } else { 'https://graph.microsoft.com/v1.0/applications?page=3' }
            return @{ value = @(); '@odata.nextLink' = $nextLink }
        }
        { Get-EntraCredentialInventory -Request $request -MaximumPageCount 2 } | Should -Throw '*exceeded the maximum page count of 2*'
        $requests.Count | Should -Be 2
    }

    It 'rejects <Name> before invoking another request' -TestCases @(
        @{ Name = 'a non-HTTPS URI'; NextLink = 'http://graph.microsoft.com/v1.0/applications?page=2' },
        @{ Name = 'an unexpected host'; NextLink = 'https://example.invalid/v1.0/applications?page=2' },
        @{ Name = 'a non-default port'; NextLink = 'https://graph.microsoft.com:444/v1.0/applications?page=2' },
        @{ Name = 'URI user information'; NextLink = 'https://user@graph.microsoft.com/v1.0/applications?page=2' },
        @{ Name = 'an absolute fragment'; NextLink = 'https://graph.microsoft.com/v1.0/applications?page=2#fragment' },
        @{ Name = 'a relative fragment'; NextLink = '/v1.0/applications?page=2#fragment' },
        @{ Name = 'an absolute path escape'; NextLink = 'https://graph.microsoft.com/v1.0/applications/extra?page=2' },
        @{ Name = 'a relative path escape'; NextLink = '/v1.0/applications/extra?page=2' },
        @{ Name = 'an absolute case variant'; NextLink = 'https://graph.microsoft.com/v1.0/Applications?page=2' },
        @{ Name = 'a relative case variant'; NextLink = '/v1.0/Applications' }
    ) {
        param($Name, $NextLink)
        $requests = [System.Collections.Generic.List[string]]::new()
        $request = { param([string]$Uri, [string]$Method); $requests.Add($Uri); return @{ value = @(); '@odata.nextLink' = $NextLink } }
        { Get-EntraCredentialInventory -Request $request } | Should -Throw '*outside*'
        $requests.Count | Should -Be 1
    }

    It 'rejects a null response without issuing another request' {
        $requests = [System.Collections.Generic.List[string]]::new()
        $request = { param([string]$Uri, [string]$Method); $requests.Add($Uri); return $null }
        { Get-EntraCredentialInventory -Request $request } | Should -Throw '*returned no response*'
        $requests.Count | Should -Be 1
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

    It 'preserves formula-leading tenant text in CSV output' {
        $outputPath = Join-Path $TestDrive 'formula.csv'
        Export-EntraCredentialExpiryReport -Finding @([pscustomobject]@{ Severity = 'warning'; DisplayName = '=1+1' }) -Path $outputPath -Format Csv
        (Import-Csv -LiteralPath $outputPath).DisplayName | Should -Be '=1+1'
    }

    It 'honors WhatIf without creating a report' {
        $outputPath = Join-Path $TestDrive 'what-if.json'
        Export-EntraCredentialExpiryReport -Finding @() -Path $outputPath -WhatIf
        $outputPath | Should -Not -Exist
    }
}

Describe 'Module metadata and documentation' {
    It 'keeps v0.1.27 and the security boundary aligned' {
        $modulePath = Join-Path $PSScriptRoot '..' 'src' 'EntraOpsKit' 'EntraOpsKit.psd1'
        $readmePath = Join-Path $PSScriptRoot '..' 'README.md'
        $securityPath = Join-Path $PSScriptRoot '..' 'SECURITY.md'
        $moduleData = Import-PowerShellDataFile $modulePath
        $readme = Get-Content -LiteralPath $readmePath -Raw
        $security = Get-Content -LiteralPath $securityPath -Raw

        $moduleData.ModuleVersion | Should -Be '0.1.27'
        $moduleData.Description | Should -BeLike '*Tenant-read-only*'
        $readme | Should -BeLike '*Version 0.1.27*'
        $readme | Should -BeLike '*call operator targets only the Request callback*'
        $readme | Should -BeLike '*Microsoft.Graph.Authentication 2.0 or later*'
        $readme | Should -BeLike '*does not support personal Microsoft accounts*'
        $readme | Should -BeLike '*National-cloud hosts are unsupported*'
        $readme | Should -BeLike '*MaximumPageCount*'
        $readme | Should -BeLike '*Application.Read.All*'
        $readme | Should -BeLike '*formula-leading tenant text*'
        $security | Should -BeLike '*EntraOpsKit 0.1.27 is tenant-read-only*'
        $security | Should -BeLike '*approved Graph command references*'
        $security | Should -BeLike '*call operator targets only the Request callback*'
        $security | Should -BeLike '*requested-tenant context rejection before Graph requests*'
        $security | Should -BeLike '*GET-only behavior*'
        $security | Should -BeLike '*do not neutralize spreadsheet formulas*'
    }
}
