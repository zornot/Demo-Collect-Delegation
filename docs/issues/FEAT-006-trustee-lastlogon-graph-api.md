# [-] [FEAT-006] TrusteeLastLogon via Graph API | Effort: 1h30 | ABANDONNEE

## PROBLEME

Le script Get-ExchangeDelegation.ps1 collecte `MailboxLastLogon` (date connexion du proprietaire) mais pas `TrusteeLastLogon` (date connexion du delegue qui possede les permissions). Cette information permettrait d'identifier les delegations vers des comptes inactifs.

## LOCALISATION
- Fichier : Get-ExchangeDelegation.ps1
- Fonction : New-DelegationRecord, section export
- Module : Script principal

## OBJECTIF INITIAL

Ajouter une colonne `TrusteeLastLogon` dans l'export CSV indiquant la derniere connexion de chaque delegue.

---

## RECHERCHE APPROFONDIE

### Methodes Identifiees

| Methode | Fiabilite | Prerequis | Verdict |
|---------|-----------|-----------|---------|
| **Get-MailboxStatistics** | FAIBLE | Aucun | `LastUserActionTime` DEPRECATED 2025, `LastLogonTime` inclut acces systeme (~30% faux positifs) |
| **Microsoft Graph signInActivity** | EXCELLENTE | Azure AD Premium P1/P2 (~6 USD/user/mois) | Seule methode fiable, mais licence obligatoire |
| **M365 Admin Center** | MOYENNE | Aucun | Interface GUI uniquement, non programmable |

### Details Techniques

#### 1. Exchange PowerShell (Get-MailboxStatistics)

**Proprietes disponibles :**
- `LastLogonTime` : Inclut les acces des services systeme (background sync, assistants) - **NON FIABLE** (~30% inflation)
- `LastUserActionTime` : **DEPRECATED par Microsoft en 2025** - date de retrait non annoncee

**Sources :**
- [Get-MailboxStatistics Documentation](https://learn.microsoft.com/en-us/powershell/module/exchangepowershell/get-mailboxstatistics)
- [Why LastLogonTime is Wrong - Petri](https://petri.com/get-mailboxstatistics-cmdlet-wrong/)
- [New Properties Added - Vasil Michev](https://michev.info/blog/post/2408/new-properties-added-to-get-mailboxstatistics-output)

#### 2. Microsoft Graph API (signInActivity)

**Propriete recommandee :** `lastSuccessfulSignInDateTime` (disponible depuis Dec 2023)

**Prerequis obligatoires :**
- Licence Azure AD Premium P1 ou P2 sur TOUS les comptes utilisateurs
- Permissions API : `User.Read.All` + `AuditLog.Read.All` (admin consent requis)
- Module : `Microsoft.Graph.Users`

**Cout :** ~6 USD/user/mois = 150 USD/mois pour 25 utilisateurs

**Sources :**
- [signInActivity Resource Type](https://learn.microsoft.com/en-us/graph/api/resources/signinactivity)
- [Graph API lastSuccessfulSignInDateTime](https://www.thelazyadministrator.com/2023/12/09/microsoft-graph-api-endpoint-adds-last-successful-sign-in-date-time/)

#### 3. M365 Admin Center

Interface GUI uniquement - export manuel CSV possible mais non programmable.

---

## DECISION : ABANDONNEE

### Justification

| Critere | Evaluation |
|---------|------------|
| **Cout** | Azure AD Premium P1 requis = 150 USD/mois pour 25 users |
| **ROI** | Faible - metrique "nice-to-have", pas critique pour audit delegations |
| **Complexite** | +30 lignes code, nouvelle dependance module Graph |
| **Baseline actuelle** | Script performant (1:33 pour 25 mailboxes), MailboxLastLogon deja implemente |
| **Methodes gratuites** | Non fiables (deprecated ou donnees incorrectes) |

### Alternative Recommandee

L'utilisateur peut consulter manuellement :
- **Azure AD Portal** > Users > [Utilisateur] > Sign-in logs
- **M365 Admin Center** > Reports > Usage > Active users

Cette information est disponible gratuitement via l'interface d'administration.

---

## IMPLEMENTATION

Non applicable - issue abandonnee.

### Code de Reference (si implementation future)

Si la licence Azure AD Premium devient disponible, utiliser ce pattern :

```powershell
function Get-TrusteeLastLogon {
    [CmdletBinding()]
    param([string[]]$UserPrincipalNames)

    # Prerequis : Connect-MgGraph -Scopes "User.Read.All","AuditLog.Read.All"
    $results = @{}

    foreach ($upn in $UserPrincipalNames) {
        try {
            $user = Get-MgUser -UserId $upn -Property "signInActivity" -ErrorAction Stop
            $lastLogon = $user.SignInActivity.LastSuccessfulSignInDateTime
            $results[$upn] = if ($lastLogon) {
                ([DateTime]$lastLogon).ToString('dd/MM/yyyy HH:mm')
            } else {
                'Jamais connecte'
            }
        }
        catch {
            $results[$upn] = 'Erreur'
        }
    }
    return $results
}
```

**Note :** Implementer avec batching (max 20 users/batch) pour eviter throttling.

---

## VALIDATION

Non applicable - issue abandonnee.

---

## DEPENDANCES
- Bloquee par : Aucune
- Bloque : Aucune

## POINTS ATTENTION
- Recherche approfondie effectuee le 2025-12-15
- 3 methodes evaluees, aucune gratuite et fiable
- Decision documentee pour reference future

## CHECKLIST
- [x] Recherche technique effectuee
- [x] Alternatives evaluees
- [x] Decision documentee
- [x] Code de reference fourni pour implementation future

Labels : feat faible abandonnee recherche

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | #11 |
| Statut | **ABANDONNEE** |
| Branche | N/A |
