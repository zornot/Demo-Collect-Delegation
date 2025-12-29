# [!] BUG-012 - LastLogon avec detection licence et anonymisation - Effort: 2h

## PROBLEME

L'API Graph Reports `getEmailActivityUserDetail` retourne des hash MD5 anonymises au lieu des UPNs reels quand le parametre de confidentialite M365 est actif. Resultat : aucune correspondance possible avec les mailboxes, LastLogon toujours vide.

De plus, la solution optimale (signInActivity) necessite Azure AD P1/P2 mais n'est pas utilisee actuellement.

## LOCALISATION

- Fichier : Get-ExchangeDelegation.ps1
- Zones : Initialize-EmailActivityCache (L333-402), Get-MailboxLastLogon (L404-458)
- Module : Script principal + GraphConnection

## OBJECTIF

Implementer une strategie en cascade pour LastLogon :

1. **signInActivity** (si P1/P2) : Meilleure precision, jamais anonymise
2. **Graph Reports** (si non-anonymise) : Bon compromis performance/precision
3. **Fallback EXO** (dernier recours) : Inclut assistants, moins precis

---

## DESIGN

### Objectif

Utiliser automatiquement la meilleure source de donnees LastLogon disponible selon les licences et la configuration du tenant.

### Architecture

- **Module concerne** : Get-ExchangeDelegation.ps1
- **Dependances** : GraphConnection (existant), Microsoft.Graph.Users (nouveau scope)
- **Impact** : Fonctions cache et lookup LastLogon
- **Pattern** : Strategy pattern avec fallback en cascade

### Strategie de Detection

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Tester signInActivity (Get-MgUser -Property SignInActivity)  │
│    ├─ OK → Utiliser signInActivity (best)                       │
│    └─ Erreur 403/license → Continuer                            │
├─────────────────────────────────────────────────────────────────┤
│ 2. Charger Graph Reports (getEmailActivityUserDetail)           │
│    ├─ UPN = email → Utiliser Graph Reports                      │
│    └─ UPN = hash MD5 → Warning + Continuer                      │
├─────────────────────────────────────────────────────────────────┤
│ 3. Fallback EXO (Get-EXOMailboxStatistics)                      │
│    └─ Toujours disponible mais moins precis                     │
└─────────────────────────────────────────────────────────────────┘
```

### Interface

```powershell
# Nouvelle fonction pour charger signInActivity
function Initialize-SignInActivityCache {
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    # Tente de charger via Get-MgUser -Property SignInActivity
    # Retourne $true si reussi, $false si licence manquante
}

# Fonction existante modifiee
function Initialize-EmailActivityCache {
    # Ajoute detection anonymisation (hash MD5)
}

# Variable de strategie
$Script:LastLogonStrategy = 'None'  # 'SignInActivity', 'GraphReports', 'EXO', 'None'
```

### Permissions Requises

| Permission | Usage | Obligatoire |
|------------|-------|-------------|
| Reports.Read.All | Graph Reports API | Oui (existant) |
| AuditLog.Read.All | signInActivity | Non (P1/P2 only) |
| User.Read.All | Get-MgUser | Oui si signInActivity |

### Tests Attendus

- [ ] Tenant P1/P2 : signInActivity utilise
- [ ] Tenant sans P1/P2 + anonymisation off : Graph Reports utilise
- [ ] Tenant sans P1/P2 + anonymisation on : Warning + fallback EXO
- [ ] Pas de regression si Graph non connecte

---

## IMPLEMENTATION

### Etape 1 : Ajouter scope AuditLog.Read.All - 5min

Fichier : Config/Settings.json

AVANT :
```json
"GraphConnection": {
    "defaultScopes": ["Reports.Read.All"],
    "autoDisconnect": true
}
```

APRES :
```json
"GraphConnection": {
    "defaultScopes": ["Reports.Read.All", "AuditLog.Read.All", "User.Read.All"],
    "autoDisconnect": true
}
```

### Etape 2 : Creer fonction Initialize-SignInActivityCache - 45min

Fichier : Get-ExchangeDelegation.ps1 (apres Initialize-EmailActivityCache)

```powershell
function Initialize-SignInActivityCache {
    <#
    .SYNOPSIS
        Charge le cache LastLogon depuis signInActivity (Azure AD P1/P2).
    .DESCRIPTION
        Utilise Get-MgUser avec la propriete SignInActivity pour obtenir
        lastSuccessfulSignInDateTime. Meilleure precision, jamais anonymise.
        Necessite licence Azure AD Premium P1 ou P2.
    .OUTPUTS
        [bool] $true si cache charge, $false si licence manquante ou erreur
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    if ($null -ne $Script:SignInActivityCache) {
        Write-Verbose "[i] Cache signInActivity deja charge"
        return $true
    }

    try {
        Write-Verbose "[i] Tentative chargement signInActivity (P1/P2)..."

        # Test avec un seul utilisateur pour verifier la disponibilite
        $testUser = Invoke-MgGraphRequest -Method GET `
            -Uri "https://graph.microsoft.com/v1.0/users?`$top=1&`$select=userPrincipalName,signInActivity" `
            -ErrorAction Stop

        # Si on arrive ici, la licence est disponible
        Write-Status -Type Success -Message "Licence P1/P2 detectee - utilisation signInActivity" -Indent 1

        # Charger tous les utilisateurs avec signInActivity
        $allUsers = @()
        $uri = "https://graph.microsoft.com/v1.0/users?`$select=userPrincipalName,signInActivity&`$top=999"

        do {
            $response = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
            $allUsers += $response.value
            $uri = $response.'@odata.nextLink'
        } while ($uri)

        # Construire le cache
        $Script:SignInActivityCache = @{}
        foreach ($user in $allUsers) {
            $upn = $user.userPrincipalName
            $lastSignIn = $user.signInActivity.lastSuccessfulSignInDateTime

            if (-not [string]::IsNullOrEmpty($upn) -and -not [string]::IsNullOrEmpty($lastSignIn)) {
                try {
                    $Script:SignInActivityCache[$upn.ToLower()] = [datetime]::Parse($lastSignIn)
                }
                catch {
                    # Date invalide - ignorer
                }
            }
        }

        $Script:LastLogonStrategy = 'SignInActivity'
        Write-Log -Message "Cache signInActivity charge: $($Script:SignInActivityCache.Count) utilisateurs" -Level Info -NoConsole
        return $true
    }
    catch {
        if ($_.Exception.Message -match '(403|Forbidden|license|Premium)') {
            Write-Verbose "[i] signInActivity non disponible (licence P1/P2 requise)"
        }
        else {
            Write-Log -Message "Erreur signInActivity: $($_.Exception.Message)" -Level Warning -NoConsole
        }
        return $false
    }
}
```

### Etape 3 : Modifier Initialize-EmailActivityCache avec detection anonymisation - 20min

Fichier : Get-ExchangeDelegation.ps1

AVANT (zone L370-395) :
```powershell
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

        Write-Log -Message "Cache activite email charge: $($Script:EmailActivityCache.Count) utilisateurs" -Level Info -NoConsole
        # Debug: afficher les UPNs dans le cache
        Write-Verbose "[DEBUG] UPNs dans le cache Graph:"
        foreach ($key in $Script:EmailActivityCache.Keys) {
            Write-Verbose "  - $key -> $($Script:EmailActivityCache[$key].ToString('yyyy-MM-dd'))"
        }
        return $true
```

APRES :
```powershell
        # Detecter anonymisation (premier UPN = hash MD5 32 chars hex)
        $firstUpn = ($activityData | Select-Object -First 1).'User Principal Name'
        if ($firstUpn -match '^[a-f0-9]{32}$') {
            Write-Log -Message "Graph Reports anonymise - UPNs remplaces par hash MD5" -Level Warning
            Write-Status -Type Warning -Message "Anonymisation Graph Reports ACTIVE - fallback EXO" -Indent 1
            Write-Status -Type Info -Message "Pour desactiver : Admin Center > Parametres > Rapports" -Indent 2
            $Script:LastLogonStrategy = 'EXO'
            return $false
        }

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

        $Script:LastLogonStrategy = 'GraphReports'
        Write-Log -Message "Cache activite email charge: $($Script:EmailActivityCache.Count) utilisateurs" -Level Info -NoConsole
        return $true
```

### Etape 4 : Modifier Get-MailboxLastLogon pour strategie cascade - 30min

Fichier : Get-ExchangeDelegation.ps1

AVANT (L404-458) :
```powershell
function Get-MailboxLastLogon {
    # ... code actuel
}
```

APRES :
```powershell
function Get-MailboxLastLogon {
    <#
    .SYNOPSIS
        Retourne la date de derniere connexion d'une mailbox.
    .DESCRIPTION
        Utilise la meilleure source disponible en cascade :
        1. signInActivity (P1/P2) - plus precis, jamais anonymise
        2. Graph Reports - bon compromis si non-anonymise
        3. EXO Statistics - fallback, inclut assistants
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$UserPrincipalName
    )

    $upnLower = $UserPrincipalName.ToLower()

    # Priorite 1 : signInActivity (P1/P2)
    if ($Script:LastLogonStrategy -eq 'SignInActivity' -and $null -ne $Script:SignInActivityCache) {
        if ($Script:SignInActivityCache.ContainsKey($upnLower)) {
            return $Script:SignInActivityCache[$upnLower].ToString('dd/MM/yyyy')
        }
        return ''
    }

    # Priorite 2 : Graph Reports (si non-anonymise)
    if ($Script:LastLogonStrategy -eq 'GraphReports' -and $null -ne $Script:EmailActivityCache) {
        if ($Script:EmailActivityCache.ContainsKey($upnLower)) {
            return $Script:EmailActivityCache[$upnLower].ToString('dd/MM/yyyy')
        }
        return ''
    }

    # Priorite 3 : EXO Statistics (fallback)
    if (-not $Script:EXOFallbackWarned) {
        Write-Log -Message "Utilisation EXO Statistics (LastLogonTime inclut assistants)" -Level Warning -NoConsole
        $Script:EXOFallbackWarned = $true
    }

    try {
        $stats = Get-EXOMailboxStatistics -Identity $UserPrincipalName -ErrorAction SilentlyContinue
        if ($stats -and $stats.LastLogonTime) {
            return $stats.LastLogonTime.ToString('dd/MM/yyyy')
        }
    }
    catch {
        # Ignorer erreurs EXO
    }

    return ''
}
```

### Etape 5 : Modifier initialisation dans Main - 15min

Fichier : Get-ExchangeDelegation.ps1 (zone connexion Graph ~L980)

AVANT :
```powershell
    if ($IncludeLastLogon) {
        Write-Status -Type Action -Message "Connexion Microsoft Graph..."
        $configPath = Join-Path $PSScriptRoot "Config\Settings.json"
        Initialize-GraphConnection -ConfigPath $configPath
        $Script:GraphConnection = Connect-GraphConnection -Interactive -Scopes @('Reports.Read.All')

        if ($Script:GraphConnection.IsConnected) {
            Write-Status -Type Action -Message "Chargement cache activite email..." -Indent 1
            $cacheLoaded = Initialize-EmailActivityCache
            # ...
        }
    }
```

APRES :
```powershell
    if ($IncludeLastLogon) {
        Write-Status -Type Action -Message "Connexion Microsoft Graph..."
        $configPath = Join-Path $PSScriptRoot "Config\Settings.json"
        Initialize-GraphConnection -ConfigPath $configPath

        # Scopes etendus pour signInActivity (P1/P2)
        $scopes = @('Reports.Read.All', 'AuditLog.Read.All', 'User.Read.All')
        $Script:GraphConnection = Connect-GraphConnection -Interactive -Scopes $scopes
        $Script:LastLogonStrategy = 'None'

        if ($Script:GraphConnection.IsConnected) {
            # Strategie 1 : Tenter signInActivity (P1/P2)
            Write-Status -Type Action -Message "Detection licence P1/P2..." -Indent 1
            $signInLoaded = Initialize-SignInActivityCache

            if (-not $signInLoaded) {
                # Strategie 2 : Fallback Graph Reports
                Write-Status -Type Action -Message "Chargement Graph Reports..." -Indent 1
                $reportsLoaded = Initialize-EmailActivityCache
            }

            # Afficher strategie finale
            switch ($Script:LastLogonStrategy) {
                'SignInActivity' { Write-Status -Type Success -Message "LastLogon: signInActivity ($($Script:SignInActivityCache.Count) users)" -Indent 1 }
                'GraphReports'   { Write-Status -Type Success -Message "LastLogon: Graph Reports ($($Script:EmailActivityCache.Count) users)" -Indent 1 }
                'EXO'            { Write-Status -Type Warning -Message "LastLogon: EXO Statistics (moins precis)" -Indent 1 }
                default          { Write-Status -Type Warning -Message "LastLogon: Non disponible" -Indent 1 }
            }
        }
        else {
            Write-Status -Type Warning -Message "Graph non disponible - LastLogon via EXO" -Indent 1
            $Script:LastLogonStrategy = 'EXO'
        }
    }
```

### Etape 6 : Declarer variables script - 5min

Fichier : Get-ExchangeDelegation.ps1 (debut, apres les autres variables script)

```powershell
# Variables pour strategie LastLogon
$Script:LastLogonStrategy = 'None'      # 'SignInActivity', 'GraphReports', 'EXO', 'None'
$Script:SignInActivityCache = $null     # Cache signInActivity (P1/P2)
$Script:EmailActivityCache = $null      # Cache Graph Reports
$Script:EXOFallbackWarned = $false      # Warning EXO affiche une seule fois
```

---

## VALIDATION

### Criteres d'Acceptation

- [ ] Tenant P1/P2 : signInActivity detecte et utilise
- [ ] Tenant sans P1/P2 : fallback sur Graph Reports
- [ ] Graph Reports anonymise : Warning + fallback EXO
- [ ] Message clair indiquant la strategie utilisee
- [ ] Pas de regression sans -IncludeLastLogon
- [ ] 88 tests Pester passent

### Tests Manuels

```powershell
# Test avec licence P1/P2 (si disponible)
.\Get-ExchangeDelegation.ps1 -IncludeLastLogon -Verbose
# Attendu : "Licence P1/P2 detectee" + "LastLogon: signInActivity"

# Test sans P1/P2, anonymisation off
.\Get-ExchangeDelegation.ps1 -IncludeLastLogon -Verbose
# Attendu : "LastLogon: Graph Reports"

# Test sans P1/P2, anonymisation on (actuel)
.\Get-ExchangeDelegation.ps1 -IncludeLastLogon -Verbose
# Attendu : "Anonymisation Graph Reports ACTIVE" + "LastLogon: EXO Statistics"
```

## CHECKLIST

- [x] Code AVANT = code reel (verifie)
- [ ] Tests passent
- [ ] Code review

Labels : bug ! graph lastlogon license

---

## ANNEXE : Desactivation Anonymisation (si necessaire)

### Option A : Microsoft 365 Admin Center

1. https://admin.microsoft.com
2. **Parametres** > **Parametres de l'organisation** > **Services** > **Rapports**
3. Decocher **"Afficher les identificateurs masques"**
4. Attendre 24-48h

### Option B : PowerShell

```powershell
Connect-MgGraph -Scopes "ReportSettings.ReadWrite.All"
Invoke-MgGraphRequest -Method PATCH `
    -Uri 'https://graph.microsoft.com/beta/admin/reportSettings' `
    -Body (@{ displayConcealedNames = $false } | ConvertTo-Json)
```

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | local |
| Statut | CLOSED |
| Branche | fix/BUG-012-lastlogon-strategy |
| Commit | 877b0d3 |
