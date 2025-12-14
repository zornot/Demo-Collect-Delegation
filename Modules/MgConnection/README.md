# MgConnection

Module PowerShell de connexion Microsoft Graph config-driven.

**Version**: 1.0.0
**Statut**: Production
**Date**: 2025-12-07

---

## Fonctionnalites

- 4 modes d'authentification : Interactive, Certificate, ClientSecret, ManagedIdentity
- Configuration centralisee via fichier JSON
- WAM (Token Protection) pour mode Interactive
- Retry configurable pour resilience
- Compatible PowerShell 7.2+

---

## Prerequis

```powershell
# Module Microsoft Graph requis
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
```

---

## Installation

```powershell
# Cloner le repository
git clone https://github.com/zornot/MgConnection.git

# Ou copier le module dans votre projet
Copy-Item -Path ".\Modules\MgConnection" -Destination ".\VotreProjet\Modules\" -Recurse
```

---

## Demarrage Rapide

```powershell
Import-Module ".\Modules\MgConnection\MgConnection.psd1"

# Option 1 : Initialisation puis connexion (recommande)
Initialize-MgConnection -ConfigPath ".\Config\Settings.json"
Connect-MgConnection

# Option 2 : Connexion directe
Connect-MgConnection -ConfigPath ".\Config\Settings.json"

# Utiliser Microsoft Graph
Get-MgApplication -Top 10

# Deconnecter
Disconnect-MgConnection
```

---

## Modes d'Authentification

| Mode | Usage | Securite | Configuration |
|------|-------|----------|---------------|
| **Interactive** | Developpement | WAM Token Protection | `scopes`, `useWAM` |
| **Certificate** | Production | Certificat X.509 | `clientId`, `thumbprint`, `tenantId` |
| **ClientSecret** | CI/CD | Variable environnement | `clientId`, `secretVariable`, `tenantId` |
| **ManagedIdentity** | Azure | Zero secret | `clientId` (optionnel) |

---

## Configuration Settings.json

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

---

## Fonctions Disponibles

| Fonction | Description |
|----------|-------------|
| `Initialize-MgConnection` | Initialise avec le chemin de configuration |
| `Connect-MgConnection` | Etablit la connexion Microsoft Graph |
| `Test-MgConnection` | Verifie si connecte |
| `Disconnect-MgConnection` | Ferme la connexion |
| `Get-MgConnectionConfig` | Charge la configuration JSON |

---

## Exemples

### Mode Interactive (dev)

```json
{
  "authentication": {
    "mode": "Interactive",
    "interactive": {
      "scopes": ["Application.Read.All"],
      "useWAM": true
    }
  }
}
```

### Mode Certificate (prod)

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

### Mode ClientSecret (CI/CD)

```powershell
# Variable d'environnement
$env:MG_CLIENT_SECRET = "votre-secret"

# Connexion
Connect-MgConnection -ConfigPath ".\Config\Settings.json" -Mode ClientSecret
```

---

## Structure du Projet

```
Module-MgConnection/
├── Modules/
│   └── MgConnection/
│       ├── MgConnection.psd1      # Manifest
│       ├── MgConnection.psm1      # Module principal
│       └── README.md
├── Config/
│   ├── Settings.example.json      # Template
│   └── README.md
├── Tests/
│   └── Unit/                      # Tests Pester
├── Logs/                          # Logs runtime (gitignore)
├── README.md
├── CHANGELOG.md
└── LICENSE
```

---

## Tests

```powershell
Invoke-Pester -Path .\Tests -Output Detailed
```

---

## Securite

| Aspect | Implementation |
|--------|----------------|
| Secrets | Variables d'environnement uniquement |
| Token Protection | WAM disponible en mode Interactive |
| Certificats | Store Windows (CurrentUser/LocalMachine) |
| Managed Identity | Zero secret (Azure natif) |

---

## Licence

MIT License
