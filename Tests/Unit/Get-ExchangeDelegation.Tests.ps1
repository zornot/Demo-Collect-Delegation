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

        It 'Contient exactement 8 proprietes' {
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
            $properties | Should -HaveCount 8
            $properties | Should -Contain 'MailboxEmail'
            $properties | Should -Contain 'MailboxDisplayName'
            $properties | Should -Contain 'TrusteeEmail'
            $properties | Should -Contain 'TrusteeDisplayName'
            $properties | Should -Contain 'DelegationType'
            $properties | Should -Contain 'AccessRights'
            $properties | Should -Contain 'FolderPath'
            $properties | Should -Contain 'CollectedAt'
        }
    }
}
