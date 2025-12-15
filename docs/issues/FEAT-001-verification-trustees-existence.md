# FEAT-001 - Detection des delegations orphelines

## Type
BUG → RESOLVED

## Statut
RESOLVED

## Description

Les delegations vers des comptes supprimes (trustees orphelins) etaient filtrees par erreur et n'apparaissaient pas dans le rapport CSV.

### Probleme Initial

Le pattern `^S-1-5-` dans `$script:SystemAccountPatterns` filtrait **tous** les SIDs, y compris les trustees orphelins (`S-1-5-21-*`).

### Solution Implementee

Remplacer le pattern generique par des patterns specifiques pour les comptes systeme uniquement :

```powershell
# AVANT (bug)
'^S-1-5-',                # Filtrait AUSSI les S-1-5-21-* (orphelins)

# APRES (corrige)
'^S-1-5-10$',             # SELF
'^S-1-5-18$',             # SYSTEM
'^S-1-5-19$',             # LOCAL SERVICE
'^S-1-5-20$',             # NETWORK SERVICE
# S-1-5-21-* (comptes utilisateurs/orphelins) ne sont PAS filtres
```

## Sources Microsoft

- [Remove-MailboxPermission - BypassMasterAccountSid](https://learn.microsoft.com/en-us/powershell/module/exchange/remove-mailboxpermission?view=exchange-ps)
- [Orphaned SID preventing mailbox delegation](https://learn.microsoft.com/en-us/answers/questions/1164214/orphaned-sid-preventing-mailbox-delegation-to-spec)
- [Send as rights removed (Nov 2025)](https://learn.microsoft.com/en-us/answers/questions/5625289/send-as-rights-removed-from-shared-mailbox)

## Fichiers Modifies

| Fichier | Modification |
|---------|--------------|
| Get-ExchangeDelegation.ps1 | Patterns SID specifiques (L100-105) |
| Tests/Unit/Get-ExchangeDelegation.Tests.ps1 | Tests pour orphelins |
| README.md | Documentation detection orphelins |

## Criteres d'Acceptation

- [x] Delegations orphelines visibles dans le CSV (TrusteeEmail = SID)
- [x] Comptes systeme toujours filtres (S-1-5-10, S-1-5-18, etc.)
- [x] Tests unitaires passes (35/35)
- [x] README documente la detection des orphelins

## Comment Identifier les Orphelins

```powershell
# Filtrer les delegations orphelines dans le CSV
Import-Csv "ExchangeDelegations_*.csv" | Where-Object { $_.TrusteeEmail -match '^S-1-5-21' }
```

## Note sur -VerifyTrustees (Non Implemente)

La feature `-VerifyTrustees` initialement proposee n'est **pas necessaire** car :
1. Les orphelins sont identifiables directement par leur pattern SID
2. Pas besoin d'appels API supplementaires
3. Filtrage simple dans Excel/PowerShell

## Priorite

P2 - Resolu

## Labels

`bug`, `exchange-online`, `security`, `audit`, `resolved`
