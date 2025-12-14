# Configuration

Ce dossier contient les fichiers de configuration du projet.

## Fichiers

| Fichier | Git | Description |
|---------|-----|-------------|
| `Settings.example.json` | Versionne | Template avec valeurs fictives |
| `Settings.json` | Ignore | Configuration reelle (a creer) |

## Installation

```powershell
Copy-Item Settings.example.json Settings.json
# Editer Settings.json avec vos valeurs
```

## Structure

```json
{
    "Logging": {
        "DefaultLevel": "INFO|DEBUG|WARNING|ERROR",
        "LogDirectory": "./Logs",
        "RetentionDays": 30
    },
    "Console": {
        "Enabled": true|false
    },
    "SIEM": {
        "Format": "ISO8601"
    }
}
```
