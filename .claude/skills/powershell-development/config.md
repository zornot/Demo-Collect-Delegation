# Configuration PowerShell

## Regle Universelle

**TOUT parametre configurable → Config/Settings.json**

### Quand utiliser Settings.json

| Categorie | Exemples | Section Settings |
|-----------|----------|------------------|
| Chemins | Logs, Output, Backup | `Paths` |
| Connexions | Tenant, Organization, SMTP | `Exchange`, `Authentication` |
| Comportements | Retention, Timeout, Threshold | `Retention`, `Application` |
| Modules | Parametres specifiques module | Section dediee par module |

### Pattern Modules

Le bootstrap genere automatiquement les sections selon les modules installes :

| Module | Section Settings.json |
|--------|----------------------|
| Write-Log | (aucune - utilise Initialize-Log) |
| Checkpoint | `Checkpoint` |
| GraphConnection | `GraphConnection` |
| EXOConnection | (aucune - parametres directs) |
| ConsoleUI | (aucune - module UI) |
| [Nouveau module] | [Nouvelle section dediee] |

**Regle** : Lors de l'ajout d'une fonctionnalite necesitant configuration, etendre Settings.json.

---

## Convention Module → Configuration

Chaque module qui necessite configuration DOIT declarer ses besoins dans son `CLAUDE.md`.

### Format Standard

Le CLAUDE.md du module doit contenir :

```markdown
## Configuration Requise

| Section | Obligatoire | Description |
|---------|-------------|-------------|
| `nomSection` | Oui/Non | Description courte |

### Template Settings.json

```json
{
    "nomSection": {
        "param1": "valeur_exemple",
        "param2": 123
    }
}
```
```

### Pourquoi cette convention ?

| Avantage | Explication |
|----------|-------------|
| **Decouverte automatique** | `/create-script` lit les besoins dynamiquement |
| **Pas de liste hardcodee** | Nouveau module = ajouter section, rien d'autre |
| **Auto-documentation** | Le module documente ses propres besoins |
| **Centralisation** | Settings.json reste la source unique |

### Workflow /create-script

Quand `/create-script` est execute :

1. Lister les modules dans `Modules/`
2. Identifier les modules utilises par le script
3. Pour chaque module, lire son `CLAUDE.md`
4. Extraire la section "Configuration Requise"
5. Synchroniser Settings.json avec les sections manquantes

---

## Pattern Configuration (MUST)

```
Config/
├── Settings.example.json    # Template (versionné, valeurs fictives)
├── Settings.json            # Production (gitignore, valeurs réelles)
└── README.md                # Instructions
```

## Settings.example.json (Template)

```json
{
    "_comment": "Copier vers Settings.json et remplir les vraies valeurs",
    "_version": "1.0.0",
    
    "Application": {
        "Name": "MonProjet",
        "Environment": "DEV|PPD|PRD",
        "LogLevel": "Info|Debug|Warning|Error"
    },
    
    "Exchange": {
        "Organization": "contoso.onmicrosoft.com",
        "AppId": "00000000-0000-0000-0000-000000000000",
        "CertThumbprint": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    },
    
    "Email": {
        "SmtpServer": "smtp.contoso.com",
        "From": "noreply@contoso.com",
        "To": ["admin@contoso.com"],
        "Enabled": true
    },
    
    "Paths": {
        "Logs": "./Logs",
        "Output": "./Output",
        "Backup": "./Backups"
    },
    
    "Retention": {
        "LogDays": 90,
        "OutputDays": 30,
        "BackupCount": 10
    }
}
```

## Fonction Get-ProjectConfig

```powershell
function Get-ProjectConfig {
    <#
    .SYNOPSIS
        Charge la configuration du projet
    .PARAMETER ConfigPath
        Chemin vers Settings.json
    .EXAMPLE
        $config = Get-ProjectConfig
        $config.Exchange.Organization
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [ValidateScript({ Test-Path (Split-Path $_ -Parent) })]
        [string]$ConfigPath = "$PSScriptRoot/Config/Settings.json"
    )
    
    if (-not (Test-Path $ConfigPath)) {
        throw "Configuration non trouvée: $ConfigPath. Copier Settings.example.json vers Settings.json"
    }
    
    try {
        $config = Get-Content -Path $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
        return $config
    }
    catch {
        throw "Erreur lecture configuration: $($_.Exception.Message)"
    }
}
```

## Priorité Configuration (MUST)

```powershell
# Priorité : Variable env > Config file > Défaut
$organization = $env:EXO_ORGANIZATION ?? 
                $config.Exchange.Organization ?? 
                "default.onmicrosoft.com"

$logLevel = $env:LOG_LEVEL ?? 
            $config.Application.LogLevel ?? 
            "Info"
```

## Validation Configuration

```powershell
function Test-ProjectConfig {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Config
    )
    
    $required = @(
        'Application.Name',
        'Exchange.Organization',
        'Paths.Logs'
    )
    
    $missing = [System.Collections.Generic.List[string]]::new()
    
    foreach ($path in $required) {
        $parts = $path -split '\.'
        $value = $Config
        foreach ($part in $parts) {
            $value = $value.$part
        }
        if ([string]::IsNullOrEmpty($value)) {
            $missing.Add($path)
        }
    }
    
    if ($missing.Count -gt 0) {
        Write-Warning "Configuration manquante: $($missing -join ', ')"
        return $false
    }
    
    return $true
}
```

## Variables d'Environnement (CI/CD)

```powershell
# Définir
$env:EXO_ORGANIZATION = "contoso.onmicrosoft.com"
$env:API_KEY = "secret-key"

# Utiliser avec validation
function Get-RequiredEnvVar {
    param([string]$Name)
    
    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrEmpty($value)) {
        throw "Variable d'environnement requise non définie: $Name"
    }
    return $value
}

$apiKey = Get-RequiredEnvVar -Name "API_KEY"
```

## Config par Environnement

```powershell
function Get-EnvironmentConfig {
    [CmdletBinding()]
    param(
        [ValidateSet('DEV', 'PPD', 'PRD')]
        [string]$Environment = ($env:ENVIRONMENT ?? 'DEV')
    )
    
    $configFile = switch ($Environment) {
        'DEV' { "Settings.dev.json" }
        'PPD' { "Settings.ppd.json" }
        'PRD' { "Settings.json" }
    }
    
    return Get-ProjectConfig -ConfigPath "./Config/$configFile"
}
```

## Secrets (MUST)

```powershell
# [-] JAMAIS dans le code
$password = "P@ssw0rd"

# [+] Variables d'environnement
$password = $env:SERVICE_PASSWORD

# [+] Azure Key Vault
$secret = Get-AzKeyVaultSecret -VaultName "MyVault" -Name "MySecret"

# [+] Fichier chiffré local (dev uniquement)
$cred = Import-Clixml -Path "./Config/credential.xml"
```

## Microsoft Graph (Module-GraphConnection)

Pour les scripts necessitant une connexion Microsoft Graph, utiliser le module
**Module-GraphConnection** : https://github.com/zornot/Module-GraphConnection

### Installation

```powershell
# Via /bootstrap-project (recommande)
# Ou manuellement :
git clone https://github.com/zornot/Module-GraphConnection.git .temp-module
Copy-Item .temp-module/Module/* Modules/GraphConnection/ -Recurse
Remove-Item .temp-module -Recurse -Force
```

### Configuration Settings.json

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

### Usage

```powershell
Import-Module "$PSScriptRoot\Modules\GraphConnection\GraphConnection.psd1" -Force -ErrorAction Stop

# Initialiser et connecter
$graphConfig = $config.GraphConnection
if (Connect-GraphConnection -TenantId $graphConfig.tenantId -ClientId $graphConfig.clientId) {
    # Operations Microsoft Graph...
    Disconnect-GraphConnection
}
```

### Modes d'authentification

| Mode | Usage | Secret |
|------|-------|--------|
| `Interactive` | Dev/Admin | Aucun (navigateur) |
| `Certificate` | Production | Certificat local |
| `ClientSecret` | CI/CD | Variable d'env |
| `ManagedIdentity` | Azure | Zero secret |
