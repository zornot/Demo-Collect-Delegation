# [!] BUG-011 - LastLogon UPN mismatch - Effort: 15min

## PROBLEME

Le parametre `-IncludeLastLogon` ne retourne jamais de valeur car :
1. `UserPrincipalName` n'est pas recupere par `Get-EXOMailbox -Properties`
2. `PrimarySmtpAddress` est passe a `Get-MailboxLastLogon` au lieu de l'UPN
3. Le cache Graph Reports utilise l'UPN comme cle

Resultat : 100% des delegations ont `MailboxLastLogon` vide.

## LOCALISATION

- Fichier : Get-ExchangeDelegation.ps1
- Zones : L1009 (Get-EXOMailbox), L1017 (inactive), L1168 (appel fonction)
- Module : Script principal

## OBJECTIF

Recuperer `UserPrincipalName` depuis EXO et l'utiliser pour le lookup dans le cache Graph.

---

## IMPLEMENTATION

### Etape 1 : Ajouter UserPrincipalName aux proprietes mailboxes actives - 5min

Fichier : Get-ExchangeDelegation.ps1

AVANT (L1009) :
```powershell
$allMailboxes = Get-EXOMailbox -ResultSize Unlimited -RecipientTypeDetails $mailboxTypes -Properties DisplayName, PrimarySmtpAddress, ExchangeObjectId, RecipientTypeDetails, GrantSendOnBehalfTo, ForwardingAddress, ForwardingSmtpAddress
```

APRES :
```powershell
$allMailboxes = Get-EXOMailbox -ResultSize Unlimited -RecipientTypeDetails $mailboxTypes -Properties DisplayName, PrimarySmtpAddress, UserPrincipalName, ExchangeObjectId, RecipientTypeDetails, GrantSendOnBehalfTo, ForwardingAddress, ForwardingSmtpAddress
```

### Etape 2 : Ajouter UserPrincipalName aux proprietes mailboxes inactives - 5min

Fichier : Get-ExchangeDelegation.ps1

AVANT (L1017) :
```powershell
$inactiveMailboxes = Get-EXOMailbox -InactiveMailboxOnly -ResultSize Unlimited -Properties DisplayName, PrimarySmtpAddress, ExchangeObjectId, RecipientTypeDetails, GrantSendOnBehalfTo, ForwardingAddress, ForwardingSmtpAddress
```

APRES :
```powershell
$inactiveMailboxes = Get-EXOMailbox -InactiveMailboxOnly -ResultSize Unlimited -Properties DisplayName, PrimarySmtpAddress, UserPrincipalName, ExchangeObjectId, RecipientTypeDetails, GrantSendOnBehalfTo, ForwardingAddress, ForwardingSmtpAddress
```

### Etape 3 : Utiliser UserPrincipalName pour le lookup - 5min

Fichier : Get-ExchangeDelegation.ps1

AVANT (L1168) :
```powershell
            $mailboxLastLogon = Get-MailboxLastLogon -UserPrincipalName $mailbox.PrimarySmtpAddress
```

APRES :
```powershell
            # UserPrincipalName pour Graph cache, fallback sur PrimarySmtpAddress si null
            $upnForLookup = if ($mailbox.UserPrincipalName) { $mailbox.UserPrincipalName } else { $mailbox.PrimarySmtpAddress }
            $mailboxLastLogon = Get-MailboxLastLogon -UserPrincipalName $upnForLookup
```

---

## VALIDATION

### Criteres d'Acceptation

- [ ] `UserPrincipalName` recupere pour toutes les mailboxes
- [ ] Lookup utilise UPN (pas PrimarySmtpAddress)
- [ ] UserMailbox avec activite Graph ont `MailboxLastLogon` rempli
- [ ] SharedMailbox restent vides (limitation API Graph connue)
- [ ] Fallback sur PrimarySmtpAddress si UPN null

### Test Manuel

```powershell
.\Get-ExchangeDelegation.ps1 -IncludeLastLogon -Verbose
# Verifier dans le CSV que les UserMailbox ont des dates
```

## CHECKLIST

- [x] Code AVANT = code reel (verifie via analyze-bug)
- [ ] Tests passent
- [ ] Code review

Labels : bug ! lastlogon graph upn

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | local |
| Statut | CLOSED |
| Branche | fix/BUG-011-lastlogon-upn-mismatch |
| Commit | 574f932 |
