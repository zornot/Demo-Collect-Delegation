# ~ DOC-002-lastlogontime-limitation-documentation - Effort: 30min

<!-- Priorite: ~ (moyenne) - Documentation non bloquante -->

## PROBLEME

Le parametre `-IncludeLastLogon` utilise `Get-EXOMailboxStatistics.LastLogonTime` qui inclut
les acces par les assistants de mailbox (processus automatiques Exchange), pas uniquement les
connexions utilisateur reelles. Cela peut donner une fausse impression d'activite sur des
mailboxes inactives. De plus, la valeur a un delai de mise a jour de 24-48h.

## LOCALISATION

- Fichier : Get-ExchangeDelegation.ps1:L34-36
- Section : Comment-based help (.PARAMETER IncludeLastLogon)
- Module : Script principal

## OBJECTIF

Ajouter un avertissement dans la documentation du parametre `-IncludeLastLogon` pour informer
les utilisateurs de cette limitation connue et suggerer l'alternative Graph API pour les cas
necessitant une precision accrue.

---

## IMPLEMENTATION

### Etape 1 : Mettre a jour le comment-based help - 20min

Fichier : Get-ExchangeDelegation.ps1

AVANT :
```powershell
.PARAMETER IncludeLastLogon
    Ajouter la date de derniere connexion de la mailbox au CSV.
    Impact performance : +1 appel API (Get-EXOMailboxStatistics) par mailbox.
```

APRES :
```powershell
.PARAMETER IncludeLastLogon
    Ajouter la date de derniere connexion de la mailbox au CSV.
    Impact performance : +1 appel API (Get-EXOMailboxStatistics) par mailbox.

    LIMITATION CONNUE: LastLogonTime inclut les acces par les assistants de mailbox
    (processus automatiques Exchange), pas uniquement les connexions utilisateur reelles.
    Delai de mise a jour: 24-48h.

    Pour une precision accrue, considerez Microsoft Graph signInActivity
    (necessite Azure AD P1/P2).
```

### Etape 2 : Ajouter un message informatif a l'execution - 10min

Fichier : Get-ExchangeDelegation.ps1 (bloc Begin, apres validation parametres)

AVANT :
```powershell
# Pas de message specifique pour IncludeLastLogon
```

APRES :
```powershell
if ($IncludeLastLogon) {
    Write-Log "Note: LastLogonTime inclut les acces par assistants de mailbox, pas uniquement les connexions utilisateur" -Level Info
}
```

---

## VALIDATION

### Criteres d'Acceptation

- [ ] Documentation du parametre mise a jour avec l'avertissement
- [ ] `Get-Help .\Get-ExchangeDelegation.ps1 -Parameter IncludeLastLogon` affiche la limitation
- [ ] Message informatif affiche a l'execution avec -IncludeLastLogon
- [ ] Pas de regression fonctionnelle

## CHECKLIST

- [x] Code AVANT = code reel (verifie 2025-12-23)
- [ ] Tests passent
- [ ] Code review

Labels : doc ~ documentation limitation

---

## ANNEXE : Recherche Technique (2025-12-23)

### Sources Consultees

| Source | Information |
|--------|-------------|
| [Office365ITpros - Graph Usage Data](https://office365itpros.com/2023/11/21/graph-usage-data-mailboxes/) | Graph 4x plus rapide |
| [Practical365 - Mailbox Statistics](https://practical365.com/report-exchange-mailbox-statistics/) | Performance Get-EXOMailboxStatistics |

### Alternatives Identifiees

| Methode | Performance | Precision | Recommandation |
|---------|-------------|-----------|----------------|
| Get-EXOMailboxStatistics.LastLogonTime | Lente (1/mailbox) | Inexacte (inclut assistants) | Actuel - a documenter |
| Get-MgUser -Property SignInActivity | Moyenne | Bonne (delai 2-3j) | Recommandee Microsoft |
| Graph Reports API (getEmailActivityUserDetail) | 4x plus rapide | Bonne | Meilleure performance |

---

## EVOLUTION FUTURE (hors scope)

Pour une version future, considerer :
- Option `-UseGraphAPI` pour basculer sur signInActivity
- Necessite Azure AD P1/P2 (cout supplementaire)
- Issue separee si decide d'implementer

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | # (apres gh issue create) |
| Statut | DRAFT |
| Branche | feature/DOC-002-lastlogontime-limitation |
