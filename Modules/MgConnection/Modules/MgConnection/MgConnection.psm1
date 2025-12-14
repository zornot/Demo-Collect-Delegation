<#
.SYNOPSIS
    Module de connexion Microsoft Graph config-driven.

.DESCRIPTION
    Fournit une connexion centralisee a Microsoft Graph avec configuration via fichier JSON.

    MODES D'AUTHENTIFICATION :
    - Interactive   : Authentification utilisateur via navigateur (dev/admin)
    - Certificate   : Authentification par certificat (production recommandee)
    - ClientSecret  : Authentification par secret client (CI/CD)
    - ManagedIdentity : Identite geree Azure (zero secret)

    SECURITE :
    - Cache persistant configurable via ContextScope (CurrentUser/Process)
    - Secrets lus depuis variables d'environnement (jamais en dur)
    - Retry configurable pour resilience

    USAGE :
    1. Configurer Settings.json avec section 'authentication'
    2. Initialize-MgConnection -ConfigPath ".\Config\Settings.json"
    3. Connect-MgConnection
#>

#region Script Variables
# Stockage du chemin de configuration pour usage ulterieur
$Script:ConfigPath = $null
$Script:Config = $null
#endregion Script Variables

#region Public Functions

function Get-MgConnectionConfig {
    <#
    .SYNOPSIS
        Charge la configuration d'authentification depuis un fichier JSON
    .PARAMETER ConfigPath
        Chemin vers le fichier Settings.json
    .EXAMPLE
        $config = Get-MgConnectionConfig -ConfigPath ".\Config\Settings.json"
    .OUTPUTS
        [PSCustomObject] Configuration d'authentification
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath
    )

    if (-not (Test-Path $ConfigPath)) {
        throw "Configuration file not found: $ConfigPath"
    }

    try {
        $content = Get-Content -Path $ConfigPath -Raw -Encoding UTF8
        $config = $content | ConvertFrom-Json -ErrorAction Stop
        return $config
    }
    catch {
        throw "Failed to parse configuration file: $($_.Exception.Message)"
    }
}

function Initialize-MgConnection {
    <#
    .SYNOPSIS
        Initialise le module avec le chemin de configuration
    .DESCRIPTION
        Stocke le chemin de configuration pour les appels ulterieurs
        a Connect-MgConnection sans parametre.
    .PARAMETER ConfigPath
        Chemin vers le fichier Settings.json
    .EXAMPLE
        Initialize-MgConnection -ConfigPath ".\Config\Settings.json"
        Connect-MgConnection  # Utilise le chemin stocke
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ })]
        [string]$ConfigPath
    )

    $Script:ConfigPath = $ConfigPath
    $Script:Config = Get-MgConnectionConfig -ConfigPath $ConfigPath
    Write-Verbose "[i] MgConnection initialise avec: $ConfigPath"
}

function Connect-MgConnection {
    <#
    .SYNOPSIS
        Etablit une connexion Microsoft Graph basee sur la configuration
    .DESCRIPTION
        Lit le mode d'authentification depuis Settings.json et etablit
        la connexion appropriee. Supporte 4 modes:
        - Interactive : Authentification utilisateur (defaut)
        - Certificate : Authentification par certificat
        - ClientSecret : Authentification par secret client
        - ManagedIdentity : Identite geree Azure
    .PARAMETER ConfigPath
        Chemin vers Settings.json (optionnel si Initialize-MgConnection appele)
    .PARAMETER Mode
        Override du mode configure (Interactive, Certificate, ClientSecret, ManagedIdentity)
    .EXAMPLE
        Connect-MgConnection -ConfigPath ".\Config\Settings.json"
    .EXAMPLE
        Connect-MgConnection -Mode Certificate
    .OUTPUTS
        [bool] $true si connexion reussie, $false sinon
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter()]
        [string]$ConfigPath,

        [Parameter()]
        [ValidateSet('Interactive', 'Certificate', 'ClientSecret', 'ManagedIdentity')]
        [string]$Mode
    )

    # Determiner le chemin de configuration
    $effectiveConfigPath = $ConfigPath
    if ([string]::IsNullOrEmpty($effectiveConfigPath)) {
        $effectiveConfigPath = $Script:ConfigPath
    }

    if ([string]::IsNullOrEmpty($effectiveConfigPath)) {
        throw "ConfigPath required. Call Initialize-MgConnection first or provide -ConfigPath parameter."
    }

    # Charger configuration
    $config = Get-MgConnectionConfig -ConfigPath $effectiveConfigPath

    # Determiner le mode: parametre > config (PAS DE FALLBACK si config chargee)
    $authMode = $Mode
    if ([string]::IsNullOrEmpty($authMode)) {
        $authMode = $config.authentication.mode
    }
    if ([string]::IsNullOrEmpty($authMode)) {
        throw "Mode d'authentification non specifie dans Settings.json (authentication.mode requis)"
    }

    # Parametres de retry
    $maxRetries = $config.authentication.retryCount
    if ($null -eq $maxRetries -or $maxRetries -lt 1) { $maxRetries = 1 }
    $retryDelaySeconds = $config.authentication.retryDelaySeconds
    if ($null -eq $retryDelaySeconds -or $retryDelaySeconds -lt 1) { $retryDelaySeconds = 2 }

    Write-Verbose "[i] Mode d'authentification: $authMode"

    # Construire parametres de connexion
    $connectionParams = @{
        NoWelcome = $true
    }

    # TenantId global (ignorer si placeholder 00000000-...)
    $tenantId = $config.authentication.tenantId
    $isPlaceholderTenant = $tenantId -eq '00000000-0000-0000-0000-000000000000'
    if (-not [string]::IsNullOrEmpty($tenantId) -and -not $isPlaceholderTenant) {
        $connectionParams['TenantId'] = $tenantId
    }

    # Configuration selon le mode
    switch ($authMode) {
        'Interactive' {
            $interactiveConfig = $config.authentication.interactive
            if ($null -eq $interactiveConfig) {
                throw "Mode Interactive: section 'authentication.interactive' manquante dans Settings.json"
            }

            # Scopes
            $scopes = $interactiveConfig.scopes
            if ($null -eq $scopes -or $scopes.Count -eq 0) {
                $scopes = @('Application.Read.All', 'Directory.Read.All')
            }
            $connectionParams['Scopes'] = $scopes

            # Desactiver WAM explicitement (bug SDK 2.26+ avec .NET 9)
            try {
                Set-MgGraphOption -EnableLoginByWAM $false -ErrorAction SilentlyContinue
            }
            catch {
                # Ignorer si l'option n'existe pas
            }

            # Persistance du cache entre sessions PS
            $persistCache = $interactiveConfig.persistCache
            if ($persistCache -eq $true) {
                # Cache persistant via fichier .mg (ContextScope = CurrentUser)
                $connectionParams['ContextScope'] = 'CurrentUser'
                Write-Verbose "[i] Cache persistant active (ContextScope=CurrentUser)"
            }
            else {
                # Pas de cache entre sessions: ContextScope = Process
                $connectionParams['ContextScope'] = 'Process'
                Write-Verbose "[i] ContextScope=Process - cache limite a cette session PS"
            }

            Write-Verbose "[i] Mode Interactive - Scopes: $($scopes -join ', '), PersistCache: $persistCache"
        }

        'Certificate' {
            $certConfig = $config.authentication.certificate
            if ($null -eq $certConfig) {
                throw "Mode Certificate: section 'authentication.certificate' manquante dans Settings.json"
            }

            # Validation
            $clientId = $certConfig.clientId
            $thumbprint = $certConfig.thumbprint

            if ([string]::IsNullOrEmpty($clientId)) {
                throw "Certificate mode requires 'authentication.certificate.clientId' in configuration"
            }
            if ([string]::IsNullOrEmpty($thumbprint)) {
                throw "Certificate mode requires 'authentication.certificate.thumbprint' in configuration"
            }

            # TenantId specifique au certificat (prioritaire)
            $certTenantId = $certConfig.tenantId
            if (-not [string]::IsNullOrEmpty($certTenantId)) {
                $connectionParams['TenantId'] = $certTenantId
            }

            $connectionParams['ClientId'] = $clientId
            $connectionParams['CertificateThumbprint'] = $thumbprint

            Write-Verbose "[i] Mode Certificate - ClientId: $clientId"
        }

        'ClientSecret' {
            $secretConfig = $config.authentication.clientSecret
            if ($null -eq $secretConfig) {
                throw "Mode ClientSecret: section 'authentication.clientSecret' manquante dans Settings.json"
            }

            # Validation
            $clientId = $secretConfig.clientId
            $secretVarName = $secretConfig.secretVariable

            if ([string]::IsNullOrEmpty($clientId)) {
                throw "ClientSecret mode requires 'authentication.clientSecret.clientId' in configuration"
            }
            if ([string]::IsNullOrEmpty($secretVarName)) {
                throw "ClientSecret mode requires 'authentication.clientSecret.secretVariable' in configuration"
            }

            # Lire le secret depuis la variable d'environnement
            $secretValue = [Environment]::GetEnvironmentVariable($secretVarName)
            if ([string]::IsNullOrEmpty($secretValue)) {
                throw "Environment variable '$secretVarName' is not defined or empty"
            }

            # TenantId specifique (prioritaire)
            $secretTenantId = $secretConfig.tenantId
            if (-not [string]::IsNullOrEmpty($secretTenantId)) {
                $connectionParams['TenantId'] = $secretTenantId
            }

            # Creer credential (ClientId = Username, Secret = Password)
            $secureSecret = ConvertTo-SecureString $secretValue -AsPlainText -Force
            $credential = [PSCredential]::new($clientId, $secureSecret)

            # Note: ClientSecretCredential contient deja le ClientId dans Username
            # Ne pas passer -ClientId separement (conflit de ParameterSet)
            $connectionParams['ClientSecretCredential'] = $credential

            Write-Verbose "[i] Mode ClientSecret - ClientId: $clientId"
        }

        'ManagedIdentity' {
            $miConfig = $config.authentication.managedIdentity
            if ($null -eq $miConfig) {
                throw "Mode ManagedIdentity: section 'authentication.managedIdentity' manquante dans Settings.json"
            }

            $connectionParams['Identity'] = $true

            # User-Assigned Managed Identity (optionnel)
            $miClientId = $miConfig.clientId
            if (-not [string]::IsNullOrEmpty($miClientId)) {
                $connectionParams['ClientId'] = $miClientId
                Write-Verbose "[i] Mode ManagedIdentity (User-Assigned) - ClientId: $miClientId"
            }
            else {
                Write-Verbose "[i] Mode ManagedIdentity (System-Assigned)"
            }
        }

        default {
            throw "Unknown authentication mode: $authMode"
        }
    }

    # Tentative de connexion avec retry
    $lastError = $null
    for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
        try {
            Connect-MgGraph @connectionParams -ErrorAction Stop

            # Verifier la connexion
            $context = Get-MgContext
            if ($null -eq $context) {
                throw "Connection established but context is null"
            }

            Write-Host "[+] " -NoNewline -ForegroundColor Green
            Write-Host "Connexion Microsoft Graph etablie (Mode: $authMode)"
            Write-Verbose "[i] Tenant: $($context.TenantId), Account: $($context.Account)"

            return $true
        }
        catch {
            $lastError = $_
            if ($attempt -lt $maxRetries) {
                Write-Verbose "[!] Tentative $attempt/$maxRetries echouee: $($_.Exception.Message)"
                Start-Sleep -Seconds $retryDelaySeconds
            }
        }
    }

    # Echec apres toutes les tentatives
    Write-Host "[-] " -NoNewline -ForegroundColor Red
    Write-Host "Echec connexion Microsoft Graph: $($lastError.Exception.Message)"
    return $false
}

function Test-MgConnection {
    <#
    .SYNOPSIS
        Verifie si une connexion Microsoft Graph est active
    .EXAMPLE
        if (Test-MgConnection) { Write-Host "Connecte" }
    .OUTPUTS
        [bool] $true si connecte, $false sinon
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $context = Get-MgContext
    return ($null -ne $context)
}

function Disconnect-MgConnection {
    <#
    .SYNOPSIS
        Deconnecte la session Microsoft Graph
    .DESCRIPTION
        Ferme proprement la connexion Microsoft Graph.
        Ne leve pas d'exception si deja deconnecte.
    .EXAMPLE
        Disconnect-MgConnection
    #>
    [CmdletBinding()]
    param()

    try {
        Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
        Write-Verbose "[i] Session Microsoft Graph deconnectee"
    }
    catch {
        # Ignorer les erreurs de deconnexion
        Write-Verbose "[!] Deconnexion: $($_.Exception.Message)"
    }
}

#endregion Public Functions

# Export des fonctions
Export-ModuleMember -Function @(
    'Connect-MgConnection',
    'Disconnect-MgConnection',
    'Test-MgConnection',
    'Get-MgConnectionConfig',
    'Initialize-MgConnection'
)
