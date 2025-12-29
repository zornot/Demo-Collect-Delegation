---
name: powershell-development
description: "PowerShell development standards for this project. Use when writing, reviewing, or debugging PowerShell code (.ps1, .psm1, .psd1). Covers naming conventions (Verb-Noun, CmdletBinding), error handling (-ErrorAction Stop), performance (List<T>, .Where()), security (TryParse, Test-SafePath), console UI (brackets not emoji), logging (Write-Log module), and Pester testing."
---

# PowerShell Development Standards

Standards de developpement PowerShell pour ce projet.

## Quick Reference

### Init obligatoire
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
- Eviter `$data`, `$temp`, `$i` → `$userData`, `$tempFilePath`, `$userIndex`

### Error Handling
```powershell
# -ErrorAction Stop REQUIS car erreurs non-terminantes ignorent catch
try {
    Get-Item $path -ErrorAction Stop
} catch [System.IO.FileNotFoundException] {
    Write-Log "Not found" -Level ERROR
}
```

### Performance
```powershell
# List<T> au lieu de @() +=
$list = [System.Collections.Generic.List[string]]::new()
$list.Add("item")

# .Where() au lieu de Where-Object pour grandes collections
$active = $users.Where({ $_.Status -eq 'Active' })
```

### User Input
```powershell
# TryParse au lieu de cast direct (qui leve exception)
$index = 0
if (-not [int]::TryParse($userInput, [ref]$index)) {
    Write-Error "Valeur numerique attendue"
}
```

### UI Console (brackets, PAS emoji)
```powershell
Write-Host "[+] " -NoNewline -ForegroundColor Green; Write-Host "Success"
Write-Host "[-] " -NoNewline -ForegroundColor Red; Write-Host "Error"
Write-Host "[!] " -NoNewline -ForegroundColor Yellow; Write-Host "Warning"
Write-Host "[i] " -NoNewline -ForegroundColor Cyan; Write-Host "Info"
Write-Host "[>] " -NoNewline -ForegroundColor White; Write-Host "Action"
Write-Host "[?] " -NoNewline -ForegroundColor DarkGray; Write-Host "WhatIf"
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

## Regle Critique : Modules Existants

**AVANT de coder une fonction UI/logging/connexion, verifier `Modules/` du projet.**

```powershell
# Lister les modules disponibles
Get-ChildItem -Path "$PSScriptRoot\Modules" -Directory
```

NE JAMAIS recreer une fonction qui existe dans un module. Voir [project-modules.md](project-modules.md).

## Regle Critique : Configuration Centralisee

**AVANT de hardcoder une valeur configurable, utiliser `Config/Settings.json`.**

Parametres a externaliser :
- Chemins (logs, output, backup)
- Connexions (serveurs, tenants, credentials)
- Comportements (retention, timeouts, thresholds)
- Emails (destinataires, SMTP)

```powershell
# Charger la configuration
$config = Get-ProjectConfig
$logPath = $config.Paths.Logs
$organization = $config.Exchange.Organization
```

NE JAMAIS hardcoder des valeurs qui varient selon l'environnement. Voir [config.md](config.md).

## Detailed Standards

Pour les details complets, voir les fichiers dans ce skill :

| Domaine | Fichier |
|---------|---------|
| **Modules projet** | [project-modules.md](project-modules.md) |
| Nommage complet | [naming.md](naming.md) |
| Parametres & validation | [parameters.md](parameters.md) |
| Gestion erreurs | [errors.md](errors.md) |
| Performance & Big O | [performance.md](performance.md) |
| Securite OWASP | [security.md](security.md) |
| Tests Pester | [pester.md](pester.md) |
| Modules structure | [modules.md](modules.md) |
| Configuration | [config.md](config.md) |
| Logging Write-Log | [logging.md](logging.md) |
| Design patterns | [patterns.md](patterns.md) |
| Anti-patterns | [anti-patterns.md](anti-patterns.md) |
| PSScriptAnalyzer | [psscriptanalyzer.md](psscriptanalyzer.md) |
| Structure projet | [project-structure.md](project-structure.md) |
| UI symboles | [ui/symbols.md](ui/symbols.md) |
| UI fonctions | [ui/functions.md](ui/functions.md) |
| UI templates | [ui/templates.md](ui/templates.md) |
| Simulation WhatIf | [simulation-whatif.md](simulation-whatif.md) |
