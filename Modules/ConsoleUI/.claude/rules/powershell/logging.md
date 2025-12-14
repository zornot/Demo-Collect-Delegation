# Module Write-Log - Standard de Logging

## Vue d'ensemble

Module de logging centralise compatible SIEM (Splunk, ELK, Azure Sentinel, Graylog).

**Standards appliques** :
- RFC 5424 : Syslog Protocol (niveaux de severite)
- ISO 8601 : Format timestamp avec timezone
- RFC 3339 : Date-time Internet
- UTF-8 : Encodage sans BOM

---

## Installation

Le module Write-Log est disponible sur GitHub : https://github.com/zornot/Module-Write-Log

### Option 1 : Clone direct (recommande)

```powershell
# Cloner le module dans Modules/
git clone https://github.com/zornot/Module-Write-Log.git Modules/Write-Log

# Import dans le script
Import-Module "$PSScriptRoot\Modules\Write-Log\Write-Log.psm1"
```

### Option 2 : Git submodule (pour projets versionnes)

```powershell
# Ajouter comme submodule
git submodule add https://github.com/zornot/Module-Write-Log.git Modules/Write-Log

# Apres clone du projet parent
git submodule update --init --recursive
```

### Option 3 : Telecharger manuellement

```powershell
# Telecharger depuis GitHub Releases ou copier le dossier
# Structure attendue : Modules/Write-Log/Write-Log.psm1
```

---

## Initialisation (MUST)

```powershell
# [-] INTERDIT : Variables manuelles
$Script:LogFile = ".\Logs\script.log"

# [+] OBLIGATOIRE : Utiliser Initialize-Log
Initialize-Log -Path ".\Logs"
# Configure automatiquement $Script:LogFile et $Script:ScriptName
```

---

## Format de Log (MUST)

### Structure ligne
```
TIMESTAMP | LEVEL | HOSTNAME | SCRIPT | PID:xxxxx | MESSAGE
```

### Exemple
```
2025-12-02T14:30:45.123+01:00 | INFO    | SRV01 | MonScript | PID:12345 | Demarrage du script
2025-12-02T14:30:46.456+01:00 | SUCCESS | SRV01 | MonScript | PID:12345 | Operation terminee
2025-12-02T14:30:47.789+01:00 | ERROR   | SRV01 | MonScript | PID:12345 | Echec connexion: timeout
```

### Timestamp ISO 8601
```
yyyy-MM-ddTHH:mm:ss.fffzzz
2025-12-02T14:30:45.123+01:00
```

---

## Niveaux de Severite (MUST)

| Niveau | Code RFC | Couleur | Usage |
|--------|----------|---------|-------|
| `DEBUG` | 7 | Gray | Diagnostic (dev uniquement) |
| `INFO` | 6 | White | Evenement normal |
| `SUCCESS` | 5 | Green | Operation reussie |
| `WARNING` | 4 | Yellow | Situation anormale non bloquante |
| `ERROR` | 3 | Red | Erreur recuperable |
| `FATAL` | 0-2 | Magenta | Erreur critique, arret immediat |

### Quand utiliser chaque niveau

```powershell
# FATAL - Arret immediat requis
Write-Log "Certificat expire - impossible de continuer" -Level FATAL
exit 1

# ERROR - Operation echouee mais script continue
Write-Log "Mailbox user@contoso.com introuvable" -Level ERROR

# WARNING - Situation anormale mais geree
Write-Log "Delai de reponse Exchange > 30s" -Level WARNING

# SUCCESS - Confirmation operation critique
Write-Log "Litigation Hold active sur 45 mailboxes" -Level SUCCESS

# INFO - Progression normale
Write-Log "Traitement lot 3/10..." -Level INFO

# DEBUG - Details techniques (jamais en production)
Write-Log "Requete EXO: Get-Mailbox -Filter {...}" -Level DEBUG
```

---

## Fonctions Disponibles

### Write-Log
```powershell
Write-Log -Message "Message" -Level INFO
Write-Log "Message" -Level SUCCESS
Write-Log "Erreur critique" -Level FATAL -NoConsole
```

| Parametre | Type | Obligatoire | Description |
|-----------|------|-------------|-------------|
| Message | string | Oui | Message a logger |
| Level | string | Non | Niveau (defaut: INFO) |
| NoConsole | switch | Non | Desactive affichage console |
| LogFile | string | Non | Override $Script:LogFile |
| ScriptName | string | Non | Override $Script:ScriptName |

### Initialize-Log
```powershell
Initialize-Log -Path ".\Logs"
Initialize-Log -Path ".\Logs" -ScriptName "MonScript"
```

| Parametre | Type | Obligatoire | Description |
|-----------|------|-------------|-------------|
| Path | string | Non | Dossier logs (defaut: .\Logs) |
| ScriptName | string | Non | Nom script (auto-detecte si omis) |

### Invoke-LogRotation
```powershell
Invoke-LogRotation -Path ".\Logs" -RetentionDays 30
Invoke-LogRotation -Path ".\Logs" -RetentionDays 7 -WhatIf
```

| Parametre | Type | Obligatoire | Description |
|-----------|------|-------------|-------------|
| Path | string | Oui | Dossier logs |
| RetentionDays | int | Non | Retention en jours (defaut: 30) |
| Filter | string | Non | Filtre fichiers (defaut: *.log) |

---

## Template Script avec Write-Log (MUST)

```powershell
#Requires -Version 7.2

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Import module logging
Import-Module "$PSScriptRoot\Modules\Write-Log\Write-Log.psm1"

# Initialisation logging
Initialize-Log -Path "$PSScriptRoot\Logs"

try {
    Write-Log "Demarrage du script" -Level INFO

    # === VOTRE CODE ICI ===

    Write-Log "Script termine avec succes" -Level SUCCESS
    exit 0
}
catch {
    Write-Log "Erreur fatale: $($_.Exception.Message)" -Level FATAL
    exit 1
}
finally {
    # Rotation des logs (optionnel)
    Invoke-LogRotation -Path "$PSScriptRoot\Logs" -RetentionDays 30
}
```

---

## Versioning dans Scripts

```powershell
<#
.SYNOPSIS
    Description du script.
.NOTES
    Version: 2.1.3
    Date: 2025-12-07
    Changelog:
        2.1.3 - Fix: Correction validation input
        2.1.2 - Fix: Gestion timeout API
        2.1.0 - Feat: Ajout export CSV
        2.0.0 - Breaking: Nouveau format config
#>

# Variable de version accessible
$script:Version = "2.1.3"

# Afficher dans banniere
Write-Banner -Title "MON SCRIPT" -Version $script:Version
```

Le pattern `$script:Version` permet :
- Affichage dans la banniere
- Logging de la version
- Verification de compatibilite

---

## Regles MUST

| Regle | Implementation |
|-------|----------------|
| Initialiser avec Initialize-Log | `Initialize-Log -Path ".\Logs"` |
| Niveau explicite pour erreurs | `-Level ERROR` ou `-Level FATAL` |
| Context dans messages erreur | Inclure identifiant, valeur concernee |
| UTF-8 sans BOM | Gere par le module |
| Jamais DEBUG en production | Desactiver avant deploiement |

## Regles SHOULD

| Regle | Implementation |
|-------|----------------|
| Rotation reguliere | `Invoke-LogRotation` en finally |
| SUCCESS pour operations critiques | Confirmer les actions importantes |
| Message informatif | Inclure le contexte (qui, quoi, combien) |

---

## Anti-Patterns

```powershell
# [-] Pas de contexte
Write-Log "Erreur" -Level ERROR

# [+] Contexte inclus
Write-Log "Echec traitement user@contoso.com: $($_.Exception.Message)" -Level ERROR

# [-] DEBUG en production
Write-Log "Variable = $value" -Level DEBUG

# [+] INFO en production
Write-Log "Traitement de $count elements" -Level INFO

# [-] Donnees sensibles
Write-Log "Connexion avec password: $password" -Level DEBUG

# [+] Masquer les donnees sensibles
Write-Log "Connexion etablie avec credentials" -Level INFO
```

---

## Nomenclature Fichiers

| Type | Pattern | Exemple |
|------|---------|---------|
| Log journalier | `{Script}_{yyyy-MM-dd}.log` | `MonScript_2025-12-02.log` |
| Archive | `Archive/{Script}_{yyyy-MM-dd}.log` | Logs > 30 jours |

---

## Compatibilite SIEM

### Regex de parsing
```regex
^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}[+-]\d{2}:\d{2})\s*\|\s*(DEBUG|INFO|SUCCESS|WARNING|ERROR|FATAL)\s*\|\s*([^\|]+)\s*\|\s*([^\|]+)\s*\|\s*(PID:\d+)\s*\|\s*(.*)$
```

### Groupes de capture
| Groupe | Contenu |
|--------|---------|
| $1 | Timestamp |
| $2 | Level |
| $3 | Hostname |
| $4 | Script |
| $5 | PID |
| $6 | Message |

---

## References

- [Module Write-Log (GitHub)](https://github.com/zornot/Module-Write-Log)
- [RFC 5424 - Syslog Protocol](https://datatracker.ietf.org/doc/html/rfc5424)
- [ISO 8601 - Date Time Format](https://en.wikipedia.org/wiki/ISO_8601)
