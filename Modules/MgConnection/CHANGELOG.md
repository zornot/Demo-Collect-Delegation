# Changelog

Toutes les modifications notables sont documentees dans ce fichier.

Format base sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/).
Ce projet adhere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-07

### Added

- `Connect-MgConnection` : Connexion config-driven
- `Disconnect-MgConnection` : Deconnexion propre
- `Test-MgConnection` : Verification connexion active
- `Get-MgConnectionConfig` : Chargement configuration JSON
- `Initialize-MgConnection` : Initialisation avec chemin config

### Modes d'authentification

- **Interactive** : Authentification utilisateur avec WAM optionnel
- **Certificate** : Authentification par certificat X.509
- **ClientSecret** : Authentification par secret (variable environnement)
- **ManagedIdentity** : Identite geree Azure (System ou User-Assigned)

### Features

- Configuration centralisee via Settings.json
- WAM (Token Protection) pour mode Interactive
- Retry configurable (retryCount, retryDelaySeconds)
- TenantId placeholder ignore (00000000-...)
- Compatible PowerShell 7.2+
