# Module GraphConnection

Module de connexion Microsoft Graph avec mode interactif et certificat.

## CRITICAL

- Prerequis : `Microsoft.Graph.Authentication` installe
- WAM automatiquement desactive (fix SDK 2.26+)
- Session reutilisee automatiquement si active
- Retourne un objet avec methode `.Disconnect()`
- Fallback automatique Interactive -> DeviceCode

## Installation

```powershell
# Copier le module dans un des chemins PSModulePath
Copy-Item -Path ".\Module-GraphConnection" -Destination "$env:USERPROFILE\Documents\PowerShell\Modules\GraphConnection" -Recurse

# Ou importer directement
Import-Module ".\GraphConnection.psd1" -Force
```

## Usage

```powershell
Import-Module GraphConnection -ErrorAction Stop

# Mode interactif (WAM desactive -> DeviceCode fallback)
$connection = Connect-GraphConnection -Interactive

# Verification
if (Test-GraphConnection) {
    $info = Get-GraphConnectionInfo
    Write-Host "Connecte a: $($info.TenantId)"
}

# Utiliser cmdlets Graph...
Get-MgUser -Top 10

# Deconnexion via objet
$connection.Disconnect()

# OU deconnexion directe
Disconnect-GraphConnection
```

## API

| Fonction | Retour | Usage |
|----------|--------|-------|
| Initialize-GraphConnection | void | Definir chemin Settings.json |
| Connect-GraphConnection | GraphConnectionResult | Connexion avec retry |
| Disconnect-GraphConnection | void | Deconnexion propre |
| Test-GraphConnection | bool | Verifie session active |
| Get-GraphConnectionInfo | PSCustomObject | Infos session |

## Modes de Connexion

### Mode Interactif (defaut)

```powershell
$conn = Connect-GraphConnection -Interactive
$conn = Connect-GraphConnection -Interactive -Scopes @('User.Read.All', 'Group.Read.All')
```

Comportement :
1. Desactive WAM (fix SDK 2.26+)
2. Tente connexion interactive
3. Si echec -> Fallback DeviceCode automatique

### Mode Certificat

```powershell
$conn = Connect-GraphConnection -CertificateThumbprint "ABC123DEF456"

# Ou avec parametres explicites
$conn = Connect-GraphConnection `
    -ClientId "00000000-0000-0000-0000-000000000000" `
    -TenantId "00000000-0000-0000-0000-000000000000" `
    -CertificateThumbprint "ABC123DEF456"
```

ClientId/TenantId : parametre OU Settings.json

## Parametres Connect

| Param | Defaut | Description |
|-------|--------|-------------|
| Interactive | - | Mode interactif (WAM/DeviceCode) |
| CertificateThumbprint | - | Mode certificat (requis) |
| ClientId | Settings.json | App Registration ID |
| TenantId | Settings.json | Tenant ID |
| Scopes | Settings.json ou User.Read | Scopes Graph |
| NoDisconnect | Settings.json | .Disconnect() ne fait rien |
| MaxRetries | 3 | Tentatives max |
| RetryDelaySeconds | 5 | Delai initial (x tentative) |
| Force | false | Reconnexion forcee |

## Objet GraphConnectionResult

```powershell
$conn = Connect-GraphConnection -Interactive

$conn.IsConnected   # bool
$conn.TenantId      # string
$conn.Account       # string
$conn.Scopes        # string[]
$conn.AuthType      # string
$conn.ConnectedAt   # datetime

$conn.Disconnect()  # Deconnecte (sauf si -NoDisconnect ou autoDisconnect=false)
```

## Configuration Settings.json

Copier `Settings.example.json` vers `Settings.json` et configurer :

```json
{
  "GraphConnection": {
    "clientId": "00000000-0000-0000-0000-000000000000",
    "tenantId": "00000000-0000-0000-0000-000000000000",
    "defaultScopes": ["User.Read"],
    "maxRetries": 3,
    "retryDelaySeconds": 5,
    "autoDisconnect": true
  }
}
```

| Cle | Usage |
|-----|-------|
| clientId | App Registration ID (mode Certificate) |
| tenantId | Tenant ID (mode Certificate) |
| defaultScopes | Scopes par defaut si non specifies |
| maxRetries | Tentatives max |
| retryDelaySeconds | Delai entre retries |
| autoDisconnect | `true` = deconnexion auto, `false` = session conservee |

### Chemin personnalise

```powershell
Initialize-GraphConnection -ConfigPath "C:\Config\Settings.json"
$conn = Connect-GraphConnection -Interactive
```

## DO NOT

- Oublier `.Disconnect()` ou `Disconnect-GraphConnection` en fin de script
- Utiliser `Connect-MgGraph` directement (pas de retry/fallback/WAM fix)
- Ignorer le retour de `Connect-GraphConnection`

## Anti-Patterns

```powershell
# [-] INTERDIT - Ignorer le resultat de Connect
Connect-GraphConnection
Get-MgUser  # Peut echouer si connexion ratee

# [+] CORRECT - Verifier IsConnected
$conn = Connect-GraphConnection
if ($conn.IsConnected) {
    Get-MgUser
}

# [-] INTERDIT - Oublier Disconnect quand autoDisconnect=true (defaut)
$conn = Connect-GraphConnection  # autoDisconnect=true par defaut
Get-MgUser -Top 10
# Fin script sans cleanup -> session orpheline

# [+] CORRECT - Pattern try/finally (safe dans tous les cas)
$conn = Connect-GraphConnection
try {
    Get-MgUser -Top 10
}
finally {
    $conn.Disconnect()  # Deconnecte si autoDisconnect=true, sinon ne fait rien
}

# [i] INFO - Si autoDisconnect=false dans Settings.json, session conservee
#            intentionnellement. try/finally optionnel mais safe.

# [-] INTERDIT - Forcer WAM (casse depuis SDK 2.26+)
Connect-MgGraph -UseWAM

# [+] CORRECT - Laisser le module gerer
Connect-GraphConnection -Interactive  # WAM desactive automatiquement
```

## Details

See @README.md for full documentation
