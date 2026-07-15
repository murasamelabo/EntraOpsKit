@{
    RootModule = 'EntraOpsKit.psm1'
    ModuleVersion = '0.1.10'
    GUID = 'f68f8044-c285-40e0-9bfc-b33e07ec60cd'
    Author = 'Murasame Labo'
    CompanyName = 'Murasame Labo'
    Copyright = '(c) 2026 Murasame Labo. All rights reserved.'
    Description = 'Read-only Microsoft Entra operations utilities.'
    PowerShellVersion = '7.2'
    CompatiblePSEditions = @('Core')
    FunctionsToExport = @(
        'Get-EntraCredentialInventory',
        'Get-EntraCredentialExpiryFinding',
        'Export-EntraCredentialExpiryReport'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('MicrosoftEntra', 'MicrosoftGraph', 'Security', 'Operations')
            ProjectUri = 'https://github.com/murasamelabo/EntraOpsKit'
            LicenseUri = 'https://github.com/murasamelabo/EntraOpsKit/blob/main/LICENSE'
        }
    }
}