# [!] FEAT-013 - LastLogon via Graph Reports API - Effort: 3h

## PROBLEME

Le parametre `-IncludeLastLogon` utilise `Get-EXOMailboxStatistics.LastLogonTime` qui :
- Inclut les acces par assistants de mailbox (faux positifs)
- Delai de mise a jour 24-48h
- Performance lente (1 appel API/mailbox)

## LOCALISATION

- Fichier : Get-ExchangeDelegation.ps1
- Zones : Parametres (L86-130), Get-MailboxLastLogon (L296-330), boucle principale
- Module : Script principal + MgConnection

## OBJECTIF

Remplacer `Get-EXOMailboxStatistics.LastLogonTime` par `Graph Reports API (getEmailActivityUserDetail)` qui fournit :
- `Last Activity Date` : activite email reelle (pas les assistants)
- Performance : 1 seul appel batch pour tous les utilisateurs
- Precision : donnees fiables sans faux positifs

---

## DESIGN

### Objectif

Utiliser Microsoft Graph Reports API pour obtenir la derniere activite email de chaque utilisateur, eliminant les faux positifs des assistants de mailbox.

### Architecture

- **Module concerne** : Get-ExchangeDelegation.ps1 (fonction existante modifiee)
- **Dependances** : Module MgConnection (existant), Microsoft.Graph.Reports
- **Impact** : Remplacement de Get-EXOMailboxStatistics par Invoke-MgGraphRequest
- **Pattern** : Cache batch (1 appel Graph pour tous les users) + lookup par UPN

### Permissions Requises

| Permission | Type | Usage |
|------------|------|-------|
| `Reports.Read.All` | Application ou Delegue | Lecture rapports activite email |

**Note** : Pas besoin d'Azure AD Premium P1/P2 (contrairement a signInActivity).

### Interface

```powershell
# Fonction modifiee - signature inchangee
function Get-MailboxLastLogon {
    [CmdletBinding()]
    [OutputType([datetime])]
    param(
        [Parameter(Mandatory)]
        [string]$UserPrincipalName
    )
    # Nouvelle implementation : lookup dans cache Graph Reports
}

# Nouvelle fonction privee pour charger le cache
function Initialize-EmailActivityCache {
    [CmdletBinding()]
    param()
    # Appel unique a getEmailActivityUserDetail
    # Stocke dans $Script:EmailActivityCache (hashtable UPN -> LastActivityDate)
}
```

### Donnees Retournees par Graph

| Colonne | Description |
|---------|-------------|
| User Principal Name | UPN de l'utilisateur |
| Last Activity Date | **Date de derniere activite email** (cible) |
| Send Count | Emails envoyes (periode) |
| Receive Count | Emails recus (periode) |

### Tests Attendus

- [ ] Cas nominal : LastLogon retourne date Graph (pas EXO)
- [ ] Cas utilisateur inexistant : retourne $null sans erreur
- [ ] Cas permission manquante : erreur explicite avec message
- [ ] Performance : <5s pour charger cache 1000 users

### Considerations

- **Fallback** : Si Graph echoue, fallback sur EXO avec warning
- **Periode** : Utiliser D30 (30 derniers jours) pour donnees fraiches
- **Cache** : Charger une seule fois au debut de la collecte
- **Retrocompatibilite** : Parametre `-IncludeLastLogon` inchange

---

## IMPLEMENTATION

### Etape 1 : Ajouter scope Reports.Read.All - 10min

Fichier : Config/Settings.json

AVANT :
```json
"scopes": [
    "Application.Read.All",
    "Directory.Read.All"
]
```

APRES :
```json
"scopes": [
    "Application.Read.All",
    "Directory.Read.All",
    "Reports.Read.All"
]
```

### Etape 2 : Creer fonction Initialize-EmailActivityCache - 45min

Fichier : Get-ExchangeDelegation.ps1 (region Helper Functions)

```powershell
# Variable de cache au niveau script
$Script:EmailActivityCache = $null

function Initialize-EmailActivityCache {
    <#
    .SYNOPSIS
        Charge le cache d'activite email depuis Graph Reports API.
    .DESCRIPTION
        Appelle getEmailActivityUserDetail une seule fois et stocke
        les resultats dans un hashtable pour lookup O(1) par UPN.
    .OUTPUTS
        [bool] $true si cache charge, $false sinon
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    if ($null -ne $Script:EmailActivityCache) {
        Write-Verbose "[i] Cache activite email deja charge"
        return $true
    }

    try {
        # Verifier connexion Graph
        if (-not (Test-MgConnection)) {
            Write-Log -Message "Graph non connecte - cache activite non disponible" -Level Warning
            return $false
        }

        Write-Verbose "[i] Chargement cache activite email depuis Graph..."

        # Appel API Reports - periode 30 jours
        $uri = "https://graph.microsoft.com/v1.0/reports/getEmailActivityUserDetail(period='D30')"
        $response = Invoke-MgGraphRequest -Uri $uri -Method GET -OutputType HttpResponseMessage

        if ($response.StatusCode -ne 200) {
            throw "API retourne status $($response.StatusCode)"
        }

        # Lire le contenu CSV
        $csvContent = $response.Content.ReadAsStringAsync().Result
        $activityData = $csvContent | ConvertFrom-Csv

        # Construire hashtable UPN -> LastActivityDate
        $Script:EmailActivityCache = @{}
        foreach ($row in $activityData) {
            $upn = $row.'User Principal Name'
            $lastActivity = $row.'Last Activity Date'

            if (-not [string]::IsNullOrEmpty($upn) -and -not [string]::IsNullOrEmpty($lastActivity)) {
                try {
                    $Script:EmailActivityCache[$upn.ToLower()] = [datetime]::Parse($lastActivity)
                }
                catch {
                    # Date invalide - ignorer
                }
            }
        }

        Write-Log -Message "Cache activite email charge: $($Script:EmailActivityCache.Count) utilisateurs" -Level Info
        return $true
    }
    catch {
        Write-Log -Message "Echec chargement cache Graph: $($_.Exception.Message)" -Level Warning
        $Script:EmailActivityCache = @{}
        return $false
    }
}
```

### Etape 3 : Modifier Get-MailboxLastLogon - 30min

Fichier : Get-ExchangeDelegation.ps1

AVANT (L296-330 environ) :
```powershell
function Get-MailboxLastLogon {
    param()
    # Implementation avec Get-EXOMailboxStatistics
    $stats = Get-EXOMailboxStatistics -Identity $Identity -ErrorAction SilentlyContinue
    if ($stats) {
        return $stats.LastLogonTime
    }
    return $null
}
```

APRES :
```powershell
function Get-MailboxLastLogon {
    <#
    .SYNOPSIS
        Retourne la date de derniere activite email d'une mailbox.
    .DESCRIPTION
        Utilise le cache Graph Reports API (Last Activity Date) pour une
        information precise sans les faux positifs des assistants de mailbox.
        Fallback sur EXO si Graph non disponible.
    .PARAMETER UserPrincipalName
        UPN de l'utilisateur (email principal).
    .OUTPUTS
        [datetime] ou $null si non disponible.
    #>
    [CmdletBinding()]
    [OutputType([datetime])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$UserPrincipalName
    )

    # Priorite 1 : Cache Graph (donnees precises)
    if ($null -ne $Script:EmailActivityCache -and $Script:EmailActivityCache.Count -gt 0) {
        $upnLower = $UserPrincipalName.ToLower()
        if ($Script:EmailActivityCache.ContainsKey($upnLower)) {
            return $Script:EmailActivityCache[$upnLower]
        }
        # UPN non trouve dans cache Graph - pas d'activite recente
        return $null
    }

    # Fallback : EXO Statistics (avec warning si premiere fois)
    if (-not $Script:EXOFallbackWarned) {
        Write-Log -Message "Graph indisponible - fallback sur EXO (LastLogonTime inclut assistants)" -Level Warning
        $Script:EXOFallbackWarned = $true
    }

    try {
        $stats = Get-EXOMailboxStatistics -Identity $UserPrincipalName -ErrorAction SilentlyContinue
        if ($stats -and $stats.LastLogonTime) {
            return $stats.LastLogonTime
        }
    }
    catch {
        # Ignorer erreurs EXO
    }

    return $null
}
```

### Etape 4 : Initialiser le cache au demarrage - 15min

Fichier : Get-ExchangeDelegation.ps1 (avant boucle principale, apres connexions)

AVANT (zone ~L890) :
```powershell
# Initialisation du cache recipients
Initialize-RecipientCache
```

APRES :
```powershell
# Initialisation du cache recipients
Initialize-RecipientCache

# Initialisation du cache activite email (si -IncludeLastLogon)
if ($IncludeLastLogon) {
    $cacheLoaded = Initialize-EmailActivityCache
    if ($cacheLoaded) {
        Write-Status -Message "Cache activite email charge (Graph Reports)" -Type Success -IndentLevel 1
    }
    else {
        Write-Status -Message "Fallback EXO pour LastLogon (moins precis)" -Type Warning -IndentLevel 1
    }
}
```

### Etape 5 : Mettre a jour la documentation - 10min

Fichier : Get-ExchangeDelegation.ps1 (comment-based help)

AVANT :
```powershell
.PARAMETER IncludeLastLogon
    Ajouter la date de derniere connexion de la mailbox au CSV.
    Impact performance : +1 appel API (Get-EXOMailboxStatistics) par mailbox.
```

APRES :
```powershell
.PARAMETER IncludeLastLogon
    Ajouter la date de derniere activite email de la mailbox au CSV.
    Utilise Microsoft Graph Reports API (getEmailActivityUserDetail) pour des
    donnees precises sans les faux positifs des assistants de mailbox.
    Fallback automatique sur EXO si Graph non disponible.
    Necessite permission Reports.Read.All dans l'application Graph.
```

---

## VALIDATION

### Criteres d'Acceptation

- [ ] `-IncludeLastLogon` utilise Graph Reports API par defaut
- [ ] Cache charge en <5s pour 1000+ utilisateurs
- [ ] Fallback EXO automatique si Graph echoue (avec warning)
- [ ] Colonne LastLogon contient `Last Activity Date` (pas LastLogonTime)
- [ ] Pas de regression sans `-IncludeLastLogon`
- [ ] Permission `Reports.Read.All` documentee

### Tests Manuels

```powershell
# Test avec Graph
.\Get-ExchangeDelegation.ps1 -IncludeLastLogon -Verbose
# Verifier log : "Cache activite email charge"

# Test fallback (deconnecter Graph avant)
Disconnect-MgGraph
.\Get-ExchangeDelegation.ps1 -IncludeLastLogon -Verbose
# Verifier warning : "Fallback sur EXO"
```

## CHECKLIST

- [ ] Code AVANT = code reel
- [ ] Tests passent
- [ ] Code review
- [ ] Permission Graph ajoutee a Settings.json

Labels : feat ! lastlogon graph performance

---

## REFERENCES

- [getEmailActivityUserDetail - Microsoft Learn](https://learn.microsoft.com/en-us/graph/api/reportroot-getemailactivityuserdetail)
- [signInActivity requires Premium](https://learn.microsoft.com/en-us/graph/api/resources/signinactivity) (non utilise)

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | # (apres gh issue create) |
| Statut | RESOLVED |
| Branche | feature/FEAT-013-lastlogon-graph |
