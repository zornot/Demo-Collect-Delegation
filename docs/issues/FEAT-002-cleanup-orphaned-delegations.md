# FEAT-002 - Nettoyage des delegations orphelines

## GitHub Issue
#3 (CLOSED)

## Type
FEATURE → RESOLVED

## Statut
CLOSED

## Description

Ajouter un parametre `-CleanupOrphans` au script `Get-ExchangeDelegation.ps1` pour supprimer automatiquement les delegations vers des comptes supprimes (SIDs orphelins).

## Contexte

Les delegations orphelines (trustees supprimes) apparaissent avec un SID `S-1-5-21-*` dans le rapport CSV. Ces delegations :
- N'ont plus d'utilite (le compte n'existe plus)
- Peuvent poser des problemes de securite (audit)
- Doivent etre nettoyees manuellement

## Solution Proposee

### Nouveau Parametre

```powershell
[CmdletBinding(SupportsShouldProcess)]
param(
    # ... parametres existants ...

    [Parameter()]
    [switch]$CleanupOrphans
)
```

### Comportement

| Mode | Action |
|------|--------|
| Sans `-CleanupOrphans` | Collecte uniquement (comportement actuel) |
| Avec `-CleanupOrphans` | Collecte + suppression des orphelins |
| Avec `-CleanupOrphans -WhatIf` | Simulation (affiche ce qui serait supprime) |

### Commandes de Suppression par Type

| DelegationType | Commande |
|----------------|----------|
| FullAccess | `Remove-MailboxPermission -Identity $mailbox -User $SID -AccessRights FullAccess -Confirm:$false` |
| SendAs | `Remove-RecipientPermission -Identity $mailbox -Trustee $SID -AccessRights SendAs -Confirm:$false` |
| SendOnBehalf | `Set-Mailbox -Identity $mailbox -GrantSendOnBehalfTo @{Remove=$SID}` |
| Calendar | `Remove-MailboxFolderPermission -Identity "$mailbox:\Calendar" -User $SID -Confirm:$false` |

### Nouvelle Fonction

```powershell
function Remove-OrphanedDelegation {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Delegation
    )

    $mailbox = $Delegation.MailboxEmail
    $trustee = $Delegation.TrusteeEmail
    $type = $Delegation.DelegationType

    if ($PSCmdlet.ShouldProcess("$mailbox -> $trustee", "Remove $type delegation")) {
        switch ($type) {
            'FullAccess' {
                Remove-MailboxPermission -Identity $mailbox -User $trustee `
                    -AccessRights FullAccess -Confirm:$false -ErrorAction Stop
            }
            'SendAs' {
                Remove-RecipientPermission -Identity $mailbox -Trustee $trustee `
                    -AccessRights SendAs -Confirm:$false -ErrorAction Stop
            }
            'SendOnBehalf' {
                Set-Mailbox -Identity $mailbox -GrantSendOnBehalfTo @{Remove=$trustee} `
                    -ErrorAction Stop
            }
            'Calendar' {
                Remove-MailboxFolderPermission -Identity "$mailbox:\Calendar" `
                    -User $trustee -Confirm:$false -ErrorAction Stop
            }
        }
        return $true
    }
    return $false
}
```

### Flux d'Execution

```
1. Collecter toutes les delegations (existant)
2. Identifier les orphelins (TrusteeEmail -match '^S-1-5-21')
3. Pour chaque orphelin :
   - Afficher [>] Suppression $type sur $mailbox...
   - Appeler Remove-OrphanedDelegation
   - Si succes: [+] Supprime
   - Si echec: [-] Erreur + log WARNING
4. Afficher resume : X orphelins supprimes / Y total
```

## Fichiers a Modifier

| Fichier | Modification |
|---------|--------------|
| Get-ExchangeDelegation.ps1 | Parametre + fonction + logique cleanup |

## Criteres d'Acceptation

- [ ] Parametre `-CleanupOrphans` ajoute
- [ ] Support `-WhatIf` pour simulation
- [ ] Fonction `Remove-OrphanedDelegation` implementee
- [ ] Gestion des 4 types de delegation
- [ ] Resume affiche (X supprimes / Y total)
- [ ] Erreurs loguees en WARNING (pas bloquantes)

## Securite

- `-WhatIf` par defaut recommande pour premiere utilisation
- `-Confirm:$false` sur les commandes Remove (deja confirme par ShouldProcess)
- Log de chaque suppression

## Estimation

| Tache | Effort |
|-------|--------|
| Parametre + ShouldProcess | 15min |
| Fonction Remove-OrphanedDelegation | 30min |
| Integration boucle principale | 30min |
| Tests manuels | 15min |
| **Total** | **1h30** |

## Priorite

P2 - Utile pour maintenance/audit

## Labels

`feature`, `exchange-online`, `cleanup`
