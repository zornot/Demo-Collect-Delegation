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

## Etape 0 : Modules Disponibles (OBLIGATOIRE)

**AVANT de coder**, decouvrir les modules existants :

1. Lister les modules :
```powershell
Get-ChildItem -Path ".\Modules" -Directory | Select-Object -ExpandProperty Name
```

2. Pour chaque module pertinent, lire sa documentation :
   - `Modules/NomModule/CLAUDE.md` (prioritaire)
   - `Modules/NomModule/README.md` (si pas de CLAUDE.md)

3. Si besoin de details, lire le code du module

**REGLE** : Ne JAMAIS recreer une fonction qui existe dans un module.

## References Requises

Lire ces fichiers d'abord :
1. `.claude/skills/powershell-development/project-modules.md` - **Modules du projet**
2. `.claude/skills/powershell-development/ui/templates.md` - Template de script
3. `.claude/skills/powershell-development/naming.md` - Conventions de nommage
4. `.claude/skills/powershell-development/logging.md` - Configuration du logging
5. `.claude/skills/powershell-development/ui/symbols.md` - Brackets de status

## Note : Technologies Evolutives

Si le script utilise des modules ou APIs susceptibles d'avoir evolue depuis la date de coupure, consulter `.claude/skills/knowledge-verification/SKILL.md` pour verifier les evolutions recentes avant d'implementer.

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
$modulePath = "$PSScriptRoot\Modules"

# Importer les modules du projet (adapter selon les besoins)
# → Voir CLAUDE.md de chaque module pour les fonctions disponibles
Import-Module "$modulePath\Write-Log\Write-Log.psm1" -ErrorAction Stop
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

- [ ] **Modules listes** et documentation lue
- [ ] **Pas de duplication** de fonctions existantes
- [ ] `#Requires -Version 7.2`
- [ ] `[CmdletBinding()]`
- [ ] `$ErrorActionPreference = 'Stop'`
- [ ] Encodage UTF-8
- [ ] try-catch avec `-ErrorAction Stop`
- [ ] Brackets [+][-][!][i][>] (pas d'emoji)
- [ ] Noms de variables explicites
