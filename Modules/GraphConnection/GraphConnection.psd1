@{
    RootModule        = 'GraphConnection.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '5a101615-d7ed-4a2e-8f31-e189483e97ff'
    Author            = 'Zornot'
    CompanyName       = 'Community'
    Copyright         = '(c) 2025. All rights reserved.'
    Description       = 'Module de connexion Microsoft Graph avec mode interactif (WAM desactive/DeviceCode fallback) et certificat. Retry automatique, session reuse, objet de connexion avec methode Disconnect().'
    PowerShellVersion = '7.2'
    RequiredModules   = @(
        @{
            ModuleName    = 'Microsoft.Graph.Authentication'
            ModuleVersion = '2.0.0'
        }
    )
    FunctionsToExport = @(
        'Initialize-GraphConnection',
        'Connect-GraphConnection',
        'Disconnect-GraphConnection',
        'Test-GraphConnection',
        'Get-GraphConnectionInfo'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags         = @('MicrosoftGraph', 'Authentication', 'Microsoft365', 'Graph', 'Azure', 'EntraID')
            LicenseUri   = 'https://opensource.org/licenses/MIT'
            ProjectUri   = 'https://github.com/zornot/Module-GraphConnection'
            ReleaseNotes = @'
Version 1.0.0:
- Mode interactif avec WAM desactive (fix SDK 2.26+) et fallback DeviceCode
- Mode certificat (App Registration)
- Reutilisation automatique de session existante
- Retry configurable avec backoff exponentiel
- Objet de connexion avec methode Disconnect()
- Option NoDisconnect pour conserver la session
- Configuration via Settings.json
- Initialize-GraphConnection pour chemin config personnalise
- Compatible PowerShell 7.2+
'@
        }
    }
}
