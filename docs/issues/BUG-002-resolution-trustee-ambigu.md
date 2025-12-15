# BUG-002 - Resolution des trustees ambigus

## GitHub Issue
#2 (CLOSED)

## Type
BUG → RESOLVED

## Statut
CLOSED

## Description

Quand `Get-Recipient` recoit un DisplayName ambigu (plusieurs destinataires avec le meme nom), il echoue avec l'erreur :
```
'Issam KHOULANI' ne représente pas un destinataire unique
```

## Cause

Exchange stocke parfois le **DisplayName** au lieu de l'email dans les permissions. Si plusieurs personnes ont le meme nom, `Get-Recipient` ne peut pas determiner laquelle est la bonne.

## Solution

Creer une fonction `Resolve-TrusteeInfo` qui :
1. Tente la resolution standard avec Get-Recipient
2. En cas d'echec (ambigu ou introuvable), retourne l'identite brute comme fallback
3. Log le cas en niveau DEBUG (pas WARNING)

```powershell
function Resolve-TrusteeInfo {
    param([string]$Identity)

    try {
        $recipient = Get-Recipient -Identity $Identity -ErrorAction Stop
        return @{ Email = $recipient.PrimarySmtpAddress; Resolved = $true }
    }
    catch {
        # Fallback: retourner l'identite brute
        return @{ Email = $Identity; Resolved = $false }
    }
}
```

## Fichiers Modifies

| Fichier | Modification |
|---------|--------------|
| Get-ExchangeDelegation.ps1 | Ajout Resolve-TrusteeInfo (L168-216) |
| Get-ExchangeDelegation.ps1 | Maj Get-MailboxFullAccessDelegation (L264) |
| Get-ExchangeDelegation.ps1 | Maj Get-MailboxSendAsDelegation (L301) |
| Get-ExchangeDelegation.ps1 | Maj Get-MailboxSendOnBehalfDelegation (L336) |

## Comportement

| Avant | Apres |
|-------|-------|
| WARNING + delegation ignoree | DEBUG + delegation avec DisplayName brut |

## Criteres d'Acceptation

- [x] Fonction Resolve-TrusteeInfo creee
- [x] Fonctions Get-Mailbox* mises a jour
- [x] Tests passes (35/35)
- [x] Erreur reduite de WARNING a DEBUG

## Priorite

P2 - Resolu

## Labels

`bug`, `exchange-online`, `resolved`
