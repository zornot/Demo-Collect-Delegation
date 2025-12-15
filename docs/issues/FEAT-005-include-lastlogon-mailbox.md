# [-] FEAT-005 Option -IncludeLastLogon pour date derniere connexion mailbox | Effort: 45min

## PROBLEME

Pour identifier les mailboxes inactives avec des delegations, l'utilisateur doit actuellement croiser manuellement le CSV avec d'autres rapports. La date de derniere connexion de la mailbox permettrait de prioriser le nettoyage des delegations sur les mailboxes obsoletes.

## LOCALISATION

- Fichier : Get-ExchangeDelegation.ps1:L67-75 (parametres)
- Fichier : Get-ExchangeDelegation.ps1:L323-350 (New-DelegationRecord)
- Fichier : Get-ExchangeDelegation.ps1:L651-656 (boucle mailboxes)

## OBJECTIF

Ajouter un parametre optionnel `-IncludeLastLogon` qui collecte `LastLogonTime` via `Get-MailboxStatistics` et l'ajoute au CSV.

---

## ANALYSE TECHNIQUE

### API utilisee
```powershell
Get-MailboxStatistics -Identity $mailbox.PrimarySmtpAddress -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty LastLogonTime
```

### Impact performance
- +1 appel API par mailbox (~0.3-0.5s chacun)
- Pour 100 mailboxes : +30-50s
- Optionnel via switch pour ne pas penaliser les executions rapides

### Donnees retournees
- `LastLogonTime` : DateTime de la derniere connexion (OWA, Outlook, ActiveSync, EWS)
- `$null` si jamais connecte

---

## IMPLEMENTATION

### Etape 1 : Ajouter le parametre IncludeLastLogon - 5min
Fichier : Get-ExchangeDelegation.ps1:L67-75

AVANT :
```powershell
    [Parameter(Mandatory = $false)]
    [switch]$OrphansOnly,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)
```

APRES :
```powershell
    [Parameter(Mandatory = $false)]
    [switch]$OrphansOnly,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeLastLogon,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)
```

### Etape 2 : Ajouter MailboxLastLogon a New-DelegationRecord - 10min
Fichier : Get-ExchangeDelegation.ps1:L323-350

AVANT :
```powershell
function New-DelegationRecord {
    param(
        [string]$MailboxEmail,
        [string]$MailboxDisplayName,
        [string]$TrusteeEmail,
        [string]$TrusteeDisplayName,
        [string]$DelegationType,
        [string]$AccessRights,
        [string]$FolderPath = '',
        [bool]$IsOrphan = $false
    )

    [PSCustomObject]@{
        MailboxEmail       = $MailboxEmail
        MailboxDisplayName = $MailboxDisplayName
        TrusteeEmail       = $TrusteeEmail
        TrusteeDisplayName = $TrusteeDisplayName
        DelegationType     = $DelegationType
        AccessRights       = $AccessRights
        FolderPath         = $FolderPath
        IsOrphan           = $IsOrphan
        CollectedAt        = $script:CollectionTimestamp
    }
}
```

APRES :
```powershell
function New-DelegationRecord {
    param(
        [string]$MailboxEmail,
        [string]$MailboxDisplayName,
        [string]$TrusteeEmail,
        [string]$TrusteeDisplayName,
        [string]$DelegationType,
        [string]$AccessRights,
        [string]$FolderPath = '',
        [bool]$IsOrphan = $false,
        [datetime]$MailboxLastLogon = [datetime]::MinValue
    )

    [PSCustomObject]@{
        MailboxEmail       = $MailboxEmail
        MailboxDisplayName = $MailboxDisplayName
        TrusteeEmail       = $TrusteeEmail
        TrusteeDisplayName = $TrusteeDisplayName
        DelegationType     = $DelegationType
        AccessRights       = $AccessRights
        FolderPath         = $FolderPath
        IsOrphan           = $IsOrphan
        MailboxLastLogon   = if ($MailboxLastLogon -eq [datetime]::MinValue) { '' } else { $MailboxLastLogon.ToString('o') }
        CollectedAt        = $script:CollectionTimestamp
    }
}
```

### Etape 3 : Collecter LastLogon dans la boucle mailbox - 15min
Fichier : Get-ExchangeDelegation.ps1 (boucle foreach mailbox ~L670)

Ajouter au debut de la boucle :
```powershell
# Collecter LastLogon si demande
$mailboxLastLogon = [datetime]::MinValue
if ($IncludeLastLogon) {
    $stats = Get-MailboxStatistics -Identity $mailbox.PrimarySmtpAddress -ErrorAction SilentlyContinue
    if ($stats -and $stats.LastLogonTime) {
        $mailboxLastLogon = $stats.LastLogonTime
    }
}
```

### Etape 4 : Passer MailboxLastLogon aux fonctions de collecte - 10min

Modifier les appels dans la boucle pour passer `$mailboxLastLogon` et le propager jusqu'a `New-DelegationRecord`.

### Etape 5 : Mettre a jour l'aide du script - 5min

Ajouter :
```powershell
.PARAMETER IncludeLastLogon
    Ajouter la date de derniere connexion de la mailbox au CSV.
    Impact performance : +1 appel API par mailbox.
```

Et exemple :
```powershell
.EXAMPLE
    .\Get-ExchangeDelegation.ps1 -IncludeLastLogon
    Collecte avec la date de derniere connexion de chaque mailbox.
```

---

## VALIDATION

### Criteres d'Acceptation

- [x] Parametre `-IncludeLastLogon` disponible
- [x] Sans `-IncludeLastLogon`, colonne MailboxLastLogon vide
- [x] Avec `-IncludeLastLogon`, colonne contient datetime ISO ou vide
- [x] Aide du script mise a jour
- [x] Pas de regression sur le comportement existant

---

## DEPENDANCES

- Bloquee par : Aucune
- Bloque : Aucune

## POINTS ATTENTION

- 1 fichier modifie
- ~30 lignes ajoutees
- Impact performance : +0.3-0.5s par mailbox (optionnel)
- Risques : Aucun - parametre optionnel

## CHECKLIST

- [x] Code AVANT = code reel verifie
- [x] Tests passent
- [x] Code review

Labels : feat faible export performance

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | # |
| Statut | RESOLVED |
| Branche | feature/FEAT-005-include-lastlogon-mailbox |
