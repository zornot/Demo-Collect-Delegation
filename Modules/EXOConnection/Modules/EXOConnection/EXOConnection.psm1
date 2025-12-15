#Requires -Version 7.2

<#
.SYNOPSIS
    Module de connexion Exchange Online avec reutilisation de session.

.DESCRIPTION
    Fournit une connexion centralisee a Exchange Online avec :
    - Reutilisation automatique de session existante
    - Connexion silencieuse (suppression output verbeux)
    - Retry configurable avec backoff exponentiel
    - Deconnexion propre

    PREREQUIS :
    - Module ExchangeOnlineManagement installe
    - Droits Exchange Administrator ou Global Reader

    USAGE :
    1. Connect-EXOConnection
    2. # ... utiliser les cmdlets Exchange Online ...
    3. Disconnect-EXOConnection
#>

#region Script Variables

$Script:MaxRetries = 3
$Script:RetryDelaySeconds = 5

#endregion Script Variables

#region Private Functions

function Invoke-SilentConnection {
    <#
    .SYNOPSIS
        Execute une commande de connexion en mode silencieux.
    .DESCRIPTION
        Supprime tous les outputs (verbose, warning, progress) pendant
        l'execution de la commande de connexion.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ConnectCommand,

        [Parameter(Mandatory)]
        [scriptblock]$TestCommand,

        [Parameter(Mandatory)]
        [string]$ServiceName
    )

    # Sauvegarder les preferences
    $savedPrefs = @{
        Error    = $ErrorActionPreference
        Warning  = $WarningPreference
        Verbose  = $VerbosePreference
        Progress = $ProgressPreference
    }

    if (Get-Variable -Name InformationPreference -ErrorAction SilentlyContinue) {
        $savedPrefs.Information = $InformationPreference
    }

    try {
        # Mode silencieux
        $ErrorActionPreference = 'Stop'
        $WarningPreference = 'SilentlyContinue'
        $VerbosePreference = 'SilentlyContinue'
        $ProgressPreference = 'SilentlyContinue'

        if ($savedPrefs.ContainsKey('Information')) {
            Set-Variable -Name InformationPreference -Value 'SilentlyContinue' -Scope Script -Force
        }

        # Executer connexion
        $null = & $ConnectCommand

        # Valider connexion
        if (& $TestCommand) {
            return $true
        }

        return $false
    }
    catch {
        Write-Verbose "[$ServiceName] Erreur connexion: $($_.Exception.Message)"
        return $false
    }
    finally {
        # Restaurer preferences
        $ErrorActionPreference = $savedPrefs.Error
        $WarningPreference = $savedPrefs.Warning
        $VerbosePreference = $savedPrefs.Verbose
        $ProgressPreference = $savedPrefs.Progress

        if ($savedPrefs.ContainsKey('Information')) {
            Set-Variable -Name InformationPreference -Value $savedPrefs.Information -Scope Script -Force
        }
    }
}

#endregion Private Functions

#region Public Functions

function Test-EXOConnection {
    <#
    .SYNOPSIS
        Verifie si une connexion Exchange Online est active.

    .DESCRIPTION
        Utilise Get-ConnectionInformation pour verifier l'etat de la connexion.
        Retourne $true si une session active existe avec TokenStatus = 'Active'.

    .EXAMPLE
        if (Test-EXOConnection) {
            Write-Host "Connecte a Exchange Online"
        }

    .OUTPUTS
        [bool] $true si connecte, $false sinon
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        $connectionInfo = Get-ConnectionInformation -ErrorAction Stop |
            Where-Object { $_.TokenStatus -eq 'Active' } |
            Select-Object -First 1

        return ($null -ne $connectionInfo)
    }
    catch {
        return $false
    }
}

function Get-EXOConnectionInfo {
    <#
    .SYNOPSIS
        Retourne les informations de la connexion Exchange Online active.

    .DESCRIPTION
        Fournit les details de la session Exchange Online :
        - Organization (tenant)
        - UserPrincipalName
        - TokenStatus
        - ConnectionUri

    .EXAMPLE
        $info = Get-EXOConnectionInfo
        Write-Host "Connecte a: $($info.Organization)"

    .OUTPUTS
        [PSCustomObject] Informations de connexion ou $null si non connecte
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    try {
        $connectionInfo = Get-ConnectionInformation -ErrorAction Stop |
            Where-Object { $_.TokenStatus -eq 'Active' } |
            Select-Object -First 1

        return $connectionInfo
    }
    catch {
        return $null
    }
}

function Connect-EXOConnection {
    <#
    .SYNOPSIS
        Etablit une connexion Exchange Online avec reutilisation de session.

    .DESCRIPTION
        - Verifie d'abord si une session active existe (reutilisation)
        - Si non, etablit une nouvelle connexion interactive
        - Supporte retry configurable avec backoff exponentiel
        - Mode silencieux (pas de banner ni output verbeux)

    .PARAMETER MaxRetries
        Nombre maximum de tentatives de connexion. Defaut: 3

    .PARAMETER RetryDelaySeconds
        Delai initial entre les tentatives (multiplie par numero tentative). Defaut: 5

    .PARAMETER Force
        Force une nouvelle connexion meme si une session existe.

    .EXAMPLE
        Connect-EXOConnection
        # Reutilise session existante ou etablit nouvelle connexion

    .EXAMPLE
        Connect-EXOConnection -Force
        # Deconnecte et reconnecte

    .EXAMPLE
        Connect-EXOConnection -MaxRetries 5 -RetryDelaySeconds 10
        # Configuration retry personnalisee

    .OUTPUTS
        [bool] $true si connexion reussie, $false sinon
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter()]
        [ValidateRange(1, 10)]
        [int]$MaxRetries = $Script:MaxRetries,

        [Parameter()]
        [ValidateRange(1, 60)]
        [int]$RetryDelaySeconds = $Script:RetryDelaySeconds,

        [Parameter()]
        [switch]$Force
    )

    # Verifier session existante
    if (-not $Force) {
        $existingConnection = Get-EXOConnectionInfo

        if ($null -ne $existingConnection) {
            Write-Host "[+] " -NoNewline -ForegroundColor Green
            Write-Host "Exchange Online deja connecte" -NoNewline -ForegroundColor Green
            Write-Host " (session reutilisee)" -ForegroundColor DarkGray
            Write-Verbose "[i] Organization: $($existingConnection.Organization)"
            return $true
        }
    }
    else {
        # Force: deconnecter d'abord
        Disconnect-EXOConnection
    }

    # Detecter version module pour options disponibles
    $exoModule = Get-Module -Name ExchangeOnlineManagement -ListAvailable |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if ($null -eq $exoModule) {
        Write-Host "[-] " -NoNewline -ForegroundColor Red
        Write-Host "Module ExchangeOnlineManagement non installe"
        Write-Host "[i] " -NoNewline -ForegroundColor Cyan
        Write-Host "Installez-le avec: Install-Module ExchangeOnlineManagement"
        return $false
    }

    $supportsInformationAction = $exoModule.Version -ge [Version]"3.0.0"

    Write-Host "[>] " -NoNewline -ForegroundColor White
    Write-Host "Connexion Exchange Online..."

    # Preparer parametres connexion
    $connectParams = @{
        ShowBanner  = $false
        ErrorAction = 'Stop'
    }

    if ($supportsInformationAction) {
        $connectParams.InformationAction = 'SilentlyContinue'
    }

    # Tentatives de connexion avec retry
    $lastError = $null

    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            $connected = Invoke-SilentConnection `
                -ConnectCommand { Connect-ExchangeOnline @connectParams } `
                -TestCommand { Test-EXOConnection } `
                -ServiceName "Exchange Online"

            if ($connected) {
                $connectionInfo = Get-EXOConnectionInfo
                Write-Host "[+] " -NoNewline -ForegroundColor Green
                Write-Host "Exchange Online connecte" -NoNewline -ForegroundColor Green
                Write-Host " ($($connectionInfo.Organization))" -ForegroundColor DarkGray
                return $true
            }

            throw "Validation connexion echouee"
        }
        catch {
            $lastError = $_

            # Detecter annulation utilisateur
            $cancelKeywords = @(
                'user_cancelled', 'user canceled', 'authentication_canceled',
                'login_required', 'AADSTS50058', 'AADSTS65004'
            )

            $isCanceled = $cancelKeywords | Where-Object { $lastError.Exception.Message -match $_ }

            if ($isCanceled) {
                Write-Host "[-] " -NoNewline -ForegroundColor Red
                Write-Host "Authentification annulee par l'utilisateur"
                return $false
            }

            if ($attempt -lt $MaxRetries) {
                $delay = $RetryDelaySeconds * $attempt
                Write-Host "[!] " -NoNewline -ForegroundColor Yellow
                Write-Host "Tentative $attempt/$MaxRetries echouee, retry dans ${delay}s..."
                Start-Sleep -Seconds $delay
            }
        }
    }

    # Echec apres toutes les tentatives
    Write-Host "[-] " -NoNewline -ForegroundColor Red
    Write-Host "Echec connexion Exchange Online apres $MaxRetries tentatives"

    if ($lastError) {
        Write-Host "[i] " -NoNewline -ForegroundColor Cyan
        Write-Host "Erreur: $($lastError.Exception.Message)"
    }

    return $false
}

function Disconnect-EXOConnection {
    <#
    .SYNOPSIS
        Deconnecte proprement la session Exchange Online.

    .DESCRIPTION
        Ferme la connexion Exchange Online sans lever d'exception
        si deja deconnecte.

    .EXAMPLE
        Disconnect-EXOConnection

    .OUTPUTS
        [void]
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()

    try {
        if (Test-EXOConnection) {
            Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
            Write-Verbose "[i] Session Exchange Online deconnectee"
        }
    }
    catch {
        Write-Verbose "[!] Erreur deconnexion: $($_.Exception.Message)"
    }
}

#endregion Public Functions

# Export des fonctions publiques
Export-ModuleMember -Function @(
    'Connect-EXOConnection',
    'Disconnect-EXOConnection',
    'Test-EXOConnection',
    'Get-EXOConnectionInfo'
)
