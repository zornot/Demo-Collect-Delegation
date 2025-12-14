---
name: powershell-standards
description: |
  Conventions PowerShell du projet. Charge automatiquement quand l'utilisateur :
  - Ecrit du code PowerShell
  - Cree des fonctions ou scripts
  - Demande une review de code
  - Travaille sur des tests Pester
globs:
  - "**/*.ps1"
  - "**/*.psm1"
  - "**/*.psd1"
---

# PowerShell Development Standards

Tu developpes du code PowerShell pour ce projet. Respecte ces conventions.

## Regles Critiques

### Init
```powershell
#Requires -Version 7.2
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
```

### Naming
- `[CmdletBinding()]` sur toutes les fonctions
- `Verb-Noun` avec verbes approuves (`Get-Verb`), **Noun toujours singulier**
- PascalCase fonctions/parametres, MAJUSCULES constantes
- Eviter les noms vagues (`$data`, `$temp`, `$i`) - utiliser des noms explicites comme `$userData`, `$tempFilePath`

### Error Handling
```powershell
# -ErrorAction Stop requis dans try-catch car les erreurs non-terminantes
# ne declenchent pas le catch par defaut
try {
    Get-Item $path -ErrorAction Stop
} catch [System.IO.FileNotFoundException] {
    Write-Log "File not found" -Level ERROR
}
```

### Performance
```powershell
# List<T> au lieu de @() +=
$list = [System.Collections.Generic.List[string]]::new()
$list.Add("item")

# .Where() au lieu de Where-Object
$active = $users.Where({ $_.Status -eq 'Active' })
```

### User Input
```powershell
# TryParse au lieu de cast direct
$index = 0
if (-not [int]::TryParse($userInput, [ref]$index)) {
    Write-Error "Valeur numerique attendue"
}
```

### UI Console
```powershell
# Brackets, PAS emoji
Write-Host "[+] " -NoNewline -ForegroundColor Green; Write-Host "Success"
Write-Host "[-] " -NoNewline -ForegroundColor Red; Write-Host "Error"
Write-Host "[!] " -NoNewline -ForegroundColor Yellow; Write-Host "Warning"
Write-Host "[i] " -NoNewline -ForegroundColor Cyan; Write-Host "Info"
```

### Simplicite

Garder les solutions simples et focalisees :
- Faire uniquement les changements demandes
- Eviter les abstractions prematurees (Rule of Three)
- Ne pas ajouter de fonctionnalites non requises
- Trois lignes similaires valent mieux qu'une abstraction inutile

Eviter le sur-engineering :
- Feature flags pour code non deploye
- Helpers pour operations ponctuelles
- Validation pour scenarios impossibles
- Documentation pour code auto-explicatif
- Backwards-compatibility pour code non publie

## References Detaillees

Pour les details complets, lis ces fichiers selon le besoin :

| Domaine | Fichier |
|---------|---------|
| Nommage | `.claude/rules/powershell/naming.md` |
| Parametres | `.claude/rules/powershell/parameters.md` |
| Erreurs | `.claude/rules/powershell/errors.md` |
| Performance | `.claude/rules/powershell/performance.md` |
| Securite | `.claude/rules/powershell/security.md` |
| Tests Pester | `.claude/rules/powershell/pester.md` |
| Modules | `.claude/rules/powershell/modules.md` |
| UI Console | `.claude/rules/powershell/ui/symbols.md` |
| Logging | `.claude/rules/powershell/logging.md` |
| Anti-patterns | `.claude/rules/powershell/anti-patterns.md` |
| Config | `.claude/rules/powershell/config.md` |
| Structure | `.claude/rules/powershell/project-structure.md` |

## Regles Communes

Pour Git, TDD, workflow issues et anonymisation des donnees :
- Reference: @.claude/rules/common/git.md
- Reference: @.claude/rules/common/tdd.md
- Reference: @.claude/rules/common/workflow.md
- Reference: @.claude/rules/common/testing-data.md

Lis `.claude/rules/RULES.md` pour le resume complet des regles.
