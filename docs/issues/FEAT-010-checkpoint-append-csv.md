# [x] [FEAT-010] Mode append CSV pour reprise checkpoint - Effort: 2h

## PROBLEME
Actuellement, chaque execution du script cree un nouveau fichier CSV avec un nouveau timestamp.
En cas de reprise apres interruption, les delegations collectees avant l'interruption sont perdues
car un nouveau CSV est cree. Le checkpoint sauvegarde les mailboxes traitees mais pas les donnees.

## LOCALISATION
- Fichier : Get-ExchangeDelegation.ps1:885-895
- Fonction : Export CSV (bloc principal)
- Module : Script principal + Checkpoint

## OBJECTIF
Lors d'une reprise checkpoint :
- Reutiliser le fichier CSV existant (chemin stocke dans checkpoint)
- Ajouter les nouvelles delegations en mode append (sans header)
- Valider que le CSV existe avant reprise

---

## IMPLEMENTATION

### Etape 1 : Stocker CsvPath dans Initialize-Checkpoint - 15min

Le parametre CsvPath est deja passe a Initialize-Checkpoint mais le fichier CSV
est cree APRES l'initialisation du checkpoint. Il faut reorganiser.

Fichier : Get-ExchangeDelegation.ps1

**Reorganisation** :
1. Generer le nom du fichier CSV AVANT Initialize-Checkpoint
2. Passer le chemin a Initialize-Checkpoint
3. En cas de reprise, recuperer le chemin depuis le checkpoint

### Etape 2 : Adapter l'export CSV - 30min

Fichier : Get-ExchangeDelegation.ps1:885-895

AVANT :
```powershell
$exportFileName = "ExchangeDelegations_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').csv"
$exportFilePath = Join-Path -Path $OutputPath -ChildPath $exportFileName

if ($allDelegations.Count -gt 0) {
    $exportData | Export-Csv -Path $exportFilePath -NoTypeInformation -Encoding UTF8
}
```

APRES :
```powershell
# Determiner le chemin CSV (nouveau ou reprise)
if ($checkpointState -and $checkpointState.IsResume -and $checkpointState.CsvPath) {
    $exportFilePath = $checkpointState.CsvPath
    $isAppendMode = $true
} else {
    $exportFileName = "ExchangeDelegations_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').csv"
    $exportFilePath = Join-Path -Path $OutputPath -ChildPath $exportFileName
    $isAppendMode = $false
}

if ($allDelegations.Count -gt 0) {
    if ($isAppendMode) {
        # Append sans header
        $exportData | ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1 |
            Add-Content -Path $exportFilePath -Encoding UTF8
    } else {
        # Nouveau fichier avec header
        $exportData | Export-Csv -Path $exportFilePath -NoTypeInformation -Encoding UTF8
    }
}
```

### Etape 3 : Passer CsvPath au checkpoint initial - 30min

Fichier : Get-ExchangeDelegation.ps1:775-779

AVANT :
```powershell
$checkpointState = Initialize-Checkpoint `
    -Config $checkpointConfig `
    -SessionId $sessionId `
    -TotalItems $mailboxCount `
    -CheckpointPath $checkpointPath
```

APRES :
```powershell
# Generer le chemin CSV maintenant pour le stocker dans le checkpoint
$exportFileName = "ExchangeDelegations_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').csv"
$csvFilePath = Join-Path -Path $OutputPath -ChildPath $exportFileName

$checkpointState = Initialize-Checkpoint `
    -Config $checkpointConfig `
    -SessionId $sessionId `
    -TotalItems $mailboxCount `
    -CheckpointPath $checkpointPath `
    -CsvPath $csvFilePath

# Si reprise, utiliser le CSV du checkpoint
if ($checkpointState.IsResume -and (Test-Path $checkpointState.CsvPath)) {
    $csvFilePath = $checkpointState.CsvPath
}
```

### Etape 4 : Validation CSV a la reprise - 30min

Dans le module Checkpoint, Get-ExistingCheckpoint valide deja que le CSV existe (L91-95).
Si le CSV est manquant, le checkpoint est invalide et une nouvelle collecte commence.

---

## VALIDATION

### Criteres d'Acceptation
- [x] Reprise utilise le CSV existant (meme fichier)
- [x] Nouvelles delegations ajoutees sans doublon de header
- [x] Si CSV manquant, nouvelle collecte (pas d'erreur)
- [x] Collecte complete = checkpoint supprime, CSV complet
- [x] -NoResume force nouveau CSV

### Tests Manuels
```powershell
# Test 1: Interruption et reprise
.\Get-ExchangeDelegation.ps1  # Ctrl+C apres 10 mailboxes
# Verifier: Checkpoints/*.checkpoint.json contient CsvPath
.\Get-ExchangeDelegation.ps1  # Doit reprendre
# Verifier: Meme fichier CSV, pas de header duplique

# Test 2: CSV supprime entre les executions
.\Get-ExchangeDelegation.ps1  # Ctrl+C
Remove-Item .\Output\ExchangeDelegations_*.csv
.\Get-ExchangeDelegation.ps1  # Doit recommencer (checkpoint invalide)

# Test 3: Collecte complete
.\Get-ExchangeDelegation.ps1  # Laisser terminer
# Verifier: Checkpoint supprime, CSV complet
```

## CHECKLIST
- [x] Reorganisation generation chemin CSV
- [x] Mode append sans header
- [x] Validation CSV existant
- [x] Tests manuels passes
- [x] Code review

Labels : feature moyenne checkpoint csv

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | local |
| Statut | RESOLVED |
| Branche | feature/FEAT-010-checkpoint-append-csv |
| Commit | (avec REFACTOR-004) |

---

## NOTES

### Alternative consideree : StreamWriter
Exchange-Data-Collector utilise un StreamWriter pour ecrire ligne par ligne.
Avantage : flush immediat, pas de perte de donnees.
Inconvenient : plus complexe, necessite gestion du Dispose.

Pour ce projet (< 1000 mailboxes typiquement), l'approche Export-Csv + Add-Content
est suffisante et plus simple.

### Ordre des colonnes
En mode append, les colonnes doivent etre dans le meme ordre que le header initial.
ConvertTo-Csv preserve l'ordre des proprietes de l'objet, donc OK si les objets
sont construits de la meme facon.
