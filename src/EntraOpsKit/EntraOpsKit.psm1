Set-StrictMode -Version Latest

$script:ApplicationReadScope = 'Application.Read.All'
$script:GlobalGraphHost = 'graph.microsoft.com'

function Get-EntraCredentialInventory {
    [CmdletBinding()]
    param(
        [Parameter()]
        [scriptblock]$Request,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string]$TenantId
    )

    if ($null -eq $Request) {
        Import-Module Microsoft.Graph.Authentication -MinimumVersion 2.0 -ErrorAction Stop
        $context = Get-MgContext
        if ($null -eq $context) {
            $connectParameters = @{
                Scopes       = @($script:ApplicationReadScope)
                NoWelcome    = $true
                ContextScope = 'Process'
            }
            if ($TenantId) {
                $connectParameters.TenantId = $TenantId
            }
            Connect-MgGraph @connectParameters | Out-Null
            $context = Get-MgContext
        }
        Assert-EntraReadContext -Context $context -TenantId $TenantId
        $Request = {
            param([string]$Uri, [string]$Method)
            Invoke-MgGraphRequest -Method $Method -Uri $Uri -OutputType PSObject
        }
    }

    $resourceQueries = @(
        [pscustomobject]@{
            Type = 'application'
            Path = '/v1.0/applications'
            Uri  = '/v1.0/applications?$select=id,appId,displayName,passwordCredentials,keyCredentials'
        },
        [pscustomobject]@{
            Type = 'servicePrincipal'
            Path = '/v1.0/servicePrincipals'
            Uri  = '/v1.0/servicePrincipals?$select=id,appId,displayName,passwordCredentials,keyCredentials'
        }
    )

    foreach ($query in $resourceQueries) {
        $uri = $query.Uri
        $visitedUris = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
        while ($uri) {
            Assert-EntraGraphReadUri -Uri $uri -ResourcePath $query.Path
            $requestKey = Get-EntraGraphReadUriKey -Uri $uri
            if (-not $visitedUris.Add($requestKey)) {
                throw "Microsoft Graph pagination URI was repeated for '$($query.Path)'."
            }
            $response = & $Request -Uri $uri -Method 'GET'
            if ($null -eq $response) {
                throw "Microsoft Graph returned no response for '$uri'."
            }
            $resources = @(Get-EntraPropertyValue -InputObject $response -Name 'value')
            foreach ($resource in $resources) {
                if (-not (Test-EntraGraphSupportedResource -InputObject $resource)) {
                    continue
                }
                [pscustomobject]@{
                    PSTypeName          = 'EntraOpsKit.CredentialResource'
                    ResourceType        = $query.Type
                    ObjectId            = [string](Get-EntraPropertyValue $resource 'id')
                    AppId               = [string](Get-EntraPropertyValue $resource 'appId')
                    DisplayName         = [string](Get-EntraPropertyValue $resource 'displayName')
                    PasswordCredentials = @(
                        ConvertTo-EntraCredentialRecord -InputObject @(
                            Get-EntraPropertyValue $resource 'passwordCredentials'
                        )
                    )
                    KeyCredentials      = @(
                        ConvertTo-EntraCredentialRecord -InputObject @(
                            Get-EntraPropertyValue $resource 'keyCredentials'
                        )
                    )
                }
            }
            $nextLink = Get-EntraPropertyValue -InputObject $response -Name '@odata.nextLink'
            $uri = if ($nextLink) { [string]$nextLink } else { $null }
        }
    }
}

function Get-EntraCredentialExpiryFinding {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$InputObject,
        [Parameter()]
        [ValidateRange(1, 3650)]
        [int]$WarningDays = 30,
        [Parameter()]
        [ValidateRange(0, 3650)]
        [int]$CriticalDays = 7,
        [Parameter()]
        [DateTimeOffset]$Now = [DateTimeOffset]::UtcNow
    )

    begin {
        if ($CriticalDays -gt $WarningDays) {
            throw 'CriticalDays cannot exceed WarningDays.'
        }
        $findings = [System.Collections.Generic.List[object]]::new()
        $severityRank = @{ expired = 0; critical = 1; warning = 2; healthy = 3; unknown = 4 }
    }

    process {
        foreach ($resource in @($InputObject)) {
            $credentialGroups = @(
                @{ Type = 'clientSecret'; Values = @(Get-EntraPropertyValue $resource 'PasswordCredentials') },
                @{ Type = 'certificate'; Values = @(Get-EntraPropertyValue $resource 'KeyCredentials') }
            )
            foreach ($group in $credentialGroups) {
                foreach ($credential in $group.Values) {
                    $endDate = ConvertTo-EntraDateTimeOffset -Value (Get-EntraPropertyValue $credential 'EndDateTime')
                    $startDate = ConvertTo-EntraDateTimeOffset -Value (Get-EntraPropertyValue $credential 'StartDateTime')
                    $daysRemaining = if ($null -eq $endDate) { $null } else { [Math]::Floor(($endDate - $Now).TotalDays) }
                    $severity = if ($null -eq $daysRemaining) {
                        'unknown'
                    }
                    elseif ($daysRemaining -lt 0) {
                        'expired'
                    }
                    elseif ($daysRemaining -le $CriticalDays) {
                        'critical'
                    }
                    elseif ($daysRemaining -le $WarningDays) {
                        'warning'
                    }
                    else {
                        'healthy'
                    }

                    $findings.Add([pscustomobject]@{
                        PSTypeName     = 'EntraOpsKit.CredentialExpiryFinding'
                        Severity       = $severity
                        SeverityRank   = $severityRank[$severity]
                        ResourceType   = [string](Get-EntraPropertyValue $resource 'ResourceType')
                        ObjectId       = [string](Get-EntraPropertyValue $resource 'ObjectId')
                        AppId          = [string](Get-EntraPropertyValue $resource 'AppId')
                        DisplayName    = [string](Get-EntraPropertyValue $resource 'DisplayName')
                        CredentialType = $group.Type
                        CredentialId   = [string](Get-EntraPropertyValue $credential 'KeyId')
                        CredentialName = [string](Get-EntraPropertyValue $credential 'DisplayName')
                        StartDateTime  = $startDate
                        EndDateTime    = $endDate
                        DaysRemaining  = $daysRemaining
                    })
                }
            }
        }
    }

    end {
        $findings |
            Sort-Object -Property @(
                @{ Expression = 'SeverityRank'; Ascending = $true },
                @{ Expression = 'EndDateTime'; Ascending = $true },
                @{ Expression = 'DisplayName'; Ascending = $true },
                @{ Expression = 'CredentialId'; Ascending = $true }
            ) |
            Select-Object -ExcludeProperty SeverityRank
    }
}

function Export-EntraCredentialExpiryReport {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Finding,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        [Parameter()]
        [ValidateSet('Json', 'Csv')]
        [string]$Format = 'Json'
    )

    if (-not $PSCmdlet.ShouldProcess($Path, "Export $Format credential expiry report")) {
        return
    }
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    if ($Format -eq 'Csv') {
        $Finding | Export-Csv -LiteralPath $Path -NoTypeInformation -Encoding utf8BOM
        return Get-Item -LiteralPath $Path
    }

    $summary = [ordered]@{
        total = $Finding.Count
        expired = @($Finding | Where-Object Severity -eq 'expired').Count
        critical = @($Finding | Where-Object Severity -eq 'critical').Count
        warning = @($Finding | Where-Object Severity -eq 'warning').Count
        healthy = @($Finding | Where-Object Severity -eq 'healthy').Count
        unknown = @($Finding | Where-Object Severity -eq 'unknown').Count
    }
    $report = [ordered]@{
        schemaVersion = 1
        generatedAt = [DateTimeOffset]::UtcNow.ToString('o')
        summary = $summary
        findings = @($Finding)
    }
    $report | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $Path -Encoding utf8BOM
    Get-Item -LiteralPath $Path
}

function Assert-EntraReadContext {
    param(
        [object]$Context,
        [string]$TenantId
    )

    if ($null -eq $Context) {
        throw 'Microsoft Graph authentication did not produce a context.'
    }
    $scopes = @(Get-EntraPropertyValue -InputObject $Context -Name 'Scopes')
    if ($scopes -notcontains $script:ApplicationReadScope) {
        throw "The active Microsoft Graph context must include '$script:ApplicationReadScope'."
    }
    if ($TenantId) {
        $contextTenantId = [string](Get-EntraPropertyValue -InputObject $Context -Name 'TenantId')
        $activeTenant = [guid]::Empty
        if ([string]::IsNullOrWhiteSpace($contextTenantId) -or
            -not [guid]::TryParse($contextTenantId, [ref]$activeTenant)) {
            throw 'The active Microsoft Graph context does not identify a valid tenant.'
        }
        if ($activeTenant -ne [guid]$TenantId) {
            throw "The active Microsoft Graph context tenant does not match requested TenantId '$TenantId'."
        }
    }
}

function Assert-EntraGraphReadUri {
    param([string]$Uri, [string]$ResourcePath)
    if ([Uri]::IsWellFormedUriString($Uri, [UriKind]::Absolute)) {
        $parsed = [Uri]$Uri
        $allowed = ($parsed.Scheme -eq 'https' -and $parsed.Host -eq $script:GlobalGraphHost -and $parsed.IsDefaultPort -and $parsed.UserInfo -eq '' -and $parsed.Fragment -eq '' -and $parsed.AbsolutePath -eq $ResourcePath)
        if (-not $allowed) {
            throw "Microsoft Graph pagination URI is outside '$ResourcePath'."
        }
        return
    }
    if ($Uri.Contains('#') -or ($Uri -ne $ResourcePath -and -not $Uri.StartsWith("${ResourcePath}?"))) {
        throw "Microsoft Graph request URI is outside '$ResourcePath'."
    }
}

function Get-EntraGraphReadUriKey {
    param([string]$Uri)
    $baseUri = [Uri]"https://$script:GlobalGraphHost/"
    $parsed = if ([Uri]::IsWellFormedUriString($Uri, [UriKind]::Absolute)) {
        [Uri]$Uri
    }
    else {
        [Uri]::new($baseUri, $Uri)
    }
    return $parsed.AbsoluteUri
}

function Test-EntraGraphSupportedResource {
    param([object]$InputObject)
    $odataType = [string](Get-EntraPropertyValue -InputObject $InputObject -Name '@odata.type')
    switch ($odataType) {
        '#microsoft.graph.agentIdentityBlueprint' { return $false }
        '#microsoft.graph.agentIdentityBlueprintPrincipal' { return $false }
        default { return $true }
    }
}

function ConvertTo-EntraCredentialRecord {
    param([object[]]$InputObject)
    foreach ($item in $InputObject) {
        if ($null -eq $item) { continue }
        [pscustomobject]@{
            DisplayName = [string](Get-EntraPropertyValue $item 'displayName')
            KeyId = [string](Get-EntraPropertyValue $item 'keyId')
            StartDateTime = Get-EntraPropertyValue $item 'startDateTime'
            EndDateTime = Get-EntraPropertyValue $item 'endDateTime'
            Type = [string](Get-EntraPropertyValue $item 'type')
            Usage = [string](Get-EntraPropertyValue $item 'usage')
        }
    }
}

function ConvertTo-EntraDateTimeOffset {
    param([object]$Value)
    if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) { return $null }
    try {
        return [DateTimeOffset]::Parse([string]$Value, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal).ToUniversalTime()
    }
    catch { return $null }
}

function Get-EntraPropertyValue {
    param(
        [Parameter(Mandatory = $true)][object]$InputObject,
        [Parameter(Mandatory = $true)][string]$Name
    )
    if ($InputObject -is [System.Collections.IDictionary]) { return $InputObject[$Name] }
    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -ne $property) { return $property.Value }
    return $null
}

Export-ModuleMember -Function @(
    'Get-EntraCredentialInventory',
    'Get-EntraCredentialExpiryFinding',
    'Export-EntraCredentialExpiryReport'
)
