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
    Inclure les mailboxes partagees dans la collecte.
    Defaut : $true
.PARAMETER IncludeRoomMailbox
    Inclure les salles de reunion dans la collecte.
    Defaut : $false
.PARAMETER CleanupOrphans
    Supprimer les delegations orphelines (trustees supprimes).
    Par defaut en mode simulation (WhatIf). Utiliser -Force pour supprimer reellement.
.PARAMETER Force
    Force la suppression reelle des delegations orphelines.
    Sans ce parametre, -CleanupOrphans fonctionne en mode simulation.
.EXAMPLE
    .\Get-ExchangeDelegation.ps1
    Collecte toutes les delegations et exporte dans Output/.
.EXAMPLE
    .\Get-ExchangeDelegation.ps1 -OutputPath "C:\Reports" -IncludeRoomMailbox
    Collecte avec les salles de reunion, export dans C:\Reports.
.EXAMPLE
    .\Get-ExchangeDelegation.ps1 -CleanupOrphans
    Simule la suppression des delegations orphelines (mode WhatIf par defaut).
.EXAMPLE
    .\Get-ExchangeDelegation.ps1 -CleanupOrphans -Force
    Collecte et supprime reellement les delegations orphelines.
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
    [switch]$IncludeSharedMailbox = $true,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeRoomMailbox = $false,

    [Parameter(Mandatory = $false)]
    [switch]$CleanupOrphans,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

#region Configuration

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$script:Version = "1.3.0"
$script:CollectionTimestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"

# OutputPath par defaut : ./Output
if ([string]::IsNullOrEmpty($OutputPath)) {
    $OutputPath = Join-Path $PSScriptRoot "Output"
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
Import-Module "$PSScriptRoot\Modules\Write-Log\Modules\Write-Log\Write-Log.psm1" -ErrorAction Stop
Import-Module "$PSScriptRoot\Modules\ConsoleUI\Modules\ConsoleUI\ConsoleUI.psm1" -ErrorAction Stop
Import-Module "$PSScriptRoot\Modules\EXOConnection\Modules\EXOConnection\EXOConnection.psm1" -ErrorAction Stop
Initialize-Log -Path "$PSScriptRoot\Logs"

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

#endregion Configuration

#region UI Functions

function Write-Status {
    param(
        [ValidateSet('Success', 'Error', 'Warning', 'Info', 'Action', 'WhatIf')]
        [string]$Type,
        [string]$Message,
        [int]$Indent = 0
    )

    $statusConfig = switch ($Type) {
        'Success' { @{ Bracket = '[+]'; Color = 'Green' } }
        'Error' { @{ Bracket = '[-]'; Color = 'Red' } }
        'Warning' { @{ Bracket = '[!]'; Color = 'Yellow' } }
        'Info' { @{ Bracket = '[i]'; Color = 'Cyan' } }
        'Action' { @{ Bracket = '[>]'; Color = 'White' } }
        'WhatIf' { @{ Bracket = '[?]'; Color = 'DarkGray' } }
    }

    $indentSpaces = "  " * $Indent
    Write-Host "$indentSpaces$($statusConfig.Bracket) " -NoNewline -ForegroundColor $statusConfig.Color
    Write-Host $Message -ForegroundColor $statusConfig.Color
}

# Note: Write-ConsoleBanner est fournie par le module ConsoleUI

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

function Resolve-TrusteeInfo {
    <#
    .SYNOPSIS
        Resout les informations d'un trustee de maniere robuste.
    .DESCRIPTION
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

    try {
        # Tenter la resolution standard
        $recipient = Get-Recipient -Identity $Identity -ErrorAction Stop
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
            Write-Log "Trustee ambigu (plusieurs destinataires): $Identity" -Level DEBUG
        }
        # Cas 2: Destinataire introuvable
        elseif ($errorMessage -match 'introuvable|couldn''t be found|not found') {
            Write-Log "Trustee introuvable: $Identity" -Level DEBUG
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
        [string]$FolderPath = ''
    )

    [PSCustomObject]@{
        MailboxEmail       = $MailboxEmail
        MailboxDisplayName = $MailboxDisplayName
        TrusteeEmail       = $TrusteeEmail
        TrusteeDisplayName = $TrusteeDisplayName
        DelegationType     = $DelegationType
        AccessRights       = $AccessRights
        FolderPath         = $FolderPath
        CollectedAt        = $script:CollectionTimestamp
    }
}

function Get-MailboxFullAccessDelegation {
    <#
    .SYNOPSIS
        Recupere les permissions FullAccess sur une mailbox.
    #>
    param([object]$Mailbox)

    $delegationList = [System.Collections.Generic.List[PSCustomObject]]::new()

    try {
        $permissions = Get-MailboxPermission -Identity $Mailbox.Identity -ErrorAction Stop |
            Where-Object {
                $_.AccessRights -contains 'FullAccess' -and
                -not $_.IsInherited -and
                -not (Test-IsSystemAccount -Identity $_.User)
            }

        foreach ($permission in $permissions) {
            $trusteeInfo = Resolve-TrusteeInfo -Identity $permission.User

            $delegationRecord = New-DelegationRecord `
                -MailboxEmail $Mailbox.PrimarySmtpAddress `
                -MailboxDisplayName $Mailbox.DisplayName `
                -TrusteeEmail $trusteeInfo.Email `
                -TrusteeDisplayName $trusteeInfo.DisplayName `
                -DelegationType 'FullAccess' `
                -AccessRights 'FullAccess'

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
    param([object]$Mailbox)

    $delegationList = [System.Collections.Generic.List[PSCustomObject]]::new()

    try {
        $permissions = Get-RecipientPermission -Identity $Mailbox.Identity -ErrorAction Stop |
            Where-Object {
                $_.AccessRights -contains 'SendAs' -and
                -not (Test-IsSystemAccount -Identity $_.Trustee)
            }

        foreach ($permission in $permissions) {
            $trusteeInfo = Resolve-TrusteeInfo -Identity $permission.Trustee

            $delegationRecord = New-DelegationRecord `
                -MailboxEmail $Mailbox.PrimarySmtpAddress `
                -MailboxDisplayName $Mailbox.DisplayName `
                -TrusteeEmail $trusteeInfo.Email `
                -TrusteeDisplayName $trusteeInfo.DisplayName `
                -DelegationType 'SendAs' `
                -AccessRights 'SendAs'

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
                $delegationRecord = New-DelegationRecord `
                    -MailboxEmail $Mailbox.PrimarySmtpAddress `
                    -MailboxDisplayName $Mailbox.DisplayName `
                    -TrusteeEmail $trusteeInfo.Email `
                    -TrusteeDisplayName $trusteeInfo.DisplayName `
                    -DelegationType 'SendOnBehalf' `
                    -AccessRights 'SendOnBehalf'

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
        $calendarFolder = Get-MailboxFolderStatistics -Identity $Mailbox.PrimarySmtpAddress -FolderScope Calendar -ErrorAction Stop |
            Where-Object { $_.FolderType -eq 'Calendar' } |
            Select-Object -First 1

        if (-not $calendarFolder) {
            Write-Log "Calendrier non trouve pour $($Mailbox.PrimarySmtpAddress)" -Level DEBUG
            return $delegationList
        }

        # Utiliser .Name qui contient directement le nom localise (ex: Calendrier)
        $folderName = $calendarFolder.Name
        $calendarFolderPath = "$($Mailbox.PrimarySmtpAddress):\$folderName"

        $permissions = Get-MailboxFolderPermission -Identity $calendarFolderPath -ErrorAction Stop |
            Where-Object {
                $_.User.DisplayName -notin @('Default', 'Anonymous', 'Par défaut', 'Anonyme') -and
                -not (Test-IsSystemAccount -Identity $_.User.DisplayName)
            }

        foreach ($permission in $permissions) {
            $trusteeEmail = $permission.User.ADRecipient.PrimarySmtpAddress ?? $permission.User.DisplayName
            $trusteeDisplayName = $permission.User.DisplayName

            # Exclure si c'est un compte systeme
            if (Test-IsSystemAccount -Identity $trusteeEmail) { continue }

            $accessRightsList = $permission.AccessRights -join ', '

            $delegationRecord = New-DelegationRecord `
                -MailboxEmail $Mailbox.PrimarySmtpAddress `
                -MailboxDisplayName $Mailbox.DisplayName `
                -TrusteeEmail $trusteeEmail `
                -TrusteeDisplayName $trusteeDisplayName `
                -DelegationType 'Calendar' `
                -AccessRights $accessRightsList `
                -FolderPath $folderName

            $delegationList.Add($delegationRecord)
        }
    }
    catch {
        Write-Log "Erreur Calendar sur $($Mailbox.PrimarySmtpAddress): $($_.Exception.Message)" -Level DEBUG
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

    Write-Log "Demarrage collecte des delegations Exchange Online" -Level INFO

    # Connexion Exchange Online (avec reutilisation session existante)
    $connected = Connect-EXOConnection
    if (-not $connected) {
        Write-Log "Echec connexion Exchange Online" -Level FATAL
        exit 1
    }

    $exoInfo = Get-EXOConnectionInfo
    Write-Log "Connexion Exchange Online: $($exoInfo.Organization)" -Level INFO

    # Construction du filtre de type de mailbox
    Write-Status -Type Action -Message "Recuperation des mailboxes..."

    $mailboxTypes = @('UserMailbox')
    if ($IncludeSharedMailbox) { $mailboxTypes += 'SharedMailbox' }
    if ($IncludeRoomMailbox) { $mailboxTypes += 'RoomMailbox' }

    Write-Status -Type Info -Message "Types inclus: $($mailboxTypes -join ', ')" -Indent 1

    # Recuperation des mailboxes
    $allMailboxes = Get-EXOMailbox -ResultSize Unlimited -RecipientTypeDetails $mailboxTypes -Properties DisplayName, PrimarySmtpAddress, GrantSendOnBehalfTo, ForwardingAddress, ForwardingSmtpAddress
    $mailboxCount = $allMailboxes.Count

    Write-Status -Type Success -Message "$mailboxCount mailboxes trouvees" -Indent 1
    Write-Log "Mailboxes recuperees: $mailboxCount" -Level INFO

    if ($mailboxCount -eq 0) {
        Write-Status -Type Warning -Message "Aucune mailbox a traiter"
        Write-Log "Aucune mailbox trouvee - arret" -Level WARNING
        exit 0
    }

    # Collection des delegations
    Write-Status -Type Action -Message "Collecte des delegations..."
    Write-Host ""

    $allDelegations = [System.Collections.Generic.List[PSCustomObject]]::new()
    $mailboxIndex = 0

    $statsPerType = @{
        FullAccess   = 0
        SendAs       = 0
        SendOnBehalf = 0
        Calendar     = 0
        Forwarding   = 0
    }

    foreach ($mailbox in $allMailboxes) {
        $mailboxIndex++

        # Progression tous les 10 elements ou a la fin
        if ($mailboxIndex % 10 -eq 0 -or $mailboxIndex -eq $mailboxCount) {
            $percent = [math]::Round(($mailboxIndex / $mailboxCount) * 100)
            Write-Host "`r    [>] Analyse mailboxes : $mailboxIndex/$mailboxCount ($percent%)" -NoNewline -ForegroundColor White
        }

        # FullAccess
        $fullAccessDelegations = @(Get-MailboxFullAccessDelegation -Mailbox $mailbox)
        $statsPerType.FullAccess += $fullAccessDelegations.Count
        $allDelegations.AddRange($fullAccessDelegations)

        # SendAs
        $sendAsDelegations = @(Get-MailboxSendAsDelegation -Mailbox $mailbox)
        $statsPerType.SendAs += $sendAsDelegations.Count
        $allDelegations.AddRange($sendAsDelegations)

        # SendOnBehalf
        $sendOnBehalfDelegations = @(Get-MailboxSendOnBehalfDelegation -Mailbox $mailbox)
        $statsPerType.SendOnBehalf += $sendOnBehalfDelegations.Count
        $allDelegations.AddRange($sendOnBehalfDelegations)

        # Calendar
        $calendarDelegations = @(Get-MailboxCalendarDelegation -Mailbox $mailbox)
        $statsPerType.Calendar += $calendarDelegations.Count
        $allDelegations.AddRange($calendarDelegations)

        # Forwarding
        $forwardingDelegations = @(Get-MailboxForwardingDelegation -Mailbox $mailbox)
        $statsPerType.Forwarding += $forwardingDelegations.Count
        $allDelegations.AddRange($forwardingDelegations)
    }

    Write-Host ""  # Nouvelle ligne apres la progression
    Write-Status -Type Success -Message "Collecte terminee: $($allDelegations.Count) delegations" -Indent 1

    # Export CSV
    Write-Status -Type Action -Message "Export CSV..."

    $exportFileName = "ExchangeDelegations_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').csv"
    $exportFilePath = Join-Path -Path $OutputPath -ChildPath $exportFileName

    if ($allDelegations.Count -gt 0) {
        $allDelegations | Export-Csv -Path $exportFilePath -NoTypeInformation -Encoding UTF8
        Write-Status -Type Success -Message "Export: $exportFilePath" -Indent 1
        Write-Log "Export CSV: $exportFilePath ($($allDelegations.Count) lignes)" -Level SUCCESS
    }
    else {
        Write-Status -Type Warning -Message "Aucune delegation trouvee - pas d'export" -Indent 1
        Write-Log "Aucune delegation a exporter" -Level WARNING
    }

    # Nettoyage des delegations orphelines (si -CleanupOrphans)
    $orphanCount = 0
    $cleanedCount = 0

    if ($CleanupOrphans) {
        # Identifier les orphelins (SID S-1-5-21-*)
        $orphanedDelegations = $allDelegations | Where-Object { $_.TrusteeEmail -match '^S-1-5-21' }
        $orphanCount = $orphanedDelegations.Count

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

    # Resume final avec Write-Box du module ConsoleUI
    $summaryContent = [ordered]@{
        'Mailboxes'    = $mailboxCount
        'FullAccess'   = $statsPerType.FullAccess
        'SendAs'       = $statsPerType.SendAs
        'SendOnBehalf' = $statsPerType.SendOnBehalf
        'Calendar'     = $statsPerType.Calendar
        'Forwarding'   = $statsPerType.Forwarding
        'TOTAL'        = $allDelegations.Count
    }

    if ($CleanupOrphans -and $orphanCount -gt 0) {
        $summaryContent['Orphelins'] = "$cleanedCount/$orphanCount supprimes"
    }

    Write-Box -Title "RESUME" -Content $summaryContent

    Write-Log "Collecte terminee - Total: $($allDelegations.Count) delegations" -Level SUCCESS
    Write-Status -Type Success -Message "Script termine avec succes"

    exit 0
}
catch {
    Write-Status -Type Error -Message "Erreur fatale: $($_.Exception.Message)"
    Write-Log "Erreur fatale: $($_.Exception.Message)" -Level FATAL
    Write-Log "StackTrace: $($_.ScriptStackTrace)" -Level DEBUG
    exit 1
}
finally {
    # Rotation des logs
    Invoke-LogRotation -Path "$PSScriptRoot\Logs" -RetentionDays 30 -ErrorAction SilentlyContinue
}

#endregion Main
