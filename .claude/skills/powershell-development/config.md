# Configuration PowerShell

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

## Microsoft Graph (Module-MgConnection)

Pour les scripts necessitant une connexion Microsoft Graph, utiliser le module
**Module-MgConnection** : https://github.com/zornot/Module-MgConnection

### Installation

```powershell
git clone https://github.com/zornot/Module-MgConnection.git Modules/MgConnection
```

### Configuration Settings.json

```json
{
    "authentication": {
        "mode": "Interactive",
        "tenantId": "00000000-0000-0000-0000-000000000000",
        "interactive": {
            "scopes": ["Application.Read.All", "Directory.Read.All"],
            "useWAM": false
        },
        "certificate": {
            "clientId": "00000000-0000-0000-0000-000000000000",
            "thumbprint": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
        },
        "clientSecret": {
            "clientId": "00000000-0000-0000-0000-000000000000",
            "secretVariable": "MG_CLIENT_SECRET"
        },
        "retryCount": 3,
        "retryDelaySeconds": 2
    }
}
```

### Usage

```powershell
Import-Module "$PSScriptRoot\Modules\MgConnection\MgConnection.psm1"

# Initialiser et connecter
Initialize-MgConnection -ConfigPath ".\Config\Settings.json"
if (Connect-MgConnection) {
    # Operations Microsoft Graph...
    Disconnect-MgConnection
}
```

### Modes d'authentification

| Mode | Usage | Secret |
|------|-------|--------|
| `Interactive` | Dev/Admin | Aucun (navigateur) |
| `Certificate` | Production | Certificat local |
| `ClientSecret` | CI/CD | Variable d'env |
| `ManagedIdentity` | Azure | Zero secret |
