# [ ] FEAT-008 - Parametre -IncludeInactive pour boites desactivees | Effort: 30min

## PROBLEME

Le script ne collecte que les boites aux lettres actives. Les boites desactivees (soft-deleted, inactive) ne sont pas incluses, ce qui peut manquer des delegations importantes sur des comptes en cours de depart ou en retention legale.

Types de boites non collectees actuellement :
- **Soft-deleted** : Boites supprimees (retention 30 jours)
- **Inactive** : Boites en retention legale (litigation hold, eDiscovery)

## LOCALISATION

- Fichier : Get-ExchangeDelegation.ps1
- Lignes : 694-701 (construction $mailboxTypes et Get-EXOMailbox)
- Fonction : Main script block

## OBJECTIF

Ajouter un parametre `-IncludeInactive` pour inclure les boites inactives dans la collecte.

---

## ANALYSE IMPACT

### Fichiers Impactes
| Fichier | Raison | Action Requise |
|---------|--------|----------------|
| Get-ExchangeDelegation.ps1 | Parametre + logique | Ajouter param + appels API |

### Considerations
- Les boites soft-deleted n'ont plus de delegations actives (inutile)
- Les boites inactives conservent leurs delegations (utile pour audit)
- Impact performance : +1 appel Get-EXOMailbox supplementaire

---

## IMPLEMENTATION

### Etape 1 : Ajouter le parametre - 5min
Fichier : Get-ExchangeDelegation.ps1
Section param() - AJOUTER

```powershell
[Parameter()]
[switch]$IncludeInactive
```

### Etape 2 : Modifier la recuperation des mailboxes - 20min
Fichier : Get-ExchangeDelegation.ps1
Lignes 692-704 - MODIFIER

AVANT :
```powershell
$mailboxTypes = @('UserMailbox')
if ($IncludeSharedMailbox) { $mailboxTypes += 'SharedMailbox' }
if ($IncludeRoomMailbox) { $mailboxTypes += 'RoomMailbox' }

Write-Status -Type Info -Message "Types inclus: $($mailboxTypes -join ', ')" -Indent 1

$allMailboxes = Get-EXOMailbox -ResultSize Unlimited -RecipientTypeDetails $mailboxTypes -Properties DisplayName, PrimarySmtpAddress, GrantSendOnBehalfTo, ForwardingAddress, ForwardingSmtpAddress
```

APRES :
```powershell
$mailboxTypes = @('UserMailbox')
if ($IncludeSharedMailbox) { $mailboxTypes += 'SharedMailbox' }
if ($IncludeRoomMailbox) { $mailboxTypes += 'RoomMailbox' }

Write-Status -Type Info -Message "Types inclus: $($mailboxTypes -join ', ')" -Indent 1

# Mailboxes actives
$allMailboxes = Get-EXOMailbox -ResultSize Unlimited -RecipientTypeDetails $mailboxTypes -Properties DisplayName, PrimarySmtpAddress, GrantSendOnBehalfTo, ForwardingAddress, ForwardingSmtpAddress

# Mailboxes inactives (si demande)
if ($IncludeInactive) {
    Write-Status -Type Info -Message "Inclusion des mailboxes inactives..." -Indent 1
    $inactiveMailboxes = Get-EXOMailbox -InactiveMailboxOnly -ResultSize Unlimited -Properties DisplayName, PrimarySmtpAddress, GrantSendOnBehalfTo, ForwardingAddress, ForwardingSmtpAddress
    $allMailboxes = @($allMailboxes) + @($inactiveMailboxes)
    Write-Status -Type Info -Message "$($inactiveMailboxes.Count) mailboxes inactives ajoutees" -Indent 2
}
```

### Etape 3 : Ajouter colonne IsInactive au CSV - 5min

Ajouter une propriete pour identifier les boites inactives dans l'export :

```powershell
$isInactive = $mailbox.ExchangeObjectId -in $inactiveMailboxes.ExchangeObjectId
```

---

## VALIDATION

### Criteres d'Acceptation
- [ ] Parametre -IncludeInactive ajoute
- [ ] Boites inactives recuperees si parametre present
- [ ] Colonne IsInactive dans le CSV
- [ ] Sans parametre : comportement inchange
- [ ] Documentation mise a jour

## CHECKLIST
- [ ] Code AVANT = code reel verifie
- [ ] Tests manuels effectues
- [ ] Documentation mise a jour

Labels : feature exchange mailbox effort-30min

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | # |
| Statut | RESOLVED |
| Branche | feature/FEAT-008-include-inactive-mailboxes |
