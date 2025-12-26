# Module GraphConnection

Module PowerShell de connexion Microsoft Graph avec gestion automatique des problemes courants.

| Info | Valeur |
|------|--------|
| Version | 1.0.0 |
| PowerShell | 7.2+ |
| Dependance | Microsoft.Graph.Authentication |
| Licence | MIT |

---

## Fonctionnalites

- **WAM desactive automatiquement** - Fix pour SDK 2.26+ qui casse l'auth dans certains terminaux
- **Fallback DeviceCode** - Si auth interactive echoue, bascule automatiquement vers Device Code
- **Retry avec backoff** - Tentatives multiples avec delai exponentiel
- **Session reuse** - Reutilise une session existante au lieu de reconnecter
- **Objet de connexion** - Retourne un objet avec methode `.Disconnect()`
- **Configuration flexible** - Via parametres ou Settings.json

---

## Installation

### Option 1 : Copie manuelle

```powershell
# Copier vers PSModulePath
$modulePath = "$env:USERPROFILE\Documents\PowerShell\Modules\GraphConnection"
Copy-Item -Path ".\*" -Destination $modulePath -Recurse -Force
```

### Option 2 : Import direct

```powershell
Import-Module ".\GraphConnection.psd1" -Force
```

### Prerequis

```powershell
# Installer Microsoft.Graph si absent
Install-Module Microsoft.Graph -Scope CurrentUser
```

---

## Quick Start

```powershell
Import-Module GraphConnection -ErrorAction Stop

# Connexion interactive
$connection = Connect-GraphConnection -Interactive

# Utiliser les cmdlets Graph
Get-MgUser -Top 10

# Deconnexion
$connection.Disconnect()
```

---

## Concepts Cles

| Terme | Definition |
|-------|------------|
| **WAM** | Windows Authentication Manager - desactive car casse depuis SDK 2.26+ |
| **DeviceCode** | Authentification via code + URL (fallback automatique) |
| **Session Reuse** | Reutilise session Graph active si presente |
| **NoDisconnect** | Option pour conserver la session apres .Disconnect() |
| **autoDisconnect** | Config Settings.json pour comportement par defaut |

---

## API Reference

### Initialize-GraphConnection

Definit le chemin vers Settings.json (optionnel).

```powershell
Initialize-GraphConnection -ConfigPath <string>
```

### Connect-GraphConnection

Etablit une connexion Microsoft Graph.

```powershell
Connect-GraphConnection
    [-Interactive]                    # Mode interactif (WAM off -> DeviceCode)
    [-ClientId <string>]              # App Registration ID
    [-TenantId <string>]              # Tenant ID
    [-CertificateThumbprint <string>] # REQUIS pour mode certificat
    [-Scopes <string[]>]              # Defaut: Settings.json ou User.Read
    [-NoDisconnect]                   # Conserve session apres .Disconnect()
    [-MaxRetries <int>]               # Defaut: 3 (range: 1-10)
    [-RetryDelaySeconds <int>]        # Defaut: 5 (range: 1-60)
    [-Force]                          # Force nouvelle connexion
```

**Retourne** `[GraphConnectionResult]` :

| Propriete | Type | Description |
|-----------|------|-------------|
| IsConnected | bool | Etat connexion |
| TenantId | string | ID du tenant |
| Account | string | Compte connecte |
| Scopes | string[] | Scopes accordes |
| AuthType | string | Type auth (Delegated, AppOnly) |
| ConnectedAt | datetime | Date/heure connexion |

**Methode** : `.Disconnect()` - Ferme la session (sauf si NoDisconnect)

### Test-GraphConnection

Verifie si une connexion Graph est active.

```powershell
Test-GraphConnection  # Returns [bool]
```

### Get-GraphConnectionInfo

Retourne les informations de la session active.

```powershell
Get-GraphConnectionInfo  # Returns [PSCustomObject] ou $null
```

### Disconnect-GraphConnection

Ferme la session Microsoft Graph.

```powershell
Disconnect-GraphConnection
```

---

## Modes de Connexion

### Mode Interactif

```powershell
# Connexion simple
$conn = Connect-GraphConnection -Interactive

# Avec scopes specifiques
$conn = Connect-GraphConnection -Interactive -Scopes @('User.Read.All', 'Group.Read.All')
```

**Comportement** :
1. Desactive WAM (Set-MgGraphOption -EnableLoginByWAM $false)
2. Tente connexion interactive
3. Si echec apres MaxRetries -> Fallback DeviceCode automatique
4. Retry avec backoff exponentiel

### Mode Certificat

```powershell
# Avec Settings.json
$conn = Connect-GraphConnection -CertificateThumbprint "ABC123DEF456"

# Avec parametres explicites
$conn = Connect-GraphConnection `
    -ClientId "00000000-0000-0000-0000-000000000000" `
    -TenantId "00000000-0000-0000-0000-000000000000" `
    -CertificateThumbprint "ABC123DEF456"
```

**Recherche certificat** : `Cert:\CurrentUser\My` puis `Cert:\LocalMachine\My`

---

## Configuration

### Settings.json

Copier `Settings.example.json` vers `Settings.json` :

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

| Cle | Type | Description |
|-----|------|-------------|
| clientId | string | App Registration ID (mode Certificate) |
| tenantId | string | Tenant ID (mode Certificate) |
| defaultScopes | string[] | Scopes par defaut |
| maxRetries | int | Tentatives max (defaut: 3) |
| retryDelaySeconds | int | Delai initial retry (defaut: 5) |
| autoDisconnect | bool | true = deconnexion auto, false = session conservee |

### Chemin personnalise

```powershell
# Specifier un chemin avant connexion
Initialize-GraphConnection -ConfigPath "D:\Config\Settings.json"
$conn = Connect-GraphConnection -Interactive
```

### Recherche automatique

Le module cherche Settings.json dans :
1. Chemin defini par `Initialize-GraphConnection`
2. Meme dossier que le module
3. `..\Config\Settings.json`
4. `..\..\Config\Settings.json`

---

## Patterns d'Utilisation

### Pattern Standard

```powershell
Import-Module GraphConnection -ErrorAction Stop

$connection = Connect-GraphConnection -Interactive

if ($connection.IsConnected) {
    try {
        # Operations Graph
        $users = Get-MgUser -Top 100
    }
    finally {
        $connection.Disconnect()
    }
}
```

### Pattern Session Persistante

```powershell
# Connexion qui reste active entre scripts
$conn = Connect-GraphConnection -Interactive -NoDisconnect

# OU via Settings.json avec autoDisconnect: false
$conn = Connect-GraphConnection -Interactive

# $conn.Disconnect() ne fait rien
# La session reste active pour le script suivant
```

### Pattern Force Reconnexion

```powershell
# Deconnecte et reconnecte
$conn = Connect-GraphConnection -Interactive -Force
```

### Pattern Config Externe

```powershell
# Utiliser une config specifique
Initialize-GraphConnection -ConfigPath "C:\MyApp\config.json"
$conn = Connect-GraphConnection -CertificateThumbprint "ABC123"
```

---

## Prerequis Azure

### App Registration (mode certificat)

1. Creer App Registration dans Entra ID (Azure AD)
2. Ajouter certificat dans "Certificates & secrets"
3. Configurer API permissions (Microsoft Graph)
4. Accorder Admin Consent si necessaire
5. Installer certificat local (CurrentUser ou LocalMachine)

---

## Gestion des Erreurs

| Situation | Comportement |
|-----------|--------------|
| Module Graph absent | Return objet avec IsConnected=$false + message |
| Auth annulee | Return IsConnected=$false |
| Auth interactive echoue | Fallback DeviceCode automatique |
| Certificat absent | Return IsConnected=$false + message |
| Network error | Retry avec backoff exponentiel |
| Session existante | Reutilisation (sauf -Force) |

---

## Problemes Connus et Solutions

### WAM casse (SDK 2.26+)

**Symptome** : Erreur "Could not load type TokenType" ou echec auth silencieux

**Solution** : Le module desactive automatiquement WAM. Aucune action requise.

### DeviceCode ne s'affiche pas

**Symptome** : Pas de code affiche pour Device Code flow

**Solution** : Le module appelle Connect-MgGraph directement (sans capture) pour afficher le code.

### Session persistante entre scripts

**Symptome** : Connexion reutilisee alors qu'on veut une nouvelle

**Solution** : Utiliser `-Force` pour forcer une nouvelle connexion.

---

## Tests

```powershell
# Importer et tester
Import-Module .\GraphConnection.psd1 -Force

# Test connexion
$conn = Connect-GraphConnection -Interactive
$conn.IsConnected  # Should be $true

# Test info
Get-GraphConnectionInfo | Format-List

# Deconnexion
$conn.Disconnect()
Test-GraphConnection  # Should be $false
```

---

## Changelog

### 1.0.0 (2025-12-21)

- Initial release
- Mode interactif avec WAM desactive et fallback DeviceCode
- Mode certificat (App Registration)
- Retry avec backoff exponentiel
- Session reuse automatique
- Objet de connexion avec .Disconnect()
- Configuration via Settings.json
- Initialize-GraphConnection pour chemin personnalise

---

## Licence

MIT License

Copyright (c) 2025

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
