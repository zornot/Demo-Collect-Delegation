#Requires -Modules Pester

<#
.SYNOPSIS
    Tests unitaires pour le module ConsoleUI
.DESCRIPTION
    Tests Pester v5 pour toutes les fonctions publiques du module.
    Ecrit en TDD (phase RED) - tests avant implementation.
.NOTES
    Version: 1.0.0
    Date: 2025-12-08
#>

BeforeAll {
    # Import du module
    $modulePath = Join-Path $PSScriptRoot '..' '..' 'Modules' 'ConsoleUI' 'ConsoleUI.psm1'
    Import-Module $modulePath -Force

    # Helper pour capturer Write-Host
    function Get-WriteHostOutput {
        param([scriptblock]$ScriptBlock)

        $output = [System.Collections.Generic.List[hashtable]]::new()

        Mock Write-Host {
            $output.Add(@{
                Object = $Object
                ForegroundColor = $ForegroundColor
                NoNewline = $NoNewline.IsPresent
            })
        } -ModuleName ConsoleUI

        & $ScriptBlock

        return $output
    }
}

#region Write-ConsoleBanner Tests
Describe 'Write-ConsoleBanner' -Tag 'Unit' {

    Context 'Validation des parametres' {

        It 'Title est obligatoire' {
            { Write-ConsoleBanner -Title $null } | Should -Throw
        }

        It 'Title ne peut pas etre vide' {
            { Write-ConsoleBanner -Title '' } | Should -Throw
        }

        It 'Accepte Title seul' {
            { Write-ConsoleBanner -Title 'TEST' } | Should -Not -Throw
        }

        It 'Accepte Title et Version' {
            { Write-ConsoleBanner -Title 'TEST' -Version '1.0.0' } | Should -Not -Throw
        }

        It 'Accepte Width personnalise' {
            { Write-ConsoleBanner -Title 'TEST' -Width 80 } | Should -Not -Throw
        }
    }

    Context 'Affichage' {

        BeforeEach {
            Mock Write-Host {} -ModuleName ConsoleUI
        }

        It 'Appelle Write-Host plusieurs fois' {
            Write-ConsoleBanner -Title 'TEST'
            Should -Invoke Write-Host -ModuleName ConsoleUI -Scope It
        }

        It 'Affiche le titre en Cyan' {
            Write-ConsoleBanner -Title 'MON TITRE'
            Should -Invoke Write-Host -ModuleName ConsoleUI -ParameterFilter {
                $Object -eq 'MON TITRE' -and $ForegroundColor -eq 'Cyan'
            }
        }

        It 'Affiche la version en DarkGray si fournie' {
            Write-ConsoleBanner -Title 'TEST' -Version '2.0.0'
            Should -Invoke Write-Host -ModuleName ConsoleUI -ParameterFilter {
                $Object -eq 'v2.0.0' -and $ForegroundColor -eq 'DarkGray'
            }
        }

        It 'Affiche les bordures en DarkGray' {
            Write-ConsoleBanner -Title 'TEST'
            Should -Invoke Write-Host -ModuleName ConsoleUI -ParameterFilter {
                $ForegroundColor -eq 'DarkGray'
            } -Scope It
        }
    }

    Context 'Ajustement automatique largeur' {

        BeforeEach {
            Mock Write-Host {} -ModuleName ConsoleUI
        }

        It 'Ajuste la largeur pour un titre long' {
            # Titre de 70 caracteres > Width par defaut (65)
            $longTitle = 'A' * 70
            { Write-ConsoleBanner -Title $longTitle } | Should -Not -Throw
        }
    }
}
#endregion

#region Write-SummaryBox Tests
Describe 'Write-SummaryBox' -Tag 'Unit' {

    Context 'Validation des parametres' {

        It 'Accepte tous les parametres optionnels' {
            { Write-SummaryBox } | Should -Not -Throw
        }

        It 'Accepte Total seul' {
            { Write-SummaryBox -Total 10 } | Should -Not -Throw
        }

        It 'Accepte combinaison Total/Success/Errors' {
            { Write-SummaryBox -Total 10 -Success 8 -Errors 2 } | Should -Not -Throw
        }

        It 'Accepte Duration' {
            { Write-SummaryBox -Total 10 -Duration '00:05:30' } | Should -Not -Throw
        }
    }

    Context 'Affichage conditionnel' {

        BeforeEach {
            Mock Write-Host {} -ModuleName ConsoleUI
        }

        It 'Affiche toujours Total' {
            Write-SummaryBox -Total 42
            Should -Invoke Write-Host -ModuleName ConsoleUI -ParameterFilter {
                $Object -match '42'
            }
        }

        It 'N affiche pas Success si 0' {
            Write-SummaryBox -Total 10 -Success 0
            Should -Invoke Write-Host -ModuleName ConsoleUI -ParameterFilter {
                $Object -eq '[+]' -and $ForegroundColor -eq 'Green'
            } -Times 0
        }

        It 'Affiche Success si > 0' {
            Write-SummaryBox -Total 10 -Success 5
            Should -Invoke Write-Host -ModuleName ConsoleUI -ParameterFilter {
                $Object -eq '[+]' -and $ForegroundColor -eq 'Green'
            }
        }

        It 'N affiche pas Errors si 0' {
            Write-SummaryBox -Total 10 -Errors 0
            Should -Invoke Write-Host -ModuleName ConsoleUI -ParameterFilter {
                $Object -eq '[-]' -and $ForegroundColor -eq 'Red'
            } -Times 0
        }

        It 'Affiche Errors si > 0' {
            Write-SummaryBox -Total 10 -Errors 3
            Should -Invoke Write-Host -ModuleName ConsoleUI -ParameterFilter {
                $Object -eq '[-]' -and $ForegroundColor -eq 'Red'
            }
        }
    }

    Context 'Couleurs semantiques' {

        BeforeEach {
            Mock Write-Host {} -ModuleName ConsoleUI
        }

        It 'Total en Cyan' {
            Write-SummaryBox -Total 10
            Should -Invoke Write-Host -ModuleName ConsoleUI -ParameterFilter {
                $Object -eq '[i]' -and $ForegroundColor -eq 'Cyan'
            }
        }

        It 'Success en Green' {
            Write-SummaryBox -Success 5
            Should -Invoke Write-Host -ModuleName ConsoleUI -ParameterFilter {
                $Object -eq '[+]' -and $ForegroundColor -eq 'Green'
            }
        }

        It 'Errors en Red' {
            Write-SummaryBox -Errors 2
            Should -Invoke Write-Host -ModuleName ConsoleUI -ParameterFilter {
                $Object -eq '[-]' -and $ForegroundColor -eq 'Red'
            }
        }

        It 'Duration en White' {
            Write-SummaryBox -Duration '01:00'
            Should -Invoke Write-Host -ModuleName ConsoleUI -ParameterFilter {
                $Object -eq '[>]' -and $ForegroundColor -eq 'White'
            }
        }
    }
}
#endregion

#region Write-MenuBox Tests
Describe 'Write-MenuBox' -Tag 'Unit' {

    Context 'Validation des parametres' {

        It 'Title est obligatoire' {
            { Write-MenuBox -Title $null -Options @(@{Key='A'; Text='Option'}) } | Should -Throw
        }

        It 'Title ne peut pas etre vide' {
            { Write-MenuBox -Title '' -Options @(@{Key='A'; Text='Option'}) } | Should -Throw
        }

        It 'Options est obligatoire' {
            { Write-MenuBox -Title 'Menu' -Options $null } | Should -Throw
        }

        It 'Options doit etre un tableau de hashtables avec Key et Text' {
            { Write-MenuBox -Title 'Menu' -Options @('invalid') } | Should -Throw
        }

        It 'Rejette hashtable sans Key' {
            { Write-MenuBox -Title 'Menu' -Options @(@{Text='Option'}) } | Should -Throw
        }

        It 'Rejette hashtable sans Text' {
            { Write-MenuBox -Title 'Menu' -Options @(@{Key='A'}) } | Should -Throw
        }

        It 'Accepte format valide' {
            { Write-MenuBox -Title 'Menu' -Options @(@{Key='A'; Text='Option A'}) } | Should -Not -Throw
        }

        It 'Accepte plusieurs options' {
            $options = @(
                @{Key='A'; Text='Option A'}
                @{Key='B'; Text='Option B'}
                @{Key='Q'; Text='Quitter'}
            )
            { Write-MenuBox -Title 'Menu' -Options $options } | Should -Not -Throw
        }

        It 'Accepte Subtitle optionnel' {
            { Write-MenuBox -Title 'Menu' -Subtitle 'Description' -Options @(@{Key='A'; Text='Option'}) } | Should -Not -Throw
        }
    }

    Context 'Affichage' {

        BeforeEach {
            Mock Write-Host {} -ModuleName ConsoleUI
        }

        It 'Affiche le titre' {
            Write-MenuBox -Title 'MON MENU' -Options @(@{Key='A'; Text='Option'})
            Should -Invoke Write-Host -ModuleName ConsoleUI -ParameterFilter {
                $Object -eq 'MON MENU'
            }
        }

        It 'Affiche les options formatees [X]' {
            Write-MenuBox -Title 'Menu' -Options @(@{Key='Z'; Text='Test'})
            Should -Invoke Write-Host -ModuleName ConsoleUI -ParameterFilter {
                $Object -match '\[Z\].*Test'
            }
        }
    }
}
#endregion

#region Write-Box Tests
Describe 'Write-Box' -Tag 'Unit' {

    Context 'Validation des parametres' {

        It 'Accepte sans parametres' {
            { Write-Box } | Should -Not -Throw
        }

        It 'Accepte Title seul' {
            { Write-Box -Title 'Info' } | Should -Not -Throw
        }

        It 'Accepte Content hashtable' {
            { Write-Box -Content @{Nom='Test'; Version='1.0'} } | Should -Not -Throw
        }

        It 'Accepte Content tableau de strings' {
            { Write-Box -Content @('Ligne 1', 'Ligne 2') } | Should -Not -Throw
        }

        It 'Accepte Content OrderedDictionary' {
            $ordered = [ordered]@{Premier='A'; Deuxieme='B'}
            { Write-Box -Content $ordered } | Should -Not -Throw
        }
    }

    Context 'Affichage' {

        BeforeEach {
            Mock Write-Host {} -ModuleName ConsoleUI
        }

        It 'Affiche le titre si fourni' {
            Write-Box -Title 'INFO'
            Should -Invoke Write-Host -ModuleName ConsoleUI -ParameterFilter {
                $Object -eq 'INFO'
            }
        }

        It 'Affiche les cles du hashtable' {
            Write-Box -Content @{TestKey='TestValue'}
            Should -Invoke Write-Host -ModuleName ConsoleUI -ParameterFilter {
                $Object -match 'TestKey'
            }
        }
    }
}
#endregion

#region Write-SelectionBox Tests
Describe 'Write-SelectionBox' -Tag 'Unit' {

    Context 'Validation des parametres' {

        It 'Count accepte 0 (pas de validation Mandatory)' {
            # [int] avec $null devient 0, ce n'est pas Mandatory
            { Write-SelectionBox -Count 0 } | Should -Not -Throw
        }

        It 'Accepte Count seul' {
            { Write-SelectionBox -Count 42 } | Should -Not -Throw
        }

        It 'Accepte MicrosoftCount' {
            { Write-SelectionBox -Count 42 -MicrosoftCount 10 } | Should -Not -Throw
        }

        It 'Accepte Width personnalise' {
            { Write-SelectionBox -Count 42 -Width 80 } | Should -Not -Throw
        }
    }

    Context 'Affichage' {

        BeforeEach {
            Mock Write-Host {} -ModuleName ConsoleUI
        }

        It 'Affiche le nombre d applications' {
            Write-SelectionBox -Count 42
            Should -Invoke Write-Host -ModuleName ConsoleUI -ParameterFilter {
                $Object -match '42.*application'
            }
        }

        It 'Affiche les options de menu' {
            Write-SelectionBox -Count 10
            Should -Invoke Write-Host -ModuleName ConsoleUI -ParameterFilter {
                $Object -match '\[A\]|\[M\]|\[S\]|\[F\]|\[Q\]'
            }
        }
    }
}
#endregion

#region Write-EnterpriseAppsSelectionBox Tests
Describe 'Write-EnterpriseAppsSelectionBox' -Tag 'Unit' {

    Context 'Validation des parametres' {

        It 'TotalCount accepte 0 (pas de validation Mandatory)' {
            # [int] avec $null devient 0, ce n'est pas Mandatory
            { Write-EnterpriseAppsSelectionBox -TotalCount 0 } | Should -Not -Throw
        }

        It 'Accepte TotalCount seul' {
            { Write-EnterpriseAppsSelectionBox -TotalCount 100 } | Should -Not -Throw
        }

        It 'Accepte tous les compteurs' {
            { Write-EnterpriseAppsSelectionBox -TotalCount 100 -MicrosoftCount 50 -ThirdPartyCount 40 -CustomCount 10 } | Should -Not -Throw
        }
    }

    Context 'Affichage' {

        BeforeEach {
            Mock Write-Host {} -ModuleName ConsoleUI
        }

        It 'Affiche le titre Enterprise Applications' {
            Write-EnterpriseAppsSelectionBox -TotalCount 100
            Should -Invoke Write-Host -ModuleName ConsoleUI -ParameterFilter {
                $Object -eq 'ENTERPRISE APPLICATIONS'
            }
        }

        It 'Affiche les statistiques' {
            Write-EnterpriseAppsSelectionBox -TotalCount 100 -MicrosoftCount 50
            Should -Invoke Write-Host -ModuleName ConsoleUI -ParameterFilter {
                $Object -match '50.*Microsoft'
            }
        }
    }
}
#endregion

#region Write-UnifiedSelectionBox Tests
Describe 'Write-UnifiedSelectionBox' -Tag 'Unit' {

    Context 'Validation des parametres' {

        It 'AppRegistrationCount accepte 0' {
            # [int] avec $null devient 0, pas Mandatory
            { Write-UnifiedSelectionBox -AppRegistrationCount 0 -EnterpriseAppCount 100 } | Should -Not -Throw
        }

        It 'EnterpriseAppCount accepte 0' {
            # [int] avec $null devient 0, pas Mandatory
            { Write-UnifiedSelectionBox -AppRegistrationCount 50 -EnterpriseAppCount 0 } | Should -Not -Throw
        }

        It 'Accepte les deux compteurs obligatoires' {
            { Write-UnifiedSelectionBox -AppRegistrationCount 50 -EnterpriseAppCount 100 } | Should -Not -Throw
        }
    }

    Context 'Affichage' {

        BeforeEach {
            Mock Write-Host {} -ModuleName ConsoleUI
        }

        It 'Affiche le titre Selection Unifiee' {
            Write-UnifiedSelectionBox -AppRegistrationCount 50 -EnterpriseAppCount 100
            Should -Invoke Write-Host -ModuleName ConsoleUI -ParameterFilter {
                $Object -eq 'SELECTION UNIFIEE'
            }
        }
    }
}
#endregion

#region Write-CollectionModeBox Tests
Describe 'Write-CollectionModeBox' -Tag 'Unit' {

    Context 'Validation des parametres' {

        It 'Accepte sans parametres' {
            { Write-CollectionModeBox } | Should -Not -Throw
        }

        It 'Accepte Width personnalise' {
            { Write-CollectionModeBox -Width 80 } | Should -Not -Throw
        }
    }

    Context 'Affichage' {

        BeforeEach {
            Mock Write-Host {} -ModuleName ConsoleUI
        }

        It 'Affiche le titre Mode de Collecte' {
            Write-CollectionModeBox
            Should -Invoke Write-Host -ModuleName ConsoleUI -ParameterFilter {
                $Object -eq 'MODE DE COLLECTE'
            }
        }

        It 'Affiche les options R, E, T, Q' {
            Write-CollectionModeBox
            Should -Invoke Write-Host -ModuleName ConsoleUI -ParameterFilter {
                $Object -match '\[R\]|\[E\]|\[T\]|\[Q\]'
            }
        }
    }
}
#endregion

#region Write-CategorySelectionMenu Tests
Describe 'Write-CategorySelectionMenu' -Tag 'Unit' {

    Context 'Validation des parametres' {

        It 'CategoryCounts est obligatoire' {
            { Write-CategorySelectionMenu -CategoryCounts $null } | Should -Throw
        }

        It 'Accepte CategoryCounts valide' {
            $counts = @{
                Custom = @{ AppReg = 10; EnterpriseApps = 20 }
                ThirdParty = @{ AppReg = 5; EnterpriseApps = 15 }
            }
            { Write-CategorySelectionMenu -CategoryCounts $counts } | Should -Not -Throw
        }

        It 'Accepte SelectedCategories personnalise' {
            $counts = @{ Custom = @{ AppReg = 10; EnterpriseApps = 20 } }
            { Write-CategorySelectionMenu -CategoryCounts $counts -SelectedCategories @('Custom') } | Should -Not -Throw
        }
    }

    Context 'Affichage' {

        BeforeEach {
            Mock Write-Host {} -ModuleName ConsoleUI
        }

        It 'Affiche le titre Perimetre Export' {
            $counts = @{ Custom = @{ AppReg = 10; EnterpriseApps = 20 } }
            Write-CategorySelectionMenu -CategoryCounts $counts
            Should -Invoke Write-Host -ModuleName ConsoleUI -ParameterFilter {
                $Object -match "PERIMETRE.*EXPORT"
            }
        }
    }
}
#endregion

#region Update-CategorySelection Tests
Describe 'Update-CategorySelection' -Tag 'Unit' {

    Context 'Validation des parametres' {

        It 'CurrentSelection est obligatoire' {
            { Update-CategorySelection -CurrentSelection $null } | Should -Throw
        }

        It 'Accepte CurrentSelection vide' {
            { Update-CategorySelection -CurrentSelection @() } | Should -Not -Throw
        }
    }

    Context 'Toggle comportement' {

        It 'Ajoute une categorie absente' {
            $result = Update-CategorySelection -CurrentSelection @('Custom') -Toggle 'ThirdParty'
            $result | Should -Contain 'Custom'
            $result | Should -Contain 'ThirdParty'
        }

        It 'Retire une categorie presente' {
            $result = Update-CategorySelection -CurrentSelection @('Custom', 'ThirdParty') -Toggle 'ThirdParty'
            $result | Should -Contain 'Custom'
            $result | Should -Not -Contain 'ThirdParty'
        }

        It 'Retourne la meme selection si pas de toggle' {
            $result = Update-CategorySelection -CurrentSelection @('Custom', 'ThirdParty')
            $result | Should -Contain 'Custom'
            $result | Should -Contain 'ThirdParty'
            $result.Count | Should -Be 2
        }
    }

    Context 'SelectAll comportement' {

        It 'Selectionne toutes les categories par defaut' {
            $result = Update-CategorySelection -CurrentSelection @() -SelectAll
            $result | Should -Contain 'Custom'
            $result | Should -Contain 'ThirdParty'
            $result | Should -Contain 'Microsoft'
            $result | Should -Contain 'ManagedIdentity'
            $result | Should -Contain 'StorageAccount'
        }

        It 'Selectionne categories personnalisees si AllCategories fourni' {
            $result = Update-CategorySelection -CurrentSelection @() -SelectAll -AllCategories @('A', 'B')
            $result | Should -Contain 'A'
            $result | Should -Contain 'B'
            $result.Count | Should -Be 2
        }
    }

    Context 'SelectNone comportement' {

        It 'Retourne un tableau vide' {
            $result = Update-CategorySelection -CurrentSelection @('Custom', 'ThirdParty') -SelectNone
            $result.Count | Should -Be 0
        }

        It 'SelectNone a priorite sur SelectAll' {
            $result = Update-CategorySelection -CurrentSelection @('Custom') -SelectAll -SelectNone
            $result.Count | Should -Be 0
        }
    }

    Context 'Retour type' {

        It 'Retourne array avec elements' {
            $result = Update-CategorySelection -CurrentSelection @('Custom', 'ThirdParty') -Toggle 'Microsoft'
            $result | Should -BeOfType [string]
            $result.Count | Should -Be 3
        }

        It 'SelectNone retourne collection vide' {
            # Note: PowerShell unwrap @() en $null dans certains contextes
            # Le comportement attendu est une collection vide (Count = 0)
            $result = @(Update-CategorySelection -CurrentSelection @('Custom') -SelectNone)
            $result.Count | Should -Be 0
        }

        It 'Toggle dernier element retourne collection vide' {
            # Quand on retire le dernier element, on attend une collection vide
            $result = @(Update-CategorySelection -CurrentSelection @('Custom') -Toggle 'Custom')
            $result.Count | Should -Be 0
        }
    }
}
#endregion

#region OutputType Tests
Describe 'OutputType declarations' -Tag 'Unit', 'Metadata' {

    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot '..' '..' 'Modules' 'ConsoleUI' 'ConsoleUI.psm1'
        $moduleContent = Get-Content $modulePath -Raw
    }

    It 'Write-ConsoleBanner a OutputType void' {
        $moduleContent | Should -Match 'function Write-ConsoleBanner[\s\S]*?\[OutputType\(\[void\]\)\]'
    }

    It 'Write-SummaryBox a OutputType void' {
        $moduleContent | Should -Match 'function Write-SummaryBox[\s\S]*?\[OutputType\(\[void\]\)\]'
    }

    It 'Write-MenuBox a OutputType void' {
        $moduleContent | Should -Match 'function Write-MenuBox[\s\S]*?\[OutputType\(\[void\]\)\]'
    }

    It 'Write-Box a OutputType void' {
        $moduleContent | Should -Match 'function Write-Box[\s\S]*?\[OutputType\(\[void\]\)\]'
    }

    It 'Update-CategorySelection a OutputType string[]' {
        $moduleContent | Should -Match 'function Update-CategorySelection[\s\S]*?\[OutputType\(\[string\[\]\]\)\]'
    }
}
#endregion
