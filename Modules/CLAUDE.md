# Modules PowerShell

## Context
Ce dossier contient les modules PowerShell du projet.
Chaque module suit la structure Public/Private.

## Structure Module
```
NomModule/
├── NomModule.psd1    # Manifeste
├── NomModule.psm1    # Module principal
├── Public/           # Fonctions exportees
└── Private/          # Fonctions internes
```

## Conventions Specifiques

### Fonctions Public/
- Doivent avoir `[CmdletBinding()]`
- Doivent avoir `.SYNOPSIS` et `.EXAMPLE`
- Doivent avoir `[OutputType()]`
- Noms en Verb-Noun avec noun SINGULIER

### Fonctions Private/
- Helpers internes, pas exportees
- Documentation minimale acceptable
- Prefixe recommande : rien ou `_` (ex: `_ValidateInput`)

### Manifeste .psd1
- `FunctionsToExport` : Uniquement les fonctions Public/
- `ModuleVersion` : Suivre SemVer

## References
- Structure : @.claude/skills/powershell-development/modules.md
- Nommage : @.claude/skills/powershell-development/naming.md
- Parametres : @.claude/skills/powershell-development/parameters.md

## Quick Commands
```powershell
# Tester un module
Import-Module ./NomModule -Force
Get-Command -Module NomModule

# Valider manifeste
Test-ModuleManifest ./NomModule/NomModule.psd1
```
