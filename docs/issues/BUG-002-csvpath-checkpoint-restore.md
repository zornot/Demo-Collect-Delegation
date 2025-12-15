# [!!] [BUG-002] CsvPath non restaure depuis checkpoint - Effort: 15min

## PROBLEME

Lors d'une reprise apres interruption, le chemin CSV stocke dans le fichier checkpoint
n'est pas restaure dans l'etat du module. Le script cree un NOUVEAU fichier CSV
avec un nouveau timestamp au lieu d'appender au fichier existant.

Consequence : Donnees splittees en plusieurs fichiers CSV incomplets.

## LOCALISATION

- Fichier : Modules/Checkpoint/Modules/Checkpoint/Checkpoint.psm1:197-208
- Fonction : Initialize-Checkpoint
- Module : Checkpoint

## OBJECTIF

Lors d'une reprise, le CsvPath du checkpoint doit etre restaure pour que
le script continue a ecrire dans le meme fichier CSV.

---

## IMPLEMENTATION

### Etape 1 : Restaurer CsvPath depuis checkpoint existant - 15min

Fichier : Modules/Checkpoint/Modules/Checkpoint/Checkpoint.psm1

AVANT (L197-208) :
```powershell
if ($existing) {
    $script:CheckpointState.StartIndex = $existing.LastProcessedIndex + 1
    $script:CheckpointState.LastSaveIndex = $existing.LastProcessedIndex

    # Hydrater le HashSet
    foreach ($key in $existing.ProcessedKeys) {
        [void]$script:CheckpointState.ProcessedKeys.Add($key)
    }

    $script:CheckpointState.IsResume = $true
    Write-Verbose "Checkpoint restaure: index $($existing.LastProcessedIndex), $($script:CheckpointState.ProcessedKeys.Count) elements traites"
}
```

APRES :
```powershell
if ($existing) {
    $script:CheckpointState.StartIndex = $existing.LastProcessedIndex + 1
    $script:CheckpointState.LastSaveIndex = $existing.LastProcessedIndex

    # Hydrater le HashSet
    foreach ($key in $existing.ProcessedKeys) {
        [void]$script:CheckpointState.ProcessedKeys.Add($key)
    }

    # Restaurer le chemin CSV depuis le checkpoint
    if ($existing.ContainsKey('CsvPath') -and -not [string]::IsNullOrEmpty($existing.CsvPath)) {
        $script:CheckpointState.CsvPath = $existing.CsvPath
    }

    $script:CheckpointState.IsResume = $true
    Write-Verbose "Checkpoint restaure: index $($existing.LastProcessedIndex), $($script:CheckpointState.ProcessedKeys.Count) elements traites"
}
```

---

## VALIDATION

### Criteres d'Acceptation

- [ ] Reprise utilise le meme fichier CSV que la session interrompue
- [ ] Pas de creation de nouveau fichier CSV lors d'une reprise
- [ ] Donnees appendees sans doublon de header
- [ ] Si CSV supprime entre les runs, nouvelle collecte (checkpoint invalide)
- [ ] Pas de regression sur -NoResume

### Tests Manuels

```powershell
# Test 1: Interruption et reprise
.\Get-ExchangeDelegation.ps1  # Ctrl+C apres 10 mailboxes
# Noter le nom du fichier CSV cree
Start-Sleep -Seconds 5  # Attendre pour nouveau timestamp
.\Get-ExchangeDelegation.ps1  # Doit reprendre
# Verifier: MEME fichier CSV utilise, pas de nouveau fichier

# Test 2: Verification contenu
# Le CSV doit contenir toutes les mailboxes sans doublon de header

# Test 3: CSV supprime
Remove-Item Output/*.csv
.\Get-ExchangeDelegation.ps1  # Doit recommencer (checkpoint invalide)
```

## CHECKLIST

- [x] Code AVANT = code reel verifie
- [ ] Tests manuels passes
- [x] Code review
- [ ] Pas de regression

Labels : bug critique checkpoint csv

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | #14 |
| Statut | CLOSED |
| Branche | fix/BUG-002-csvpath-checkpoint-restore |
| Commit | 76d10b4 |

---

## NOTES

### Decouverte

Bug decouvert lors de l'audit de code approfondi (2025-12-15).
Simulation complete du flux de reprise a revele que CsvPath n'etait pas restaure.

### Impact

- Severite : CRITIQUE
- Donnees potentiellement perdues/splittees
- Fonctionnalite FEAT-010 (append CSV) non fonctionnelle en pratique

### Reference

- Audit : audit/AUDIT-2025-12-15-Get-ExchangeDelegation.md (Phase 3, BUG-001)
- Issue liee : FEAT-010 (implementation initiale du mode append)
