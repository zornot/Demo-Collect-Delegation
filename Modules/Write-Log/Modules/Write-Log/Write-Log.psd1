@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'Write-Log.psm1'

    # Version number of this module.
    ModuleVersion = '2.0.0'

    # ID used to uniquely identify this module
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'

    # Author of this module
    Author = 'Zornot'

    # Company or vendor of this module
    CompanyName = 'Community'

    # Copyright statement for this module
    Copyright = '(c) 2025. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Module de logging centralise au format ISO 8601, compatible SIEM (Splunk, ELK, Azure Sentinel). Conforme RFC 5424 (Syslog) et RFC 3339 (Date-time).'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = @('Write-Log', 'Initialize-Log', 'Invoke-LogRotation')

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module for discoverability
            Tags = @('Logging', 'SIEM', 'ISO8601', 'RFC5424', 'Splunk', 'ELK', 'Sentinel')

            # A URL to the license for this module
            LicenseUri = 'https://github.com/zornot/Module-Write-Log/blob/main/LICENSE'

            # A URL to the main website for this project
            ProjectUri = 'https://github.com/zornot/Module-Write-Log'

            # Release notes
            ReleaseNotes = @'
Version 2.0.0:
- Format ISO 8601 avec timezone (yyyy-MM-ddTHH:mm:ss.fffzzz)
- Compatibilite SIEM (Splunk, ELK, Azure Sentinel, Graylog)
- Niveaux RFC 5424: DEBUG, INFO, SUCCESS, WARNING, ERROR, FATAL
- Affichage console colore
- Encodage UTF-8 sans BOM
'@
        }
    }
}
