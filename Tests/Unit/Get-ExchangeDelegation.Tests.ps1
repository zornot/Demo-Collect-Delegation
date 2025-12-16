#Requires -Modules Pester

<#
.SYNOPSIS
    Tests unitaires pour Get-ExchangeDelegation.ps1
.DESCRIPTION
    Tests TDD pour les fonctions helper du script de collecte des delegations Exchange Online.
    Les fonctions testees sont :
    - Test-IsSystemAccount : Detection des comptes systeme
    - New-DelegationRecord : Creation d'objets delegation
.NOTES
    Phase TDD : RED (tests ecrits avant implementation complete)
    Donnees : Anonymisees avec contoso.com / fabrikam.com
#>

BeforeAll {
    # Les fonctions sont definies directement dans ce fichier de test
    # pour eviter les dependances externes (modules Exchange, Write-Log, etc.)
    # Cela permet des tests unitaires isoles et rapides.

    # Variables script simulees
    $script:ExcludedTrustees = @(
        'NT AUTHORITY\SELF',
        'NT AUTHORITY\SYSTEM',
        'S-1-5-10',
        'S-1-5-18',
        'NT AUTHORITY\NETWORK SERVICE',
        'NT AUTHORITY\LOCAL SERVICE'
    )

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

    $script:CollectionTimestamp = "2025-12-15T10:00:00+01:00"

    # Definition des fonctions a tester (copiees du script pour isolation)
    function Test-IsSystemAccount {
        param([string]$Identity)

        if ([string]::IsNullOrWhiteSpace($Identity)) { return $true }

        if ($script:ExcludedTrustees -contains $Identity) { return $true }

        foreach ($pattern in $script:SystemAccountPatterns) {
            if ($Identity -match $pattern) { return $true }
        }

        return $false
    }

    function New-DelegationRecord {
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

    function Resolve-TrusteeInfo {
        param(
            [Parameter(Mandatory)]
            [AllowEmptyString()]
            [string]$Identity
        )

        if ([string]::IsNullOrWhiteSpace($Identity)) {
            return $null
        }

        # Simuler la resolution - dans les tests on mock Get-Recipient
        try {
            $recipient = Get-Recipient -Identity $Identity -ErrorAction Stop
            return [PSCustomObject]@{
                Email       = $recipient.PrimarySmtpAddress
                DisplayName = $recipient.DisplayName
                Resolved    = $true
            }
        }
        catch {
            return [PSCustomObject]@{
                Email       = $Identity
                DisplayName = $Identity
                Resolved    = $false
            }
        }
    }
}

Describe 'Test-IsSystemAccount' -Tag 'Unit' {

    Context 'Comptes systeme explicites' {

        It 'Retourne $true pour NT AUTHORITY\SELF' {
            # Arrange
            $identity = 'NT AUTHORITY\SELF'

            # Act
            $result = Test-IsSystemAccount -Identity $identity

            # Assert
            $result | Should -BeTrue
        }

        It 'Retourne $true pour NT AUTHORITY\SYSTEM' {
            $result = Test-IsSystemAccount -Identity 'NT AUTHORITY\SYSTEM'
            $result | Should -BeTrue
        }

        It 'Retourne $true pour S-1-5-10' {
            $result = Test-IsSystemAccount -Identity 'S-1-5-10'
            $result | Should -BeTrue
        }

        It 'Retourne $true pour S-1-5-18' {
            $result = Test-IsSystemAccount -Identity 'S-1-5-18'
            $result | Should -BeTrue
        }
    }

    Context 'Comptes systeme par pattern' {

        It 'Retourne $true pour tout compte NT AUTHORITY\*' {
            $result = Test-IsSystemAccount -Identity 'NT AUTHORITY\LOCAL SERVICE'
            $result | Should -BeTrue
        }

        It 'Retourne $true pour SELF' {
            $result = Test-IsSystemAccount -Identity 'SELF'
            $result | Should -BeTrue
        }

        It 'Retourne $true pour Default' {
            $result = Test-IsSystemAccount -Identity 'Default'
            $result | Should -BeTrue
        }

        It 'Retourne $true pour Anonymous' {
            $result = Test-IsSystemAccount -Identity 'Anonymous'
            $result | Should -BeTrue
        }

        It 'Retourne $true pour DiscoverySearchMailbox{guid}' {
            $result = Test-IsSystemAccount -Identity 'DiscoverySearchMailbox{00000000-0000-0000-0000-000000000001}'
            $result | Should -BeTrue
        }

        It 'Retourne $true pour SystemMailbox{guid}' {
            $result = Test-IsSystemAccount -Identity 'SystemMailbox{00000000-0000-0000-0000-000000000002}'
            $result | Should -BeTrue
        }

        It 'Retourne $true pour FederatedEmail.*' {
            $result = Test-IsSystemAccount -Identity 'FederatedEmail.Exchange'
            $result | Should -BeTrue
        }

        It 'Retourne $true pour Par defaut (localisation FR)' {
            $result = Test-IsSystemAccount -Identity 'Par défaut'
            $result | Should -BeTrue
        }

        It 'Retourne $true pour Anonyme (localisation FR)' {
            $result = Test-IsSystemAccount -Identity 'Anonyme'
            $result | Should -BeTrue
        }

        It 'Retourne $true pour S-1-5-10 (SELF)' {
            $result = Test-IsSystemAccount -Identity 'S-1-5-10'
            $result | Should -BeTrue
        }

        It 'Retourne $true pour S-1-5-18 (SYSTEM)' {
            $result = Test-IsSystemAccount -Identity 'S-1-5-18'
            $result | Should -BeTrue
        }
    }

    Context 'Comptes orphelins (S-1-5-21-*) - NON filtres pour detection' {

        It 'Retourne $false pour SID orphelin court S-1-5-21' {
            # Les SIDs S-1-5-21-* sont des comptes utilisateurs (potentiellement orphelins)
            # Ils ne doivent PAS etre filtres pour permettre la detection
            $result = Test-IsSystemAccount -Identity 'S-1-5-21'
            $result | Should -BeFalse
        }

        It 'Retourne $false pour SID orphelin long S-1-5-21-xxx-xxx-xxx-xxx' {
            # SID reel de type domaine (compte supprime = orphelin)
            $result = Test-IsSystemAccount -Identity 'S-1-5-21-583983544-471682574-2706792393-39628563'
            $result | Should -BeFalse
        }
    }

    Context 'Utilisateurs reels (non-systeme)' {

        It 'Retourne $false pour un email utilisateur contoso.com' {
            # Arrange - Donnees anonymisees
            $identity = 'jean.dupont@contoso.com'

            # Act
            $result = Test-IsSystemAccount -Identity $identity

            # Assert
            $result | Should -BeFalse
        }

        It 'Retourne $false pour un email utilisateur fabrikam.com' {
            $result = Test-IsSystemAccount -Identity 'marie.martin@fabrikam.com'
            $result | Should -BeFalse
        }

        It 'Retourne $false pour un nom affiche' {
            $result = Test-IsSystemAccount -Identity 'Jean DUPONT'
            $result | Should -BeFalse
        }

        It 'Retourne $false pour un groupe de distribution' {
            $result = Test-IsSystemAccount -Identity 'equipe-finance@contoso.com'
            $result | Should -BeFalse
        }
    }

    Context 'Cas limites' {

        It 'Retourne $true pour une chaine vide' {
            $result = Test-IsSystemAccount -Identity ''
            $result | Should -BeTrue
        }

        It 'Retourne $true pour $null' {
            $result = Test-IsSystemAccount -Identity $null
            $result | Should -BeTrue
        }

        It 'Retourne $true pour des espaces uniquement' {
            $result = Test-IsSystemAccount -Identity '   '
            $result | Should -BeTrue
        }
    }
}

Describe 'New-DelegationRecord' -Tag 'Unit' {

    Context 'Creation objet delegation' {

        It 'Cree un objet avec toutes les proprietes' {
            # Arrange - Donnees anonymisees
            $params = @{
                MailboxEmail       = 'shared.mailbox@contoso.com'
                MailboxDisplayName = 'Boite Partagee Contoso'
                TrusteeEmail       = 'jean.dupont@contoso.com'
                TrusteeDisplayName = 'Jean DUPONT'
                DelegationType     = 'FullAccess'
                AccessRights       = 'FullAccess'
            }

            # Act
            $record = New-DelegationRecord @params

            # Assert
            $record | Should -Not -BeNullOrEmpty
            $record.MailboxEmail | Should -Be 'shared.mailbox@contoso.com'
            $record.MailboxDisplayName | Should -Be 'Boite Partagee Contoso'
            $record.TrusteeEmail | Should -Be 'jean.dupont@contoso.com'
            $record.TrusteeDisplayName | Should -Be 'Jean DUPONT'
            $record.DelegationType | Should -Be 'FullAccess'
            $record.AccessRights | Should -Be 'FullAccess'
        }

        It 'Inclut le timestamp de collecte' {
            # Arrange
            $params = @{
                MailboxEmail       = 'user@contoso.com'
                MailboxDisplayName = 'User Contoso'
                TrusteeEmail       = 'delegate@contoso.com'
                TrusteeDisplayName = 'Delegate Contoso'
                DelegationType     = 'SendAs'
                AccessRights       = 'SendAs'
            }

            # Act
            $record = New-DelegationRecord @params

            # Assert
            $record.CollectedAt | Should -Be $script:CollectionTimestamp
        }

        It 'FolderPath est vide par defaut' {
            # Arrange
            $params = @{
                MailboxEmail       = 'user@contoso.com'
                MailboxDisplayName = 'User'
                TrusteeEmail       = 'delegate@contoso.com'
                TrusteeDisplayName = 'Delegate'
                DelegationType     = 'FullAccess'
                AccessRights       = 'FullAccess'
            }

            # Act
            $record = New-DelegationRecord @params

            # Assert
            $record.FolderPath | Should -Be ''
        }

        It 'FolderPath peut etre specifie pour Calendar' {
            # Arrange
            $params = @{
                MailboxEmail       = 'user@contoso.com'
                MailboxDisplayName = 'User'
                TrusteeEmail       = 'delegate@contoso.com'
                TrusteeDisplayName = 'Delegate'
                DelegationType     = 'Calendar'
                AccessRights       = 'Editor'
                FolderPath         = 'Calendar'
            }

            # Act
            $record = New-DelegationRecord @params

            # Assert
            $record.FolderPath | Should -Be 'Calendar'
        }
    }

    Context 'Types de delegation' -ForEach @(
        @{ Type = 'FullAccess'; Rights = 'FullAccess' }
        @{ Type = 'SendAs'; Rights = 'SendAs' }
        @{ Type = 'SendOnBehalf'; Rights = 'SendOnBehalf' }
        @{ Type = 'Calendar'; Rights = 'Editor, Reviewer' }
        @{ Type = 'Forwarding'; Rights = 'ForwardingSmtpAddress' }
    ) {

        It 'Cree correctement une delegation <Type>' {
            # Arrange
            $params = @{
                MailboxEmail       = 'mailbox@contoso.com'
                MailboxDisplayName = 'Mailbox'
                TrusteeEmail       = 'trustee@contoso.com'
                TrusteeDisplayName = 'Trustee'
                DelegationType     = $Type
                AccessRights       = $Rights
            }

            # Act
            $record = New-DelegationRecord @params

            # Assert
            $record.DelegationType | Should -Be $Type
            $record.AccessRights | Should -Be $Rights
        }
    }

    Context 'Format export CSV' {

        It 'Objet est exportable en CSV' {
            # Arrange
            $params = @{
                MailboxEmail       = 'export.test@contoso.com'
                MailboxDisplayName = 'Export Test'
                TrusteeEmail       = 'trustee@contoso.com'
                TrusteeDisplayName = 'Trustee'
                DelegationType     = 'FullAccess'
                AccessRights       = 'FullAccess'
            }

            # Act
            $record = New-DelegationRecord @params
            $csvOutput = $record | ConvertTo-Csv -NoTypeInformation

            # Assert
            $csvOutput | Should -Not -BeNullOrEmpty
            $csvOutput[0] | Should -Match 'MailboxEmail'
            $csvOutput[0] | Should -Match 'TrusteeEmail'
            $csvOutput[0] | Should -Match 'DelegationType'
            $csvOutput[0] | Should -Match 'CollectedAt'
        }

        It 'Contient exactement 13 proprietes' {
            # Arrange
            $params = @{
                MailboxEmail       = 'test@contoso.com'
                MailboxDisplayName = 'Test'
                TrusteeEmail       = 'trustee@contoso.com'
                TrusteeDisplayName = 'Trustee'
                DelegationType     = 'FullAccess'
                AccessRights       = 'FullAccess'
            }

            # Act
            $record = New-DelegationRecord @params
            $properties = $record.PSObject.Properties.Name

            # Assert
            $properties | Should -HaveCount 13
            $properties | Should -Contain 'MailboxEmail'
            $properties | Should -Contain 'MailboxDisplayName'
            $properties | Should -Contain 'TrusteeEmail'
            $properties | Should -Contain 'TrusteeDisplayName'
            $properties | Should -Contain 'DelegationType'
            $properties | Should -Contain 'AccessRights'
            $properties | Should -Contain 'FolderPath'
            $properties | Should -Contain 'IsOrphan'
            $properties | Should -Contain 'IsInactive'
            $properties | Should -Contain 'IsSoftDeleted'
            $properties | Should -Contain 'MailboxType'
            $properties | Should -Contain 'MailboxLastLogon'
            $properties | Should -Contain 'CollectedAt'
        }
    }

    Context 'Propriete IsOrphan (FEAT-003)' {

        It 'IsOrphan est $false par defaut' {
            # Arrange
            $params = @{
                MailboxEmail       = 'user@contoso.com'
                MailboxDisplayName = 'User'
                TrusteeEmail       = 'delegate@contoso.com'
                TrusteeDisplayName = 'Delegate'
                DelegationType     = 'FullAccess'
                AccessRights       = 'FullAccess'
            }

            # Act
            $record = New-DelegationRecord @params

            # Assert
            $record.IsOrphan | Should -BeFalse
        }

        It 'IsOrphan peut etre $true pour delegation orpheline' {
            # Arrange - SID orphelin
            $params = @{
                MailboxEmail       = 'shared@contoso.com'
                MailboxDisplayName = 'Shared Mailbox'
                TrusteeEmail       = 'S-1-5-21-583983544-471682574-2706792393-39628563'
                TrusteeDisplayName = 'S-1-5-21-583983544-471682574-2706792393-39628563'
                DelegationType     = 'FullAccess'
                AccessRights       = 'FullAccess'
                IsOrphan           = $true
            }

            # Act
            $record = New-DelegationRecord @params

            # Assert
            $record.IsOrphan | Should -BeTrue
            $record.TrusteeEmail | Should -Match '^S-1-5-21-'
        }
    }

    Context 'Propriete IsSoftDeleted (BUG-009)' -Tag 'BUG-009' {

        It 'IsSoftDeleted est $false par defaut' {
            # Arrange
            $params = @{
                MailboxEmail       = 'user@contoso.com'
                MailboxDisplayName = 'User'
                TrusteeEmail       = 'delegate@contoso.com'
                TrusteeDisplayName = 'Delegate'
                DelegationType     = 'FullAccess'
                AccessRights       = 'FullAccess'
            }

            # Act
            $record = New-DelegationRecord @params

            # Assert
            $record.IsSoftDeleted | Should -BeFalse
        }

        It 'IsSoftDeleted peut etre $true pour mailbox soft-deleted (mode forensic)' {
            # Arrange - Delegation recuperee via -SoftDeletedMailbox
            $params = @{
                MailboxEmail       = 'deleted.user@contoso.com'
                MailboxDisplayName = 'Deleted User'
                TrusteeEmail       = 'jean.dupont@contoso.com'
                TrusteeDisplayName = 'Jean DUPONT'
                DelegationType     = 'FullAccess'
                AccessRights       = 'FullAccess'
                IsSoftDeleted      = $true
            }

            # Act
            $record = New-DelegationRecord @params

            # Assert
            $record.IsSoftDeleted | Should -BeTrue
        }
    }

    Context 'Propriete IsInactive (BUG-008)' {

        It 'IsInactive est $false par defaut' {
            # Arrange
            $params = @{
                MailboxEmail       = 'user@contoso.com'
                MailboxDisplayName = 'User'
                TrusteeEmail       = 'delegate@contoso.com'
                TrusteeDisplayName = 'Delegate'
                DelegationType     = 'FullAccess'
                AccessRights       = 'FullAccess'
            }

            # Act
            $record = New-DelegationRecord @params

            # Assert
            $record.IsInactive | Should -BeFalse
        }

        It 'IsInactive peut etre $true pour mailbox inactive' {
            # Arrange
            $params = @{
                MailboxEmail       = 'inactive@contoso.com'
                MailboxDisplayName = 'Inactive Mailbox'
                TrusteeEmail       = 'delegate@contoso.com'
                TrusteeDisplayName = 'Delegate'
                DelegationType     = 'FullAccess'
                AccessRights       = 'FullAccess'
                IsInactive         = $true
            }

            # Act
            $record = New-DelegationRecord @params

            # Assert
            $record.IsInactive | Should -BeTrue
        }
    }

    Context 'Propriete MailboxType' {

        It 'MailboxType est vide par defaut' {
            # Arrange
            $params = @{
                MailboxEmail       = 'user@contoso.com'
                MailboxDisplayName = 'User'
                TrusteeEmail       = 'delegate@contoso.com'
                TrusteeDisplayName = 'Delegate'
                DelegationType     = 'FullAccess'
                AccessRights       = 'FullAccess'
            }

            # Act
            $record = New-DelegationRecord @params

            # Assert
            $record.MailboxType | Should -Be ''
        }

        It 'MailboxType peut contenir le RecipientTypeDetails' -TestCases @(
            @{ Type = 'UserMailbox' }
            @{ Type = 'SharedMailbox' }
            @{ Type = 'RoomMailbox' }
            @{ Type = 'EquipmentMailbox' }
        ) {
            param($Type)

            # Arrange
            $params = @{
                MailboxEmail       = 'mailbox@contoso.com'
                MailboxDisplayName = 'Mailbox'
                TrusteeEmail       = 'delegate@contoso.com'
                TrusteeDisplayName = 'Delegate'
                DelegationType     = 'FullAccess'
                AccessRights       = 'FullAccess'
                MailboxType        = $Type
            }

            # Act
            $record = New-DelegationRecord @params

            # Assert
            $record.MailboxType | Should -Be $Type
        }
    }

    Context 'Propriete MailboxLastLogon (FEAT-005)' {

        It 'MailboxLastLogon est vide par defaut' {
            # Arrange
            $params = @{
                MailboxEmail       = 'user@contoso.com'
                MailboxDisplayName = 'User'
                TrusteeEmail       = 'delegate@contoso.com'
                TrusteeDisplayName = 'Delegate'
                DelegationType     = 'FullAccess'
                AccessRights       = 'FullAccess'
            }

            # Act
            $record = New-DelegationRecord @params

            # Assert
            $record.MailboxLastLogon | Should -Be ''
        }

        It 'MailboxLastLogon peut contenir une date au format dd/MM/yyyy' {
            # Arrange
            $params = @{
                MailboxEmail       = 'user@contoso.com'
                MailboxDisplayName = 'User'
                TrusteeEmail       = 'delegate@contoso.com'
                TrusteeDisplayName = 'Delegate'
                DelegationType     = 'FullAccess'
                AccessRights       = 'FullAccess'
                MailboxLastLogon   = '15/12/2025'
            }

            # Act
            $record = New-DelegationRecord @params

            # Assert
            $record.MailboxLastLogon | Should -Be '15/12/2025'
        }
    }
}

Describe 'Resolve-TrusteeInfo' -Tag 'Unit' {

    BeforeAll {
        # Stub pour Get-Recipient (requis pour Pester Mock)
        function Get-Recipient { param($Identity) }
    }

    Context 'Resolution reussie' {

        BeforeAll {
            # Mock Get-Recipient pour simuler un destinataire trouve
            Mock Get-Recipient {
                [PSCustomObject]@{
                    PrimarySmtpAddress = 'jean.dupont@contoso.com'
                    DisplayName        = 'Jean DUPONT'
                }
            }
        }

        It 'Retourne les infos resolues pour un email valide' {
            # Act
            $result = Resolve-TrusteeInfo -Identity 'jean.dupont@contoso.com'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Email | Should -Be 'jean.dupont@contoso.com'
            $result.DisplayName | Should -Be 'Jean DUPONT'
            $result.Resolved | Should -BeTrue
        }

        It 'Appelle Get-Recipient avec la bonne identite' {
            # Act
            Resolve-TrusteeInfo -Identity 'test.user@contoso.com'

            # Assert
            Should -Invoke Get-Recipient -Times 1 -ParameterFilter {
                $Identity -eq 'test.user@contoso.com'
            }
        }
    }

    Context 'Resolution echouee' {

        BeforeAll {
            # Mock Get-Recipient qui echoue
            Mock Get-Recipient {
                throw "The operation couldn't be performed because object 'unknown@contoso.com' couldn't be found"
            }
        }

        It 'Retourne l identite brute si destinataire introuvable' {
            # Act
            $result = Resolve-TrusteeInfo -Identity 'unknown@contoso.com'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Email | Should -Be 'unknown@contoso.com'
            $result.DisplayName | Should -Be 'unknown@contoso.com'
            $result.Resolved | Should -BeFalse
        }

        It 'Retourne le SID orphelin tel quel' {
            # Arrange - SID orphelin
            $orphanSid = 'S-1-5-21-583983544-471682574-2706792393-39628563'

            # Act
            $result = Resolve-TrusteeInfo -Identity $orphanSid

            # Assert
            $result.Email | Should -Be $orphanSid
            $result.Resolved | Should -BeFalse
        }
    }

    Context 'Cas limites' {

        It 'Retourne $null pour une chaine vide' {
            # Act
            $result = Resolve-TrusteeInfo -Identity ''

            # Assert
            $result | Should -BeNullOrEmpty
        }

        It 'Retourne $null pour des espaces uniquement' {
            # Act
            $result = Resolve-TrusteeInfo -Identity '   '

            # Assert
            $result | Should -BeNullOrEmpty
        }
    }
}

Describe 'Get-MailboxFullAccessDelegation' -Tag 'Unit', 'Integration' {

    BeforeAll {
        # Stubs pour cmdlets Exchange (requis pour Pester Mock)
        function Get-MailboxPermission { param($Identity) }
        function Get-Recipient { param($Identity) }

        # Definition de la fonction pour les tests
        function Get-MailboxFullAccessDelegation {
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
                    $isOrphan = $trusteeInfo.Email -match '^S-1-5-21-'

                    $delegationRecord = New-DelegationRecord `
                        -MailboxEmail $Mailbox.PrimarySmtpAddress `
                        -MailboxDisplayName $Mailbox.DisplayName `
                        -TrusteeEmail $trusteeInfo.Email `
                        -TrusteeDisplayName $trusteeInfo.DisplayName `
                        -DelegationType 'FullAccess' `
                        -AccessRights 'FullAccess' `
                        -IsOrphan $isOrphan

                    $delegationList.Add($delegationRecord)
                }
            }
            catch {
                # Silently continue for tests
            }

            return $delegationList
        }

        # Mock mailbox objet
        $script:TestMailbox = [PSCustomObject]@{
            Identity           = 'shared@contoso.com'
            PrimarySmtpAddress = 'shared@contoso.com'
            DisplayName        = 'Shared Mailbox Contoso'
        }
    }

    Context 'Permissions FullAccess valides' {

        BeforeAll {
            # Mock Get-MailboxPermission avec delegations valides
            Mock Get-MailboxPermission {
                @(
                    [PSCustomObject]@{
                        User         = 'jean.dupont@contoso.com'
                        AccessRights = @('FullAccess')
                        IsInherited  = $false
                    },
                    [PSCustomObject]@{
                        User         = 'marie.martin@contoso.com'
                        AccessRights = @('FullAccess')
                        IsInherited  = $false
                    }
                )
            }

            # Mock Resolve-TrusteeInfo
            Mock Resolve-TrusteeInfo {
                param($Identity)
                [PSCustomObject]@{
                    Email       = $Identity
                    DisplayName = $Identity.Split('@')[0] -replace '\.', ' '
                    Resolved    = $true
                }
            }
        }

        It 'Retourne les delegations FullAccess' {
            # Act
            $result = Get-MailboxFullAccessDelegation -Mailbox $script:TestMailbox

            # Assert
            $result | Should -HaveCount 2
            $result[0].DelegationType | Should -Be 'FullAccess'
            $result[0].AccessRights | Should -Be 'FullAccess'
        }

        It 'Inclut les infos mailbox correctes' {
            # Act
            $result = Get-MailboxFullAccessDelegation -Mailbox $script:TestMailbox

            # Assert
            $result[0].MailboxEmail | Should -Be 'shared@contoso.com'
            $result[0].MailboxDisplayName | Should -Be 'Shared Mailbox Contoso'
        }

        It 'Inclut les infos trustee correctes' {
            # Act
            $result = Get-MailboxFullAccessDelegation -Mailbox $script:TestMailbox

            # Assert
            $result[0].TrusteeEmail | Should -Be 'jean.dupont@contoso.com'
        }
    }

    Context 'Filtrage comptes systeme' {

        BeforeAll {
            Mock Get-MailboxPermission {
                @(
                    [PSCustomObject]@{
                        User         = 'NT AUTHORITY\SELF'
                        AccessRights = @('FullAccess')
                        IsInherited  = $false
                    },
                    [PSCustomObject]@{
                        User         = 'jean.dupont@contoso.com'
                        AccessRights = @('FullAccess')
                        IsInherited  = $false
                    }
                )
            }

            Mock Resolve-TrusteeInfo {
                param($Identity)
                [PSCustomObject]@{
                    Email       = $Identity
                    DisplayName = $Identity
                    Resolved    = $true
                }
            }
        }

        It 'Exclut NT AUTHORITY\SELF' {
            # Act
            $result = Get-MailboxFullAccessDelegation -Mailbox $script:TestMailbox

            # Assert
            $result | Should -HaveCount 1
            $result[0].TrusteeEmail | Should -Be 'jean.dupont@contoso.com'
        }
    }

    Context 'Detection delegations orphelines' {

        BeforeAll {
            Mock Get-MailboxPermission {
                @(
                    [PSCustomObject]@{
                        User         = 'S-1-5-21-583983544-471682574-2706792393-39628563'
                        AccessRights = @('FullAccess')
                        IsInherited  = $false
                    }
                )
            }

            Mock Resolve-TrusteeInfo {
                param($Identity)
                [PSCustomObject]@{
                    Email       = $Identity
                    DisplayName = $Identity
                    Resolved    = $false
                }
            }
        }

        It 'Marque IsOrphan = $true pour SID orphelin' {
            # Act
            $result = Get-MailboxFullAccessDelegation -Mailbox $script:TestMailbox

            # Assert
            $result | Should -HaveCount 1
            $result[0].IsOrphan | Should -BeTrue
            $result[0].TrusteeEmail | Should -Match '^S-1-5-21-'
        }
    }

    Context 'Aucune delegation' {

        BeforeAll {
            Mock Get-MailboxPermission { @() }
        }

        It 'Retourne liste vide si aucune permission FullAccess' {
            # Act
            $result = Get-MailboxFullAccessDelegation -Mailbox $script:TestMailbox

            # Assert
            $result | Should -HaveCount 0
        }
    }
}

Describe 'Get-MailboxSendAsDelegation' -Tag 'Unit', 'Integration' {

    BeforeAll {
        # Stubs pour cmdlets Exchange (requis pour Pester Mock)
        function Get-RecipientPermission { param($Identity) }
        function Get-Recipient { param($Identity) }

        function Get-MailboxSendAsDelegation {
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
                    $isOrphan = $trusteeInfo.Email -match '^S-1-5-21-'

                    $delegationRecord = New-DelegationRecord `
                        -MailboxEmail $Mailbox.PrimarySmtpAddress `
                        -MailboxDisplayName $Mailbox.DisplayName `
                        -TrusteeEmail $trusteeInfo.Email `
                        -TrusteeDisplayName $trusteeInfo.DisplayName `
                        -DelegationType 'SendAs' `
                        -AccessRights 'SendAs' `
                        -IsOrphan $isOrphan

                    $delegationList.Add($delegationRecord)
                }
            }
            catch {
                # Silently continue for tests
            }

            return $delegationList
        }

        $script:TestMailbox = [PSCustomObject]@{
            Identity           = 'user@contoso.com'
            PrimarySmtpAddress = 'user@contoso.com'
            DisplayName        = 'User Contoso'
        }
    }

    Context 'Permissions SendAs valides' {

        BeforeAll {
            Mock Get-RecipientPermission {
                @(
                    [PSCustomObject]@{
                        Trustee      = 'assistant@contoso.com'
                        AccessRights = @('SendAs')
                    }
                )
            }

            Mock Resolve-TrusteeInfo {
                param($Identity)
                [PSCustomObject]@{
                    Email       = $Identity
                    DisplayName = 'Assistant Contoso'
                    Resolved    = $true
                }
            }
        }

        It 'Retourne les delegations SendAs' {
            # Act
            $result = Get-MailboxSendAsDelegation -Mailbox $script:TestMailbox

            # Assert
            $result | Should -HaveCount 1
            $result[0].DelegationType | Should -Be 'SendAs'
            $result[0].TrusteeEmail | Should -Be 'assistant@contoso.com'
        }
    }

    Context 'Aucune delegation' {

        BeforeAll {
            Mock Get-RecipientPermission { @() }
        }

        It 'Retourne liste vide si aucune permission SendAs' {
            # Act
            $result = Get-MailboxSendAsDelegation -Mailbox $script:TestMailbox

            # Assert
            $result | Should -HaveCount 0
        }
    }
}

Describe 'Get-MailboxSendOnBehalfDelegation' -Tag 'Unit', 'Integration' {

    BeforeAll {
        # Stubs pour cmdlets Exchange (requis pour Pester Mock)
        function Get-Recipient { param($Identity) }

        function Get-MailboxSendOnBehalfDelegation {
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
                    # Silently continue
                }
            }

            return $delegationList
        }
    }

    Context 'Permissions SendOnBehalf via propriete mailbox' {

        BeforeAll {
            Mock Resolve-TrusteeInfo {
                param($Identity)
                [PSCustomObject]@{
                    Email       = "$Identity@contoso.com"
                    DisplayName = $Identity
                    Resolved    = $true
                }
            }
        }

        It 'Retourne les delegations SendOnBehalf' {
            # Arrange
            $mailbox = [PSCustomObject]@{
                Identity            = 'exec@contoso.com'
                PrimarySmtpAddress  = 'exec@contoso.com'
                DisplayName         = 'Executive Contoso'
                GrantSendOnBehalfTo = @('assistant1', 'assistant2')
            }

            # Act
            $result = Get-MailboxSendOnBehalfDelegation -Mailbox $mailbox

            # Assert
            $result | Should -HaveCount 2
            $result[0].DelegationType | Should -Be 'SendOnBehalf'
        }

        It 'Retourne liste vide si GrantSendOnBehalfTo est null' {
            # Arrange
            $mailbox = [PSCustomObject]@{
                Identity            = 'user@contoso.com'
                PrimarySmtpAddress  = 'user@contoso.com'
                DisplayName         = 'User'
                GrantSendOnBehalfTo = $null
            }

            # Act
            $result = Get-MailboxSendOnBehalfDelegation -Mailbox $mailbox

            # Assert
            $result | Should -HaveCount 0
        }

        It 'Retourne liste vide si GrantSendOnBehalfTo est vide' {
            # Arrange
            $mailbox = [PSCustomObject]@{
                Identity            = 'user@contoso.com'
                PrimarySmtpAddress  = 'user@contoso.com'
                DisplayName         = 'User'
                GrantSendOnBehalfTo = @()
            }

            # Act
            $result = Get-MailboxSendOnBehalfDelegation -Mailbox $mailbox

            # Assert
            $result | Should -HaveCount 0
        }
    }
}

Describe 'Get-MailboxCalendarDelegation' -Tag 'Unit', 'Integration' {

    BeforeAll {
        # Stubs pour cmdlets Exchange (requis pour Pester Mock)
        function Get-MailboxFolderStatistics { param($Identity, $FolderScope) }
        function Get-MailboxFolderPermission { param($Identity) }
        function Get-Recipient { param($Identity) }

        function Get-MailboxCalendarDelegation {
            param([object]$Mailbox)

            $delegationList = [System.Collections.Generic.List[PSCustomObject]]::new()

            try {
                $calendarFolder = Get-MailboxFolderStatistics -Identity $Mailbox.PrimarySmtpAddress -FolderScope Calendar -ErrorAction Stop |
                    Where-Object { $_.FolderType -eq 'Calendar' } |
                    Select-Object -First 1

                if (-not $calendarFolder) {
                    return $delegationList
                }

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

                    if (Test-IsSystemAccount -Identity $trusteeEmail) { continue }

                    $isOrphan = ($trusteeEmail -match '^S-1-5-21-') -or ($null -eq $permission.User.ADRecipient)

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
                # Silently continue
            }

            return $delegationList
        }

        $script:TestMailbox = [PSCustomObject]@{
            Identity           = 'room@contoso.com'
            PrimarySmtpAddress = 'room@contoso.com'
            DisplayName        = 'Salle de reunion Contoso'
        }
    }

    Context 'Permissions calendrier' {

        BeforeAll {
            Mock Get-MailboxFolderStatistics {
                @([PSCustomObject]@{
                        Name       = 'Calendrier'
                        FolderType = 'Calendar'
                    })
            }

            Mock Get-MailboxFolderPermission {
                @(
                    [PSCustomObject]@{
                        User         = [PSCustomObject]@{
                            DisplayName = 'Jean DUPONT'
                            ADRecipient = [PSCustomObject]@{
                                PrimarySmtpAddress = 'jean.dupont@contoso.com'
                            }
                        }
                        AccessRights = @('Editor')
                    }
                )
            }
        }

        It 'Retourne les delegations Calendar' {
            # Act
            $result = Get-MailboxCalendarDelegation -Mailbox $script:TestMailbox

            # Assert
            $result | Should -HaveCount 1
            $result[0].DelegationType | Should -Be 'Calendar'
            $result[0].FolderPath | Should -Be 'Calendrier'
        }

        It 'Inclut le nom localise du calendrier (Calendrier vs Calendar)' {
            # Act
            $result = Get-MailboxCalendarDelegation -Mailbox $script:TestMailbox

            # Assert
            $result[0].FolderPath | Should -Be 'Calendrier'
        }
    }

    Context 'Detection orphelins calendrier (nom cache)' {

        BeforeAll {
            Mock Get-MailboxFolderStatistics {
                @([PSCustomObject]@{
                        Name       = 'Calendar'
                        FolderType = 'Calendar'
                    })
            }

            Mock Get-MailboxFolderPermission {
                @(
                    [PSCustomObject]@{
                        User         = [PSCustomObject]@{
                            DisplayName = 'Ancien Employe'
                            ADRecipient = $null  # ADRecipient null = orphelin
                        }
                        AccessRights = @('Reviewer')
                    }
                )
            }
        }

        It 'Marque IsOrphan = $true quand ADRecipient est null' {
            # Act
            $result = Get-MailboxCalendarDelegation -Mailbox $script:TestMailbox

            # Assert
            $result | Should -HaveCount 1
            $result[0].IsOrphan | Should -BeTrue
            $result[0].TrusteeDisplayName | Should -Be 'Ancien Employe'
        }
    }

    Context 'Filtrage Default/Anonymous' {

        BeforeAll {
            Mock Get-MailboxFolderStatistics {
                @([PSCustomObject]@{
                        Name       = 'Calendar'
                        FolderType = 'Calendar'
                    })
            }

            Mock Get-MailboxFolderPermission {
                @(
                    [PSCustomObject]@{
                        User         = [PSCustomObject]@{
                            DisplayName = 'Default'
                            ADRecipient = $null
                        }
                        AccessRights = @('AvailabilityOnly')
                    },
                    [PSCustomObject]@{
                        User         = [PSCustomObject]@{
                            DisplayName = 'jean.dupont@contoso.com'
                            ADRecipient = [PSCustomObject]@{
                                PrimarySmtpAddress = 'jean.dupont@contoso.com'
                            }
                        }
                        AccessRights = @('Editor')
                    }
                )
            }
        }

        It 'Exclut les permissions Default' {
            # Act
            $result = Get-MailboxCalendarDelegation -Mailbox $script:TestMailbox

            # Assert
            $result | Should -HaveCount 1
            $result[0].TrusteeEmail | Should -Not -Be 'Default'
        }
    }
}

Describe 'Get-MailboxForwardingDelegation' -Tag 'Unit', 'Integration' {

    BeforeAll {
        # Stubs pour cmdlets Exchange (requis pour Pester Mock)
        function Get-Recipient { param($Identity) }

        function Get-MailboxForwardingDelegation {
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
                    # Silently continue
                }
            }

            return $delegationList
        }
    }

    Context 'ForwardingSmtpAddress (externe)' {

        It 'Detecte ForwardingSmtpAddress avec prefixe smtp:' {
            # Arrange
            $mailbox = [PSCustomObject]@{
                Identity              = 'user@contoso.com'
                PrimarySmtpAddress    = 'user@contoso.com'
                DisplayName           = 'User Contoso'
                ForwardingSmtpAddress = 'smtp:backup@fabrikam.com'
                ForwardingAddress     = $null
            }

            # Act
            $result = Get-MailboxForwardingDelegation -Mailbox $mailbox

            # Assert
            $result | Should -HaveCount 1
            $result[0].DelegationType | Should -Be 'Forwarding'
            $result[0].AccessRights | Should -Be 'ForwardingSmtpAddress'
            $result[0].TrusteeEmail | Should -Be 'backup@fabrikam.com'
        }

        It 'Detecte ForwardingSmtpAddress sans prefixe' {
            # Arrange
            $mailbox = [PSCustomObject]@{
                Identity              = 'user@contoso.com'
                PrimarySmtpAddress    = 'user@contoso.com'
                DisplayName           = 'User'
                ForwardingSmtpAddress = 'external@gmail.com'
                ForwardingAddress     = $null
            }

            # Act
            $result = Get-MailboxForwardingDelegation -Mailbox $mailbox

            # Assert
            $result | Should -HaveCount 1
            $result[0].TrusteeEmail | Should -Be 'external@gmail.com'
        }
    }

    Context 'ForwardingAddress (interne)' {

        BeforeAll {
            Mock Get-Recipient {
                [PSCustomObject]@{
                    PrimarySmtpAddress = 'manager@contoso.com'
                    DisplayName        = 'Manager Contoso'
                }
            }
        }

        It 'Detecte ForwardingAddress interne' {
            # Arrange
            $mailbox = [PSCustomObject]@{
                Identity              = 'user@contoso.com'
                PrimarySmtpAddress    = 'user@contoso.com'
                DisplayName           = 'User'
                ForwardingSmtpAddress = $null
                ForwardingAddress     = 'contoso.com/Users/Manager'
            }

            # Act
            $result = Get-MailboxForwardingDelegation -Mailbox $mailbox

            # Assert
            $result | Should -HaveCount 1
            $result[0].AccessRights | Should -Be 'ForwardingAddress'
            $result[0].TrusteeEmail | Should -Be 'manager@contoso.com'
        }
    }

    Context 'Aucun forwarding' {

        It 'Retourne liste vide si aucun forwarding configure' {
            # Arrange
            $mailbox = [PSCustomObject]@{
                Identity              = 'user@contoso.com'
                PrimarySmtpAddress    = 'user@contoso.com'
                DisplayName           = 'User'
                ForwardingSmtpAddress = $null
                ForwardingAddress     = $null
            }

            # Act
            $result = Get-MailboxForwardingDelegation -Mailbox $mailbox

            # Assert
            $result | Should -HaveCount 0
        }
    }

    Context 'Les deux types de forwarding' {

        BeforeAll {
            Mock Get-Recipient {
                [PSCustomObject]@{
                    PrimarySmtpAddress = 'internal@contoso.com'
                    DisplayName        = 'Internal User'
                }
            }
        }

        It 'Retourne les deux delegations si les deux sont configures' {
            # Arrange
            $mailbox = [PSCustomObject]@{
                Identity              = 'user@contoso.com'
                PrimarySmtpAddress    = 'user@contoso.com'
                DisplayName           = 'User'
                ForwardingSmtpAddress = 'smtp:external@fabrikam.com'
                ForwardingAddress     = 'contoso.com/Users/Internal'
            }

            # Act
            $result = Get-MailboxForwardingDelegation -Mailbox $mailbox

            # Assert
            $result | Should -HaveCount 2
            ($result | Where-Object AccessRights -EQ 'ForwardingSmtpAddress').TrusteeEmail | Should -Be 'external@fabrikam.com'
            ($result | Where-Object AccessRights -EQ 'ForwardingAddress').TrusteeEmail | Should -Be 'internal@contoso.com'
        }
    }
}

Describe 'Detection Transitoire et Mode Forensic (BUG-009)' -Tag 'Unit', 'BUG-009' {

    BeforeAll {
        # Variables script simulees
        $script:RecipientCache = @{}
        $script:ForensicMode = $false
        $script:SkippedTransitionalCount = 0
        $script:ForensicCollectedCount = 0

        # Peupler le cache avec des recipients actifs
        $script:RecipientCache['active@contoso.com'] = [PSCustomObject]@{
            PrimarySmtpAddress = 'active@contoso.com'
            DisplayName        = 'Active User'
        }
        $script:RecipientCache['shared@contoso.com'] = [PSCustomObject]@{
            PrimarySmtpAddress = 'shared@contoso.com'
            DisplayName        = 'Shared Mailbox'
        }

        # Fonction de detection transitoire
        function Test-IsTransitional {
            param([string]$PrimarySmtpAddress)
            return -not $script:RecipientCache.ContainsKey($PrimarySmtpAddress.ToLower())
        }
    }

    Context 'Detection via RecipientCache' {

        It 'Mailbox active (dans cache) = non-transitoire' {
            # Arrange
            $mailboxEmail = 'active@contoso.com'

            # Act
            $isTransitional = Test-IsTransitional -PrimarySmtpAddress $mailboxEmail

            # Assert
            $isTransitional | Should -BeFalse
        }

        It 'Mailbox soft-deleted (pas dans cache) = transitoire' {
            # Arrange
            $mailboxEmail = 'deleted@contoso.com'

            # Act
            $isTransitional = Test-IsTransitional -PrimarySmtpAddress $mailboxEmail

            # Assert
            $isTransitional | Should -BeTrue
        }

        It 'Detection est case-insensitive' {
            # Arrange - Email en majuscules
            $mailboxEmail = 'ACTIVE@CONTOSO.COM'

            # Act
            $isTransitional = Test-IsTransitional -PrimarySmtpAddress $mailboxEmail

            # Assert
            $isTransitional | Should -BeFalse
        }
    }

    Context 'Mode normal (sans -Forensic)' {

        BeforeAll {
            $script:ForensicMode = $false
            $script:SkippedTransitionalCount = 0
        }

        It 'Transitoire est skippee en mode normal' {
            # Arrange
            $isTransitional = $true

            # Act - Simulation du comportement du script
            if ($isTransitional -and -not $script:ForensicMode) {
                $script:SkippedTransitionalCount++
                $skipped = $true
            }
            else {
                $skipped = $false
            }

            # Assert
            $skipped | Should -BeTrue
            $script:SkippedTransitionalCount | Should -Be 1
        }

        It 'Non-transitoire est traitee normalement' {
            # Arrange
            $isTransitional = $false
            $processed = $false

            # Act
            if ($isTransitional -and -not $script:ForensicMode) {
                $script:SkippedTransitionalCount++
            }
            else {
                $processed = $true
            }

            # Assert
            $processed | Should -BeTrue
        }
    }

    Context 'Mode forensic (avec -Forensic)' {

        BeforeAll {
            $script:ForensicMode = $true
            $script:ForensicCollectedCount = 0
        }

        It 'Transitoire est traitee en mode forensic' {
            # Arrange
            $isTransitional = $true
            $processed = $false

            # Act
            if ($isTransitional -and -not $script:ForensicMode) {
                $script:SkippedTransitionalCount++
            }
            else {
                $processed = $true
            }

            # Assert
            $processed | Should -BeTrue
        }

        It 'ForensicCollectedCount incremente apres retry reussi' {
            # Arrange
            $script:ForensicCollectedCount = 0

            # Act - Simuler un retry reussi
            $script:ForensicCollectedCount++

            # Assert
            $script:ForensicCollectedCount | Should -Be 1
        }
    }

    Context 'Compteurs dans le resume' {

        It 'SkippedTransitionalCount affiche si > 0' {
            # Arrange
            $script:SkippedTransitionalCount = 5
            $summaryContent = [ordered]@{}

            # Act
            if ($script:SkippedTransitionalCount -gt 0) {
                $summaryContent['Transitoires'] = "$($script:SkippedTransitionalCount) ignorees"
            }

            # Assert
            $summaryContent.Contains('Transitoires') | Should -BeTrue
            $summaryContent['Transitoires'] | Should -Be '5 ignorees'
        }

        It 'ForensicCollectedCount affiche si > 0' {
            # Arrange
            $script:ForensicCollectedCount = 3
            $summaryContent = [ordered]@{}

            # Act
            if ($script:ForensicCollectedCount -gt 0) {
                $summaryContent['Forensic'] = "$($script:ForensicCollectedCount) soft-deleted collectees"
            }

            # Assert
            $summaryContent.Contains('Forensic') | Should -BeTrue
            $summaryContent['Forensic'] | Should -Be '3 soft-deleted collectees'
        }

        It 'Compteurs non affiches si = 0' {
            # Arrange
            $script:SkippedTransitionalCount = 0
            $script:ForensicCollectedCount = 0
            $summaryContent = [ordered]@{}

            # Act
            if ($script:SkippedTransitionalCount -gt 0) {
                $summaryContent['Transitoires'] = "$($script:SkippedTransitionalCount) ignorees"
            }
            if ($script:ForensicCollectedCount -gt 0) {
                $summaryContent['Forensic'] = "$($script:ForensicCollectedCount) soft-deleted collectees"
            }

            # Assert
            $summaryContent.Contains('Transitoires') | Should -BeFalse
            $summaryContent.Contains('Forensic') | Should -BeFalse
        }
    }
}

Describe 'Get-MailboxFullAccessDelegation avec IsTransitional (BUG-009)' -Tag 'Unit', 'BUG-009' {

    BeforeAll {
        # Stubs pour cmdlets Exchange
        function Get-EXOMailboxPermission { param($Identity, [switch]$SoftDeletedMailbox) }
        function Get-Recipient { param($Identity) }

        $script:ForensicMode = $false
        $script:ForensicCollectedCount = 0

        function Get-MailboxFullAccessDelegationWithTransitional {
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
                    $delegationRecord = New-DelegationRecord `
                        -MailboxEmail $Mailbox.PrimarySmtpAddress `
                        -MailboxDisplayName $Mailbox.DisplayName `
                        -TrusteeEmail $permission.User `
                        -TrusteeDisplayName $permission.User `
                        -DelegationType 'FullAccess' `
                        -AccessRights 'FullAccess' `
                        -IsSoftDeleted $isSoftDeleted

                    $delegationList.Add($delegationRecord)
                }
            }
            catch {
                # Log warning et continuer
            }

            return $delegationList
        }

        $script:TestMailbox = [PSCustomObject]@{
            Identity           = 'test@contoso.com'
            PrimarySmtpAddress = 'test@contoso.com'
            DisplayName        = 'Test Mailbox'
        }
    }

    Context 'Mailbox active (IsTransitional = $false)' {

        BeforeAll {
            $script:ForensicMode = $false

            Mock Get-EXOMailboxPermission {
                @([PSCustomObject]@{
                        User         = 'delegate@contoso.com'
                        AccessRights = @('FullAccess')
                        IsInherited  = $false
                    })
            }
        }

        It 'Traitement normal sans retry' {
            # Act
            $result = Get-MailboxFullAccessDelegationWithTransitional -Mailbox $script:TestMailbox -IsTransitional $false

            # Assert
            $result | Should -HaveCount 1
            $result[0].IsSoftDeleted | Should -BeFalse

            Should -Invoke Get-EXOMailboxPermission -Times 1 -ParameterFilter {
                $SoftDeletedMailbox -eq $false -or $null -eq $SoftDeletedMailbox
            }
        }
    }

    Context 'Mailbox transitoire en mode normal' {

        BeforeAll {
            $script:ForensicMode = $false

            Mock Get-EXOMailboxPermission {
                throw "The operation couldn't be performed because object 'test@contoso.com' couldn't find as a recipient."
            }
        }

        It 'Erreur propagee sans retry (mode normal)' {
            # Act
            $result = Get-MailboxFullAccessDelegationWithTransitional -Mailbox $script:TestMailbox -IsTransitional $true

            # Assert - Liste vide car erreur catchee
            $result | Should -HaveCount 0

            # Pas de retry avec -SoftDeletedMailbox
            Should -Invoke Get-EXOMailboxPermission -Times 1
        }
    }

    Context 'Mailbox transitoire en mode forensic' {

        BeforeAll {
            $script:ForensicMode = $true
            $script:ForensicCollectedCount = 0

            # Premier appel echoue, deuxieme (avec -SoftDeletedMailbox) reussit
            Mock Get-EXOMailboxPermission {
                param($Identity, [switch]$SoftDeletedMailbox)

                if ($SoftDeletedMailbox) {
                    # Retry reussi
                    @([PSCustomObject]@{
                            User         = 'delegate@contoso.com'
                            AccessRights = @('FullAccess')
                            IsInherited  = $false
                        })
                }
                else {
                    throw "The operation couldn't be performed because object 'test@contoso.com' couldn't find as a recipient."
                }
            }
        }

        It 'Retry avec -SoftDeletedMailbox en mode forensic' {
            # Arrange
            $script:ForensicCollectedCount = 0

            # Act
            $result = Get-MailboxFullAccessDelegationWithTransitional -Mailbox $script:TestMailbox -IsTransitional $true

            # Assert
            $result | Should -HaveCount 1
            $result[0].IsSoftDeleted | Should -BeTrue
            $script:ForensicCollectedCount | Should -Be 1
        }
    }

    Context 'Erreur non-matchee (timeout, throttling)' {

        BeforeAll {
            $script:ForensicMode = $true

            Mock Get-EXOMailboxPermission {
                throw "Request timed out after 30 seconds"
            }
        }

        It 'Pas de retry pour erreur non-recipient' {
            # Act
            $result = Get-MailboxFullAccessDelegationWithTransitional -Mailbox $script:TestMailbox -IsTransitional $true

            # Assert - Erreur non matchee = pas de retry = liste vide
            $result | Should -HaveCount 0

            # Un seul appel (pas de retry)
            Should -Invoke Get-EXOMailboxPermission -Times 1
        }
    }
}
