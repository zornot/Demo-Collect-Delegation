@{
    RootModule        = 'EXOConnection.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author            = 'Zornot'
    CompanyName       = 'Community'
    Copyright         = '(c) 2025. All rights reserved.'
    Description       = 'Module de connexion Exchange Online avec reutilisation de session, retry configurable et mode silencieux.'
    PowerShellVersion = '7.2'
    RequiredModules   = @('ExchangeOnlineManagement')
    FunctionsToExport = @(
        'Connect-EXOConnection',
        'Disconnect-EXOConnection',
        'Test-EXOConnection',
        'Get-EXOConnectionInfo'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags         = @('ExchangeOnline', 'Authentication', 'Microsoft365', 'Exchange')
            LicenseUri   = 'https://github.com/zornot/EXOConnection/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/zornot/EXOConnection'
            ReleaseNotes = @'
Version 1.0.0:
- Reutilisation automatique de session existante
- Connexion silencieuse (suppression output verbeux)
- Retry configurable avec backoff exponentiel
- Compatible PowerShell 7.2+
'@
        }
    }
}
