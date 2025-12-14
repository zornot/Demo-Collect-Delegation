@{
    RootModule        = 'ConsoleUI.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author            = 'Zornot'
    CompanyName       = 'Community'
    Copyright         = '(c) 2025. All rights reserved.'
    Description       = 'Module PowerShell d affichage console avec bannieres, menus et boites alignees dynamiquement. Box drawing Unicode, icones brackets, pas d emoji.'
    PowerShellVersion = '7.2'
    FunctionsToExport = @(
        'Write-ConsoleBanner',
        'Write-SummaryBox',
        'Write-SelectionBox',
        'Write-MenuBox',
        'Write-Box',
        'Write-EnterpriseAppsSelectionBox',
        'Write-UnifiedSelectionBox',
        'Write-CollectionModeBox',
        'Write-CategorySelectionMenu',
        'Update-CategorySelection'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags         = @('Console', 'UI', 'Menu', 'Banner', 'Box', 'PowerShell')
            LicenseUri   = 'https://github.com/zornot/ConsoleUI/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/zornot/ConsoleUI'
            ReleaseNotes = @'
Version 1.0.0:
- Bannieres avec padding dynamique
- Boites de resume (total, succes, erreurs, duree)
- Menus de selection interactifs
- Support Box Drawing Unicode
- Icones brackets: [+] [-] [!] [i] [>] [?]
- Compatible PowerShell 7.2+
'@
        }
    }
}
