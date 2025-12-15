# [!!] BUG-007 - Checkpoint sauve index en cours au lieu du dernier complete - Effort: 45min

## PROBLEME

Le checkpoint sauvegarde `$currentIndex` (l'index de la mailbox EN COURS de traitement) au lieu du dernier index COMPLETE. Au resume, `StartIndex = LastProcessedIndex + 1` fait sauter la mailbox incomplete, causant une perte de donnees.

**Impact** : Perte de delegations a chaque interruption (11 delegations perdues sur 64 dans le test = 17% de perte).

## LOCALISATION

- Fichier : Get-ExchangeDelegation.ps1:L843, L960-961
- Module : Modules/Checkpoint/Checkpoint.psm1:L198
- Variables : `$currentIndex`, `LastProcessedIndex`, `StartIndex`

## OBJECTIF

Le checkpoint doit sauvegarder uniquement les mailboxes dont le traitement est TERMINE (delegations ecrites au CSV). Sur interruption d'une mailbox incomplete, elle doit etre re-traitee au resume.

---

## ANALYSE DETAILLEE

### Flux actuel (bugge)

```
BOUCLE:
  for ($i = $startIndex; ...) {
      $currentIndex = $i                    ← Set au DEBUT
      ...traitement mailbox...
      ...ecriture CSV...
      Add-ProcessedItem -Index $i           ← MARK a la FIN
  }

FINALLY:
  Save-CheckpointAtomic -LastProcessedIndex $currentIndex  ← Sauve l'index EN COURS
```

### Scenario de perte

```
1. Run 1 demarre, $currentIndex = 0 (administration)
2. Traitement en cours...
3. INTERRUPT (Ctrl+C) AVANT ecriture CSV
4. Finally: sauve LastProcessedIndex = 0
5. Run 2: StartIndex = 0 + 1 = 1
6. Run 2 commence a business (index 1)
7. administration (index 0) JAMAIS traitee = delegations perdues
```

### Preuve dans les logs

```
Run 1: CSV existant: 0 → interrompu → 0 delegations ecrites
Run 2: CSV existant: 0 → commence a business, pas administration
       Checkpoint dit "0 deja traite" mais CSV est vide!
```

---

## IMPLEMENTATION

### Etape 1 : Tracker le dernier index COMPLETE - 15min

Fichier : Get-ExchangeDelegation.ps1

AVANT (ligne ~840) :
```powershell
    # Boucle principale avec gestion checkpoint
    $currentIndex = $startIndex
    try {
        for ($i = $startIndex; $i -lt $mailboxCount; $i++) {
            $mailbox = $allMailboxes[$i]
            $currentIndex = $i
```

APRES :
```powershell
    # Boucle principale avec gestion checkpoint
    $currentIndex = $startIndex
    $lastCompletedIndex = $startIndex - 1  # Aucune mailbox completee au debut
    try {
        for ($i = $startIndex; $i -lt $mailboxCount; $i++) {
            $mailbox = $allMailboxes[$i]
            $currentIndex = $i
```

### Etape 2 : Mettre a jour apres MARK - 5min

Fichier : Get-ExchangeDelegation.ps1

AVANT (ligne ~949) :
```powershell
            # MARK: Marquer comme traite + checkpoint periodique
            if ($checkpointState) {
                Add-ProcessedItem -InputObject $mailbox -Index $i
            }
        }
```

APRES :
```powershell
            # MARK: Marquer comme traite + checkpoint periodique
            if ($checkpointState) {
                Add-ProcessedItem -InputObject $mailbox -Index $i
            }

            # Cette mailbox est maintenant completee
            $lastCompletedIndex = $i
        }
```

### Etape 3 : Corriger le finally block - 10min

Fichier : Get-ExchangeDelegation.ps1

AVANT (ligne ~960) :
```powershell
    finally {
        # Checkpoint de securite si interruption (verifier etat module actuel)
        if ((Get-CheckpointState) -and $currentIndex -lt $mailboxCount) {
            Save-CheckpointAtomic -LastProcessedIndex $currentIndex -Force
            Write-Status -Type Warning -Message "Interruption - checkpoint sauvegarde (index $currentIndex)" -Indent 1
        }
    }
```

APRES :
```powershell
    finally {
        # Checkpoint de securite si interruption
        # Sauvegarder UNIQUEMENT si au moins une mailbox a ete completee
        if ((Get-CheckpointState) -and $lastCompletedIndex -ge $startIndex) {
            Save-CheckpointAtomic -LastProcessedIndex $lastCompletedIndex -Force
            Write-Status -Type Warning -Message "Interruption - checkpoint sauvegarde (index $lastCompletedIndex)" -Indent 1
        }
        elseif ((Get-CheckpointState) -and $lastCompletedIndex -lt $startIndex) {
            # Aucune mailbox completee - ne pas sauvegarder de checkpoint invalide
            Write-Status -Type Warning -Message "Interruption - aucune mailbox completee, pas de checkpoint" -Indent 1
        }
    }
```

### Etape 4 : Verification coherence CSV/Checkpoint - 10min

Fichier : Get-ExchangeDelegation.ps1 (apres Initialize-Checkpoint, ligne ~820)

AJOUTER apres le comptage des delegations existantes :
```powershell
    # Verification coherence: si checkpoint dit "X traites" mais CSV a 0 lignes
    # C'est un checkpoint corrompu - on repart de 0
    if ($checkpointState.IsResume -and $existingDelegationCount -eq 0) {
        Write-Log "Checkpoint incoherent (0 delegations dans CSV) - redemarrage complet" -Level WARNING
        Write-Status -Type Warning -Message "Checkpoint invalide - redemarrage depuis index 0" -Indent 1
        $startIndex = 0
        $checkpointState.StartIndex = 0
        $checkpointState.ProcessedKeys.Clear()
    }
```

---

## VALIDATION

### Criteres d'Acceptation

- [x] Interruption pendant mailbox N → resume re-traite mailbox N
- [x] Interruption avant toute completion → resume demarre a 0
- [x] Checkpoint incoherent (ProcessedKeys > 0 mais CSV vide) → reset a 0
- [x] Aucune perte de delegations apres N interruptions
- [x] Run complet donne le meme resultat qu'avant (pas de regression)

### Scenario de Test

1. Lancer collecte
2. Interrompre PENDANT le traitement de la 1ere mailbox (avant 10/24)
3. Relancer
4. Verifier que la 1ere mailbox est re-traitee
5. Laisser terminer
6. Comparer avec run complet (doit avoir le meme nombre de delegations)

### Resultats de Validation (2025-12-15)

| Run | Checkpoint In | CSV existant | Action | Checkpoint Out |
|-----|---------------|--------------|--------|----------------|
| 1 | - | 0 | Interrupt avant completion | Pas de checkpoint |
| 2 | - | 0 | 3 mailboxes completees | index 2 |
| 3 | 3 traitees | 11 | +16 delegations | index 8 |
| 4 | 9 traitees | 27 | +17 delegations | index 16 |
| 5 | 17 traitees | 44 | Complete | - |

**TOTAL : 64 delegations = reference (0% perte)**

| Comportement | Resultat |
|--------------|----------|
| Interrupt avant completion | "aucune mailbox completee, pas de checkpoint" |
| Interrupt apres mailbox N | Checkpoint sauve index N (pas N+1) |
| Reprise checkpoint | Re-traite depuis index correct |
| Aucune perte de donnees | 64 = 64 |

**Avant/Apres BUG-007** : 5 interruptions passent de 53 delegations (17% perte) a 64 delegations (0% perte)

## CHECKLIST

- [x] Code AVANT = code reel
- [x] Tests manuels interruption/reprise
- [x] Verification avec reference 64 delegations
- [x] Pas de regression mode normal

Labels : bug critical checkpoint data-loss

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | # (apres gh issue create) |
| Statut | CLOSED |
| Branche | fix/BUG-007-checkpoint-sauve-index-incorrect |
