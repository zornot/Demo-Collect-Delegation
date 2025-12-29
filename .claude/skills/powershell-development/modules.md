# Modules & Manifestes PowerShell

> **Note** : Ce fichier decrit la structure pour CREER un nouveau module PowerShell.
> Pour UTILISER un module existant, voir [project-modules.md](project-modules.md).

## Anti-Patterns Manifest (CRITIQUE)

### Wildcards dans FunctionsToExport (INTERDIT)

```powershell
# [-] INTERDIT - Impact performance -15 secondes au demarrage Windows
FunctionsToExport = '*'
CmdletsToExport = '*'

# [+] CORRECT - Liste explicite obligatoire
FunctionsToExport = @('Get-Something', 'Set-Something')
CmdletsToExport = @()
```

**Pourquoi ?** Les wildcards forcent PowerShell a parser tout le module pour la decouverte de commandes. En Constrained Language Mode (DeviceGuard/AppLocker), les wildcards causent un **echec total** : aucune fonction exportee.

### RequiredModules sans version

```powershell
# [-] RISQUE - Conflits de dependances possibles
RequiredModules = @('OtherModule')

# [+] CORRECT - Version minimale specifiee
RequiredModules = @(
    @{ ModuleName = 'OtherModule'; ModuleVersion = '1.0.0' }
)
```

### Documentation CLAUDE.md

Chaque module DOIT avoir un fichier `CLAUDE.md` (recommande ~50 lignes, limite 200 lignes) avec les sections :
- **CRITICAL** : Prerequis bloquants (2-5 points)
- **Configuration Requise** : Dependances PowerShell + Settings.json requis
- **Usage** : Snippet copier-coller
- **API** : Tableau Fonction/Retour/Usage
- **DO NOT** : Anti-patterns (2-4 points)

Voir `Modules/CLAUDE.md` du projet pour le template complet.

## Structure Module
```
MyModule/
├── Config/
│   └── Settings.json     # Config par defaut (si applicable)
├── Examples/
│   └── Example-Usage.ps1 # Scripts demonstration (requis Gallery)
├── Public/               # Fonctions exportees
│   └── Get-Something.ps1
├── Private/              # Fonctions internes
│   └── Helper.ps1
├── Classes/
│   └── CustomClass.ps1
├── en-US/
│   └── about_MyModule.help.txt
├── MyModule.psd1         # Manifeste avec RequiredModules versions
├── MyModule.psm1         # Module principal
├── CLAUDE.md             # Documentation Claude (recommande ~50, limite 200)
└── README.md             # Documentation complete (200-400 lignes)
```

**Notes** :
- `Config/` : Pas de `.example.json` (pattern Node.js, pas idiomatique PS)
- `Examples/` : Requis pour publication PowerShell Gallery
- Format `.psd1` recommande pour config (natif), `.json` si interop

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

## Synchronisation .psd1 / .psm1 (priorite manifest)

Le manifest `.psd1` a **priorite** sur `Export-ModuleMember` du `.psm1`.

| Scenario | Resultat |
|----------|----------|
| Fonction dans .psm1 avec Export-ModuleMember, **absente** de FunctionsToExport | **NON EXPORTEE** |
| Fonction dans FunctionsToExport, absente du .psm1 | Erreur au chargement |
| Fonction dans les deux | Exportee correctement |

### Checklist ajout fonction publique

Quand vous ajoutez une nouvelle fonction publique :

1. Creer le fichier dans `Public/NomFonction.ps1`
2. Verifier que le .psm1 dot-source le dossier Public/
3. Ajouter la fonction dans `FunctionsToExport` du `.psd1`
4. Tester avec `Get-Command -Module NomModule`

### Pourquoi cette regle ?

Le manifest `.psd1` sert de "contrat" pour le module. PowerShell l'utilise pour :
- Lister les fonctions sans charger le module (`Get-Command -Module X -ListAvailable`)
- Optimiser le chargement (ne charge que ce qui est declare)
- Valider les dependances

Si `FunctionsToExport = @()` (vide), toutes les fonctions de Export-ModuleMember sont exportees.
Si `FunctionsToExport = @('Func1', 'Func2')`, seules celles-ci sont accessibles.

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
