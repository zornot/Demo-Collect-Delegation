# [!] BUG-006 - Statistiques incorrectes en reprise checkpoint - Effort: 30min

## PROBLEME

Lors d'une reprise depuis un checkpoint, les statistiques finales (RESUME et logs) n'affichent que les delegations collectees dans la session courante, ignorant celles deja presentes dans le CSV. Resultat : affichage de 46 delegations au lieu de 63 reelles.

## LOCALISATION

- Fichier : Get-ExchangeDelegation.ps1:L1016-1050
- Variables : `$allDelegations`, `$statsPerType`, `$orphansInExport`
- Section : Resume final et statistiques

## OBJECTIF

Les statistiques doivent refleter le total reel du fichier CSV (existant + session), pas uniquement la session courante.

---

## IMPLEMENTATION

### Etape 1 : Compter les lignes CSV existantes au demarrage - 10min

Fichier : Get-ExchangeDelegation.ps1 (apres initialisation checkpoint ~L820)

AVANT :
```powershell
# Initialisation checkpoint - apres creation/detection CSV
Write-Log "CSV initialise: $exportFilePath" -Level DEBUG -NoConsole
```

APRES :
```powershell
# Compter les delegations existantes si reprise checkpoint
$existingDelegationCount = 0
$existingStats = @{ FullAccess = 0; SendAs = 0; SendOnBehalf = 0; Calendar = 0; Forwarding = 0 }
if ($checkpointState -and (Test-Path $exportFilePath)) {
    $existingLines = Get-Content $exportFilePath | Select-Object -Skip 1  # Skip header
    $existingDelegationCount = $existingLines.Count
    foreach ($line in $existingLines) {
        $cols = $line -split ','
        $delegationType = $cols[4] -replace '"', ''  # DelegationType est colonne 5 (index 4)
        if ($existingStats.ContainsKey($delegationType)) {
            $existingStats[$delegationType]++
        }
    }
    Write-Log "CSV existant: $existingDelegationCount delegations pre-existantes" -Level DEBUG -NoConsole
}
```

### Etape 2 : Ajouter les stats existantes au resume final - 10min

Fichier : Get-ExchangeDelegation.ps1:L1016-1028

AVANT :
```powershell
# Compter les orphelins dans l'export
$orphansInExport = @($allDelegations | Where-Object { $_.IsOrphan -eq $true }).Count

# Resume final avec Write-Box du module ConsoleUI
$summaryContent = [ordered]@{
    'Mailboxes'    = $mailboxCount
    'FullAccess'   = $statsPerType.FullAccess
    'SendAs'       = $statsPerType.SendAs
    'SendOnBehalf' = $statsPerType.SendOnBehalf
    'Calendar'     = $statsPerType.Calendar
    'Forwarding'   = $statsPerType.Forwarding
    'TOTAL'        = $allDelegations.Count
    'Orphelins'    = $orphansInExport
}
```

APRES :
```powershell
# Compter les orphelins - session + existants si reprise
$orphansInExport = @($allDelegations | Where-Object { $_.IsOrphan -eq $true }).Count
if ($existingDelegationCount -gt 0) {
    # Compter orphelins dans CSV existant
    $existingLines = Get-Content $exportFilePath | Select-Object -Skip 1
    foreach ($line in $existingLines) {
        $cols = $line -split ','
        if ($cols[7] -replace '"', '' -eq 'True') { $orphansInExport++ }  # IsOrphan colonne 8
    }
}

# Calculer totaux (session + existants)
$totalDelegations = $allDelegations.Count + $existingDelegationCount

# Resume final avec Write-Box du module ConsoleUI
$summaryContent = [ordered]@{
    'Mailboxes'    = $mailboxCount
    'FullAccess'   = $statsPerType.FullAccess + $existingStats.FullAccess
    'SendAs'       = $statsPerType.SendAs + $existingStats.SendAs
    'SendOnBehalf' = $statsPerType.SendOnBehalf + $existingStats.SendOnBehalf
    'Calendar'     = $statsPerType.Calendar + $existingStats.Calendar
    'Forwarding'   = $statsPerType.Forwarding + $existingStats.Forwarding
    'TOTAL'        = $totalDelegations
    'Orphelins'    = $orphansInExport
}
```

### Etape 3 : Corriger le message de log final - 5min

Fichier : Get-ExchangeDelegation.ps1:L1050

AVANT :
```powershell
Write-Log "Collecte terminee - Total: $($allDelegations.Count) delegations - Duree: $($executionTime.ToString('mm\:ss'))" -Level SUCCESS
```

APRES :
```powershell
Write-Log "Collecte terminee - Total: $totalDelegations delegations - Duree: $($executionTime.ToString('mm\:ss'))" -Level SUCCESS
```

---

## VALIDATION

### Criteres d'Acceptation

- [ ] Stats affichent le total reel du CSV (existant + session)
- [ ] Orphelins comptent ceux du CSV existant
- [ ] Message log final affiche le bon total
- [ ] Fonctionne en mode normal (sans checkpoint) - pas de regression

### Scenario de Test

1. Lancer collecte, interrompre a ~50%
2. Relancer (reprise checkpoint)
3. Verifier que RESUME affiche le total du fichier CSV
4. Comparer avec `wc -l` sur le fichier CSV

## CHECKLIST

- [ ] Code AVANT = code reel
- [ ] Tests manuels reprise checkpoint
- [ ] Pas de regression mode normal

Labels : bug elevated checkpoint statistics

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | # (apres gh issue create) |
| Statut | RESOLVED |
| Branche | fix/BUG-006-statistiques-reprise-checkpoint |
