# Module Write-Log

Module de logging centralise au format ISO 8601, compatible SIEM.

## Installation

```powershell
Import-Module "$PSScriptRoot\Modules\Write-Log\Write-Log.psd1"
```

## Usage

```powershell
# Configuration
$Script:LogFile = ".\Logs\MonScript_$(Get-Date -Format 'yyyy-MM-dd').log"
$Script:ScriptName = "MonScript"

# Utilisation
Write-Log "Demarrage du script" -Level INFO
Write-Log "Operation reussie" -Level SUCCESS
Write-Log "Attention: delai eleve" -Level WARNING
Write-Log "Erreur de connexion" -Level ERROR
Write-Log "Arret critique" -Level FATAL
```

## Format de sortie

```
TIMESTAMP | LEVEL | HOSTNAME | SCRIPT | PID:xxxxx | MESSAGE
```

Exemple:
```
2025-12-02T14:30:45.123+01:00 | INFO    | SRV01 | MonScript | PID:12345 | Demarrage du script
```

## Niveaux de log

| Niveau | Couleur | Usage |
|--------|---------|-------|
| DEBUG | Gris | Informations de debogage |
| INFO | Blanc | Informations generales |
| SUCCESS | Vert | Operations reussies |
| WARNING | Jaune | Avertissements |
| ERROR | Rouge | Erreurs recuperables |
| FATAL | Magenta | Erreurs critiques |

## Parametres

| Parametre | Type | Obligatoire | Description |
|-----------|------|-------------|-------------|
| Message | string | Oui | Message a logger |
| Level | string | Non | Niveau (defaut: INFO) |
| NoConsole | switch | Non | Desactive affichage console |
| LogFile | string | Non | Chemin fichier log |
| ScriptName | string | Non | Nom du script |

## Standards

- **RFC 5424**: Syslog Protocol (niveaux de severite)
- **ISO 8601**: Format timestamp avec timezone
- **RFC 3339**: Date-time Internet
- **UTF-8**: Encodage caracteres (sans BOM)
