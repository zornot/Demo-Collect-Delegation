# MgConnection

Module PowerShell de connexion Microsoft Graph config-driven.

**Version** : 1.0.0
**Auteur** : Zornot
**Compatibilite** : PowerShell 7.2+

---

## Vue d'ensemble

MgConnection centralise l'authentification Microsoft Graph avec une configuration externe via fichier JSON. Il supporte 4 modes d'authentification adaptes a differents environnements (developpement, production, CI/CD, Azure).

## Prerequis

```powershell
# Module Microsoft Graph requis
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
```

---

## Installation

### Option 1 : Import direct

```powershell
Import-Module ".\Modules\MgConnection\MgConnection.psm1"
```

### Option 2 : Import avec chemin relatif

```powershell
$modulePath = Join-Path $PSScriptRoot 'Modules' 'MgConnection' 'MgConnection.psm1'
Import-Module $modulePath -Force
```

---

## Configuration

### Structure Settings.json

La configuration se fait via la section `authentication` du fichier `Config/Settings.json` :

```json
{
  "authentication": {
    "mode": "Interactive",
    "tenantId": "00000000-0000-0000-0000-000000000000",
    "retryCount": 3,
    "retryDelaySeconds": 2,

    "interactive": {
      "scopes": ["Application.Read.All", "Directory.Read.All"],
      "useWAM": true
    },

    "certificate": {
      "clientId": "00000000-0000-0000-0000-000000000000",
      "tenantId": "00000000-0000-0000-0000-000000000000",
      "thumbprint": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    },

    "clientSecret": {
      "clientId": "00000000-0000-0000-0000-000000000000",
      "tenantId": "00000000-0000-0000-0000-000000000000",
      "secretVariable": "MG_CLIENT_SECRET"
    },

    "managedIdentity": {
      "clientId": null
    }
  }
}
```

### Modes d'authentification

| Mode | Usage | Securite | Configuration requise |
|------|-------|----------|----------------------|
| **Interactive** | Developpement, admin ponctuel | Token Protection WAM | `scopes`, `useWAM` (optionnel) |
| **Certificate** | Production (recommande) | Certificat X.509 | `clientId`, `thumbprint`, `tenantId` |
| **ClientSecret** | CI/CD, automation | Variable environnement | `clientId`, `secretVariable`, `tenantId` |
| **ManagedIdentity** | Azure VM/App Service | Zero secret | `clientId` (optionnel pour User-Assigned) |

---

## Utilisation

### Methode 1 : Initialisation puis connexion (recommande)

```powershell
# 1. Importer le module
Import-Module ".\Modules\MgConnection\MgConnection.psm1"

# 2. Initialiser avec le chemin de configuration
Initialize-MgConnection -ConfigPath ".\Config\Settings.json"

# 3. Connecter (utilise le mode configure dans Settings.json)
Connect-MgConnection

# 4. Utiliser Microsoft Graph
Get-MgApplication -Top 10

# 5. Deconnecter
Disconnect-MgConnection
```

### Methode 2 : Connexion directe avec ConfigPath

```powershell
Import-Module ".\Modules\MgConnection\MgConnection.psm1"

# Connexion directe
Connect-MgConnection -ConfigPath ".\Config\Settings.json"

# ... utiliser Graph ...

Disconnect-MgConnection
```

### Methode 3 : Override du mode

```powershell
# Forcer un mode specifique (ignore authentication.mode dans config)
Connect-MgConnection -ConfigPath ".\Config\Settings.json" -Mode Certificate
```

---

## Fonctions exportees

### Initialize-MgConnection

Initialise le module avec le chemin de configuration.

```powershell
Initialize-MgConnection -ConfigPath ".\Config\Settings.json"
```

| Parametre | Type | Obligatoire | Description |
|-----------|------|-------------|-------------|
| ConfigPath | string | Oui | Chemin vers Settings.json |

### Connect-MgConnection

Etablit la connexion Microsoft Graph.

```powershell
Connect-MgConnection [-ConfigPath <string>] [-Mode <string>]
```

| Parametre | Type | Obligatoire | Description |
|-----------|------|-------------|-------------|
| ConfigPath | string | Non* | Chemin vers Settings.json |
| Mode | string | Non | Override: Interactive, Certificate, ClientSecret, ManagedIdentity |

*Requis si `Initialize-MgConnection` n'a pas ete appele.

**Retour** : `[bool]` - `$true` si connexion reussie, `$false` sinon.

### Test-MgConnection

Verifie si une connexion est active.

```powershell
if (Test-MgConnection) {
    Write-Host "Connecte a Microsoft Graph"
}
```

**Retour** : `[bool]`

### Disconnect-MgConnection

Ferme proprement la connexion.

```powershell
Disconnect-MgConnection
```

### Get-MgConnectionConfig

Charge la configuration depuis un fichier JSON.

```powershell
$config = Get-MgConnectionConfig -ConfigPath ".\Config\Settings.json"
$config.authentication.mode  # Affiche le mode configure
```

**Retour** : `[PSCustomObject]`

---

## Configuration par mode

### Mode Interactive (developpement)

```json
{
  "authentication": {
    "mode": "Interactive",
    "interactive": {
      "scopes": ["Application.Read.All", "Directory.Read.All"],
      "useWAM": true
    }
  }
}
```

- **useWAM** : Active Windows Authentication Manager pour Token Protection (TPM/biometrie)
- **scopes** : Permissions demandees (delegated permissions)

### Mode Certificate (production)

```json
{
  "authentication": {
    "mode": "Certificate",
    "certificate": {
      "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "thumbprint": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    }
  }
}
```

**Installation du certificat** :
```powershell
# Importer dans le store utilisateur
Import-PfxCertificate -FilePath ".\cert.pfx" -CertStoreLocation "Cert:\CurrentUser\My" -Password (Read-Host -AsSecureString)

# Verifier
Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Subject -like "*MonApp*" }
```

### Mode ClientSecret (CI/CD)

```json
{
  "authentication": {
    "mode": "ClientSecret",
    "clientSecret": {
      "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "secretVariable": "MG_CLIENT_SECRET"
    }
  }
}
```

**Configuration de la variable** :
```powershell
# PowerShell (session courante)
$env:MG_CLIENT_SECRET = "votre-secret-ici"

# GitHub Actions
# secrets.MG_CLIENT_SECRET dans le workflow

# Azure DevOps
# Variable de pipeline (secret)
```

**Important** : Le secret n'est JAMAIS stocke dans le fichier de configuration.

### Mode ManagedIdentity (Azure)

```json
{
  "authentication": {
    "mode": "ManagedIdentity",
    "managedIdentity": {
      "clientId": null
    }
  }
}
```

- **System-Assigned** : `clientId: null`
- **User-Assigned** : `clientId: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"`

---

## Mecanisme de retry

Le module supporte les tentatives de reconnexion :

```json
{
  "authentication": {
    "retryCount": 3,
    "retryDelaySeconds": 2
  }
}
```

- **retryCount** : Nombre de tentatives (defaut: 1)
- **retryDelaySeconds** : Delai entre tentatives (defaut: 2)

---

## Retrocompatibilite

Le module est concu pour fonctionner avec `AppRegistrationCollector` tout en preservant les anciens appels :

```powershell
# Ancien appel (toujours supporte)
Connect-AppRegistrationCollector `
    -TenantId "xxx" `
    -ClientId "yyy" `
    -CertificateThumbprint "zzz"

# Nouvel appel config-driven
Initialize-MgConnection -ConfigPath "./Config/Settings.json"
Connect-AppRegistrationCollector -ConfigPath "./Config/Settings.json" -Mode Certificate
```

---

## Exemples complets

### Script de collecte (production)

```powershell
#Requires -Version 7.2

$ErrorActionPreference = 'Stop'

# Import modules
Import-Module ".\Modules\MgConnection\MgConnection.psm1"
Import-Module ".\Modules\AppRegistrationCollector\AppRegistrationCollector.psm1"

try {
    # Connexion via configuration
    Initialize-MgConnection -ConfigPath ".\Config\Settings.json"

    if (-not (Connect-MgConnection)) {
        throw "Echec de connexion Microsoft Graph"
    }

    # Collecte des donnees
    $apps = Get-MgApplication -All
    Write-Host "[+] $($apps.Count) applications trouvees"

} finally {
    Disconnect-MgConnection
}
```

### Script CI/CD (GitHub Actions)

```yaml
- name: Run App Registration Collector
  env:
    MG_CLIENT_SECRET: ${{ secrets.MG_CLIENT_SECRET }}
  run: |
    pwsh -Command "
      Import-Module ./Modules/MgConnection/MgConnection.psm1
      Connect-MgConnection -ConfigPath './Config/Settings.json' -Mode ClientSecret
      # ... collection ...
      Disconnect-MgConnection
    "
```

---

## Securite

| Aspect | Implementation |
|--------|----------------|
| Secrets | Variables d'environnement uniquement |
| Token Protection | WAM disponible en mode Interactive |
| Certificats | Store Windows (CurrentUser/LocalMachine) |
| Managed Identity | Zero secret (Azure natif) |
| Retry | Configurable pour resilience |

---

## Troubleshooting

### Erreur "ConfigPath required"

```
ConfigPath required. Call Initialize-MgConnection first or provide -ConfigPath parameter.
```

**Solution** : Appeler `Initialize-MgConnection` avant `Connect-MgConnection`, ou passer `-ConfigPath`.

### Erreur "Environment variable not defined"

```
Environment variable 'MG_CLIENT_SECRET' is not defined or empty
```

**Solution** : Definir la variable d'environnement :
```powershell
$env:MG_CLIENT_SECRET = "votre-secret"
```

### Erreur certificat

```
Certificate mode requires 'authentication.certificate.thumbprint'
```

**Solution** : Verifier que le thumbprint est configure dans Settings.json et que le certificat est installe.

### WAM non disponible

```
WAM non disponible: ...
```

**Note** : WAM n'est pas bloquant. La connexion Interactive fonctionne sans.

---

## Tests

```powershell
# Executer les tests unitaires
Invoke-Pester -Path ".\Tests\Unit\MgConnection.Tests.ps1" -Output Detailed

# Resultats attendus : 30 tests, 100% pass
```

---

## Licence

MIT License - Voir [LICENSE](LICENSE)
