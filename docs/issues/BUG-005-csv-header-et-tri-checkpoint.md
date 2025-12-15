# BUG-005 : Header CSV inversé et tri checkpoint manquant

## Statut
CLOSED

## Problème

Deux bugs liés au système de checkpoint introduits lors de l'implémentation Write-Then-Mark :

### Bug 1 : Header CSV inversé
Le header CSV manuel (ligne 806) avait les colonnes `IsInactive` et `MailboxLastLogon` dans le mauvais ordre par rapport à `New-DelegationRecord` :

```powershell
# Header (FAUX):
'MailboxLastLogon', 'IsInactive', 'CollectedAt'

# New-DelegationRecord (lignes 414-415):
IsInactive         = $IsInactive      # Position 9
MailboxLastLogon   = $MailboxLastLogon # Position 10
```

**Impact** : Les données étaient décalées - IsInactive contenait des dates, MailboxLastLogon contenait des booléens.

### Bug 2 : Tri stable manquant
`Get-EXOMailbox` ne garantit pas l'ordre des résultats. Lors d'une reprise checkpoint, le `StartIndex` pointait vers une mailbox différente si l'ordre avait changé.

**Impact** : Des mailboxes étaient sautées (ex: `business@it-metrics.io`, `lou.deschamps@it-metrics.cloud`).

## Solution

### Fix 1 : Corriger l'ordre du header (ligne 806)
```powershell
'IsInactive', 'MailboxLastLogon', 'CollectedAt'
```

### Fix 2 : Trier les mailboxes (après ligne 735)
```powershell
$allMailboxes = $allMailboxes | Sort-Object -Property PrimarySmtpAddress
```

## Validation

Export 182926.csv comparé à la référence 125839 :
- ✅ 64 lignes (identique)
- ✅ 16 mailboxes (toutes présentes)
- ✅ Colonnes alignées correctement
- ✅ Tri alphabétique respecté
- ✅ 15 orphelins (identique)

## Fichiers modifiés

- `Get-ExchangeDelegation.ps1` : lignes 737-739 (tri) et 806 (header)
