# [!] [REFACTOR-004] Pattern Write-Then-Mark pour persistance CSV - Effort: 2h

## PROBLEME
Actuellement, les delegations sont collectees en memoire (`$allDelegations`) pendant la boucle,
puis exportees dans le CSV APRES la boucle. En cas d'interruption (Ctrl+C), les donnees
collectees sont perdues car jamais ecrites sur disque.

Le checkpoint sauvegarde l'index de la derniere mailbox traitee, mais les delegations
correspondantes n'ont pas ete persistees dans le CSV.

## LOCALISATION
- Fichier : Get-ExchangeDelegation.ps1:843-891
- Fonction : Boucle principale de collecte
- Module : Script principal

## OBJECTIF
Implementer le pattern **Write-Then-Mark** :
1. Collecter les delegations d'une mailbox
2. **ECRIRE** immediatement dans le CSV (append)
3. **PUIS** marquer comme traitee dans le checkpoint

En cas d'interruption, le CSV contient toutes les donnees jusqu'a la derniere mailbox
completement traitee, et le checkpoint est coherent.

---

## IMPLEMENTATION

### Etape 1 : Collecter delegations par mailbox - 30min

Fichier : Get-ExchangeDelegation.ps1:843-886

AVANT :
```powershell
# FullAccess
$fullAccessDelegations = Get-MailboxFullAccessDelegation -Mailbox $mailbox
$statsPerType.FullAccess += $fullAccessDelegations.Count
foreach ($delegation in $fullAccessDelegations) {
    $delegation.MailboxLastLogon = $mailboxLastLogon
    $delegation.IsInactive = $isInactive
    $allDelegations.Add($delegation)
}

# SendAs
$sendAsDelegations = Get-MailboxSendAsDelegation -Mailbox $mailbox
# ... meme pattern pour chaque type
```

APRES :
```powershell
# Collecter toutes les delegations de cette mailbox
$mailboxDelegations = [System.Collections.Generic.List[PSCustomObject]]::new()

# FullAccess
$fullAccessDelegations = Get-MailboxFullAccessDelegation -Mailbox $mailbox
$statsPerType.FullAccess += $fullAccessDelegations.Count
foreach ($delegation in $fullAccessDelegations) {
    $delegation.MailboxLastLogon = $mailboxLastLogon
    $delegation.IsInactive = $isInactive
    $mailboxDelegations.Add($delegation)
}

# SendAs
$sendAsDelegations = Get-MailboxSendAsDelegation -Mailbox $mailbox
$statsPerType.SendAs += $sendAsDelegations.Count
foreach ($delegation in $sendAsDelegations) {
    $delegation.MailboxLastLogon = $mailboxLastLogon
    $delegation.IsInactive = $isInactive
    $mailboxDelegations.Add($delegation)
}

# SendOnBehalf
$sendOnBehalfDelegations = Get-MailboxSendOnBehalfDelegation -Mailbox $mailbox
$statsPerType.SendOnBehalf += $sendOnBehalfDelegations.Count
foreach ($delegation in $sendOnBehalfDelegations) {
    $delegation.MailboxLastLogon = $mailboxLastLogon
    $delegation.IsInactive = $isInactive
    $mailboxDelegations.Add($delegation)
}

# Calendar
$calendarDelegations = Get-MailboxCalendarDelegation -Mailbox $mailbox
$statsPerType.Calendar += $calendarDelegations.Count
foreach ($delegation in $calendarDelegations) {
    $delegation.MailboxLastLogon = $mailboxLastLogon
    $delegation.IsInactive = $isInactive
    $mailboxDelegations.Add($delegation)
}

# Forwarding
$forwardingDelegations = Get-MailboxForwardingDelegation -Mailbox $mailbox
$statsPerType.Forwarding += $forwardingDelegations.Count
foreach ($delegation in $forwardingDelegations) {
    $delegation.MailboxLastLogon = $mailboxLastLogon
    $delegation.IsInactive = $isInactive
    $mailboxDelegations.Add($delegation)
}
```

### Etape 2 : Write-Then-Mark - 45min

Fichier : Get-ExchangeDelegation.ps1 (apres collecte delegations)

AVANT :
```powershell
# Marquer comme traite + checkpoint periodique
if ($checkpointState) {
    Add-ProcessedItem -InputObject $mailbox -Index $i
}
```

APRES :
```powershell
# WRITE: Ecrire immediatement dans le CSV (append sans header)
if ($mailboxDelegations.Count -gt 0) {
    # Filtrer si OrphansOnly
    $dataToWrite = if ($OrphansOnly) {
        $mailboxDelegations | Where-Object { $_.IsOrphan -eq $true }
    } else {
        $mailboxDelegations
    }

    if ($dataToWrite.Count -gt 0) {
        $dataToWrite | ConvertTo-Csv -NoTypeInformation |
            Select-Object -Skip 1 |
            Add-Content -Path $exportFilePath -Encoding UTF8
    }

    # Garder en memoire pour stats et cleanup
    $allDelegations.AddRange($mailboxDelegations)
}

# MARK: Marquer comme traite + checkpoint periodique
if ($checkpointState) {
    Add-ProcessedItem -InputObject $mailbox -Index $i
}
```

### Etape 3 : Supprimer export CSV post-boucle - 30min

Fichier : Get-ExchangeDelegation.ps1:912-927

AVANT :
```powershell
# Export CSV
Write-Status -Type Action -Message "Export CSV..."

if ($allDelegations.Count -gt 0) {
    # Filtrer si OrphansOnly
    $exportData = if ($OrphansOnly) {
        $allDelegations | Where-Object { $_.IsOrphan -eq $true }
    }
    else {
        $allDelegations
    }

    if ($isAppendMode) {
        # Mode append
        $exportData | ConvertTo-Csv -NoTypeInformation |
            Select-Object -Skip 1 |
            Add-Content -Path $exportFilePath -Encoding UTF8
    }
    else {
        $exportData | Export-Csv -Path $exportFilePath -NoTypeInformation -Encoding UTF8 -WhatIf:$false
    }
}
```

APRES :
```powershell
# CSV deja ecrit pendant la boucle - juste afficher le resultat
Write-Status -Type Action -Message "Export CSV..."

if ($allDelegations.Count -gt 0) {
    $exportedCount = if ($OrphansOnly) {
        ($allDelegations | Where-Object { $_.IsOrphan -eq $true }).Count
    } else {
        $allDelegations.Count
    }

    Write-Status -Type Success -Message "Export: $exportFilePath ($exportedCount lignes)" -Indent 1
    $filterNote = if ($OrphansOnly) { " (orphelins uniquement)" } else { "" }
    Write-Log "Export CSV: $exportFilePath ($exportedCount lignes$filterNote)" -Level SUCCESS
}
else {
    Write-Status -Type Warning -Message "Aucune delegation trouvee" -Indent 1
    Write-Log "Aucune delegation a exporter" -Level WARNING
}
```

### Etape 4 : Gestion reprise (append) - 15min

En cas de reprise, le CSV existe deja avec des donnees.
Le code actuel cree le header au debut si nouvelle collecte.
En mode append, on continue a ajouter apres les donnees existantes.

**Aucun changement necessaire** - le code FEAT-010 gere deja ce cas.

---

## FLUX FINAL

```
NOUVELLE COLLECTE :
1. Creer CSV avec header
2. Boucle mailboxes :
   - Collecter delegations
   - WRITE: Append au CSV
   - MARK: Add-ProcessedItem
3. Fin: CSV complet, checkpoint supprime

INTERRUPTION (Ctrl+C) :
1. Finally: Checkpoint sauvegarde (dernier index)
2. CSV contient delegations jusqu'a derniere mailbox traitee
3. Pas de perte de donnees

REPRISE :
1. Checkpoint charge
2. CSV existant reutilise
3. Reprend a mailbox N+1
4. Continue append au CSV
```

---

## VALIDATION

### Criteres d'Acceptation
- [ ] Delegations ecrites dans CSV AVANT marquage checkpoint
- [ ] Interruption Ctrl+C ne perd pas les donnees deja collectees
- [ ] Reprise continue en append (pas de doublon)
- [ ] OrphansOnly filtre correctement pendant la boucle
- [ ] Stats finales correctes ($allDelegations.Count)
- [ ] CleanupOrphans fonctionne toujours (utilise $allDelegations)

### Tests Manuels
```powershell
# Test 1: Interruption et verification
Remove-Item .\Checkpoints\*.json, .\Output\*.csv -Force -EA Silent
.\Get-ExchangeDelegation.ps1  # Ctrl+C apres 5 mailboxes
# Verifier: CSV contient les delegations des 5 mailboxes

# Test 2: Reprise
.\Get-ExchangeDelegation.ps1  # Doit reprendre
# Verifier: CSV contient TOUTES les delegations (append)
# Verifier: Pas de header duplique

# Test 3: OrphansOnly
.\Get-ExchangeDelegation.ps1 -OrphansOnly
# Verifier: CSV ne contient que IsOrphan=True

# Test 4: CleanupOrphans
.\Get-ExchangeDelegation.ps1 -CleanupOrphans
# Verifier: Orphelins detectes et proposes a suppression
```

## CHECKLIST
- [x] Collecte delegations par mailbox (liste locale)
- [x] WRITE avant MARK
- [x] Suppression export post-boucle
- [ ] Tests manuels passes
- [ ] Code review

Labels : refactor elevee checkpoint csv persistence

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | local |
| Statut | RESOLVED |
| Branche | feature/REFACTOR-004-write-then-mark |
