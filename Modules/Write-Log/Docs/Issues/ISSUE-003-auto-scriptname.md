# [x] [FEAT-003] Ameliorer detection automatique ScriptName | Effort: 30min

## PROBLEME

La detection automatique du nom de script dans Write-Log utilise actuellement un fallback basique (`$Global:ScriptName` ou "PowerShell"). Lorsque Initialize-Log n'est pas appele, le nom de script n'est pas detecte automatiquement, ce qui reduit la tracabilite des logs.

## LOCALISATION

- Fichier : `Modules/Write-Log/Write-Log.psm1:L104-L109`
- Fonction : `Write-Log`
- Module : Write-Log

## OBJECTIF

Ameliorer la detection du ScriptName directement dans Write-Log pour qu'il fonctionne meme sans appel a Initialize-Log. Utiliser `Get-PSCallStack` ou `$MyInvocation` pour detecter le script appelant.

---

## ANALYSE IMPACT

### Fichiers Impactes

| Fichier | Raison | Action Requise |
|---------|--------|----------------|
| `Write-Log.psm1` | Modifier detection | Ameliorer fallback ScriptName |

### Code Mort a Supprimer

| Ligne | Code | Raison |
|-------|------|--------|
| - | - | Aucun code a supprimer |

---

## IMPLEMENTATION

### Etape 1 : Ameliorer detection ScriptName dans Write-Log - 20min

Fichier : `Modules/Write-Log/Write-Log.psm1`
Lignes [104-109] - MODIFIER

**AVANT** (code REEL) :
```powershell
if ([string]::IsNullOrEmpty($ScriptName)) {
    $ScriptName = $Script:ScriptName
    if ([string]::IsNullOrEmpty($ScriptName)) {
        # Fallback: nom du script appelant ou valeur par defaut
        $ScriptName = if ($Global:ScriptName) { $Global:ScriptName } else { "PowerShell" }
    }
}
```

**APRES** :
```powershell
if ([string]::IsNullOrEmpty($ScriptName)) {
    $ScriptName = $Script:ScriptName
    if ([string]::IsNullOrEmpty($ScriptName)) {
        $ScriptName = $Global:ScriptName
    }
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
}
```

**Justification** : Permet d'avoir un nom de script significatif meme sans Initialize-Log.

---

## VALIDATION

### Execution Virtuelle

```
Entree : Write-Log "Test" (appele depuis MonScript.ps1, sans Initialize-Log)
L1 : $ScriptName = $null (pas de parametre)
L2 : $Script:ScriptName = $null (pas d'initialisation)
L3 : $Global:ScriptName = $null
L4 : Get-PSCallStack retourne [{MonScript.ps1, ligne 10}, {Write-Log.psm1}]
L5 : $caller = {MonScript.ps1, ligne 10}
L6 : $ScriptName = "MonScript"
Sortie : Log avec ScriptName = "MonScript"
```

> VALIDE - Le code APRES couvre tous les cas

### Criteres d'Acceptation

- [x] `Write-Log "test"` sans Initialize-Log detecte le bon nom de script
- [x] Le ScriptName defini via Initialize-Log a priorite
- [x] Le ScriptName passe en parametre a priorite maximale
- [x] Fallback "PowerShell" si execution interactive

---

## DEPENDANCES

- Bloquee par : Aucune
- Bloque : Aucune
- Liee a : FEAT-001 (utilise la meme logique de detection)

## CHECKLIST

- [x] Code AVANT = code reel verifie
- [x] Execution virtuelle validee
- [x] Tests unitaires passent
- [ ] Issue GitHub creee

---

**Labels** : `feat` `low` `write-log`
**GitHub** : #3
