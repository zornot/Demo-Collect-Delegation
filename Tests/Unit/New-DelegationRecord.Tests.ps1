#Requires -Modules Pester

# PSScriptAnalyzer ne comprend pas le scope Pester (BeforeEach -> It)
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

BeforeAll {
    # Dot-source le script principal pour avoir acces a New-DelegationRecord
    $scriptPath = Join-Path $PSScriptRoot '..' '..' 'Get-ExchangeDelegation.ps1'

    # Creer des stubs pour les fonctions externes AVANT de les mocker
    # (Mock ne peut pas mocker une fonction qui n'existe pas)
    function global:Write-Log { param([string]$Message, [string]$Level, [switch]$NoConsole) }
    function global:Write-Status { param([string]$Type, [string]$Message, [int]$Indent) }
    function global:Connect-GraphConnection { param([string[]]$Scopes) }
    function global:Connect-ExchangeOnline { }

    # Mock des dependances externes pour eviter l'execution du script complet
    Mock -CommandName Write-Log -MockWith {}
    Mock -CommandName Write-Status -MockWith {}
    Mock -CommandName Connect-GraphConnection -MockWith {
        [PSCustomObject]@{ IsConnected = $false }
    }
    Mock -CommandName Connect-ExchangeOnline -MockWith {}

    # Dot-source le script
    . $scriptPath
}

Describe 'New-DelegationRecord' -Tag 'Unit', 'FEAT-014' {

    Context 'Cas nominal - Tous les parametres fournis' {

        It 'Cree un enregistrement avec toutes les proprietes standards' {
            # Arrange
            $params = @{
                MailboxEmail       = 'jean.dupont@contoso.com'
                MailboxDisplayName = 'Jean Dupont'
                TrusteeEmail       = 'marie.martin@contoso.com'
                TrusteeDisplayName = 'Marie Martin'
                DelegationType     = 'FullAccess'
                AccessRights       = 'FullAccess'
                FolderPath         = ''
                IsOrphan           = $false
                IsInactive         = $false
                IsSoftDeleted      = $false
                MailboxType        = 'UserMailbox'
                MailboxLastLogon   = '15/12/2025'
            }

            # Act
            $result = New-DelegationRecord @params

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.MailboxEmail | Should -Be 'jean.dupont@contoso.com'
            $result.MailboxDisplayName | Should -Be 'Jean Dupont'
            $result.TrusteeEmail | Should -Be 'marie.martin@contoso.com'
            $result.TrusteeDisplayName | Should -Be 'Marie Martin'
            $result.DelegationType | Should -Be 'FullAccess'
            $result.AccessRights | Should -Be 'FullAccess'
            $result.FolderPath | Should -Be ''
            $result.IsOrphan | Should -Be $false
            $result.IsInactive | Should -Be $false
            $result.IsSoftDeleted | Should -Be $false
            $result.MailboxType | Should -Be 'UserMailbox'
            $result.MailboxLastLogon | Should -Be '15/12/2025'
            $result.CollectedAt | Should -Not -BeNullOrEmpty
        }

        It 'Retourne un PSCustomObject' {
            # Arrange
            $params = @{
                MailboxEmail       = 'test@contoso.com'
                MailboxDisplayName = 'Test User'
                TrusteeEmail       = 'trustee@contoso.com'
                TrusteeDisplayName = 'Trustee User'
                DelegationType     = 'SendAs'
                AccessRights       = 'SendAs'
            }

            # Act
            $result = New-DelegationRecord @params

            # Assert
            $result | Should -BeOfType [PSCustomObject]
        }

        It 'Accepte FolderPath pour delegations Calendar' {
            # Arrange
            $params = @{
                MailboxEmail       = 'boss@contoso.com'
                MailboxDisplayName = 'Boss'
                TrusteeEmail       = 'assistant@contoso.com'
                TrusteeDisplayName = 'Assistant'
                DelegationType     = 'Calendar'
                AccessRights       = 'Editor'
                FolderPath         = 'Calendar'
            }

            # Act
            $result = New-DelegationRecord @params

            # Assert
            $result.FolderPath | Should -Be 'Calendar'
        }
    }

    Context 'Parametres optionnels - Valeurs par defaut' {

        It 'Utilise valeurs par defaut pour parametres optionnels' {
            # Arrange
            $params = @{
                MailboxEmail       = 'user@contoso.com'
                MailboxDisplayName = 'User'
                TrusteeEmail       = 'trustee@contoso.com'
                TrusteeDisplayName = 'Trustee'
                DelegationType     = 'SendAs'
                AccessRights       = 'SendAs'
            }

            # Act
            $result = New-DelegationRecord @params

            # Assert
            $result.FolderPath | Should -Be ''
            $result.IsOrphan | Should -Be $false
            $result.IsInactive | Should -Be $false
            $result.IsSoftDeleted | Should -Be $false
            $result.MailboxType | Should -Be ''
            $result.MailboxLastLogon | Should -Be ''
        }
    }

    Context 'FEAT-014 - Nouveau parametre LastLogonSource' {

        It 'Accepte le parametre LastLogonSource' {
            # Arrange
            $params = @{
                MailboxEmail       = 'user@contoso.com'
                MailboxDisplayName = 'User'
                TrusteeEmail       = 'trustee@contoso.com'
                TrusteeDisplayName = 'Trustee'
                DelegationType     = 'FullAccess'
                AccessRights       = 'FullAccess'
                MailboxLastLogon   = '15/12/2025'
                LastLogonSource    = 'SignInActivity'
            }

            # Act
            $result = New-DelegationRecord @params

            # Assert
            $result.LastLogonSource | Should -Be 'SignInActivity'
        }

        It 'Retourne LastLogonSource = SignInActivity pour Azure AD P1' {
            # Arrange
            $params = @{
                MailboxEmail       = 'user@contoso.com'
                MailboxDisplayName = 'User'
                TrusteeEmail       = 'trustee@contoso.com'
                TrusteeDisplayName = 'Trustee'
                DelegationType     = 'FullAccess'
                AccessRights       = 'FullAccess'
                MailboxLastLogon   = '15/12/2025'
                LastLogonSource    = 'SignInActivity'
            }

            # Act
            $result = New-DelegationRecord @params

            # Assert
            $result.LastLogonSource | Should -Be 'SignInActivity'
        }

        It 'Retourne LastLogonSource = GraphReports pour Graph Reports API' {
            # Arrange
            $params = @{
                MailboxEmail       = 'user@contoso.com'
                MailboxDisplayName = 'User'
                TrusteeEmail       = 'trustee@contoso.com'
                TrusteeDisplayName = 'Trustee'
                DelegationType     = 'SendAs'
                AccessRights       = 'SendAs'
                MailboxLastLogon   = '10/12/2025'
                LastLogonSource    = 'GraphReports'
            }

            # Act
            $result = New-DelegationRecord @params

            # Assert
            $result.LastLogonSource | Should -Be 'GraphReports'
        }

        It 'Retourne LastLogonSource = EXO pour EXO Statistics fallback' {
            # Arrange
            $params = @{
                MailboxEmail       = 'user@contoso.com'
                MailboxDisplayName = 'User'
                TrusteeEmail       = 'trustee@contoso.com'
                TrusteeDisplayName = 'Trustee'
                DelegationType     = 'SendOnBehalf'
                AccessRights       = 'SendOnBehalf'
                MailboxLastLogon   = '01/12/2025'
                LastLogonSource    = 'EXO'
            }

            # Act
            $result = New-DelegationRecord @params

            # Assert
            $result.LastLogonSource | Should -Be 'EXO'
        }

        It 'Retourne LastLogonSource vide quand MailboxLastLogon est vide' {
            # Arrange
            $params = @{
                MailboxEmail       = 'user@contoso.com'
                MailboxDisplayName = 'User'
                TrusteeEmail       = 'trustee@contoso.com'
                TrusteeDisplayName = 'Trustee'
                DelegationType     = 'FullAccess'
                AccessRights       = 'FullAccess'
                MailboxLastLogon   = ''
                LastLogonSource    = ''
            }

            # Act
            $result = New-DelegationRecord @params

            # Assert
            $result.LastLogonSource | Should -Be ''
        }

        It 'Utilise valeur par defaut vide pour LastLogonSource si non fourni' {
            # Arrange
            $params = @{
                MailboxEmail       = 'user@contoso.com'
                MailboxDisplayName = 'User'
                TrusteeEmail       = 'trustee@contoso.com'
                TrusteeDisplayName = 'Trustee'
                DelegationType     = 'Forwarding'
                AccessRights       = 'ForwardingSmtpAddress'
            }

            # Act
            $result = New-DelegationRecord @params

            # Assert
            $result.LastLogonSource | Should -Be ''
        }
    }

    Context 'Flags booléens - IsOrphan, IsInactive, IsSoftDeleted' {

        It 'Marque IsOrphan = $true pour delegation orpheline' {
            # Arrange
            $params = @{
                MailboxEmail       = 'user@contoso.com'
                MailboxDisplayName = 'User'
                TrusteeEmail       = 'S-1-5-21-1234567890-1234567890-1234567890-1001'
                TrusteeDisplayName = 'S-1-5-21-1234567890-1234567890-1234567890-1001'
                DelegationType     = 'FullAccess'
                AccessRights       = 'FullAccess'
                IsOrphan           = $true
            }

            # Act
            $result = New-DelegationRecord @params

            # Assert
            $result.IsOrphan | Should -Be $true
        }

        It 'Marque IsInactive = $true pour compte inactif' {
            # Arrange
            $params = @{
                MailboxEmail       = 'inactive@contoso.com'
                MailboxDisplayName = 'Inactive User'
                TrusteeEmail       = 'trustee@contoso.com'
                TrusteeDisplayName = 'Trustee'
                DelegationType     = 'SendAs'
                AccessRights       = 'SendAs'
                IsInactive         = $true
            }

            # Act
            $result = New-DelegationRecord @params

            # Assert
            $result.IsInactive | Should -Be $true
        }

        It 'Marque IsSoftDeleted = $true pour boite supprimee' {
            # Arrange
            $params = @{
                MailboxEmail       = 'deleted@contoso.com'
                MailboxDisplayName = 'Deleted Mailbox'
                TrusteeEmail       = 'trustee@contoso.com'
                TrusteeDisplayName = 'Trustee'
                DelegationType     = 'FullAccess'
                AccessRights       = 'FullAccess'
                IsSoftDeleted      = $true
            }

            # Act
            $result = New-DelegationRecord @params

            # Assert
            $result.IsSoftDeleted | Should -Be $true
        }
    }

    Context 'Types de boites - MailboxType' {

        It 'Enregistre MailboxType = UserMailbox' {
            # Arrange
            $params = @{
                MailboxEmail       = 'user@contoso.com'
                MailboxDisplayName = 'User'
                TrusteeEmail       = 'trustee@contoso.com'
                TrusteeDisplayName = 'Trustee'
                DelegationType     = 'FullAccess'
                AccessRights       = 'FullAccess'
                MailboxType        = 'UserMailbox'
            }

            # Act
            $result = New-DelegationRecord @params

            # Assert
            $result.MailboxType | Should -Be 'UserMailbox'
        }

        It 'Enregistre MailboxType = SharedMailbox' {
            # Arrange
            $params = @{
                MailboxEmail       = 'shared@contoso.com'
                MailboxDisplayName = 'Shared Mailbox'
                TrusteeEmail       = 'trustee@contoso.com'
                TrusteeDisplayName = 'Trustee'
                DelegationType     = 'FullAccess'
                AccessRights       = 'FullAccess'
                MailboxType        = 'SharedMailbox'
            }

            # Act
            $result = New-DelegationRecord @params

            # Assert
            $result.MailboxType | Should -Be 'SharedMailbox'
        }

        It 'Enregistre MailboxType = RoomMailbox' {
            # Arrange
            $params = @{
                MailboxEmail       = 'room@contoso.com'
                MailboxDisplayName = 'Room 101'
                TrusteeEmail       = 'trustee@contoso.com'
                TrusteeDisplayName = 'Trustee'
                DelegationType     = 'FullAccess'
                AccessRights       = 'FullAccess'
                MailboxType        = 'RoomMailbox'
            }

            # Act
            $result = New-DelegationRecord @params

            # Assert
            $result.MailboxType | Should -Be 'RoomMailbox'
        }
    }

    Context 'Types de delegations' {

        It 'Cree enregistrement pour FullAccess' {
            # Arrange
            $params = @{
                MailboxEmail       = 'user@contoso.com'
                MailboxDisplayName = 'User'
                TrusteeEmail       = 'trustee@contoso.com'
                TrusteeDisplayName = 'Trustee'
                DelegationType     = 'FullAccess'
                AccessRights       = 'FullAccess'
            }

            # Act
            $result = New-DelegationRecord @params

            # Assert
            $result.DelegationType | Should -Be 'FullAccess'
            $result.AccessRights | Should -Be 'FullAccess'
        }

        It 'Cree enregistrement pour SendAs' {
            # Arrange
            $params = @{
                MailboxEmail       = 'user@contoso.com'
                MailboxDisplayName = 'User'
                TrusteeEmail       = 'trustee@contoso.com'
                TrusteeDisplayName = 'Trustee'
                DelegationType     = 'SendAs'
                AccessRights       = 'SendAs'
            }

            # Act
            $result = New-DelegationRecord @params

            # Assert
            $result.DelegationType | Should -Be 'SendAs'
            $result.AccessRights | Should -Be 'SendAs'
        }

        It 'Cree enregistrement pour SendOnBehalf' {
            # Arrange
            $params = @{
                MailboxEmail       = 'user@contoso.com'
                MailboxDisplayName = 'User'
                TrusteeEmail       = 'trustee@contoso.com'
                TrusteeDisplayName = 'Trustee'
                DelegationType     = 'SendOnBehalf'
                AccessRights       = 'SendOnBehalf'
            }

            # Act
            $result = New-DelegationRecord @params

            # Assert
            $result.DelegationType | Should -Be 'SendOnBehalf'
            $result.AccessRights | Should -Be 'SendOnBehalf'
        }

        It 'Cree enregistrement pour Calendar avec droits multiples' {
            # Arrange
            $params = @{
                MailboxEmail       = 'user@contoso.com'
                MailboxDisplayName = 'User'
                TrusteeEmail       = 'trustee@contoso.com'
                TrusteeDisplayName = 'Trustee'
                DelegationType     = 'Calendar'
                AccessRights       = 'Editor, Reviewer'
                FolderPath         = 'Calendar'
            }

            # Act
            $result = New-DelegationRecord @params

            # Assert
            $result.DelegationType | Should -Be 'Calendar'
            $result.AccessRights | Should -Be 'Editor, Reviewer'
        }

        It 'Cree enregistrement pour Forwarding (ForwardingSmtpAddress)' {
            # Arrange
            $params = @{
                MailboxEmail       = 'user@contoso.com'
                MailboxDisplayName = 'User'
                TrusteeEmail       = 'external@fabrikam.com'
                TrusteeDisplayName = 'external@fabrikam.com'
                DelegationType     = 'Forwarding'
                AccessRights       = 'ForwardingSmtpAddress'
            }

            # Act
            $result = New-DelegationRecord @params

            # Assert
            $result.DelegationType | Should -Be 'Forwarding'
            $result.AccessRights | Should -Be 'ForwardingSmtpAddress'
        }

        It 'Cree enregistrement pour Forwarding (ForwardingAddress)' {
            # Arrange
            $params = @{
                MailboxEmail       = 'user@contoso.com'
                MailboxDisplayName = 'User'
                TrusteeEmail       = 'internal@contoso.com'
                TrusteeDisplayName = 'Internal User'
                DelegationType     = 'Forwarding'
                AccessRights       = 'ForwardingAddress'
            }

            # Act
            $result = New-DelegationRecord @params

            # Assert
            $result.DelegationType | Should -Be 'Forwarding'
            $result.AccessRights | Should -Be 'ForwardingAddress'
        }
    }

    Context 'Timestamp - CollectedAt' {

        It 'Inclut un timestamp CollectedAt' {
            # Arrange
            $params = @{
                MailboxEmail       = 'user@contoso.com'
                MailboxDisplayName = 'User'
                TrusteeEmail       = 'trustee@contoso.com'
                TrusteeDisplayName = 'Trustee'
                DelegationType     = 'FullAccess'
                AccessRights       = 'FullAccess'
            }

            # Act
            $result = New-DelegationRecord @params

            # Assert
            $result.CollectedAt | Should -Not -BeNullOrEmpty
        }

        It 'CollectedAt est au format attendu (DateTime ou string)' {
            # Arrange
            $params = @{
                MailboxEmail       = 'user@contoso.com'
                MailboxDisplayName = 'User'
                TrusteeEmail       = 'trustee@contoso.com'
                TrusteeDisplayName = 'Trustee'
                DelegationType     = 'SendAs'
                AccessRights       = 'SendAs'
            }

            # Act
            $result = New-DelegationRecord @params

            # Assert
            # Peut etre datetime ou string selon implementation
            { [DateTime]::Parse($result.CollectedAt) } | Should -Not -Throw
        }
    }

    Context 'Donnees anonymisees - Standards contoso.com' {

        It 'Accepte domaine contoso.com' {
            # Arrange
            $params = @{
                MailboxEmail       = 'test@contoso.com'
                MailboxDisplayName = 'Test User'
                TrusteeEmail       = 'trustee@contoso.com'
                TrusteeDisplayName = 'Trustee User'
                DelegationType     = 'FullAccess'
                AccessRights       = 'FullAccess'
            }

            # Act
            $result = New-DelegationRecord @params

            # Assert
            $result.MailboxEmail | Should -BeLike '*@contoso.com'
            $result.TrusteeEmail | Should -BeLike '*@contoso.com'
        }

        It 'Accepte domaine fabrikam.com' {
            # Arrange
            $params = @{
                MailboxEmail       = 'test@fabrikam.com'
                MailboxDisplayName = 'Test User'
                TrusteeEmail       = 'trustee@fabrikam.com'
                TrusteeDisplayName = 'Trustee User'
                DelegationType     = 'SendAs'
                AccessRights       = 'SendAs'
            }

            # Act
            $result = New-DelegationRecord @params

            # Assert
            $result.MailboxEmail | Should -BeLike '*@fabrikam.com'
            $result.TrusteeEmail | Should -BeLike '*@fabrikam.com'
        }
    }
}
