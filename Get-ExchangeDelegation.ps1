#Requires -Version 7.2
#Requires -Modules ExchangeOnlineManagement

<#
.SYNOPSIS
    Collecte toutes les delegations Exchange Online d'une organisation.
.DESCRIPTION
    Ce script recupere l'ensemble des delegations configurees sur les mailboxes :
    - FullAccess : Acces complet a la mailbox
    - SendAs : Envoyer en tant que
    - SendOnBehalf : Envoyer de la part de
    - Calendar : Droits sur le calendrier
    - Forwarding : Regles de transfert SMTP

    Les permissions systeme (NT AUTHORITY, SELF, etc.) sont exclues.
    Les delegations orphelines (SID S-1-5-21-*) sont detectees et peuvent etre nettoyees.
    Export vers un fichier CSV unique consolide.
.PARAMETER OutputPath
    Chemin du dossier de sortie pour le fichier CSV.
    Defaut : Dossier Output/ du projet.
.PARAMETER IncludeSharedMailbox
    Inclure les mailboxes partagees (SharedMailbox) dans la collecte.
    Par defaut, seules les UserMailbox sont collectees.
.PARAMETER IncludeRoomMailbox
    Inclure les salles de reunion (RoomMailbox) dans la collecte.
    Par defaut, seules les UserMailbox sont collectees.
.PARAMETER CleanupOrphans
    Supprimer les delegations orphelines (trustees supprimes).
    Par defaut en mode simulation (WhatIf). Utiliser -Force pour supprimer reellement.
.PARAMETER OrphansOnly
    Exporter uniquement les delegations orphelines (IsOrphan = True).
    Collecte les mailbox selon -IncludeSharedMailbox/-IncludeRoomMailbox (UserMailbox par defaut).
    Utile pour analyser ou nettoyer les permissions obsoletes.
.PARAMETER IncludeLastLogon
    Ajouter la date de derniere activite email de la mailbox au CSV.
    Utilise Microsoft Graph Reports API (getEmailActivityUserDetail) pour des
    donnees precises sans les faux positifs des assistants de mailbox.
    Fallback automatique sur EXO si Graph non disponible.
    Necessite permission Reports.Read.All dans l'application Graph.
.PARAMETER Force
    Force la suppression reelle des delegations orphelines.
    Sans ce parametre, -CleanupOrphans fonctionne en mode simulation.
.PARAMETER NoResume
    Force une nouvelle collecte en ignorant tout checkpoint existant.
    Par defaut, le script reprend automatiquement depuis le dernier checkpoint valide.
.EXAMPLE
    .\Get-ExchangeDelegation.ps1
    Collecte les delegations des UserMailbox uniquement (comportement par defaut).
    Exporte dans Output/.
.EXAMPLE
    .\Get-ExchangeDelegation.ps1 -IncludeSharedMailbox
    Collecte les delegations des UserMailbox + SharedMailbox.
.EXAMPLE
    .\Get-ExchangeDelegation.ps1 -IncludeSharedMailbox -IncludeRoomMailbox
    Collecte les delegations de tous les types : UserMailbox + SharedMailbox + RoomMailbox.
.EXAMPLE
    .\Get-ExchangeDelegation.ps1 -IncludeSharedMailbox -IncludeInactive -IncludeLastLogon
    Collecte complete : User + Shared + Inactive, avec date de derniere connexion.
.EXAMPLE
    .\Get-ExchangeDelegation.ps1 -OutputPath "C:\Reports" -IncludeSharedMailbox
    Collecte User + Shared, export dans C:\Reports.
.EXAMPLE
    .\Get-ExchangeDelegation.ps1 -CleanupOrphans
    Collecte UserMailbox + simule la suppression des delegations orphelines (mode WhatIf).
.EXAMPLE
    .\Get-ExchangeDelegation.ps1 -CleanupOrphans -Force -IncludeSharedMailbox
    Collecte User + Shared et supprime reellement les delegations orphelines.
.EXAMPLE
    .\Get-ExchangeDelegation.ps1 -OrphansOnly
    Exporte uniquement les delegations orphelines des UserMailbox.
.EXAMPLE
    .\Get-ExchangeDelegation.ps1 -OrphansOnly -IncludeSharedMailbox
    Exporte uniquement les delegations orphelines des User + Shared.
.EXAMPLE
    .\Get-ExchangeDelegation.ps1 -NoResume
    Force une nouvelle collecte UserMailbox en ignorant tout checkpoint existant.
.NOTES
    Author: zornot
    Date: 2025-12-15
    Version: 1.3.0

    Prerequis:
    - Module ExchangeOnlineManagement installe
    - Connexion Exchange Online etablie (Connect-ExchangeOnline)
    - Droits: Exchange Administrator ou Global Reader
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeSharedMailbox,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeRoomMailbox,

    [Parameter(Mandatory = $false)]
    [switch]$CleanupOrphans,

    [Parameter(Mandatory = $false)]
    [switch]$OrphansOnly,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeLastLogon,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeInactive,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$NoResume,

    [Parameter(Mandatory = $false)]
    [switch]$Forensic
)

#region Configuration

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$script:Version = "1.3.0"
$script:CollectionTimestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"

# Fonction de chargement configuration
function Get-ScriptConfiguration {
    <#
    .SYNOPSIS
        Charge la configuration depuis Settings.json ou retourne les defauts.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $configPath = Join-Path $PSScriptRoot "Config\Settings.json"
    $defaultConfig = @{
        Application = @{
            Name        = "Get-ExchangeDelegation"
            Environment = "PROD"
            LogLevel    = "Info"
        }
        Paths       = @{
            Logs        = "./Logs"
            Output      = "./Output"
            Checkpoints = "./Checkpoints"
        }
        Retention   = @{
            LogDays         = 30
            OutputDays      = 7
            CheckpointHours = 24
        }
        Checkpoint  = @{
            Enabled     = $true
            Interval    = 50
            KeyProperty = "ExchangeObjectId"
        }
        _source     = "default"
    }

    if (Test-Path $configPath) {
        try {
            $fileConfig = Get-Content $configPath -Raw -ErrorAction Stop | ConvertFrom-Json -AsHashtable -ErrorAction Stop
            $fileConfig._source = "file"
            return $fileConfig
        }
        catch {
            # Fallback silencieux, log apres Initialize-Log
            return $defaultConfig
        }
    }

    return $defaultConfig
}

# Charger configuration
$script:Config = Get-ScriptConfiguration

# OutputPath par defaut depuis config
if ([string]::IsNullOrEmpty($OutputPath)) {
    $OutputPath = Join-Path $PSScriptRoot $script:Config.Paths.Output
}

# Validation securisee du chemin (SEC-001)
$resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
if ($OutputPath -match '\.\.') {
    throw "Path traversal non autorise dans OutputPath: $OutputPath"
}
$OutputPath = $resolvedOutputPath

# Creer le dossier Output si inexistant
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Import modules projet
Import-Module "$PSScriptRoot\Modules\Write-Log\Modules\Write-Log\Write-Log.psm1" -Force -ErrorAction Stop
Import-Module "$PSScriptRoot\Modules\ConsoleUI\Modules\ConsoleUI\ConsoleUI.psm1" -Force -ErrorAction Stop
Import-Module "$PSScriptRoot\Modules\EXOConnection\Modules\EXOConnection\EXOConnection.psm1" -ErrorAction Stop
Import-Module "$PSScriptRoot\Modules\Checkpoint\Modules\Checkpoint\Checkpoint.psm1" -Force -ErrorAction Stop
Import-Module "$PSScriptRoot\Modules\GraphConnection\GraphConnection.psm1" -Force -ErrorAction Stop

# Initialiser logs avec chemin depuis config
$logPath = Join-Path $PSScriptRoot $script:Config.Paths.Logs
Initialize-Log -Path $logPath

# Log source de configuration
if ($script:Config._source -eq "file") {
    Write-Log "Configuration chargee depuis Config/Settings.json" -Level INFO -NoConsole
}
else {
    Write-Log "Configuration par defaut (Settings.json absent)" -Level DEBUG -NoConsole
}

# Forcer WhatIf si CleanupOrphans sans Force (securite par defaut)
if ($CleanupOrphans -and -not $Force) {
    $WhatIfPreference = $true
}

# Comptes systeme a exclure des resultats
$script:ExcludedTrustees = @(
    'NT AUTHORITY\SELF',
    'NT AUTHORITY\SYSTEM',
    'S-1-5-10',
    'S-1-5-18',
    'NT AUTHORITY\NETWORK SERVICE',
    'NT AUTHORITY\LOCAL SERVICE'
)

# Pattern pour detecter les comptes systeme
# Note: S-1-5-21-* (comptes utilisateurs/orphelins) ne sont PAS filtres
# pour permettre la detection des delegations orphelines
$script:SystemAccountPatterns = @(
    '^NT AUTHORITY\\',
    '^S-1-5-10$',             # SELF
    '^S-1-5-18$',             # SYSTEM
    '^S-1-5-19$',             # LOCAL SERVICE
    '^S-1-5-20$',             # NETWORK SERVICE
    '^SELF$',
    '^Default$',
    '^Anonymous$',
    '^Par défaut$',           # Localisation francaise
    '^Anonyme$',              # Localisation francaise
    'DiscoverySearchMailbox',
    'SystemMailbox',
    'FederatedEmail'
)

# Cache global des recipients pour eviter appels API redondants
$script:RecipientCache = @{}

# Mode forensic (collecte permissions soft-deleted)
$script:ForensicMode = $false
$script:SkippedTransitionalCount = 0
$script:ForensicCollectedCount = 0

# Variables pour strategie LastLogon
$Script:LastLogonStrategy = 'None'      # 'SignInActivity', 'GraphReports', 'EXO', 'None'
$Script:SignInActivityCache = $null     # Cache signInActivity (P1/P2)
$Script:EmailActivityCache = $null      # Cache Graph Reports
$Script:EXOFallbackWarned = $false      # Warning EXO affiche une seule fois

#endregion Configuration

#region UI Functions

# Note: Write-Status et Write-ConsoleBanner sont fournies par le module ConsoleUI

#endregion UI Functions

#region Helper Functions

function Test-IsSystemAccount {
    <#
    .SYNOPSIS
        Determine si un compte est un compte systeme a exclure.
    #>
    param([string]$Identity)

    if ([string]::IsNullOrWhiteSpace($Identity)) { return $true }

    # Verification liste explicite
    if ($script:ExcludedTrustees -contains $Identity) { return $true }

    # Verification patterns
    foreach ($pattern in $script:SystemAccountPatterns) {
        if ($Identity -match $pattern) { return $true }
    }

    return $false
}

function Initialize-RecipientCache {
    <#
    .SYNOPSIS
        Charge le cache des recipients pour optimiser les resolutions.
    .DESCRIPTION
        Pre-charge tous les recipients du tenant pour eviter les appels API
        redondants dans Resolve-TrusteeInfo. Reduit de 50-80% les appels API.
    #>
    [CmdletBinding()]
    param()

    Write-Status -Type Info -Message "Chargement cache recipients..." -Indent 1

    try {
        # Note: Get-EXORecipient n'existe pas, utiliser Get-Recipient
        $recipients = Get-Recipient -ResultSize Unlimited -ErrorAction Stop

        foreach ($r in $recipients) {
            # Indexer par email (cle principale)
            if ($r.PrimarySmtpAddress) {
                $script:RecipientCache[$r.PrimarySmtpAddress.ToLower()] = $r
            }
            # Indexer aussi par DisplayName (fallback)
            if ($r.DisplayName -and -not $script:RecipientCache.ContainsKey($r.DisplayName)) {
                $script:RecipientCache[$r.DisplayName] = $r
            }
        }

        Write-Status -Type Success -Message "Cache: $($script:RecipientCache.Count) entrees" -Indent 1
        Write-Log "Cache recipients initialise: $($script:RecipientCache.Count) entrees" -Level DEBUG -NoConsole
    }
    catch {
        Write-Status -Type Warning -Message "Cache recipients non charge (mode fallback)" -Indent 1
        Write-Log "Echec chargement cache recipients: $($_.Exception.Message)" -Level WARNING -NoConsole
        # Continuer sans cache - Resolve-TrusteeInfo fera les appels individuels
    }
}

# Variables pour le cache d'activite email (Graph Reports API)
$Script:EmailActivityCache = $null
$Script:EXOFallbackWarned = $false

function Initialize-EmailActivityCache {
    <#
    .SYNOPSIS
        Charge le cache d'activite email depuis Graph Reports API.
    .DESCRIPTION
        Appelle getEmailActivityUserDetail une seule fois et stocke
        les resultats dans un hashtable pour lookup O(1) par UPN.
        Utilise Last Activity Date (activite email reelle, pas les assistants).
    .OUTPUTS
        [bool] $true si cache charge, $false sinon
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    if ($null -ne $Script:EmailActivityCache -and $Script:EmailActivityCache.Count -gt 0) {
        Write-Verbose "[i] Cache activite email deja charge"
        return $true
    }

    try {
        # Verifier connexion Graph
        if (-not (Test-GraphConnection)) {
            Write-Log -Message "Graph non connecte - cache activite non disponible" -Level Warning
            return $false
        }

        Write-Log -Message "Chargement cache activite email depuis Graph..." -Level Info -NoConsole

        # Appel API Reports - periode 30 jours
        $uri = "https://graph.microsoft.com/v1.0/reports/getEmailActivityUserDetail(period='D30')"
        $response = Invoke-MgGraphRequest -Uri $uri -Method GET -OutputType HttpResponseMessage

        if ($response.StatusCode -ne 200) {
            throw "API retourne status $($response.StatusCode)"
        }

        # Lire le contenu CSV
        $csvContent = $response.Content.ReadAsStringAsync().Result
        $activityData = $csvContent | ConvertFrom-Csv

        # Detecter anonymisation (premier UPN = hash MD5 32 chars hex)
        $firstUpn = ($activityData | Select-Object -First 1).'User Principal Name'
        if ($firstUpn -match '^[a-f0-9]{32}$') {
            Write-Log -Message "Graph Reports anonymise - UPNs remplaces par hash MD5" -Level Warning
            Write-Status -Type Warning -Message "Anonymisation Graph Reports ACTIVE - fallback EXO" -Indent 1
            Write-Status -Type Info -Message "Pour desactiver : Admin Center > Parametres > Rapports" -Indent 2
            $Script:LastLogonStrategy = 'EXO'
            return $false
        }

        # Construire hashtable UPN -> LastActivityDate
        $Script:EmailActivityCache = @{}
        foreach ($row in $activityData) {
            $upn = $row.'User Principal Name'
            $lastActivity = $row.'Last Activity Date'

            if (-not [string]::IsNullOrEmpty($upn) -and -not [string]::IsNullOrEmpty($lastActivity)) {
                try {
                    $Script:EmailActivityCache[$upn.ToLower()] = [datetime]::Parse($lastActivity)
                }
                catch {
                    # Date invalide - ignorer
                }
            }
        }

        $Script:LastLogonStrategy = 'GraphReports'
        Write-Log -Message "Cache activite email charge: $($Script:EmailActivityCache.Count) utilisateurs" -Level Info -NoConsole
        return $true
    }
    catch {
        Write-Log -Message "Echec chargement cache Graph: $($_.Exception.Message)" -Level Warning
        $Script:EmailActivityCache = @{}
        return $false
    }
}

function Initialize-SignInActivityCache {
    <#
    .SYNOPSIS
        Charge le cache LastLogon depuis signInActivity (Azure AD P1/P2).
    .DESCRIPTION
        Utilise l'API Graph avec la propriete SignInActivity pour obtenir
        lastSuccessfulSignInDateTime. Meilleure precision, jamais anonymise.
        Necessite licence Azure AD Premium P1 ou P2.
    .OUTPUTS
        [bool] $true si cache charge, $false si licence manquante ou erreur
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    if ($null -ne $Script:SignInActivityCache -and $Script:SignInActivityCache.Count -gt 0) {
        Write-Verbose "[i] Cache signInActivity deja charge"
        return $true
    }

    try {
        Write-Verbose "[i] Tentative chargement signInActivity (P1/P2)..."

        # Test avec un seul utilisateur pour verifier la disponibilite
        $testUser = Invoke-MgGraphRequest -Method GET `
            -Uri "https://graph.microsoft.com/v1.0/users?`$top=1&`$select=userPrincipalName,signInActivity" `
            -ErrorAction Stop

        # Si on arrive ici, la licence est disponible
        Write-Status -Type Success -Message "Licence P1/P2 detectee - utilisation signInActivity" -Indent 1

        # Charger tous les utilisateurs avec signInActivity
        $allUsers = [System.Collections.Generic.List[object]]::new()
        $uri = "https://graph.microsoft.com/v1.0/users?`$select=userPrincipalName,signInActivity&`$top=999"

        do {
            $response = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
            if ($response.value) {
                $allUsers.AddRange($response.value)
            }
            $uri = $response.'@odata.nextLink'
        } while ($uri)

        # Construire le cache
        $Script:SignInActivityCache = @{}
        foreach ($user in $allUsers) {
            $upn = $user.userPrincipalName
            $lastSignIn = $user.signInActivity.lastSuccessfulSignInDateTime

            if (-not [string]::IsNullOrEmpty($upn) -and -not [string]::IsNullOrEmpty($lastSignIn)) {
                try {
                    $Script:SignInActivityCache[$upn.ToLower()] = [datetime]::Parse($lastSignIn)
                }
                catch {
                    # Date invalide - ignorer
                }
            }
        }

        $Script:LastLogonStrategy = 'SignInActivity'
        Write-Log -Message "Cache signInActivity charge: $($Script:SignInActivityCache.Count) utilisateurs" -Level Info -NoConsole
        return $true
    }
    catch {
        if ($_.Exception.Message -match '(403|Forbidden|license|Premium|Authorization_RequestDenied)') {
            Write-Verbose "[i] signInActivity non disponible (licence P1/P2 requise)"
        }
        else {
            Write-Log -Message "Erreur signInActivity: $($_.Exception.Message)" -Level Warning -NoConsole
        }
        return $false
    }
}

function Get-MailboxLastLogon {
    <#
    .SYNOPSIS
        Retourne la date de derniere connexion d'une mailbox.
    .DESCRIPTION
        Utilise la meilleure source disponible en cascade :
        1. signInActivity (P1/P2) - plus precis, jamais anonymise
        2. Graph Reports - bon compromis si non-anonymise
        3. EXO Statistics - fallback, inclut assistants
    .PARAMETER UserPrincipalName
        UPN de l'utilisateur (email principal).
    .PARAMETER MailboxType
        Type de mailbox (UserMailbox, SharedMailbox, etc.) pour affichage contextuel.
    .OUTPUTS
        [string] Date formatee dd/MM/yyyy, "N/A (SharedMailbox)" ou chaine vide.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$UserPrincipalName,

        [Parameter()]
        [string]$MailboxType = ''
    )

    $upnLower = $UserPrincipalName.ToLower()

    # Priorite 1 : signInActivity (P1/P2)
    if ($Script:LastLogonStrategy -eq 'SignInActivity' -and $null -ne $Script:SignInActivityCache) {
        if ($Script:SignInActivityCache.ContainsKey($upnLower)) {
            return $Script:SignInActivityCache[$upnLower].ToString('dd/MM/yyyy')
        }
        return ''
    }

    # Priorite 2 : Graph Reports (si non-anonymise)
    if ($Script:LastLogonStrategy -eq 'GraphReports' -and $null -ne $Script:EmailActivityCache) {
        if ($Script:EmailActivityCache.ContainsKey($upnLower)) {
            return $Script:EmailActivityCache[$upnLower].ToString('dd/MM/yyyy')
        }
        return ''
    }

    # Priorite 3 : EXO Statistics (fallback)
    if (-not $Script:EXOFallbackWarned) {
        Write-Log -Message "Utilisation EXO Statistics (LastLogonTime inclut assistants)" -Level Warning -NoConsole
        $Script:EXOFallbackWarned = $true
    }

    try {
        $stats = Get-EXOMailboxStatistics -Identity $UserPrincipalName -ErrorAction SilentlyContinue
        if ($stats) {
            if ($stats.LastLogonTime) {
                $result = $stats.LastLogonTime.ToString('dd/MM/yyyy')
                Write-Verbose "[DEBUG] EXO LastLogon: $UserPrincipalName -> $result"
                return $result
            }
            else {
                # SharedMailbox n'a pas de login direct (acces via delegation)
                if ($MailboxType -eq 'SharedMailbox') {
                    Write-Verbose "[DEBUG] EXO LastLogon: $UserPrincipalName -> N/A (SharedMailbox - pas de login direct)"
                    return 'N/A (SharedMailbox)'
                }
                Write-Verbose "[DEBUG] EXO LastLogon: $UserPrincipalName -> NULL (jamais connecte)"
            }
        }
    }
    catch {
        Write-Verbose "[DEBUG] EXO LastLogon ERROR: $UserPrincipalName -> $($_.Exception.Message)"
    }

    # SharedMailbox sans stats retourne aussi N/A
    if ($MailboxType -eq 'SharedMailbox') {
        return 'N/A (SharedMailbox)'
    }

    return ''
}

function Resolve-TrusteeInfo {
    <#
    .SYNOPSIS
        Resout les informations d'un trustee de maniere robuste.
    .DESCRIPTION
        Utilise le cache pre-charge pour eviter les appels API redondants.
        Gere les cas problematiques :
        - DisplayName ambigu (plusieurs destinataires avec le meme nom)
        - Destinataire introuvable
        - SID orphelin
    #>
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Identity
    )

    # Retourner null si vide
    if ([string]::IsNullOrWhiteSpace($Identity)) {
        return $null
    }

    # Verifier le cache d'abord (optimisation performance)
    $cacheKey = $Identity.ToLower()
    if ($script:RecipientCache.ContainsKey($cacheKey)) {
        $cached = $script:RecipientCache[$cacheKey]
        return [PSCustomObject]@{
            Email       = $cached.PrimarySmtpAddress
            DisplayName = $cached.DisplayName
            Resolved    = $true
        }
    }

    # Verifier aussi par DisplayName (cas ou Identity est un nom)
    if ($script:RecipientCache.ContainsKey($Identity)) {
        $cached = $script:RecipientCache[$Identity]
        return [PSCustomObject]@{
            Email       = $cached.PrimarySmtpAddress
            DisplayName = $cached.DisplayName
            Resolved    = $true
        }
    }

    # Fallback: appel API si pas en cache (nouveau recipient ou SID)
    try {
        $recipient = Get-Recipient -Identity $Identity -ErrorAction Stop

        # Ajouter au cache pour les prochains appels
        if ($recipient.PrimarySmtpAddress) {
            $script:RecipientCache[$recipient.PrimarySmtpAddress.ToLower()] = $recipient
        }

        return [PSCustomObject]@{
            Email       = $recipient.PrimarySmtpAddress
            DisplayName = $recipient.DisplayName
            Resolved    = $true
        }
    }
    catch {
        $errorMessage = $_.Exception.Message

        # Cas 1: Destinataire ambigu (plusieurs matches)
        if ($errorMessage -match 'ne représente pas un destinataire unique|doesn''t represent a unique recipient') {
            Write-Log "Trustee ambigu (plusieurs destinataires): $Identity" -Level DEBUG -NoConsole
        }
        # Cas 2: Destinataire introuvable
        elseif ($errorMessage -match 'introuvable|couldn''t be found|not found') {
            Write-Log "Trustee introuvable: $Identity" -Level DEBUG -NoConsole
        }

        # Retourner l'identite brute comme fallback
        return [PSCustomObject]@{
            Email       = $Identity
            DisplayName = $Identity
            Resolved    = $false
        }
    }
}

function Remove-OrphanedDelegation {
    <#
    .SYNOPSIS
        Supprime une delegation orpheline.
    .DESCRIPTION
        Supprime une delegation vers un trustee supprime (SID orphelin).
        Supporte -WhatIf pour simulation.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Delegation
    )

    $mailbox = $Delegation.MailboxEmail
    $trustee = $Delegation.TrusteeEmail
    $type = $Delegation.DelegationType

    $description = "$type : $mailbox -> $trustee"

    if ($PSCmdlet.ShouldProcess($description, "Supprimer delegation orpheline")) {
        try {
            switch ($type) {
                'FullAccess' {
                    Remove-MailboxPermission -Identity $mailbox -User $trustee `
                        -AccessRights FullAccess -Confirm:$false -ErrorAction Stop
                }
                'SendAs' {
                    Remove-RecipientPermission -Identity $mailbox -Trustee $trustee `
                        -AccessRights SendAs -Confirm:$false -ErrorAction Stop
                }
                'SendOnBehalf' {
                    Set-Mailbox -Identity $mailbox -GrantSendOnBehalfTo @{Remove = $trustee } `
                        -ErrorAction Stop
                }
                'Calendar' {
                    # Utiliser le FolderPath stocke (nom localise: Calendar, Calendrier, etc.)
                    $folderPath = $Delegation.FolderPath
                    if ([string]::IsNullOrEmpty($folderPath)) { $folderPath = 'Calendar' }
                    $calendarPath = "${mailbox}:\$folderPath"
                    Remove-MailboxFolderPermission -Identity $calendarPath `
                        -User $trustee -Confirm:$false -ErrorAction Stop
                }
                'Forwarding' {
                    # Forwarding ne peut pas etre supprime via SID
                    Write-Log "Forwarding orphelin ignore (suppression manuelle requise): $mailbox" -Level WARNING
                    return $false
                }
                default {
                    Write-Log "Type de delegation inconnu: $type" -Level WARNING
                    return $false
                }
            }

            Write-Host "[+] " -NoNewline -ForegroundColor Green
            Write-Host "Supprime: $description"
            Write-Log "Delegation orpheline supprimee: $description" -Level INFO
            return $true
        }
        catch {
            Write-Host "[-] " -NoNewline -ForegroundColor Red
            Write-Host "Echec: $description - $($_.Exception.Message)"
            Write-Log "Erreur suppression delegation: $description - $($_.Exception.Message)" -Level WARNING
            return $false
        }
    }

    return $false
}

function New-DelegationRecord {
    <#
    .SYNOPSIS
        Cree un objet delegation standardise pour l'export CSV.
    #>
    param(
        [string]$MailboxEmail,
        [string]$MailboxDisplayName,
        [string]$TrusteeEmail,
        [string]$TrusteeDisplayName,
        [string]$DelegationType,
        [string]$AccessRights,
        [string]$FolderPath = '',
        [bool]$IsOrphan = $false,
        [bool]$IsInactive = $false,
        [bool]$IsSoftDeleted = $false,
        [string]$MailboxType = '',
        [string]$MailboxLastLogon = ''
    )

    [PSCustomObject]@{
        MailboxEmail       = $MailboxEmail
        MailboxDisplayName = $MailboxDisplayName
        TrusteeEmail       = $TrusteeEmail
        TrusteeDisplayName = $TrusteeDisplayName
        DelegationType     = $DelegationType
        AccessRights       = $AccessRights
        FolderPath         = $FolderPath
        IsOrphan           = $IsOrphan
        IsInactive         = $IsInactive
        IsSoftDeleted      = $IsSoftDeleted
        MailboxType        = $MailboxType
        MailboxLastLogon   = $MailboxLastLogon
        CollectedAt        = $script:CollectionTimestamp
    }
}

function Get-MailboxFullAccessDelegation {
    <#
    .SYNOPSIS
        Recupere les permissions FullAccess sur une mailbox.
    #>
    param(
        [object]$Mailbox,
        [bool]$IsTransitional = $false
    )

    $delegationList = [System.Collections.Generic.List[PSCustomObject]]::new()

    try {
        $permissions = $null
        $isSoftDeleted = $false

        try {
            $permissions = Get-EXOMailboxPermission -Identity $Mailbox.PrimarySmtpAddress -ErrorAction Stop
        }
        catch {
            # Retry avec -SoftDeletedMailbox si transitoire et mode forensic
            if ($IsTransitional -and $script:ForensicMode -and
                $_.Exception.Message -match "couldn't find.*as a recipient|Soft Deleted") {
                $permissions = Get-EXOMailboxPermission -Identity $Mailbox.PrimarySmtpAddress -SoftDeletedMailbox -ErrorAction Stop
                $isSoftDeleted = $true
                $script:ForensicCollectedCount++
            }
            else {
                throw
            }
        }

        $permissions = $permissions | Where-Object {
            $_.AccessRights -contains 'FullAccess' -and
            -not $_.IsInherited -and
            -not (Test-IsSystemAccount -Identity $_.User)
        }

        foreach ($permission in $permissions) {
            $trusteeInfo = Resolve-TrusteeInfo -Identity $permission.User
            $isOrphan = $trusteeInfo.Email -match '^S-1-5-21-'

            $delegationRecord = New-DelegationRecord `
                -MailboxEmail $Mailbox.PrimarySmtpAddress `
                -MailboxDisplayName $Mailbox.DisplayName `
                -TrusteeEmail $trusteeInfo.Email `
                -TrusteeDisplayName $trusteeInfo.DisplayName `
                -DelegationType 'FullAccess' `
                -AccessRights 'FullAccess' `
                -IsOrphan $isOrphan `
                -IsSoftDeleted $isSoftDeleted

            $delegationList.Add($delegationRecord)
        }
    }
    catch {
        Write-Log "Erreur FullAccess sur $($Mailbox.PrimarySmtpAddress): $($_.Exception.Message)" -Level WARNING
    }

    return $delegationList
}

function Get-MailboxSendAsDelegation {
    <#
    .SYNOPSIS
        Recupere les permissions SendAs sur une mailbox.
    #>
    param(
        [object]$Mailbox,
        [bool]$IsTransitional = $false
    )

    $delegationList = [System.Collections.Generic.List[PSCustomObject]]::new()

    try {
        $permissions = $null
        $isSoftDeleted = $false

        try {
            $permissions = Get-RecipientPermission -Identity $Mailbox.Identity -ErrorAction Stop
        }
        catch {
            # Get-RecipientPermission n'a pas -SoftDeletedMailbox
            # En mode forensic, on log et retourne vide
            if ($IsTransitional -and $script:ForensicMode -and
                $_.Exception.Message -match "couldn't find.*as a recipient|Soft Deleted") {
                Write-Log "SendAs non disponible pour mailbox soft-deleted: $($Mailbox.PrimarySmtpAddress)" -Level DEBUG -NoConsole
                return $delegationList
            }
            else {
                throw
            }
        }

        $permissions = $permissions | Where-Object {
            $_.AccessRights -contains 'SendAs' -and
            -not (Test-IsSystemAccount -Identity $_.Trustee)
        }

        foreach ($permission in $permissions) {
            $trusteeInfo = Resolve-TrusteeInfo -Identity $permission.Trustee
            $isOrphan = $trusteeInfo.Email -match '^S-1-5-21-'

            $delegationRecord = New-DelegationRecord `
                -MailboxEmail $Mailbox.PrimarySmtpAddress `
                -MailboxDisplayName $Mailbox.DisplayName `
                -TrusteeEmail $trusteeInfo.Email `
                -TrusteeDisplayName $trusteeInfo.DisplayName `
                -DelegationType 'SendAs' `
                -AccessRights 'SendAs' `
                -IsOrphan $isOrphan `
                -IsSoftDeleted $isSoftDeleted

            $delegationList.Add($delegationRecord)
        }
    }
    catch {
        Write-Log "Erreur SendAs sur $($Mailbox.PrimarySmtpAddress): $($_.Exception.Message)" -Level WARNING
    }

    return $delegationList
}

function Get-MailboxSendOnBehalfDelegation {
    <#
    .SYNOPSIS
        Recupere les permissions SendOnBehalf sur une mailbox.
    #>
    param([object]$Mailbox)

    $delegationList = [System.Collections.Generic.List[PSCustomObject]]::new()

    if ($null -eq $Mailbox.GrantSendOnBehalfTo -or $Mailbox.GrantSendOnBehalfTo.Count -eq 0) {
        return $delegationList
    }

    foreach ($trustee in $Mailbox.GrantSendOnBehalfTo) {
        try {
            $trusteeInfo = Resolve-TrusteeInfo -Identity $trustee

            if ($null -ne $trusteeInfo -and -not (Test-IsSystemAccount -Identity $trusteeInfo.Email)) {
                $isOrphan = $trusteeInfo.Email -match '^S-1-5-21-'

                $delegationRecord = New-DelegationRecord `
                    -MailboxEmail $Mailbox.PrimarySmtpAddress `
                    -MailboxDisplayName $Mailbox.DisplayName `
                    -TrusteeEmail $trusteeInfo.Email `
                    -TrusteeDisplayName $trusteeInfo.DisplayName `
                    -DelegationType 'SendOnBehalf' `
                    -AccessRights 'SendOnBehalf' `
                    -IsOrphan $isOrphan

                $delegationList.Add($delegationRecord)
            }
        }
        catch {
            Write-Log "Erreur SendOnBehalf trustee $trustee : $($_.Exception.Message)" -Level WARNING
        }
    }

    return $delegationList
}

function Get-MailboxCalendarDelegation {
    <#
    .SYNOPSIS
        Recupere les permissions sur le calendrier d'une mailbox.
    .DESCRIPTION
        Detecte automatiquement le nom localise du dossier Calendar
        (Calendar, Calendrier, Kalender, etc.) via FolderType.
    #>
    param([object]$Mailbox)

    $delegationList = [System.Collections.Generic.List[PSCustomObject]]::new()

    try {
        # Detecter le nom localise du calendrier via FolderType (toujours en anglais)
        $calendarFolder = Get-EXOMailboxFolderStatistics -Identity $Mailbox.PrimarySmtpAddress -Folderscope Calendar -ErrorAction Stop |
            Where-Object { $_.FolderType -eq 'Calendar' } |
            Select-Object -First 1

        if (-not $calendarFolder) {
            Write-Log "Calendrier non trouve pour $($Mailbox.PrimarySmtpAddress)" -Level DEBUG -NoConsole
            return $delegationList
        }

        # Utiliser .Name qui contient directement le nom localise (ex: Calendrier)
        $folderName = $calendarFolder.Name
        $calendarFolderPath = "$($Mailbox.PrimarySmtpAddress):\$folderName"

        $permissions = Get-EXOMailboxFolderPermission -Identity $calendarFolderPath -ErrorAction Stop |
            Where-Object {
                $_.User.DisplayName -notin @('Default', 'Anonymous', 'Par défaut', 'Anonyme') -and
                -not (Test-IsSystemAccount -Identity $_.User.DisplayName)
            }

        foreach ($permission in $permissions) {
            $trusteeEmail = $permission.User.ADRecipient.PrimarySmtpAddress ?? $permission.User.DisplayName
            $trusteeDisplayName = $permission.User.DisplayName

            # Exclure si c'est un compte systeme
            if (Test-IsSystemAccount -Identity $trusteeEmail) { continue }

            # Detecter si orphelin : SID (S-1-5-21-*) OU ADRecipient null (nom cache)
            $isOrphan = ($trusteeEmail -match '^S-1-5-21-') -or ($null -eq $permission.User.ADRecipient)
            if ($isOrphan -and $trusteeEmail -notmatch '^S-1-5-21-') {
                Write-Log "Permission calendrier orpheline (nom cache): $trusteeDisplayName sur $($Mailbox.PrimarySmtpAddress)" -Level DEBUG -NoConsole
            }

            $accessRightsList = $permission.AccessRights -join ', '

            $delegationRecord = New-DelegationRecord `
                -MailboxEmail $Mailbox.PrimarySmtpAddress `
                -MailboxDisplayName $Mailbox.DisplayName `
                -TrusteeEmail $trusteeEmail `
                -TrusteeDisplayName $trusteeDisplayName `
                -DelegationType 'Calendar' `
                -AccessRights $accessRightsList `
                -FolderPath $folderName `
                -IsOrphan $isOrphan

            $delegationList.Add($delegationRecord)
        }
    }
    catch {
        Write-Log "Erreur Calendar sur $($Mailbox.PrimarySmtpAddress): $($_.Exception.Message)" -Level DEBUG -NoConsole
    }

    return $delegationList
}

function Get-MailboxForwardingDelegation {
    <#
    .SYNOPSIS
        Recupere les regles de transfert SMTP sur une mailbox.
    #>
    param([object]$Mailbox)

    $delegationList = [System.Collections.Generic.List[PSCustomObject]]::new()

    # ForwardingSmtpAddress
    if (-not [string]::IsNullOrWhiteSpace($Mailbox.ForwardingSmtpAddress)) {
        $forwardingAddress = $Mailbox.ForwardingSmtpAddress -replace '^smtp:', ''

        $delegationRecord = New-DelegationRecord `
            -MailboxEmail $Mailbox.PrimarySmtpAddress `
            -MailboxDisplayName $Mailbox.DisplayName `
            -TrusteeEmail $forwardingAddress `
            -TrusteeDisplayName $forwardingAddress `
            -DelegationType 'Forwarding' `
            -AccessRights 'ForwardingSmtpAddress'

        $delegationList.Add($delegationRecord)
    }

    # ForwardingAddress (interne)
    if (-not [string]::IsNullOrWhiteSpace($Mailbox.ForwardingAddress)) {
        try {
            $forwardingRecipient = Get-Recipient -Identity $Mailbox.ForwardingAddress -ErrorAction SilentlyContinue

            if ($null -ne $forwardingRecipient) {
                $delegationRecord = New-DelegationRecord `
                    -MailboxEmail $Mailbox.PrimarySmtpAddress `
                    -MailboxDisplayName $Mailbox.DisplayName `
                    -TrusteeEmail $forwardingRecipient.PrimarySmtpAddress `
                    -TrusteeDisplayName $forwardingRecipient.DisplayName `
                    -DelegationType 'Forwarding' `
                    -AccessRights 'ForwardingAddress'

                $delegationList.Add($delegationRecord)
            }
        }
        catch {
            Write-Log "Erreur resolution ForwardingAddress $($Mailbox.ForwardingAddress): $($_.Exception.Message)" -Level WARNING
        }
    }

    return $delegationList
}

#endregion Helper Functions

#region Main

try {
    # Demarrer le chronometre
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    Write-ConsoleBanner -Title "COLLECT EXCHANGE DELEGATIONS" -Version $script:Version

    # Afficher le mode d'execution apres la banniere
    if ($CleanupOrphans) {
        if ($Force) {
            # Mode SUPPRESSION REELLE - encart avec Write-Box
            Write-Box -Title "[!] MODE SUPPRESSION REELLE" -Content @(
                "Les delegations orphelines seront SUPPRIMEES definitivement"
            )

            # Confirmation interactive obligatoire
            Write-Host "  Pour confirmer la suppression, tapez " -NoNewline -ForegroundColor White
            Write-Host "SUPPRIMER" -NoNewline -ForegroundColor Red
            Write-Host " : " -NoNewline -ForegroundColor White
            $confirmation = Read-Host

            if ($confirmation -ne "SUPPRIMER") {
                Write-Host ""
                Write-Status -Type Info -Message "Annule - confirmation incorrecte. Aucune modification effectuee."
                Write-Log "Mode Force annule - confirmation incorrecte" -Level INFO
                exit 0
            }

            Write-Host ""
            Write-Status -Type Success -Message "Confirmation acceptee - suppression en cours..."
            Write-Log "Mode CleanupOrphans avec Force - suppression reelle activee (confirme)" -Level WARNING
        }
        else {
            # Mode SIMULATION - encart avec Write-Box
            Write-Box -Title "[i] MODE SIMULATION (WhatIf)" -Content @(
                "Aucune suppression ne sera effectuee"
                "Utiliser -Force pour supprimer reellement"
            )
            Write-Log "Mode CleanupOrphans sans Force - simulation WhatIf" -Level INFO
        }
    }

    Write-Log "Demarrage collecte des delegations Exchange Online" -Level INFO -NoConsole

    # Connexion Exchange Online (avec reutilisation session existante)
    $connected = Connect-EXOConnection
    if (-not $connected) {
        Write-Log "Echec connexion Exchange Online" -Level FATAL
        exit 1
    }

    $exoInfo = Get-EXOConnectionInfo
    Write-Log "Connexion Exchange Online: $($exoInfo.Organization)" -Level INFO -NoConsole

    # Initialiser le cache des recipients (optimisation performance)
    Initialize-RecipientCache

    # Connexion Graph et cache activite email (si -IncludeLastLogon)
    if ($IncludeLastLogon) {
        Write-Status -Type Action -Message "Connexion Microsoft Graph..."
        $configPath = Join-Path $PSScriptRoot "Config\Settings.json"
        Initialize-GraphConnection -ConfigPath $configPath

        # Scopes etendus pour signInActivity (P1/P2)
        $scopes = @('Reports.Read.All', 'AuditLog.Read.All', 'User.Read.All')
        $Script:GraphConnection = Connect-GraphConnection -Interactive -Scopes $scopes
        $Script:LastLogonStrategy = 'None'

        if ($Script:GraphConnection.IsConnected) {
            # Strategie 1 : Tenter signInActivity (P1/P2)
            Write-Status -Type Action -Message "Detection licence P1/P2..." -Indent 1
            $signInLoaded = Initialize-SignInActivityCache

            if (-not $signInLoaded) {
                # Strategie 2 : Fallback Graph Reports
                Write-Status -Type Action -Message "Chargement Graph Reports..." -Indent 1
                $reportsLoaded = Initialize-EmailActivityCache
            }

            # Afficher strategie finale
            switch ($Script:LastLogonStrategy) {
                'SignInActivity' { Write-Status -Type Success -Message "LastLogon: signInActivity ($($Script:SignInActivityCache.Count) users)" -Indent 1 }
                'GraphReports' { Write-Status -Type Success -Message "LastLogon: Graph Reports ($($Script:EmailActivityCache.Count) users)" -Indent 1 }
                'EXO' { Write-Status -Type Warning -Message "LastLogon: EXO Statistics (moins precis)" -Indent 1 }
                default { Write-Status -Type Warning -Message "LastLogon: Non disponible" -Indent 1 }
            }
        }
        else {
            Write-Status -Type Warning -Message "Graph non disponible - LastLogon via EXO" -Indent 1
            $Script:LastLogonStrategy = 'EXO'
        }
    }

    # Construction du filtre de type de mailbox
    Write-Status -Type Action -Message "Recuperation des mailboxes..."

    $mailboxTypes = @('UserMailbox')
    if ($IncludeSharedMailbox) { $mailboxTypes += 'SharedMailbox' }
    if ($IncludeRoomMailbox) { $mailboxTypes += 'RoomMailbox' }

    Write-Status -Type Info -Message "Types inclus: $($mailboxTypes -join ', ')" -Indent 1

    # Recuperation des mailboxes actives
    $allMailboxes = Get-EXOMailbox -ResultSize Unlimited -RecipientTypeDetails $mailboxTypes -Properties DisplayName, PrimarySmtpAddress, UserPrincipalName, ExchangeObjectId, RecipientTypeDetails, GrantSendOnBehalfTo, ForwardingAddress, ForwardingSmtpAddress
    $activeCount = $allMailboxes.Count
    Write-Status -Type Success -Message "$activeCount mailboxes actives trouvees" -Indent 1

    # Mailboxes inactives (si demande)
    $script:InactiveMailboxIds = @()
    if ($IncludeInactive) {
        Write-Status -Type Info -Message "Recuperation des mailboxes inactives..." -Indent 1
        $inactiveMailboxes = Get-EXOMailbox -InactiveMailboxOnly -ResultSize Unlimited -Properties DisplayName, PrimarySmtpAddress, UserPrincipalName, ExchangeObjectId, RecipientTypeDetails, GrantSendOnBehalfTo, ForwardingAddress, ForwardingSmtpAddress
        $script:InactiveMailboxIds = $inactiveMailboxes | ForEach-Object { $_.ExchangeObjectId }
        $allMailboxes = @($allMailboxes) + @($inactiveMailboxes)
        Write-Status -Type Success -Message "$($inactiveMailboxes.Count) mailboxes inactives ajoutees" -Indent 1
    }

    # Tri stable par PrimarySmtpAddress pour garantir un ordre coherent entre les runs
    # (requis pour le checkpoint: StartIndex doit pointer vers la meme mailbox)
    $allMailboxes = $allMailboxes | Sort-Object -Property PrimarySmtpAddress

    $mailboxCount = $allMailboxes.Count
    Write-Status -Type Success -Message "$mailboxCount mailboxes au total" -Indent 1
    Write-Log "Mailboxes recuperees: $mailboxCount" -Level INFO -NoConsole

    if ($mailboxCount -eq 0) {
        Write-Status -Type Warning -Message "Aucune mailbox a traiter"
        Write-Log "Aucune mailbox trouvee - arret" -Level WARNING
        exit 0
    }

    # Collection des delegations
    Write-Status -Type Action -Message "Collecte des delegations..."

    # Mode forensic et compteurs transitoires
    $script:ForensicMode = $Forensic.IsPresent
    $script:SkippedTransitionalCount = 0
    $script:ForensicCollectedCount = 0

    $allDelegations = [System.Collections.Generic.List[PSCustomObject]]::new()

    $statsPerType = @{
        FullAccess   = 0
        SendAs       = 0
        SendOnBehalf = 0
        Calendar     = 0
        Forwarding   = 0
    }

    # Initialisation checkpoint si active
    $checkpointEnabled = $script:Config.Checkpoint.Enabled -and -not $NoResume
    $checkpointState = $null
    $startIndex = 0
    $isAppendMode = $false

    # Generer le chemin CSV maintenant (pour le stocker dans le checkpoint)
    $exportFileName = "ExchangeDelegations_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').csv"
    $exportFilePath = Join-Path -Path $OutputPath -ChildPath $exportFileName

    if ($checkpointEnabled) {
        $sessionId = "ExchangeDelegations_$(Get-Date -Format 'yyyy-MM-dd')"
        $checkpointPath = Join-Path $PSScriptRoot $script:Config.Paths.Checkpoints

        # Ajouter MaxAgeHours depuis Retention si present
        $checkpointConfig = $script:Config.Checkpoint.Clone()
        if ($script:Config.Retention.ContainsKey('CheckpointHours')) {
            $checkpointConfig.MaxAgeHours = $script:Config.Retention.CheckpointHours
        }

        $checkpointState = Initialize-Checkpoint `
            -Config $checkpointConfig `
            -SessionId $sessionId `
            -TotalItems $mailboxCount `
            -CheckpointPath $checkpointPath `
            -CsvPath $exportFilePath

        if ($checkpointState.IsResume) {
            $startIndex = $checkpointState.StartIndex
            Write-Status -Type Info -Message "Reprise checkpoint: $($checkpointState.ProcessedKeys.Count) mailboxes deja traitees, reprise a mailbox $($startIndex + 1)/$mailboxCount" -Indent 1

            # Utiliser le CSV existant si disponible
            if (-not [string]::IsNullOrEmpty($checkpointState.CsvPath) -and (Test-Path $checkpointState.CsvPath)) {
                $exportFilePath = $checkpointState.CsvPath
                $isAppendMode = $true
                Write-Status -Type Info -Message "CSV existant: $(Split-Path $exportFilePath -Leaf)" -Indent 1
            }
        }
    }

    # Creer le CSV avec header si nouvelle collecte (pour que le checkpoint reference un fichier existant)
    if (-not $isAppendMode) {
        # Header CSV - doit correspondre aux proprietes de New-DelegationRecord
        $csvHeader = @(
            'MailboxEmail', 'MailboxDisplayName', 'TrusteeEmail', 'TrusteeDisplayName',
            'DelegationType', 'AccessRights', 'FolderPath', 'IsOrphan',
            'IsInactive', 'IsSoftDeleted', 'MailboxType', 'MailboxLastLogon', 'CollectedAt'
        )
        $csvHeader -join ',' | Set-Content -Path $exportFilePath -Encoding UTF8
        Write-Log "CSV initialise: $exportFilePath" -Level DEBUG -NoConsole
    }

    # Compter les delegations existantes si reprise checkpoint (pour stats finales)
    $existingDelegationCount = 0
    $existingStats = @{ FullAccess = 0; SendAs = 0; SendOnBehalf = 0; Calendar = 0; Forwarding = 0 }
    $existingOrphansCount = 0
    if ($checkpointState -and (Test-Path $exportFilePath)) {
        $existingLines = Get-Content $exportFilePath | Select-Object -Skip 1  # Skip header
        $existingDelegationCount = $existingLines.Count
        foreach ($line in $existingLines) {
            $cols = $line -split ','
            $delegationType = $cols[4] -replace '"', ''  # DelegationType est colonne 5 (index 4)
            if ($existingStats.ContainsKey($delegationType)) {
                $existingStats[$delegationType]++
            }
            # Compter orphelins (IsOrphan est colonne 8, index 7)
            if ($cols[7] -replace '"', '' -eq 'True') {
                $existingOrphansCount++
            }
        }
        Write-Log "CSV existant: $existingDelegationCount delegations pre-existantes" -Level DEBUG -NoConsole
    }

    # Verification coherence: si checkpoint dit "X traites" mais CSV a 0 lignes
    # C'est un checkpoint corrompu (interruption avant toute ecriture) - on repart de 0
    if ($checkpointState.IsResume -and $existingDelegationCount -eq 0) {
        Write-Log "Checkpoint incoherent (0 delegations dans CSV) - redemarrage complet" -Level WARNING
        Write-Status -Type Warning -Message "Checkpoint invalide - redemarrage depuis index 0" -Indent 1
        $startIndex = 0
        $checkpointState.StartIndex = 0
        $checkpointState.ProcessedKeys.Clear()
    }

    # Boucle principale avec gestion checkpoint
    $lastCompletedIndex = $startIndex - 1  # Aucune mailbox completee au debut
    try {
        for ($i = $startIndex; $i -lt $mailboxCount; $i++) {
            $mailbox = $allMailboxes[$i]

            # Skip si deja traite (checkpoint)
            if ($checkpointState -and (Test-AlreadyProcessed -InputObject $mailbox)) {
                continue
            }

            # Detection mailbox transitoire (pas dans le cache des recipients valides)
            $isTransitional = -not $script:RecipientCache.ContainsKey($mailbox.PrimarySmtpAddress.ToLower())

            if ($isTransitional) {
                if ($script:ForensicMode) {
                    # Mode forensic : on continue avec retry dans les fonctions de collecte
                    Write-Log "Mailbox $($mailbox.PrimarySmtpAddress) transitoire (forensic mode - retry actif)" -Level INFO -NoConsole
                }
                else {
                    # Mode normal : skip immediat
                    Write-Log "Mailbox $($mailbox.PrimarySmtpAddress) ignoree (recipient invalide, utiliser -Forensic pour inclure)" -Level INFO -NoConsole
                    $script:SkippedTransitionalCount++
                    continue
                }
            }

            # Collecter LastLogon si demande (Graph Reports API ou fallback EXO)
            $mailboxLastLogon = ''
            if ($IncludeLastLogon) {
                # UserPrincipalName pour Graph cache, fallback sur PrimarySmtpAddress si null
                $upnForLookup = if ($mailbox.UserPrincipalName) { $mailbox.UserPrincipalName } else { $mailbox.PrimarySmtpAddress }
                Write-Verbose "[DEBUG] Mailbox: $($mailbox.PrimarySmtpAddress) | UPN: $($mailbox.UserPrincipalName) | Lookup: $upnForLookup"
                $mailboxLastLogon = Get-MailboxLastLogon -UserPrincipalName $upnForLookup -MailboxType $mailbox.RecipientTypeDetails
            }

            # Verifier si mailbox inactive
            $isInactive = $mailbox.ExchangeObjectId -in $script:InactiveMailboxIds

            # Type de mailbox (UserMailbox, SharedMailbox, RoomMailbox, etc.)
            $mailboxType = $mailbox.RecipientTypeDetails

            # Collecter toutes les delegations de cette mailbox
            $mailboxDelegations = [System.Collections.Generic.List[PSCustomObject]]::new()

            # FullAccess
            $fullAccessDelegations = Get-MailboxFullAccessDelegation -Mailbox $mailbox -IsTransitional $isTransitional
            $statsPerType.FullAccess += $fullAccessDelegations.Count
            foreach ($delegation in $fullAccessDelegations) {
                $delegation.MailboxLastLogon = $mailboxLastLogon
                $delegation.IsInactive = $isInactive
                $delegation.MailboxType = $mailboxType
                $mailboxDelegations.Add($delegation)
            }

            # SendAs
            $sendAsDelegations = Get-MailboxSendAsDelegation -Mailbox $mailbox -IsTransitional $isTransitional
            $statsPerType.SendAs += $sendAsDelegations.Count
            foreach ($delegation in $sendAsDelegations) {
                $delegation.MailboxLastLogon = $mailboxLastLogon
                $delegation.IsInactive = $isInactive
                $delegation.MailboxType = $mailboxType
                $mailboxDelegations.Add($delegation)
            }

            # SendOnBehalf
            $sendOnBehalfDelegations = Get-MailboxSendOnBehalfDelegation -Mailbox $mailbox
            $statsPerType.SendOnBehalf += $sendOnBehalfDelegations.Count
            foreach ($delegation in $sendOnBehalfDelegations) {
                $delegation.MailboxLastLogon = $mailboxLastLogon
                $delegation.IsInactive = $isInactive
                $delegation.MailboxType = $mailboxType
                $mailboxDelegations.Add($delegation)
            }

            # Calendar
            $calendarDelegations = Get-MailboxCalendarDelegation -Mailbox $mailbox
            $statsPerType.Calendar += $calendarDelegations.Count
            foreach ($delegation in $calendarDelegations) {
                $delegation.MailboxLastLogon = $mailboxLastLogon
                $delegation.IsInactive = $isInactive
                $delegation.MailboxType = $mailboxType
                $mailboxDelegations.Add($delegation)
            }

            # Forwarding
            $forwardingDelegations = Get-MailboxForwardingDelegation -Mailbox $mailbox
            $statsPerType.Forwarding += $forwardingDelegations.Count
            foreach ($delegation in $forwardingDelegations) {
                $delegation.MailboxLastLogon = $mailboxLastLogon
                $delegation.IsInactive = $isInactive
                $delegation.MailboxType = $mailboxType
                $mailboxDelegations.Add($delegation)
            }

            # WRITE: Ecrire immediatement dans le CSV (append sans header)
            if ($mailboxDelegations.Count -gt 0) {
                # Filtrer si OrphansOnly
                $dataToWrite = if ($OrphansOnly) {
                    @($mailboxDelegations | Where-Object { $_.IsOrphan -eq $true })
                }
                else {
                    $mailboxDelegations
                }

                if ($dataToWrite.Count -gt 0) {
                    $dataToWrite | ConvertTo-Csv -NoTypeInformation |
                        Select-Object -Skip 1 |
                        Add-Content -Path $exportFilePath -Encoding UTF8
                }

                # Garder en memoire pour stats et cleanup
                $allDelegations.AddRange($mailboxDelegations)
            }

            # MARK: Marquer comme traite + checkpoint periodique
            if ($checkpointState) {
                Add-ProcessedItem -InputObject $mailbox -Index $i
            }

            # Cette mailbox est maintenant completee
            $lastCompletedIndex = $i

            # Progression tous les 10 elements termines ou a la fin
            $completedCount = $i + 1
            if ($completedCount % 10 -eq 0 -or $completedCount -eq $mailboxCount) {
                $percent = [math]::Round(($completedCount / $mailboxCount) * 100)
                Write-Status -Type Action -Message "Mailboxes traitees : $completedCount/$mailboxCount ($percent%)" -Indent 1
            }
        }

        # Collecte terminee avec succes - supprimer checkpoint
        if ($checkpointState) {
            Complete-Checkpoint
            Write-Log "Checkpoint supprime (collecte terminee)" -Level DEBUG -NoConsole
        }
    }
    finally {
        # Checkpoint de securite si interruption
        # Sauvegarder UNIQUEMENT si au moins une mailbox a ete completee
        if ((Get-CheckpointState) -and $lastCompletedIndex -ge $startIndex) {
            Save-CheckpointAtomic -LastProcessedIndex $lastCompletedIndex -Force
            $mailboxNumber = $lastCompletedIndex + 1
            Write-Status -Type Warning -Message "Interruption - checkpoint sauvegarde (mailbox $mailboxNumber/$mailboxCount, index $lastCompletedIndex)" -Indent 1
        }
        elseif ((Get-CheckpointState) -and $lastCompletedIndex -lt $startIndex) {
            # Aucune mailbox completee - ne pas sauvegarder de checkpoint invalide
            Write-Status -Type Warning -Message "Interruption - aucune mailbox completee, pas de checkpoint" -Indent 1
        }
    }

    # Calculer le total (session + existants si reprise checkpoint)
    $totalDelegations = $allDelegations.Count + $existingDelegationCount
    Write-Status -Type Success -Message "Collecte terminee: $totalDelegations delegations" -Indent 1

    # CSV deja ecrit pendant la boucle (pattern Write-Then-Mark)
    # Juste afficher le resultat final
    if ($totalDelegations -gt 0) {
        $exportedCount = if ($OrphansOnly) {
            @($allDelegations | Where-Object { $_.IsOrphan -eq $true }).Count + $existingOrphansCount
        }
        else {
            $totalDelegations
        }

        Write-Status -Type Success -Message "Export: $exportFilePath ($exportedCount lignes)" -Indent 1
        $filterNote = if ($OrphansOnly) { " (orphelins uniquement)" } else { "" }
        Write-Log "Export CSV: $exportFilePath ($exportedCount lignes$filterNote)" -Level SUCCESS
    }
    else {
        Write-Status -Type Warning -Message "Aucune delegation trouvee" -Indent 1
        Write-Log "Aucune delegation a exporter" -Level WARNING
    }

    # Nettoyage des delegations orphelines (si -CleanupOrphans)
    $orphanCount = 0
    $cleanedCount = 0

    if ($CleanupOrphans) {
        # Identifier les orphelins : SID (S-1-5-21-*) OU noms caches (IsOrphan = $true)
        $orphanedDelegations = $allDelegations | Where-Object {
            ($_.TrusteeEmail -match '^S-1-5-21-') -or ($_.IsOrphan -eq $true)
        }
        $orphanCount = $orphanedDelegations.Count

        # Stats detaillees pour le log
        $sidOrphans = @($orphanedDelegations | Where-Object { $_.TrusteeEmail -match '^S-1-5-21-' }).Count
        $cachedOrphans = @($orphanedDelegations | Where-Object { $_.IsOrphan -and $_.TrusteeEmail -notmatch '^S-1-5-21-' }).Count
        Write-Log "Orphelins detectes: $orphanCount total (SID: $sidOrphans, Noms caches: $cachedOrphans)" -Level INFO

        if ($orphanCount -gt 0) {
            Write-Host ""
            Write-Status -Type Action -Message "Nettoyage des delegations orphelines..."
            Write-Status -Type Info -Message "$orphanCount delegation(s) orpheline(s) detectee(s)" -Indent 1

            if ($WhatIfPreference) {
                Write-Status -Type Warning -Message "Mode simulation (-WhatIf) - aucune suppression" -Indent 1
            }

            foreach ($orphan in $orphanedDelegations) {
                $removed = Remove-OrphanedDelegation -Delegation $orphan
                if ($removed) {
                    $cleanedCount++
                }
            }

            Write-Host ""
            if ($WhatIfPreference) {
                Write-Status -Type Info -Message "Simulation: $orphanCount delegation(s) a supprimer" -Indent 1
            }
            else {
                Write-Status -Type Success -Message "$cleanedCount/$orphanCount delegation(s) orpheline(s) supprimee(s)" -Indent 1
            }
            Write-Log "Nettoyage orphelins: $cleanedCount/$orphanCount supprimes" -Level INFO
        }
        else {
            Write-Status -Type Success -Message "Aucune delegation orpheline detectee" -Indent 1
        }
    }

    # Arreter le chronometre
    $stopwatch.Stop()
    $executionTime = $stopwatch.Elapsed

    # Compter les orphelins - session + existants si reprise checkpoint
    $orphansInExport = @($allDelegations | Where-Object { $_.IsOrphan -eq $true }).Count + $existingOrphansCount

    # Deconnexion Graph si connecte
    if ($Script:GraphConnection -and $Script:GraphConnection.IsConnected) {
        $Script:GraphConnection.Disconnect()
    }

    # Resume final avec Write-Box du module ConsoleUI
    $summaryContent = [ordered]@{
        'Mailboxes'    = $mailboxCount
        'FullAccess'   = $statsPerType.FullAccess + $existingStats.FullAccess
        'SendAs'       = $statsPerType.SendAs + $existingStats.SendAs
        'SendOnBehalf' = $statsPerType.SendOnBehalf + $existingStats.SendOnBehalf
        'Calendar'     = $statsPerType.Calendar + $existingStats.Calendar
        'Forwarding'   = $statsPerType.Forwarding + $existingStats.Forwarding
        'TOTAL'        = $totalDelegations
        'Orphelins'    = $orphansInExport
    }

    if ($script:SkippedTransitionalCount -gt 0) {
        $summaryContent['Transitoires'] = "$($script:SkippedTransitionalCount) ignorees"
    }
    if ($script:ForensicCollectedCount -gt 0) {
        $summaryContent['Forensic'] = "$($script:ForensicCollectedCount) soft-deleted collectees"
    }

    if ($CleanupOrphans -and $orphanCount -gt 0) {
        $summaryContent['Nettoyes'] = "$cleanedCount/$orphanCount supprimes"
    }

    Write-Box -Title "RESUME" -Content $summaryContent

    # Statistiques finales avec Write-Box
    $statsContent = [ordered]@{
        'Duree' = $executionTime.ToString('mm\:ss')
    }
    if ($totalDelegations -gt 0 -and $exportFilePath) {
        $statsContent['Export'] = $exportFilePath
    }
    if ($orphansInExport -gt 0) {
        $statsContent['Orphelins'] = "$orphansInExport delegation(s) a nettoyer"
    }

    Write-Box -Title "STATISTIQUES" -Content $statsContent

    Write-Log "Collecte terminee - Total: $totalDelegations delegations - Duree: $($executionTime.ToString('mm\:ss'))" -Level SUCCESS
    Write-Status -Type Success -Message "Script termine avec succes"

    exit 0
}
catch {
    Write-Status -Type Error -Message "Erreur fatale: $($_.Exception.Message)"
    Write-Log "Erreur fatale: $($_.Exception.Message)" -Level FATAL
    Write-Log "StackTrace: $($_.ScriptStackTrace)" -Level DEBUG -NoConsole
    exit 1
}
finally {
    # Rotation des logs
    Invoke-LogRotation -Path $logPath -RetentionDays $script:Config.Retention.LogDays -ErrorAction SilentlyContinue
}

#endregion Main
