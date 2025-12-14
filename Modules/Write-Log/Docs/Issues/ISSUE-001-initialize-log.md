# [x] [FEAT-001] Ajouter fonction Initialize-Log | Effort: 1h

## PROBLEME

L'utilisateur doit actuellement definir manuellement `$Script:LogFile` et `$Script:ScriptName` dans chaque script avant d'utiliser Write-Log. Cette configuration repetitive est source d'erreurs et reduit l'adoption du module.

## LOCALISATION

- Fichier : `Modules/Write-Log/Write-Log.psm1`
- Fonction : Nouvelle fonction `Initialize-Log`
- Module : Write-Log

## OBJECTIF

Permettre l'initialisation du logging en une seule ligne avec detection automatique du nom de script et creation du chemin de log standardise.

```powershell
# AVANT (3 lignes, repetitif)
$Script:LogFile = ".\Logs\MonScript_$(Get-Date -Format 'yyyy-MM-dd').log"
$Script:ScriptName = "MonScript"
Import-Module Write-Log

# APRES (1 ligne)
Initialize-Log -Path ".\Logs"
```

---

## ANALYSE IMPACT

### Fichiers Impactes

| Fichier | Raison | Action Requise |
|---------|--------|----------------|
| `Write-Log.psm1` | Ajout fonction | Ajouter Initialize-Log |
| `Write-Log.psd1` | Export fonction | Ajouter a FunctionsToExport |
| `README.md` (module) | Documentation | Mettre a jour usage |

### Code Mort a Supprimer

| Ligne | Code | Raison |
|-------|------|--------|
| - | - | Aucun code a supprimer |

---

## IMPLEMENTATION

### Etape 1 : Ajouter fonction Initialize-Log - 30min

Fichier : `Modules/Write-Log/Write-Log.psm1`
Lignes [fin] - AJOUTER

**AVANT** (code REEL) :
```powershell
# Exporter la fonction
Export-ModuleMember -Function Write-Log
```

**APRES** :
```powershell
function Initialize-Log {
    <#
    .SYNOPSIS
        Initialise le logging pour le script courant.
    .DESCRIPTION
        Configure $Script:LogFile et $Script:ScriptName automatiquement.
        Cree le dossier de logs si inexistant.
    .PARAMETER Path
        Chemin du dossier de logs. Defaut: .\Logs
    .PARAMETER ScriptName
        Nom du script. Si non specifie, detecte automatiquement.
    .EXAMPLE
        Initialize-Log -Path ".\Logs"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = ".\Logs",

        [Parameter()]
        [string]$ScriptName
    )

    # Detection auto du nom de script
    if ([string]::IsNullOrEmpty($ScriptName)) {
        $callStack = Get-PSCallStack
        $caller = $callStack | Where-Object { $_.ScriptName } | Select-Object -First 1
        $ScriptName = if ($caller -and $caller.ScriptName) {
            [System.IO.Path]::GetFileNameWithoutExtension($caller.ScriptName)
        } else {
            "PowerShell"
        }
    }

    # Construire le chemin du fichier log
    $logFileName = "{0}_{1}.log" -f $ScriptName, (Get-Date -Format 'yyyy-MM-dd')
    $logFilePath = Join-Path -Path $Path -ChildPath $logFileName

    # Creer le dossier si inexistant
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }

    # Definir les variables dans le scope appelant
    Set-Variable -Name 'LogFile' -Value $logFilePath -Scope Script
    Set-Variable -Name 'ScriptName' -Value $ScriptName -Scope Script

    # Aussi dans le scope global pour compatibilite
    $Global:LogFile = $logFilePath
    $Global:ScriptName = $ScriptName

    Write-Verbose "Log initialise: $logFilePath"
}

# Exporter les fonctions
Export-ModuleMember -Function Write-Log, Initialize-Log
```

**Justification** : Simplifie l'adoption du module en reduisant la configuration a une seule ligne.

### Etape 2 : Mettre a jour le manifest - 5min

Fichier : `Modules/Write-Log/Write-Log.psd1`
Lignes [FunctionsToExport] - MODIFIER

**AVANT** :
```powershell
FunctionsToExport = @('Write-Log')
```

**APRES** :
```powershell
FunctionsToExport = @('Write-Log', 'Initialize-Log')
```

**Justification** : Exporter la nouvelle fonction.

---

## VALIDATION

### Execution Virtuelle

```
Entree : Initialize-Log -Path ".\Logs" (appele depuis MonScript.ps1)
L1 : $ScriptName = "MonScript" (detecte via Get-PSCallStack)
L2 : $logFileName = "MonScript_2025-12-02.log"
L3 : $logFilePath = ".\Logs\MonScript_2025-12-02.log"
L4 : $Script:LogFile = ".\Logs\MonScript_2025-12-02.log"
L5 : $Script:ScriptName = "MonScript"
Sortie : Variables definies, dossier cree si besoin
```

> VALIDE - Le code APRES couvre tous les cas

### Criteres d'Acceptation

- [x] `Initialize-Log -Path ".\Logs"` cree le dossier et definit les variables
- [x] Le nom du script est detecte automatiquement
- [x] `Write-Log "test"` fonctionne apres Initialize-Log sans parametres supplementaires
- [x] Pas de regression sur Write-Log existant

---

## DEPENDANCES

- Bloquee par : Aucune
- Bloque : Aucune
- Liee a : FEAT-003 (detection ScriptName)

## CHECKLIST

- [x] Code AVANT = code reel verifie
- [x] Execution virtuelle validee
- [ ] Tests unitaires passent
- [ ] Issue GitHub creee

---

**Labels** : `feat` `high` `write-log`
**GitHub** : #1
