# [~] [DRY-001] Factoriser detection ScriptName dupliquee | Effort: 30min

## PROBLEME
La logique de detection automatique du ScriptName via `Get-PSCallStack` est dupliquee
entre `Write-Log` (L109-118) et `Initialize-Log` (L185-191). Ces deux blocs font
essentiellement la meme chose avec une legere variation dans le filtre Where-Object.

## LOCALISATION
- Fichier : Modules/Write-Log/Write-Log.psm1:L109-118, L185-191
- Fonctions : Write-Log, Initialize-Log
- Module : Write-Log

## OBJECTIF
Creer une fonction privee `Get-CallerScriptName` pour centraliser cette logique,
simplifiant la maintenance et garantissant un comportement coherent.

---

## ANALYSE IMPACT

### Code Duplique

**Write-Log (L109-118)** :
```powershell
$callStack = Get-PSCallStack
$caller = $callStack | Where-Object { $_.ScriptName -and $_.ScriptName -ne $PSCommandPath } | Select-Object -First 1
$ScriptName = if ($caller -and $caller.ScriptName) {
    [System.IO.Path]::GetFileNameWithoutExtension($caller.ScriptName)
} else {
    "PowerShell"
}
```

**Initialize-Log (L185-191)** :
```powershell
$callStack = Get-PSCallStack
$caller = $callStack | Where-Object { $_.ScriptName } | Select-Object -First 1
$ScriptName = if ($caller -and $caller.ScriptName) {
    [System.IO.Path]::GetFileNameWithoutExtension($caller.ScriptName)
} else {
    "PowerShell"
}
```

### Difference
```diff
- Where-Object { $_.ScriptName -and $_.ScriptName -ne $PSCommandPath }
+ Where-Object { $_.ScriptName }
```

### Fichiers Impactes
| Fichier | Raison | Action Requise |
|---------|--------|----------------|
| Write-Log.psm1 | Ajout fonction + refactoring | Creation + modification |
| Tests existants | Valider comportement inchange | Executer Pester |

---

## IMPLEMENTATION

### Etape 1 : Creer fonction privee - 15min
Fichier : Modules/Write-Log/Write-Log.psm1
Ajouter AVANT les fonctions publiques (apres le header)

AJOUTER :
```powershell
function Get-CallerScriptName {
    <#
    .SYNOPSIS
        Detecte automatiquement le nom du script appelant via la call stack.
    .DESCRIPTION
        Fonction privee utilisee par Write-Log et Initialize-Log pour determiner
        le nom du script qui appelle les fonctions de logging.
    .PARAMETER ExcludeCurrentScript
        Exclut le script courant (PSCommandPath) de la recherche.
        Utilise par Write-Log pour eviter de retourner le module lui-meme.
    .OUTPUTS
        [string] Nom du script sans extension, ou "PowerShell" si non detecte.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [switch]$ExcludeCurrentScript
    )

    $callStack = Get-PSCallStack

    $filter = if ($ExcludeCurrentScript) {
        { $_.ScriptName -and $_.ScriptName -ne $PSCommandPath }
    } else {
        { $_.ScriptName }
    }

    $caller = $callStack | Where-Object $filter | Select-Object -First 1

    if ($caller -and $caller.ScriptName) {
        return [System.IO.Path]::GetFileNameWithoutExtension($caller.ScriptName)
    }
    return "PowerShell"
}
```

### Etape 2 : Refactorer Write-Log - 5min
Fichier : Modules/Write-Log/Write-Log.psm1
Lignes 109-118 - REMPLACER

AVANT :
```powershell
if ([string]::IsNullOrEmpty($ScriptName)) {
    # Detection automatique via call stack
    $callStack = Get-PSCallStack
    $caller = $callStack | Where-Object { $_.ScriptName -and $_.ScriptName -ne $PSCommandPath } | Select-Object -First 1
    $ScriptName = if ($caller -and $caller.ScriptName) {
        [System.IO.Path]::GetFileNameWithoutExtension($caller.ScriptName)
    } else {
        "PowerShell"
    }
}
```

APRES :
```powershell
if ([string]::IsNullOrEmpty($ScriptName)) {
    $ScriptName = Get-CallerScriptName -ExcludeCurrentScript
}
```

### Etape 3 : Refactorer Initialize-Log - 5min
Fichier : Modules/Write-Log/Write-Log.psm1
Lignes 185-191 - REMPLACER

AVANT :
```powershell
if ([string]::IsNullOrEmpty($ScriptName)) {
    $callStack = Get-PSCallStack
    $caller = $callStack | Where-Object { $_.ScriptName } | Select-Object -First 1
    $ScriptName = if ($caller -and $caller.ScriptName) {
        [System.IO.Path]::GetFileNameWithoutExtension($caller.ScriptName)
    } else {
        "PowerShell"
    }
}
```

APRES :
```powershell
if ([string]::IsNullOrEmpty($ScriptName)) {
    $ScriptName = Get-CallerScriptName
}
```

### Etape 4 : Verifier tests - 5min
Executer tous les tests Pester pour valider que le comportement est inchange.

---

## VALIDATION

### Execution Virtuelle
```
# Appel depuis MonScript.ps1
Initialize-Log -Path ".\Logs"
  > Get-CallerScriptName (sans -ExcludeCurrentScript)
  > Retourne "MonScript"

Write-Log "Test"
  > Get-CallerScriptName -ExcludeCurrentScript
  > Retourne "MonScript" (exclut Write-Log.psm1)
```
[>] VALIDE - Comportement identique a l'original

### Criteres d'Acceptation
- [ ] Fonction Get-CallerScriptName creee et documentee
- [ ] Write-Log utilise Get-CallerScriptName -ExcludeCurrentScript
- [ ] Initialize-Log utilise Get-CallerScriptName
- [ ] Tous les tests existants passent (Invoke-Pester)
- [ ] Detection ScriptName fonctionne dans les deux contextes

## CHECKLIST
- [x] Code AVANT = code reel verifie
- [x] Fonction privee non exportee (Export-ModuleMember)
- [x] Tests passent (16/16)
- [ ] Code review effectuee

Labels : refactor dry write-log effort-30min

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | #6 |
| Statut | CLOSED |
| Commit Resolution | 6b488f5 |
| Date Resolution | 2025-12-08 |
