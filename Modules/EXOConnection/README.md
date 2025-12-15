# EXOConnection

Module PowerShell de connexion Exchange Online avec reutilisation de session.

## Fonctionnalites

- Reutilisation automatique de session existante
- Connexion silencieuse (pas de banner ni output verbeux)
- Retry configurable avec backoff exponentiel
- Deconnexion propre

## Prerequis

- PowerShell 7.2+
- Module `ExchangeOnlineManagement` installe
- Droits Exchange Administrator ou Global Reader

## Installation

```powershell
# Installer le module Exchange Online Management si absent
Install-Module ExchangeOnlineManagement -Force

# Importer le module EXOConnection
Import-Module .\Modules\EXOConnection\EXOConnection.psm1
```

## Utilisation

### Connexion simple

```powershell
# Connexion avec reutilisation automatique de session
Connect-EXOConnection

# Verifier si connecte
if (Test-EXOConnection) {
    Write-Host "Connecte!"
}

# Obtenir infos connexion
$info = Get-EXOConnectionInfo
Write-Host "Organization: $($info.Organization)"

# Deconnexion
Disconnect-EXOConnection
```

### Connexion avec options

```powershell
# Forcer nouvelle connexion
Connect-EXOConnection -Force

# Personnaliser retry
Connect-EXOConnection -MaxRetries 5 -RetryDelaySeconds 10
```

## Fonctions Exportees

| Fonction | Description |
|----------|-------------|
| `Connect-EXOConnection` | Connexion avec reutilisation session |
| `Disconnect-EXOConnection` | Deconnexion propre |
| `Test-EXOConnection` | Verifie si connecte |
| `Get-EXOConnectionInfo` | Retourne infos session |

## Licence

MIT License
