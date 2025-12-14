---
description: Cree un nouveau script PowerShell suivant les standards du projet
argument-hint: NomScript
allowed-tools: Read, Write, Glob, Bash
---

Creer un script PowerShell nomme `$ARGUMENTS.ps1` en utilisant les standards du projet.

## Workflow TDD (RECOMMANDE)

Pour les scripts contenant des fonctions testables, suivre le cycle TDD :

```
1. TESTS D'ABORD  → Creer les tests pour les fonctions du script
2. IMPLEMENTATION → Creer le script (cette commande)
3. VALIDATION     → Executer les tests
```

### Apres creation du script

1. **Validation syntaxe** : Verifier que le script est valide
```powershell
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile("$ARGUMENTS.ps1", [ref]$null, [ref]$errors)
if ($errors) { $errors | ForEach-Object { Write-Host "[-] $($_.Message)" } }
else { Write-Host "[+] Syntaxe valide" }
```

2. **Si des fonctions existent dans le script** : Proposer de creer les tests
> Veux-tu creer des tests pour les fonctions de ce script ?

3. **Executer les tests existants** (si applicable)
```powershell
Invoke-Pester -Path ./Tests -Output Detailed
```

## References Requises

Lire ces fichiers d'abord :
1. `.claude/rules/powershell/ui/templates.md` - Template de script
2. `.claude/rules/powershell/naming.md` - Conventions de nommage
3. `.claude/rules/powershell/logging.md` - Configuration du logging
4. `.claude/rules/powershell/ui/symbols.md` - Brackets de status

## Structure du Script

```powershell
#Requires -Version 7.2

<#
.SYNOPSIS
    Description
#>

[CmdletBinding()]
param()

#region Configuration
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$script:Version = "1.0.0"

Import-Module "$PSScriptRoot\Modules\Write-Log\Write-Log.psm1"
Initialize-Log -Path "$PSScriptRoot\Logs"
#endregion

#region Main
try {
    Write-Log "Demarrage du script" -Level INFO

    # Votre code ici

    Write-Log "Script termine" -Level SUCCESS
    exit 0
} catch {
    Write-Log "Erreur : $($_.Exception.Message)" -Level ERROR
    throw
}
#endregion
```

## Checklist

- [ ] `#Requires -Version 7.2`
- [ ] `[CmdletBinding()]`
- [ ] `$ErrorActionPreference = 'Stop'`
- [ ] Encodage UTF-8
- [ ] Write-Log importe
- [ ] try-catch avec `-ErrorAction Stop`
- [ ] Brackets [+][-][!][i][>] (pas d'emoji)
- [ ] Noms de variables explicites
