#Requires -Version 7.2

<#
.SYNOPSIS
    Module de connexion Microsoft Graph avec modes interactif et certificat.

.DESCRIPTION
    Fournit une connexion centralisee a Microsoft Graph avec :
    - Mode interactif (WAM desactive -> DeviceCode fallback)
    - Mode certificat (App Registration)
    - Reutilisation automatique de session existante
    - Retry configurable avec backoff exponentiel
    - Objet de connexion avec methode Disconnect()

    PREREQUIS :
    - Module Microsoft.Graph.Authentication installe
    - Pour mode certificat : App Registration avec certificat

    USAGE :
    1. $connection = Connect-GraphConnection -Interactive
    2. # ... utiliser les cmdlets Graph ...
    3. $connection.Disconnect()
#>

#region Script Variables

$Script:MaxRetries = 3
$Script:RetryDelaySeconds = 5
$Script:DefaultScopes = @('User.Read')
$Script:CurrentConnection = $null
$Script:ConfigPath = $null

#endregion Script Variables

#region Classes

class GraphConnectionResult {
    [bool]$IsConnected
    [string]$TenantId
    [string]$Account
    [string[]]$Scopes
    [string]$AuthType
    [datetime]$ConnectedAt
    hidden [bool]$NoDisconnect

    GraphConnectionResult([bool]$connected, [string]$tenantId, [string]$account, [string[]]$scopes, [string]$authType, [bool]$noDisconnect) {
        $this.IsConnected = $connected
        $this.TenantId = $tenantId
        $this.Account = $account
        $this.Scopes = $scopes
        $this.AuthType = $authType
        $this.ConnectedAt = Get-Date
        $this.NoDisconnect = $noDisconnect
    }

    [void] Disconnect() {
        if ($this.IsConnected -and -not $this.NoDisconnect) {
            try {
                Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
                $this.IsConnected = $false
                Write-Host "[+] " -NoNewline -ForegroundColor Green
                Write-Host "Microsoft Graph deconnecte"
            }
            catch {
                Write-Verbose "[!] Erreur deconnexion: $($_.Exception.Message)"
            }
        }
        elseif ($this.NoDisconnect) {
            Write-Verbose "[i] NoDisconnect active - session conservee"
        }
    }

    [string] ToString() {
        return "GraphConnection: $($this.Account) @ $($this.TenantId) [$($this.AuthType)]"
    }
}

#endregion Classes

#region Private Functions

function Get-SettingsValue {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory)]
        [string]$Section,

        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter()]
        [object]$Default = $null
    )

    # Chercher Settings.json dans plusieurs emplacements
    $possiblePaths = @(
        $Script:ConfigPath,
        (Join-Path $PSScriptRoot 'Settings.json'),
        (Join-Path $PSScriptRoot '..\Config\Settings.json'),
        (Join-Path $PSScriptRoot '..\..\Config\Settings.json')
    )

    $settingsPath = $null
    foreach ($path in $possiblePaths) {
        if ($path -and (Test-Path $path -ErrorAction SilentlyContinue)) {
            $settingsPath = $path
            break
        }
    }

    if (-not $settingsPath) {
        return $Default
    }

    try {
        $settings = Get-Content $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($settings.$Section -and $null -ne $settings.$Section.$Key) {
            return $settings.$Section.$Key
        }
    }
    catch {
        Write-Verbose "[!] Erreur lecture Settings.json: $($_.Exception.Message)"
    }

    return $Default
}

function Invoke-SilentConnection {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ConnectCommand,

        [Parameter(Mandatory)]
        [string]$ServiceName
    )

    $savedPrefs = @{
        Error    = $ErrorActionPreference
        Warning  = $WarningPreference
        Verbose  = $VerbosePreference
        Progress = $ProgressPreference
    }

    try {
        $ErrorActionPreference = 'Stop'
        $WarningPreference = 'SilentlyContinue'
        $VerbosePreference = 'SilentlyContinue'
        $ProgressPreference = 'SilentlyContinue'

        $null = & $ConnectCommand

        if (Test-GraphConnection) {
            return $true
        }
        return $false
    }
    catch {
        Write-Verbose "[$ServiceName] Erreur: $($_.Exception.Message)"
        return $false
    }
    finally {
        $ErrorActionPreference = $savedPrefs.Error
        $WarningPreference = $savedPrefs.Warning
        $VerbosePreference = $savedPrefs.Verbose
        $ProgressPreference = $savedPrefs.Progress
    }
}

function Connect-WithInteractive {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [string[]]$Scopes,
        [int]$MaxRetries,
        [int]$RetryDelaySeconds
    )

    $lastError = $null

    # Desactiver WAM (casse depuis SDK 2.26+)
    try {
        Set-MgGraphOption -EnableLoginByWAM $false -ErrorAction SilentlyContinue
        Write-Verbose "[i] WAM desactive"
    }
    catch {
        # Ignorer si cmdlet n'existe pas (anciennes versions)
    }

    # Tentative connexion interactive standard
    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            $connected = Invoke-SilentConnection -ServiceName "Graph Interactive" -ConnectCommand {
                Connect-MgGraph -Scopes $Scopes -ContextScope Process -NoWelcome -ErrorAction Stop
            }

            if ($connected) { return $true }
            throw "Validation echouee"
        }
        catch {
            $lastError = $_

            # Detecter annulation utilisateur
            if ($lastError.Exception.Message -match 'user_cancel|AADSTS50058|AADSTS65004') {
                Write-Host "[-] " -NoNewline -ForegroundColor Red
                Write-Host "Authentification annulee"
                return $false
            }

            if ($attempt -lt $MaxRetries) {
                $delay = $RetryDelaySeconds * $attempt
                Write-Host "[!] " -NoNewline -ForegroundColor Yellow
                Write-Host "Interactive $attempt/$MaxRetries echouee, retry ${delay}s..."
                Start-Sleep -Seconds $delay
            }
        }
    }

    # Fallback DeviceCode
    Write-Host "[!] " -NoNewline -ForegroundColor Yellow
    Write-Host "Interactive echoue, fallback DeviceCode..."

    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            # Appel DIRECT sans Invoke-SilentConnection pour afficher le code device
            Connect-MgGraph -Scopes $Scopes -UseDeviceCode -ContextScope Process -NoWelcome -ErrorAction Stop

            # Verifier connexion via Get-MgContext (Connect-MgGraph ne retourne rien)
            if (Test-GraphConnection) {
                return $true
            }
            throw "Validation echouee"
        }
        catch {
            $lastError = $_
            if ($attempt -lt $MaxRetries) {
                $delay = $RetryDelaySeconds * $attempt
                Write-Host "[!] " -NoNewline -ForegroundColor Yellow
                Write-Host "DeviceCode $attempt/$MaxRetries echouee, retry ${delay}s..."
                Start-Sleep -Seconds $delay
            }
        }
    }

    Write-Host "[-] " -NoNewline -ForegroundColor Red
    Write-Host "Echec connexion interactive"
    if ($lastError) {
        Write-Host "[i] " -NoNewline -ForegroundColor Cyan
        Write-Host "$($lastError.Exception.Message)"
    }
    return $false
}

function Connect-WithCertificate {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][string]$ClientId,
        [Parameter(Mandatory)][string]$TenantId,
        [Parameter(Mandatory)][string]$CertificateThumbprint,
        [int]$MaxRetries,
        [int]$RetryDelaySeconds
    )

    # Verifier certificat
    $cert = Get-ChildItem -Path "Cert:\CurrentUser\My\$CertificateThumbprint" -ErrorAction SilentlyContinue
    if (-not $cert) {
        $cert = Get-ChildItem -Path "Cert:\LocalMachine\My\$CertificateThumbprint" -ErrorAction SilentlyContinue
    }

    if (-not $cert) {
        Write-Host "[-] " -NoNewline -ForegroundColor Red
        Write-Host "Certificat non trouve: $CertificateThumbprint"
        return $false
    }

    $lastError = $null

    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            $connected = Invoke-SilentConnection -ServiceName "Graph Certificate" -ConnectCommand {
                Connect-MgGraph -ClientId $ClientId -TenantId $TenantId `
                    -CertificateThumbprint $CertificateThumbprint -NoWelcome -ErrorAction Stop
            }

            if ($connected) { return $true }
            throw "Validation echouee"
        }
        catch {
            $lastError = $_
            if ($attempt -lt $MaxRetries) {
                $delay = $RetryDelaySeconds * $attempt
                Write-Host "[!] " -NoNewline -ForegroundColor Yellow
                Write-Host "Certificate $attempt/$MaxRetries echouee, retry ${delay}s..."
                Start-Sleep -Seconds $delay
            }
        }
    }

    Write-Host "[-] " -NoNewline -ForegroundColor Red
    Write-Host "Echec connexion certificat"
    if ($lastError) {
        Write-Host "[i] " -NoNewline -ForegroundColor Cyan
        Write-Host "$($lastError.Exception.Message)"
    }
    return $false
}

#endregion Private Functions

#region Public Functions

function Initialize-GraphConnection {
    <#
    .SYNOPSIS
        Initialise le module avec un chemin de configuration personnalise.
    .DESCRIPTION
        Permet de specifier le chemin vers Settings.json avant d'appeler Connect-GraphConnection.
    .PARAMETER ConfigPath
        Chemin vers le fichier Settings.json.
    .EXAMPLE
        Initialize-GraphConnection -ConfigPath "C:\Config\Settings.json"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ })]
        [string]$ConfigPath
    )

    $Script:ConfigPath = $ConfigPath
    Write-Verbose "[i] Configuration initialisee: $ConfigPath"
}

function Test-GraphConnection {
    <#
    .SYNOPSIS
        Verifie si une connexion Microsoft Graph est active.
    .EXAMPLE
        if (Test-GraphConnection) { Write-Host "Connecte" }
    .OUTPUTS
        [bool] $true si connecte, $false sinon
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        $context = Get-MgContext -ErrorAction Stop
        return ($null -ne $context -and $null -ne $context.Account)
    }
    catch {
        return $false
    }
}

function Get-GraphConnectionInfo {
    <#
    .SYNOPSIS
        Retourne les informations de la connexion Microsoft Graph active.
    .EXAMPLE
        $info = Get-GraphConnectionInfo
        Write-Host "Tenant: $($info.TenantId)"
    .OUTPUTS
        [PSCustomObject] Informations ou $null
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    try {
        $context = Get-MgContext -ErrorAction Stop
        if ($null -eq $context) { return $null }

        return [PSCustomObject]@{
            TenantId   = $context.TenantId
            Account    = $context.Account
            Scopes     = $context.Scopes
            AuthType   = $context.AuthType
            AppName    = $context.AppName
            PSTypeName = 'GraphConnectionInfo'
        }
    }
    catch {
        return $null
    }
}

function Connect-GraphConnection {
    <#
    .SYNOPSIS
        Etablit une connexion Microsoft Graph (Interactive ou Certificate).

    .DESCRIPTION
        Modes disponibles :
        - Interactive : WAM desactive avec fallback DeviceCode
        - Certificate : App Registration avec certificat local

        Caracteristiques :
        - Reutilisation automatique de session existante
        - Retry configurable avec backoff exponentiel
        - Retourne un objet avec methode Disconnect()

    .PARAMETER Interactive
        Mode interactif (WAM desactive -> DeviceCode fallback). Defaut.

    .PARAMETER ClientId
        ID App Registration (mode certificat).
        Defaut: Settings.json -> GraphConnection.clientId

    .PARAMETER TenantId
        ID Tenant (mode certificat).
        Defaut: Settings.json -> GraphConnection.tenantId

    .PARAMETER CertificateThumbprint
        Empreinte du certificat (mode certificat). Requis pour ce mode.

    .PARAMETER Scopes
        Scopes Graph demandes. Defaut: User.Read

    .PARAMETER NoDisconnect
        Si active, $connection.Disconnect() ne deconnecte pas.

    .PARAMETER MaxRetries
        Nombre max de tentatives. Defaut: 3

    .PARAMETER RetryDelaySeconds
        Delai initial entre tentatives. Defaut: 5

    .PARAMETER Force
        Force reconnexion meme si session existe.

    .EXAMPLE
        $conn = Connect-GraphConnection -Interactive
        # ... operations ...
        $conn.Disconnect()

    .EXAMPLE
        $conn = Connect-GraphConnection -CertificateThumbprint "ABC123DEF456"

    .EXAMPLE
        $conn = Connect-GraphConnection -Interactive -NoDisconnect
        # Session conservee meme apres $conn.Disconnect()

    .OUTPUTS
        [GraphConnectionResult] Objet avec methode Disconnect()
    #>
    [CmdletBinding(DefaultParameterSetName = 'Interactive')]
    [OutputType([GraphConnectionResult])]
    param(
        [Parameter(ParameterSetName = 'Interactive')]
        [switch]$Interactive,

        [Parameter(ParameterSetName = 'Certificate')]
        [string]$ClientId,

        [Parameter(ParameterSetName = 'Certificate')]
        [ValidateScript({
                if ([string]::IsNullOrEmpty($_) -or $_ -match '^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$') { $true }
                else { throw "TenantId doit etre un GUID valide (ex: 12345678-1234-1234-1234-123456789abc)" }
            })]
        [string]$TenantId,

        [Parameter(ParameterSetName = 'Certificate', Mandatory)]
        [ValidateScript({
                if ($_ -match '^[0-9a-fA-F]{40}$') { $true }
                else { throw "CertificateThumbprint doit contenir 40 caracteres hexadecimaux" }
            })]
        [string]$CertificateThumbprint,

        [Parameter()]
        [string[]]$Scopes,

        [Parameter()]
        [switch]$NoDisconnect,

        [Parameter()]
        [ValidateRange(1, 10)]
        [int]$MaxRetries = $Script:MaxRetries,

        [Parameter()]
        [ValidateRange(1, 60)]
        [int]$RetryDelaySeconds = $Script:RetryDelaySeconds,

        [Parameter()]
        [switch]$Force
    )

    # Verifier module Graph
    $graphModule = Get-Module -Name Microsoft.Graph.Authentication -ListAvailable |
        Sort-Object Version -Descending | Select-Object -First 1

    if ($null -eq $graphModule) {
        Write-Host "[-] " -NoNewline -ForegroundColor Red
        Write-Host "Module Microsoft.Graph.Authentication non installe"
        Write-Host "[i] " -NoNewline -ForegroundColor Cyan
        Write-Host "Install-Module Microsoft.Graph -Scope CurrentUser"
        return [GraphConnectionResult]::new($false, $null, $null, @(), 'None', $false)
    }

    if (-not (Get-Module -Name Microsoft.Graph.Authentication)) {
        Import-Module Microsoft.Graph.Authentication -Global -ErrorAction Stop
    }

    # Lire autoDisconnect depuis Settings.json si -NoDisconnect non specifie
    if (-not $NoDisconnect.IsPresent) {
        $autoDisconnect = Get-SettingsValue -Section 'GraphConnection' -Key 'autoDisconnect' -Default $true
        if (-not $autoDisconnect) {
            $NoDisconnect = [switch]::new($true)
        }
    }

    # Scopes par defaut
    if (-not $Scopes -or $Scopes.Count -eq 0) {
        $configScopes = Get-SettingsValue -Section 'GraphConnection' -Key 'defaultScopes'
        if ($configScopes) {
            $Scopes = $configScopes
        }
        else {
            $Scopes = $Script:DefaultScopes
        }
    }

    # Session existante?
    if (-not $Force) {
        $existing = Get-GraphConnectionInfo
        if ($null -ne $existing) {
            Write-Host "[+] " -NoNewline -ForegroundColor Green
            Write-Host "Graph deja connecte" -NoNewline
            Write-Host " (session reutilisee)" -ForegroundColor DarkGray

            return [GraphConnectionResult]::new(
                $true, $existing.TenantId, $existing.Account,
                $existing.Scopes, $existing.AuthType, $NoDisconnect.IsPresent
            )
        }
    }
    else {
        Disconnect-GraphConnection
    }

    Write-Host "[>] " -NoNewline -ForegroundColor White
    Write-Host "Connexion Microsoft Graph..."

    $connected = $false

    if ($PSCmdlet.ParameterSetName -eq 'Certificate') {
        # Valeurs Settings.json si non fournies
        if (-not $ClientId) { $ClientId = Get-SettingsValue -Section 'GraphConnection' -Key 'clientId' }
        if (-not $TenantId) { $TenantId = Get-SettingsValue -Section 'GraphConnection' -Key 'tenantId' }

        if (-not $ClientId -or -not $TenantId) {
            Write-Host "[-] " -NoNewline -ForegroundColor Red
            Write-Host "ClientId et TenantId requis (parametre ou Settings.json)"
            return [GraphConnectionResult]::new($false, $null, $null, @(), 'Certificate', $false)
        }

        $connected = Connect-WithCertificate -ClientId $ClientId -TenantId $TenantId `
            -CertificateThumbprint $CertificateThumbprint `
            -MaxRetries $MaxRetries -RetryDelaySeconds $RetryDelaySeconds
    }
    else {
        $connected = Connect-WithInteractive -Scopes $Scopes `
            -MaxRetries $MaxRetries -RetryDelaySeconds $RetryDelaySeconds
    }

    if ($connected) {
        $info = Get-GraphConnectionInfo
        Write-Host "[+] " -NoNewline -ForegroundColor Green
        Write-Host "Graph connecte" -NoNewline
        Write-Host " ($($info.Account))" -ForegroundColor DarkGray

        $Script:CurrentConnection = [GraphConnectionResult]::new(
            $true, $info.TenantId, $info.Account,
            $info.Scopes, $info.AuthType, $NoDisconnect.IsPresent
        )
        return $Script:CurrentConnection
    }

    return [GraphConnectionResult]::new($false, $null, $null, @(), 'None', $false)
}

function Disconnect-GraphConnection {
    <#
    .SYNOPSIS
        Deconnecte la session Microsoft Graph.
    .DESCRIPTION
        Ferme proprement la connexion Graph.
        Ne leve pas d'exception si deja deconnecte.
    .EXAMPLE
        Disconnect-GraphConnection
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()

    try {
        if (Test-GraphConnection) {
            Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
            Write-Verbose "[i] Graph deconnecte"
        }
        $Script:CurrentConnection = $null
    }
    catch {
        Write-Verbose "[!] Erreur: $($_.Exception.Message)"
    }
}

#endregion Public Functions

Export-ModuleMember -Function @(
    'Initialize-GraphConnection',
    'Connect-GraphConnection',
    'Disconnect-GraphConnection',
    'Test-GraphConnection',
    'Get-GraphConnectionInfo'
)
