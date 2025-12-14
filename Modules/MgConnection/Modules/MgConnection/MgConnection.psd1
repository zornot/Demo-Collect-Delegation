@{
    RootModule        = 'MgConnection.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'b2c3d4e5-f6a7-8901-bcde-f23456789012'
    Author            = 'Zornot'
    CompanyName       = 'Community'
    Copyright         = '(c) 2025. All rights reserved.'
    Description       = 'Module de connexion Microsoft Graph config-driven. Supporte Interactive, Certificate, ClientSecret et ManagedIdentity avec configuration centralisee.'
    PowerShellVersion = '7.2'
    RequiredModules   = @('Microsoft.Graph.Authentication')
    FunctionsToExport = @(
        'Connect-MgConnection',
        'Disconnect-MgConnection',
        'Test-MgConnection',
        'Get-MgConnectionConfig',
        'Initialize-MgConnection'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags         = @('MicrosoftGraph', 'Authentication', 'Azure', 'EntraID', 'Config')
            LicenseUri   = 'https://github.com/zornot/MgConnection/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/zornot/MgConnection'
            ReleaseNotes = @'
Version 1.0.0:
- Support 4 modes: Interactive, Certificate, ClientSecret, ManagedIdentity
- Configuration centralisee via Settings.json
- WAM (Token Protection) pour mode Interactive
- Retry configurable
- Compatible PowerShell 7.2+
'@
        }
    }
}
