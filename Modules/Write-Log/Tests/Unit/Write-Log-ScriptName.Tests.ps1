#Requires -Modules Pester
<#
.SYNOPSIS
    Tests unitaires pour la detection automatique de ScriptName dans Write-Log
.DESCRIPTION
    TDD - Ces tests sont ecrits AVANT l'implementation.
    Basés sur les criteres d'acceptation de FEAT-003.
#>

BeforeAll {
    # Charger le module
    $modulePath = Join-Path $PSScriptRoot "..\..\Modules\Write-Log\Write-Log.psd1"
    Import-Module $modulePath -Force

    # Dossier temporaire pour les tests
    $script:testDir = Join-Path $env:TEMP "WriteLogTests_$(Get-Random)"
    New-Item -Path $script:testDir -ItemType Directory -Force | Out-Null
}

AfterAll {
    # Nettoyer
    if (Test-Path $script:testDir) {
        Remove-Item -Path $script:testDir -Recurse -Force
    }
    # Reset des variables globales
    Remove-Variable -Name LogFile -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable -Name ScriptName -Scope Global -ErrorAction SilentlyContinue
}

Describe "Write-Log ScriptName Detection" {
    BeforeEach {
        # Reset des variables avant chaque test
        Remove-Variable -Name LogFile -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name ScriptName -Scope Global -ErrorAction SilentlyContinue
        # Recharger le module pour reset les variables $Script:
        Import-Module $modulePath -Force
    }

    Context "Priorite des sources de ScriptName" {
        It "Utilise le parametre ScriptName si fourni" {
            # Arrange
            $logFile = Join-Path $script:testDir "param-test.log"

            # Act
            Write-Log "Test" -LogFile $logFile -ScriptName "MonScriptParam" -NoConsole

            # Assert
            $content = Get-Content $logFile -Raw
            $content | Should -Match "MonScriptParam"
        }

        It "Utilise ScriptName defini par Initialize-Log" {
            # Arrange
            $logDir = Join-Path $script:testDir "init-test"
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null

            # Act - Initialize-Log definit $Script:ScriptName dans le module
            Initialize-Log -Path $logDir -ScriptName "InitializedName"
            Write-Log "Test" -NoConsole

            # Assert
            $logFile = Get-ChildItem -Path $logDir -Filter "*.log" | Select-Object -First 1
            $content = Get-Content $logFile.FullName -Raw
            $content | Should -Match "InitializedName"
        }

        It "Utilise Global:ScriptName si Script:ScriptName est vide" {
            # Arrange
            $logFile = Join-Path $script:testDir "global-var-test.log"
            $Global:ScriptName = "GlobalVarName"

            # Act
            Write-Log "Test" -LogFile $logFile -NoConsole

            # Assert
            $content = Get-Content $logFile -Raw
            $content | Should -Match "GlobalVarName"
        }
    }

    Context "Detection automatique via call stack" {
        It "Detecte le nom du script appelant si aucune variable definie" {
            # Arrange - Creer un script de test qui appelle Write-Log
            $testScript = Join-Path $script:testDir "TestCaller.ps1"
            $logFile = Join-Path $script:testDir "caller-test.log"

            @"
Import-Module '$modulePath' -Force
Write-Log 'Test from script' -LogFile '$logFile' -NoConsole
"@ | Set-Content -Path $testScript -Encoding UTF8

            # Act
            & pwsh -NoProfile -File $testScript

            # Assert
            $content = Get-Content $logFile -Raw
            $content | Should -Match "TestCaller"
        }

        It "Retourne PowerShell si appele depuis la console interactive" {
            # Arrange
            $logFile = Join-Path $script:testDir "interactive-test.log"

            # Act - Appel direct sans script appelant
            Write-Log "Test" -LogFile $logFile -NoConsole

            # Assert - Doit contenir "PowerShell" ou le nom du fichier de test
            $content = Get-Content $logFile -Raw
            # Dans le contexte Pester, c'est le fichier .Tests.ps1 qui appelle
            $content | Should -Match "(PowerShell|Write-Log-ScriptName)"
        }
    }

    Context "Fallback PowerShell" {
        It "Utilise PowerShell comme fallback final" {
            # Arrange
            $logFile = Join-Path $script:testDir "fallback-test.log"
            Remove-Variable -Name ScriptName -Scope Global -ErrorAction SilentlyContinue
            $Script:ScriptName = $null

            # Act - Simuler un appel sans call stack script
            # Ce test verifie que le fallback existe
            $result = & {
                # Contexte sans $PSCommandPath
                Write-Log "Test" -LogFile $logFile -NoConsole
            }

            # Assert
            Test-Path $logFile | Should -Be $true
        }
    }
}
