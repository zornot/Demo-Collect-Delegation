# Standard de Logging - RFC 5424 / ISO 8601

## Document Interne - Ne pas publier

**Version** : 1.0
**Date** : 2025-12-02
**Auteur** : Contributors
**Statut** : Reference interne

---

## 1. Vue d'ensemble

Ce document definit le standard de logging utilise dans le projet Exchange-NewMailBox-Litigation.
Le format est optimise pour :
- **Ingestion SIEM** (Splunk, ELK Stack, Azure Sentinel, Graylog)
- **Parsing automatique** via regex standards
- **Lisibilite humaine** dans les fichiers bruts
- **Correlation multi-sources** via timestamps UTC

---

## 2. Normes de Reference

| Norme | Usage | Lien |
|-------|-------|------|
| **RFC 5424** | Format Syslog Protocol | https://datatracker.ietf.org/doc/html/rfc5424 |
| **ISO 8601** | Format timestamp | https://en.wikipedia.org/wiki/ISO_8601 |
| **RFC 3339** | Format date-time Internet | https://datatracker.ietf.org/doc/html/rfc3339 |
| **UTF-8** | Encodage caracteres | Standard Unicode |

---

## 3. Format de Ligne de Log

### 3.1 Structure

```
TIMESTAMP | LEVEL | HOSTNAME | SCRIPT | PID:xxxxx | MESSAGE
```

### 3.2 Champs Detailles

| Champ | Format | Longueur | Description |
|-------|--------|----------|-------------|
| TIMESTAMP | `yyyy-MM-ddTHH:mm:ss.fffzzz` | 29 car. | ISO 8601 avec millisecondes et timezone |
| LEVEL | Padding 7 car. | 7 car. | Niveau de severite (voir 4.0) |
| HOSTNAME | Variable | - | Nom NetBIOS du serveur (`$env:COMPUTERNAME`) |
| SCRIPT | Variable | - | Nom du script sans extension |
| PID | `PID:xxxxx` | ~9 car. | Process ID Windows |
| MESSAGE | Variable | - | Message libre UTF-8 |

### 3.3 Separateur

- Caractere : Pipe avec espaces ` | `
- Regex separateur : `\s*\|\s*`

### 3.4 Exemple Concret

```
2025-12-02T14:30:45.123+01:00 | INFO    | SRV01 | Enable-LitigationHold | PID:12345 | Demarrage du script v1.5
2025-12-02T14:30:45.456+01:00 | WARNING | SRV01 | Enable-LitigationHold | PID:12345 | Mode SIMULATION active
2025-12-02T14:30:46.789+01:00 | ERROR   | SRV01 | Enable-LitigationHold | PID:12345 | Connexion Exchange echouee
2025-12-02T14:30:47.012+01:00 | SUCCESS | SRV01 | Enable-LitigationHold | PID:12345 | Mailbox user@contoso.com traitee
```

---

## 4. Niveaux de Severite (Severity Levels)

### 4.1 Tableau des Niveaux

| Niveau | Code | Padding | Couleur Console | Usage |
|--------|------|---------|-----------------|-------|
| `FATAL` | 0 | 7 car. | Magenta | Erreur critique causant l'arret immediat |
| `ERROR` | 3 | 7 car. | Rouge | Erreur empechant une operation |
| `WARNING` | 4 | 7 car. | Jaune | Situation anormale non bloquante |
| `SUCCESS` | 5 | 7 car. | Vert | Operation reussie (extension custom) |
| `INFO` | 6 | 7 car. | Blanc | Evenement normal significatif |
| `DEBUG` | 7 | 7 car. | Gris | Diagnostic (desactive en production) |

### 4.2 Correspondance RFC 5424 Syslog

| RFC 5424 Level | Code | Notre Equivalent |
|----------------|------|------------------|
| Emergency | 0 | FATAL |
| Alert | 1 | FATAL |
| Critical | 2 | FATAL |
| Error | 3 | ERROR |
| Warning | 4 | WARNING |
| Notice | 5 | SUCCESS/INFO |
| Informational | 6 | INFO |
| Debug | 7 | DEBUG |

### 4.3 Quand Utiliser Chaque Niveau

```powershell
# FATAL - Arret immediat requis
Write-Log "Certificat expire - impossible de continuer" -Level FATAL
exit 1

# ERROR - Operation echouee mais script continue
Write-Log "Mailbox user@contoso.com introuvable" -Level ERROR

# WARNING - Situation anormale mais geree
Write-Log "Delai de reponse Exchange > 30s" -Level WARNING

# SUCCESS - Operation reussie (confirmation)
Write-Log "Litigation Hold active sur 45 mailboxes" -Level SUCCESS

# INFO - Progression normale
Write-Log "Traitement lot 3/10..." -Level INFO

# DEBUG - Details techniques (dev/debug)
Write-Log "Requete EXO: Get-Mailbox -Filter {...}" -Level DEBUG
```

---

## 5. Format Timestamp ISO 8601

### 5.1 Specification

```
yyyy-MM-ddTHH:mm:ss.fffzzz
```

| Composant | Format | Exemple | Description |
|-----------|--------|---------|-------------|
| Date | `yyyy-MM-dd` | 2025-12-02 | Annee-Mois-Jour |
| Separateur | `T` | T | Lettre T majuscule |
| Heure | `HH:mm:ss` | 14:30:45 | 24h avec secondes |
| Millisecondes | `.fff` | .123 | 3 decimales |
| Timezone | `zzz` | +01:00 | Offset UTC avec : |

### 5.2 Exemples par Timezone

```
# France (CET/CEST)
2025-12-02T14:30:45.123+01:00  # Hiver (CET)
2025-07-15T14:30:45.123+02:00  # Ete (CEST)

# UTC
2025-12-02T13:30:45.123+00:00

# US Eastern
2025-12-02T08:30:45.123-05:00
```

### 5.3 Code PowerShell

```powershell
# Generation timestamp ISO 8601
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffzzz"
# Resultat: 2025-12-02T14:30:45.123+01:00
```

---

## 6. Configuration SIEM

### 6.1 Splunk - props.conf

```ini
[exchange_litigation]
TIME_FORMAT = %Y-%m-%dT%H:%M:%S.%3N%:z
TIME_PREFIX = ^
MAX_TIMESTAMP_LOOKAHEAD = 29
SHOULD_LINEMERGE = false
LINE_BREAKER = ([\r\n]+)
TRUNCATE = 10000

# Extraction des champs
EXTRACT-fields = ^(?<timestamp>[^\|]+)\s*\|\s*(?<level>\w+)\s*\|\s*(?<hostname>[^\|]+)\s*\|\s*(?<script>[^\|]+)\s*\|\s*(?<pid>PID:\d+)\s*\|\s*(?<message>.*)$
```

### 6.2 Splunk - transforms.conf

```ini
[exchange_level_extraction]
REGEX = \|\s*(\w+)\s*\|
FORMAT = level::$1
```

### 6.3 ELK Stack - Logstash Filter

```ruby
filter {
  if [type] == "exchange_litigation" {
    grok {
      match => {
        "message" => "^%{TIMESTAMP_ISO8601:timestamp}\s*\|\s*%{WORD:level}\s*\|\s*%{DATA:hostname}\s*\|\s*%{DATA:script}\s*\|%{DATA:pid}\s*\|\s*%{GREEDYDATA:log_message}$"
      }
    }
    date {
      match => [ "timestamp", "ISO8601" ]
      target => "@timestamp"
    }
    mutate {
      strip => ["level", "hostname", "script", "pid", "log_message"]
    }
  }
}
```

### 6.4 Azure Sentinel - KQL Query

```kusto
// Parser les logs Exchange Litigation Hold
let ExchangeLogs = ExternalData(RawLog: string)
| parse RawLog with
    Timestamp:datetime " | "
    Level:string " | "
    Hostname:string " | "
    Script:string " | "
    PID:string " | "
    Message:string
| extend Level = trim(" ", Level)
| extend Hostname = trim(" ", Hostname);

// Alertes sur erreurs
ExchangeLogs
| where Level in ("ERROR", "FATAL")
| summarize Count = count() by Script, Level, bin(Timestamp, 1h)
| where Count > 5
```

### 6.5 Graylog - Extractor

```json
{
  "extractors": [{
    "title": "Exchange Log Parser",
    "type": "REGEX",
    "configuration": {
      "regex_value": "^([^|]+)\\s*\\|\\s*(\\w+)\\s*\\|\\s*([^|]+)\\s*\\|\\s*([^|]+)\\s*\\|\\s*([^|]+)\\s*\\|\\s*(.*)$"
    },
    "converters": [],
    "order": 0,
    "cursor_strategy": "COPY",
    "target_field": "",
    "source_field": "message",
    "condition_type": "NONE"
  }]
}
```

---

## 7. Regex de Parsing

### 7.1 Regex Complete (PCRE)

```regex
^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}[+-]\d{2}:\d{2})\s*\|\s*(DEBUG|INFO|SUCCESS|WARNING|ERROR|FATAL)\s*\|\s*([^\|]+)\s*\|\s*([^\|]+)\s*\|\s*(PID:\d+)\s*\|\s*(.*)$
```

### 7.2 Groupes de Capture

| Groupe | Contenu | Exemple |
|--------|---------|---------|
| $1 | Timestamp | 2025-12-02T14:30:45.123+01:00 |
| $2 | Level | INFO |
| $3 | Hostname | SRV01 |
| $4 | Script | Enable-LitigationHold |
| $5 | PID | PID:12345 |
| $6 | Message | Demarrage du script v1.5 |

### 7.3 PowerShell - Exemple de Parsing

```powershell
$pattern = '^(?<timestamp>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}[+-]\d{2}:\d{2})\s*\|\s*(?<level>\w+)\s*\|\s*(?<hostname>[^\|]+)\s*\|\s*(?<script>[^\|]+)\s*\|\s*(?<pid>PID:\d+)\s*\|\s*(?<message>.*)$'

Get-Content "LitigationHold_2025-12-02.log" | ForEach-Object {
    if ($_ -match $pattern) {
        [PSCustomObject]@{
            Timestamp = [datetime]$Matches.timestamp
            Level     = $Matches.level.Trim()
            Hostname  = $Matches.hostname.Trim()
            Script    = $Matches.script.Trim()
            PID       = $Matches.pid.Trim()
            Message   = $Matches.message.Trim()
        }
    }
} | Where-Object { $_.Level -eq "ERROR" }
```

---

## 8. Nomenclature des Fichiers

### 8.1 Fichiers de Log

| Type | Pattern | Exemple |
|------|---------|---------|
| Log journalier | `{Script}_{yyyy-MM-dd}.log` | `LitigationHold_2025-12-02.log` |
| Transcript debug | `Transcript-{Script}.txt` | `Transcript-LitigationHold.txt` |
| Archive | `Archive/{Script}_{yyyy-MM-dd}.log` | `Archive/LitigationHold_2025-11-01.log` |

### 8.2 Arborescence

```
<ScriptDir>/
+-- Logs/
|   +-- LitigationHold_2025-12-02.log      # Log structure (rotation journaliere)
|   +-- MailboxCreation_2025-12-02.log     # Log structure (rotation journaliere)
|   +-- Transcript-LitigationHold.txt      # Debug (ecrase a chaque run)
|   +-- Transcript-MailboxCreation.txt     # Debug (ecrase a chaque run)
|   +-- Archive/                           # Logs > 30 jours
|       +-- LitigationHold_2025-11-01.log
+-- Reports/
    +-- Archive/                           # Reports > 30 jours
```

---

## 9. Politique de Retention

| Type | Retention Active | Archive | Purge |
|------|------------------|---------|-------|
| Logs `.log` | 30 jours | Oui | 365 jours |
| Transcripts | Derniere execution | Non | Ecrase |
| Reports HTML | 30 jours | Oui | 365 jours |

---

## 10. Module Write-Log.psm1

Le module complet est fourni en annexe de ce document.
Une copie isolee est disponible dans : `Audit/Write-Log.psm1`

### 10.1 Utilisation Basique

```powershell
# Import du module
Import-Module "$PSScriptRoot\Common\Modules\Write-Log.psm1"

# Configuration des variables globales
$Script:LogFile = "$PSScriptRoot\Logs\MonScript_$(Get-Date -Format 'yyyy-MM-dd').log"
$Script:ScriptName = "MonScript"

# Utilisation
Write-Log "Demarrage du script" -Level INFO
Write-Log "Operation reussie" -Level SUCCESS
Write-Log "Attention: delai eleve" -Level WARNING
Write-Log "Erreur de connexion" -Level ERROR
```

### 10.2 Parametres

| Parametre | Type | Obligatoire | Description |
|-----------|------|-------------|-------------|
| Message | string | Oui | Message a logger |
| Level | string | Non | Niveau (defaut: INFO) |
| NoConsole | switch | Non | Desactive affichage console |
| LogFile | string | Non | Chemin fichier (defaut: $Script:LogFile) |
| ScriptName | string | Non | Nom script (defaut: $Script:ScriptName) |

---

## 11. Bonnes Pratiques

### 11.1 A Faire

- Utiliser le niveau `INFO` pour le flux normal
- Utiliser `SUCCESS` uniquement pour confirmer les operations critiques
- Logger les parametres d'entree au niveau `DEBUG`
- Inclure le contexte dans les messages d'erreur (identifiant, valeurs)

### 11.2 A Eviter

- Ne pas logger de donnees sensibles (mots de passe, tokens)
- Ne pas utiliser `DEBUG` en production
- Ne pas logger dans une boucle chaude (performance)
- Ne pas inclure de stacktrace completes dans les logs structures

### 11.3 Exemple Message d'Erreur

```powershell
# BON - Contexte inclus
Write-Log "Echec activation LitHold pour user@contoso.com : $_" -Level ERROR

# MAUVAIS - Pas de contexte
Write-Log "Erreur" -Level ERROR
```

---

## 12. References

- [RFC 5424 - The Syslog Protocol](https://datatracker.ietf.org/doc/html/rfc5424)
- [RFC 3339 - Date and Time on the Internet](https://datatracker.ietf.org/doc/html/rfc3339)
- [ISO 8601 - Date and Time Format](https://en.wikipedia.org/wiki/ISO_8601)
- [Splunk - Configure timestamp recognition](https://docs.splunk.com/Documentation/Splunk/latest/Data/Configuretimestamprecognition)
- [ELK - Date Filter Plugin](https://www.elastic.co/guide/en/logstash/current/plugins-filters-date.html)
- [Azure Sentinel - KQL Quick Reference](https://docs.microsoft.com/en-us/azure/data-explorer/kusto/query/)

---

**Document interne - Usage reference uniquement**
