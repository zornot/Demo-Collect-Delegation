# Modules & Manifestes PowerShell

## Structure Module
```
MyModule/
├── MyModule.psd1         # Manifeste
├── MyModule.psm1         # Module principal
├── Public/               # Fonctions exportées
│   └── Get-Something.ps1
├── Private/              # Fonctions internes
│   └── Helper.ps1
├── Classes/
│   └── CustomClass.ps1
└── en-US/
    └── about_MyModule.help.txt
```

## Module .psm1
```powershell
# Dot-source classes
$classPath = Join-Path $PSScriptRoot 'Classes'
if (Test-Path $classPath) {
    Get-ChildItem -Path $classPath -Filter '*.ps1' | ForEach-Object {
        . $_.FullName
    }
}

# Dot-source private
$privatePath = Join-Path $PSScriptRoot 'Private'
if (Test-Path $privatePath) {
    Get-ChildItem -Path $privatePath -Filter '*.ps1' | ForEach-Object {
        . $_.FullName
    }
}

# Dot-source et exporter public
$publicPath = Join-Path $PSScriptRoot 'Public'
if (Test-Path $publicPath) {
    $publicFunctions = Get-ChildItem -Path $publicPath -Filter '*.ps1' | ForEach-Object {
        . $_.FullName
        $_.BaseName
    }
    Export-ModuleMember -Function $publicFunctions
}
```

## Manifeste .psd1
```powershell
@{
    RootModule = 'MyModule.psm1'
    ModuleVersion = '1.0.0'
    GUID = '12345678-1234-1234-1234-123456789012'
    Author = 'Zornot'
    Description = 'Module description'
    PowerShellVersion = '7.2'
    
    FunctionsToExport = @('Get-Something', 'Set-Something')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    RequiredModules = @(
        @{ModuleName='OtherModule'; ModuleVersion='1.0.0'}
    )
    
    PrivateData = @{
        PSData = @{
            Tags = @('Tag1', 'Tag2')
            LicenseUri = 'https://opensource.org/licenses/MIT'
            ProjectUri = 'https://github.com/user/repo'
            ReleaseNotes = 'Initial release'
        }
    }
}
```

## Créer manifeste
```powershell
New-ModuleManifest -Path .\MyModule.psd1 `
    -ModuleVersion '1.0.0' `
    -Author 'Zornot' `
    -Description 'Description' `
    -PowerShellVersion '7.2' `
    -RootModule 'MyModule.psm1' `
    -FunctionsToExport @('Get-Something')
```

## Commandes modules
```powershell
# Import
Import-Module -Name .\MyModule

# Lister fonctions
Get-Command -Module MyModule

# Info module
Get-Module -Name MyModule -ListAvailable

# Désinstaller
Remove-Module -Name MyModule

# Publier Gallery
Publish-Module -Name MyModule -NuGetApiKey $apiKey

# Installer depuis Gallery
Install-Module -Name MyModule
Update-Module -Name MyModule
```
