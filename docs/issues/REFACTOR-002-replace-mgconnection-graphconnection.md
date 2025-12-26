# [~] REFACTOR-002 - Remplacer MgConnection par GraphConnection - Effort: 1h

## PROBLEME

Le module MgConnection actuel est complexe avec 4 modes d'authentification et une configuration segmentee. Le nouveau module GraphConnection est plus simple, avec une API objet intuitive et un fallback DeviceCode automatique.

## LOCALISATION

- Fichier : Get-ExchangeDelegation.ps1
- Zones : Import (L202), Connexion Graph (L974-994)
- Module : Modules/MgConnection -> Modules/GraphConnection

## OBJECTIF

Remplacer MgConnection par GraphConnection pour :
- API plus intuitive (objet avec `.Disconnect()`)
- Configuration simplifiee (1 section au lieu de 4)
- Fallback DeviceCode automatique si WAM echoue
- Reutilisation automatique de session existante

---

## DESIGN

### Architecture

- **Module source** : D:\01 Projet\Module-GraphConnection\Module\
- **Destination** : Modules/GraphConnection/
- **Impact** : Get-ExchangeDelegation.ps1, Config/Settings.json

### Mapping des fonctions

| MgConnection | GraphConnection | Notes |
|--------------|-----------------|-------|
| `Initialize-MgConnection` | `Initialize-GraphConnection` | Meme signature |
| `Connect-MgConnection` | `Connect-GraphConnection` | Retourne objet au lieu de bool |
| `Disconnect-MgConnection` | `$connection.Disconnect()` | Methode sur objet |
| `Test-MgConnection` | `Test-GraphConnection` | Identique |

### Configuration Settings.json

AVANT (MgConnection) :
```json
"authentication": {
    "mode": "Interactive",
    "tenantId": "...",
    "interactive": { "scopes": [...], "persistCache": true },
    "certificate": { ... },
    "clientSecret": { ... },
    "managedIdentity": { ... }
}
```

APRES (GraphConnection) :
```json
"GraphConnection": {
    "defaultScopes": ["Reports.Read.All"],
    "autoDisconnect": true
}
```

### API Connect-GraphConnection

```powershell
# Mode interactif (defaut)
$connection = Connect-GraphConnection -Interactive -Scopes @('Reports.Read.All')

# Mode certificat
$connection = Connect-GraphConnection -CertificateThumbprint "ABC123..."

# Proprietes objet retourne
$connection.IsConnected   # bool
$connection.TenantId      # string
$connection.Account       # string
$connection.Scopes        # string[]
$connection.AuthType      # string
$connection.Disconnect()  # methode
```

---

## IMPLEMENTATION

### Etape 1 : Copier le module GraphConnection - 5min

```powershell
# Source
$source = "D:\01 Projet\Module-GraphConnection\Module"

# Destination (structure standard)
$dest = "Modules/GraphConnection"

# Copier
Copy-Item -Path $source -Destination $dest -Recurse
```

Structure finale :
```
Modules/GraphConnection/
├── GraphConnection.psd1
├── GraphConnection.psm1
├── README.md
└── Settings.example.json
```

### Etape 2 : Modifier l'import dans Get-ExchangeDelegation.ps1 - 5min

Fichier : Get-ExchangeDelegation.ps1

AVANT :
```powershell
Import-Module "$PSScriptRoot\Modules\MgConnection\Modules\MgConnection\MgConnection.psm1" -Force -ErrorAction Stop
```

APRES :
```powershell
Import-Module "$PSScriptRoot\Modules\GraphConnection\GraphConnection.psm1" -Force -ErrorAction Stop
```

### Etape 3 : Modifier la connexion Graph - 10min

Fichier : Get-ExchangeDelegation.ps1 (zone L974-994)

AVANT :
```powershell
    # Connexion Graph et cache activite email (si -IncludeLastLogon)
    if ($IncludeLastLogon) {
        Write-Status -Type Action -Message "Connexion Microsoft Graph..."
        $configPath = Join-Path $PSScriptRoot "Config\Settings.json"
        Initialize-MgConnection -ConfigPath $configPath
        $graphConnected = Connect-MgConnection

        if ($graphConnected) {
            Write-Status -Type Action -Message "Chargement cache activite email..." -Indent 1
            $cacheLoaded = Initialize-EmailActivityCache
            if ($cacheLoaded) {
                Write-Status -Type Success -Message "Cache charge: $($Script:EmailActivityCache.Count) utilisateurs (Graph Reports)" -Indent 1
            }
            else {
                Write-Status -Type Warning -Message "Fallback EXO pour LastLogon (moins precis)" -Indent 1
            }
        }
        else {
            Write-Status -Type Warning -Message "Graph non disponible - fallback EXO pour LastLogon" -Indent 1
        }
    }
```

APRES :
```powershell
    # Connexion Graph et cache activite email (si -IncludeLastLogon)
    if ($IncludeLastLogon) {
        Write-Status -Type Action -Message "Connexion Microsoft Graph..."
        $configPath = Join-Path $PSScriptRoot "Config\Settings.json"
        Initialize-GraphConnection -ConfigPath $configPath
        $Script:GraphConnection = Connect-GraphConnection -Interactive -Scopes @('Reports.Read.All')

        if ($Script:GraphConnection.IsConnected) {
            Write-Status -Type Action -Message "Chargement cache activite email..." -Indent 1
            $cacheLoaded = Initialize-EmailActivityCache
            if ($cacheLoaded) {
                Write-Status -Type Success -Message "Cache charge: $($Script:EmailActivityCache.Count) utilisateurs (Graph Reports)" -Indent 1
            }
            else {
                Write-Status -Type Warning -Message "Fallback EXO pour LastLogon (moins precis)" -Indent 1
            }
        }
        else {
            Write-Status -Type Warning -Message "Graph non disponible - fallback EXO pour LastLogon" -Indent 1
        }
    }
```

### Etape 4 : Modifier Test-MgConnection dans Initialize-EmailActivityCache - 5min

Fichier : Get-ExchangeDelegation.ps1 (fonction Initialize-EmailActivityCache)

AVANT :
```powershell
        if (-not (Test-MgConnection)) {
            Write-Log -Message "Graph non connecte - cache activite non disponible" -Level Warning
            return $false
        }
```

APRES :
```powershell
        if (-not (Test-GraphConnection)) {
            Write-Log -Message "Graph non connecte - cache activite non disponible" -Level Warning
            return $false
        }
```

### Etape 5 : Ajouter deconnexion en fin de script - 5min

Fichier : Get-ExchangeDelegation.ps1 (fin du script, avant Write-Box final)

AVANT :
```powershell
# Affichage du resume final
```

APRES :
```powershell
# Deconnexion Graph si connecte
if ($Script:GraphConnection -and $Script:GraphConnection.IsConnected) {
    $Script:GraphConnection.Disconnect()
}

# Affichage du resume final
```

### Etape 6 : Mettre a jour Config/Settings.json - 5min

Fichier : Config/Settings.json

AVANT :
```json
"authentication": {
    "mode": "Interactive",
    "tenantId": "00000000-0000-0000-0000-000000000000",
    "retryCount": 3,
    "retryDelaySeconds": 2,
    "interactive": {
        "scopes": ["Reports.Read.All"],
        "persistCache": true
    }
}
```

APRES :
```json
"GraphConnection": {
    "defaultScopes": ["Reports.Read.All"],
    "autoDisconnect": true
}
```

### Etape 7 : Supprimer l'ancien module - 5min

```powershell
Remove-Item -Path "Modules/MgConnection" -Recurse -Force
```

---

## VALIDATION

### Criteres d'Acceptation

- [ ] Module GraphConnection copie dans Modules/
- [ ] Import fonctionne sans erreur
- [ ] `-IncludeLastLogon` se connecte via GraphConnection
- [ ] Cache Graph charge correctement
- [ ] Deconnexion propre en fin de script
- [ ] Fallback EXO fonctionne si Graph echoue
- [ ] Ancien module MgConnection supprime

### Tests Manuels

```powershell
# Test connexion
.\Get-ExchangeDelegation.ps1 -IncludeLastLogon -Verbose

# Verifier logs
# - "Graph connecte" (pas "Graph deja connecte" si premiere fois)
# - "Cache activite email charge"
# - "Microsoft Graph deconnecte" en fin

# Test fallback (permission manquante)
# Retirer Reports.Read.All des scopes
# Verifier warning "Fallback EXO pour LastLogon"
```

## CHECKLIST

- [ ] Module copie
- [ ] Imports corriges
- [ ] Connexion adaptee
- [ ] Deconnexion ajoutee
- [ ] Tests passent
- [ ] Ancien module supprime

Labels : refactor ~ module graph

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | local |
| Statut | CLOSED |
| Branche | feature/REFACTOR-002-graphconnection |
| Commit | ba34410 |
