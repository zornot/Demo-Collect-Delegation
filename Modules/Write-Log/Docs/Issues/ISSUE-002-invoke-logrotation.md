# [x] [FEAT-002] Ajouter fonction Invoke-LogRotation | Effort: 2h

## PROBLEME

Les fichiers de logs s'accumulent indefiniment dans le dossier Logs/. Sans mecanisme de nettoyage, les disques peuvent se remplir sur le long terme, particulierement pour les scripts executes quotidiennement en tache planifiee.

## LOCALISATION

- Fichier : `Modules/Write-Log/Write-Log.psm1`
- Fonction : Nouvelle fonction `Invoke-LogRotation`
- Module : Write-Log

## OBJECTIF

Fournir une fonction simple pour supprimer les fichiers de logs plus anciens qu'un nombre de jours specifie. Pas de compression (eviter la complexite), juste suppression.

```powershell
# Supprimer les logs > 30 jours
Invoke-LogRotation -Path ".\Logs" -RetentionDays 30

# Previsualiser sans supprimer
Invoke-LogRotation -Path ".\Logs" -RetentionDays 30 -WhatIf
```

---

## ANALYSE IMPACT

### Fichiers Impactes

| Fichier | Raison | Action Requise |
|---------|--------|----------------|
| `Write-Log.psm1` | Ajout fonction | Ajouter Invoke-LogRotation |
| `Write-Log.psd1` | Export fonction | Ajouter a FunctionsToExport |
| `README.md` (module) | Documentation | Ajouter section rotation |

### Code Mort a Supprimer

| Ligne | Code | Raison |
|-------|------|--------|
| - | - | Aucun code a supprimer |

---

## IMPLEMENTATION

### Etape 1 : Ajouter fonction Invoke-LogRotation - 45min

Fichier : `Modules/Write-Log/Write-Log.psm1`
Lignes [avant Export-ModuleMember] - AJOUTER

**AVANT** (code REEL) :
```powershell
# Exporter les fonctions
Export-ModuleMember -Function Write-Log, Initialize-Log
```

**APRES** :
```powershell
function Invoke-LogRotation {
    <#
    .SYNOPSIS
        Supprime les fichiers de logs plus anciens que la retention specifiee.
    .DESCRIPTION
        Nettoie les fichiers .log dans le dossier specifie selon leur date de modification.
        Supporte -WhatIf pour previsualiser les suppressions.
    .PARAMETER Path
        Chemin du dossier de logs a nettoyer.
    .PARAMETER RetentionDays
        Nombre de jours de retention. Les fichiers plus anciens seront supprimes. Defaut: 30
    .PARAMETER Filter
        Filtre des fichiers a traiter. Defaut: *.log
    .EXAMPLE
        Invoke-LogRotation -Path ".\Logs" -RetentionDays 30
    .EXAMPLE
        Invoke-LogRotation -Path ".\Logs" -RetentionDays 7 -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$Path,

        [Parameter(Position = 1)]
        [ValidateRange(1, 365)]
        [int]$RetentionDays = 30,

        [Parameter()]
        [string]$Filter = "*.log"
    )

    $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
    $deletedCount = 0
    $deletedSize = 0

    $oldFiles = Get-ChildItem -Path $Path -Filter $Filter -File |
        Where-Object { $_.LastWriteTime -lt $cutoffDate }

    if (-not $oldFiles) {
        Write-Verbose "Aucun fichier a supprimer (retention: $RetentionDays jours)"
        return
    }

    foreach ($file in $oldFiles) {
        if ($PSCmdlet.ShouldProcess($file.FullName, "Supprimer (age: $([int]((Get-Date) - $file.LastWriteTime).TotalDays) jours)")) {
            try {
                $fileSize = $file.Length
                Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                $deletedCount++
                $deletedSize += $fileSize
            }
            catch {
                Write-Warning "Impossible de supprimer $($file.Name): $_"
            }
        }
    }

    if ($deletedCount -gt 0 -and -not $WhatIfPreference) {
        $sizeInMB = [math]::Round($deletedSize / 1MB, 2)
        Write-Verbose "$deletedCount fichier(s) supprime(s), $sizeInMB MB libere(s)"
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Write-Log, Initialize-Log, Invoke-LogRotation
```

**Justification** : Evite l'accumulation de logs et les disques pleins, tout en restant simple (pas de compression).

### Etape 2 : Mettre a jour le manifest - 5min

Fichier : `Modules/Write-Log/Write-Log.psd1`
Lignes [FunctionsToExport] - MODIFIER

**AVANT** :
```powershell
FunctionsToExport = @('Write-Log', 'Initialize-Log')
```

**APRES** :
```powershell
FunctionsToExport = @('Write-Log', 'Initialize-Log', 'Invoke-LogRotation')
```

**Justification** : Exporter la nouvelle fonction.

---

## VALIDATION

### Execution Virtuelle

```
Entree : Invoke-LogRotation -Path ".\Logs" -RetentionDays 30
Setup : Dossier contient 5 fichiers .log (3 de plus de 30 jours, 2 recents)
L1 : $cutoffDate = 2025-11-02 (30 jours avant aujourd'hui)
L2 : $oldFiles = 3 fichiers (dates: 2025-10-01, 2025-10-15, 2025-10-20)
L3 : Remove-Item pour chaque fichier
Sortie : 3 fichiers supprimes, 2 conserves
```

> VALIDE - Le code APRES couvre tous les cas

### Criteres d'Acceptation

- [x] Les fichiers plus anciens que RetentionDays sont supprimes
- [x] Les fichiers recents sont conserves
- [x] `-WhatIf` affiche les fichiers sans les supprimer
- [x] Erreurs de suppression sont loguees en Warning (pas d'arret)
- [x] Fonctionne avec dossier vide (pas d'erreur)

---

## DEPENDANCES

- Bloquee par : FEAT-001 (Initialize-Log doit etre implemente avant pour l'export)
- Bloque : Aucune
- Liee a : Aucune

## CHECKLIST

- [x] Code AVANT = code reel verifie
- [x] Execution virtuelle validee
- [x] Tests unitaires passent
- [ ] Issue GitHub creee

---

**Labels** : `feat` `high` `write-log`
**GitHub** : #2
