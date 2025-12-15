# [~] [FEAT-007] Support fichier de configuration Settings.json | Effort: 1h

## PROBLEME

Le script `Get-ExchangeDelegation.ps1` a toute sa configuration hardcodee dans le code (L91-156). Le dossier `Config/` existe avec un template `Settings.example.json` mais n'est jamais utilise. Cela rend difficile la personnalisation sans modifier le code source.

## LOCALISATION

- Fichier : Get-ExchangeDelegation.ps1:L91-156
- Dossier : Config/Settings.example.json (template non utilise)
- Module : Configuration region

## OBJECTIF

Charger la configuration depuis `Config/Settings.json` si le fichier existe, sinon utiliser les valeurs par defaut hardcodees. Permettre la personnalisation de :
- Chemins (Logs, Output)
- Niveau de log
- Retention des fichiers
- Comptes systeme a exclure (optionnel)

---

## IMPLEMENTATION

### Etape 1 : Creer fonction de chargement config - 20min
Fichier : Get-ExchangeDelegation.ps1

AJOUTER apres L97 :

```powershell
function Get-ScriptConfiguration {
    <#
    .SYNOPSIS
        Charge la configuration depuis Settings.json ou retourne les defauts.
    #>
    [CmdletBinding()]
    param()

    $configPath = Join-Path $PSScriptRoot "Config\Settings.json"
    $defaultConfig = @{
        Application = @{
            Name        = "Get-ExchangeDelegation"
            Environment = "PROD"
            LogLevel    = "Info"
        }
        Paths = @{
            Logs   = "./Logs"
            Output = "./Output"
        }
        Retention = @{
            LogDays    = 30
            OutputDays = 7
        }
    }

    if (Test-Path $configPath) {
        try {
            $fileConfig = Get-Content $configPath -Raw | ConvertFrom-Json -AsHashtable
            Write-Log "Configuration chargee depuis $configPath" -Level INFO
            return $fileConfig
        }
        catch {
            Write-Log "Erreur lecture config, utilisation defauts: $($_.Exception.Message)" -Level WARNING
            return $defaultConfig
        }
    }

    return $defaultConfig
}
```

### Etape 2 : Utiliser la configuration - 15min
Fichier : Get-ExchangeDelegation.ps1

AVANT (L101-103) :
```powershell
if ([string]::IsNullOrEmpty($OutputPath)) {
    $OutputPath = Join-Path $PSScriptRoot "Output"
}
```

APRES :
```powershell
# Charger configuration
$script:Config = Get-ScriptConfiguration

# OutputPath par defaut depuis config
if ([string]::IsNullOrEmpty($OutputPath)) {
    $OutputPath = Join-Path $PSScriptRoot $script:Config.Paths.Output
}
```

### Etape 3 : Utiliser LogPath depuis config - 10min
Fichier : Get-ExchangeDelegation.ps1

AVANT (L121) :
```powershell
Initialize-Log -Path "$PSScriptRoot\Logs"
```

APRES :
```powershell
$logPath = Join-Path $PSScriptRoot $script:Config.Paths.Logs
Initialize-Log -Path $logPath
```

### Etape 4 : Mettre a jour Settings.example.json - 10min
Fichier : Config/Settings.example.json

```json
{
    "_comment": "Copier vers Settings.json et adapter les valeurs",
    "_version": "1.0.0",

    "Application": {
        "Name": "Get-ExchangeDelegation",
        "Environment": "PROD",
        "LogLevel": "Info"
    },

    "Paths": {
        "Logs": "./Logs",
        "Output": "./Output"
    },

    "Retention": {
        "LogDays": 30,
        "OutputDays": 7
    }
}
```

---

## VALIDATION

### Criteres d'Acceptation

- [ ] Script fonctionne sans Settings.json (valeurs par defaut)
- [ ] Script charge Settings.json si present
- [ ] OutputPath peut etre override par parametre CLI
- [ ] Logs generes dans le chemin configure
- [ ] Message de log indique la source de config (fichier ou defaut)
- [ ] Pas de regression sur fonctionnalites existantes

### Tests Manuels

```powershell
# Test 1 : Sans Settings.json (defauts)
Remove-Item Config/Settings.json -ErrorAction SilentlyContinue
.\Get-ExchangeDelegation.ps1 -WhatIf
# Verifier : Output dans ./Output, Logs dans ./Logs

# Test 2 : Avec Settings.json
Copy-Item Config/Settings.example.json Config/Settings.json
# Modifier Output vers ./CustomOutput
.\Get-ExchangeDelegation.ps1 -WhatIf
# Verifier : Output dans ./CustomOutput

# Test 3 : Override CLI
.\Get-ExchangeDelegation.ps1 -OutputPath "C:\Temp" -WhatIf
# Verifier : Output dans C:\Temp (priorite au parametre)
```

---

## DEPENDANCES

- Bloquee par : Aucune
- Bloque : Aucune

## POINTS ATTENTION

- 1 fichier modifie (Get-ExchangeDelegation.ps1)
- ~40 lignes ajoutees
- Risques : Faibles (fallback sur defauts si erreur)

## CHECKLIST

- [ ] Code AVANT = code reel verifie
- [ ] Tests manuels passent
- [ ] Settings.example.json a jour

Labels : feat moyenne script-principal effort-1h

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | # |
| Statut | RESOLVED |
| Branche | feature/FEAT-007-support-fichier-configuration |
