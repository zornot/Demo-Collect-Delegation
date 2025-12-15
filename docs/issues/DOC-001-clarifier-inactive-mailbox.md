# [-] DOC-001 - Clarifier documentation -IncludeInactive (types de mailbox inactives) - Effort: 15min

## PROBLEME

La documentation du parametre `-IncludeInactive` ne precise pas ce qu'est une "mailbox inactive". L'utilisateur ne sait pas s'il s'agit de soft-deleted, litigation hold, retention policy, etc.

**Impact** : Confusion utilisateur, mauvaise comprehension du scope de collecte.

## LOCALISATION

- Fichier : Get-ExchangeDelegation.ps1 (section .PARAMETER IncludeInactive)
- Fichier : README.md (section Parametres)

## OBJECTIF

Documenter clairement les types de mailboxes couvertes par `-IncludeInactive` :
- Mailboxes avec Litigation Hold
- Mailboxes avec Microsoft 365 Retention Policy
- Mailboxes soft-deleted (periode 30 jours)
- Mailboxes avec eDiscovery Hold (deprecated)

---

## ANALYSE

### Sources Microsoft

| Type de Hold | Statut | Effet |
|--------------|--------|-------|
| **Litigation Hold** | Supporte | Preserve tout le contenu |
| **Microsoft 365 Retention** | Recommande | ComplianceTagHoldApplied = True |
| **In-Place Hold** | Retire (2020) | Legacy, ne plus utiliser |
| **eDiscovery Hold** | Retire (Aug 2025) | Classic eDiscovery retire |

### Definition technique

Une mailbox devient **inactive** quand :
1. Un hold est applique (Litigation, Retention, eDiscovery)
2. Le compte utilisateur Microsoft 365 est supprime
3. Exchange Online detecte le hold et garde la mailbox en "soft-deleted"

Reference : [Microsoft Learn - Inactive Mailboxes](https://learn.microsoft.com/en-us/purview/change-the-hold-duration-for-an-inactive-mailbox)

### Commande API utilisee

```powershell
Get-EXOMailbox -InactiveMailboxOnly -ResultSize Unlimited
```

---

## IMPLEMENTATION

### Etape 1 : Mettre a jour .PARAMETER IncludeInactive - 5min

Fichier : Get-ExchangeDelegation.ps1

AVANT :
```powershell
.PARAMETER IncludeInactive
    Inclure les mailboxes inactives dans la collecte.
```

APRES :
```powershell
.PARAMETER IncludeInactive
    Inclure les mailboxes inactives (soft-deleted avec hold) dans la collecte.
    Une mailbox devient inactive quand le compte M365 est supprime mais un hold existe :
    - Litigation Hold (LitigationHoldEnabled)
    - Microsoft 365 Retention Policy (ComplianceTagHoldApplied)
    - eDiscovery Hold (legacy)
    Utile pour auditer les delegations sur comptes d'anciens employes.
```

### Etape 2 : Ajouter exemple explicatif - 5min

Fichier : Get-ExchangeDelegation.ps1 (section .EXAMPLE)

AJOUTER :
```powershell
.EXAMPLE
    .\Get-ExchangeDelegation.ps1 -IncludeInactive
    Collecte UserMailbox actives + inactives (ex-employes avec Litigation Hold).
```

### Etape 3 : Mettre a jour README - 5min

Fichier : README.md (tableau Parametres)

AVANT :
```
| `-IncludeInactive` | switch | - | Inclure les mailboxes inactives |
```

APRES :
```
| `-IncludeInactive` | switch | - | Inclure les mailboxes inactives (soft-deleted avec Litigation/Retention Hold) |
```

---

## VALIDATION

### Criteres d'Acceptation

- [ ] Get-Help affiche la definition complete des mailboxes inactives
- [ ] README mentionne Litigation Hold / Retention
- [ ] Exemple explicite dans la section .EXAMPLE
- [ ] Pas de regression fonctionnelle

## CHECKLIST

- [ ] Documentation .PARAMETER a jour
- [ ] README a jour
- [ ] Exemple ajoute

Labels : documentation parameters user-experience

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | # (apres gh issue create) |
| Statut | DRAFT |
| Branche | feature/DOC-001-clarifier-inactive-mailbox |
