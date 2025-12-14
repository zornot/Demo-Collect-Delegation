# Changelog

Toutes les modifications notables sont documentees dans ce fichier.

Format base sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/).
Ce projet adhere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

---

## [2.0.0] - 2025-12-02

### Added
- Format ISO 8601 avec timezone (`yyyy-MM-ddTHH:mm:ss.fffzzz`)
- Compatibilite SIEM (Splunk, ELK, Azure Sentinel, Graylog)
- Niveaux RFC 5424: DEBUG, INFO, SUCCESS, WARNING, ERROR, FATAL
- Affichage console colore par niveau
- Encodage UTF-8 sans BOM pour compatibilite SIEM
- Creation automatique du dossier de logs
- Fallback vers `$env:TEMP` si aucun fichier specifie
- Manifest de module (.psd1)
- Documentation complete (README, CONTRIBUTING)
- Standard de logging RFC 5424 / ISO 8601

### Changed
- Structure de projet reorganisee selon conventions PowerShell

---

## [1.0.0] - 2025-01-01

### Added
- Version initiale du module Write-Log
- Fonction Write-Log basique
