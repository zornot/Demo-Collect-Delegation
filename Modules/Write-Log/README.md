# Logger

Module PowerShell de logging centralise au format ISO 8601, compatible SIEM.

**Version**: 2.0.0
**Statut**: Production
**Date**: 2025-12-02

---

## Fonctionnalites

- Format ISO 8601 avec timezone (`yyyy-MM-ddTHH:mm:ss.fffzzz`)
- Compatibilite SIEM (Splunk, ELK, Azure Sentinel, Graylog)
- Niveaux RFC 5424: DEBUG, INFO, SUCCESS, WARNING, ERROR, FATAL
- Affichage console colore
- Encodage UTF-8 sans BOM
- Rotation journaliere des logs

---

## Demarrage rapide

### Prerequis

- PowerShell 5.1+ ou PowerShell 7.x

### Installation

```powershell
git clone https://github.com/zornot/Logger.git
cd Logger
```

### Utilisation

```powershell
# Import du module
Import-Module "$PSScriptRoot\Modules\Write-Log\Write-Log.psd1"

# Configuration
$Script:LogFile = ".\Logs\MonScript_$(Get-Date -Format 'yyyy-MM-dd').log"
$Script:ScriptName = "MonScript"

# Utilisation
Write-Log "Demarrage du script" -Level INFO
Write-Log "Operation reussie" -Level SUCCESS
Write-Log "Attention: delai eleve" -Level WARNING
Write-Log "Erreur de connexion" -Level ERROR
```

---

## Format de sortie

```
TIMESTAMP | LEVEL | HOSTNAME | SCRIPT | PID:xxxxx | MESSAGE
```

Exemple:
```
2025-12-02T14:30:45.123+01:00 | INFO    | SRV01 | MonScript | PID:12345 | Demarrage du script
2025-12-02T14:30:45.456+01:00 | SUCCESS | SRV01 | MonScript | PID:12345 | Operation terminee
2025-12-02T14:30:46.789+01:00 | ERROR   | SRV01 | MonScript | PID:12345 | Connexion echouee
```

---

## Structure du projet

```
Logger/
+-- Modules/
|   +-- Write-Log/
|       +-- Write-Log.psd1      # Manifest
|       +-- Write-Log.psm1      # Module principal
|       +-- README.md
+-- Config/
|   +-- Settings.example.json   # Template configuration
+-- Tests/
|   +-- Unit/                   # Tests unitaires
|   +-- Integration/            # Tests integration
|   +-- Fixtures/               # Donnees de test
+-- Docs/
|   +-- STANDARD-LOGGING-RFC5424-ISO8601.md
+-- Logs/                       # Logs runtime (gitignore)
+-- Output/                     # Fichiers generes (gitignore)
+-- README.md
+-- CHANGELOG.md
+-- CONTRIBUTING.md
+-- .gitignore
```

---

## Standards appliques

| Norme | Usage |
|-------|-------|
| RFC 5424 | Format Syslog Protocol |
| ISO 8601 | Format timestamp |
| RFC 3339 | Format date-time Internet |
| UTF-8 | Encodage caracteres |

---

## Documentation

- [Standard de Logging](Docs/STANDARD-LOGGING-RFC5424-ISO8601.md)
- [Guide de Contribution](CONTRIBUTING.md)
- [Changelog](CHANGELOG.md)

---

## Licence

MIT License
