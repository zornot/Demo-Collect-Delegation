#Requires -Modules Pester
<#
.SYNOPSIS
    Tests unitaires pour Initialize-Log
.DESCRIPTION
    Tests couvrant la creation de dossier, gestion d'erreurs (BUG-001),
    et configuration des variables.
#>

BeforeAll {
    # Charger le module
    $modulePath = Join-Path $PSScriptRoot "..\..\Modules\Write-Log\Write-Log.psd1"
    Import-Module $modulePath -Force
}

AfterAll {
    # Reset des variables globales
    Remove-Variable -Name LogFile -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable -Name ScriptName -Scope Global -ErrorAction SilentlyContinue
}

Describe "Initialize-Log" {
    BeforeAll {
        $script:testDir = Join-Path $env:TEMP "InitializeLogTests_$(Get-Random)"
    }

    AfterAll {
        if (Test-Path $script:testDir) {
            Remove-Item -Path $script:testDir -Recurse -Force
        }
    }

    BeforeEach {
        # Reset des variables et recharger le module
        Remove-Variable -Name LogFile -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name ScriptName -Scope Global -ErrorAction SilentlyContinue
        Import-Module $modulePath -Force

        # Nettoyer le dossier de test
        if (Test-Path $script:testDir) {
            Remove-Item -Path $script:testDir -Recurse -Force
        }
    }

    Context "Creation du dossier de logs" {
        It "Cree le dossier s'il n'existe pas" {
            # Arrange
            $logPath = Join-Path $script:testDir "NewLogs"
            Test-Path $logPath | Should -Be $false

            # Act
            Initialize-Log -Path $logPath -ScriptName "TestScript"

            # Assert
            Test-Path $logPath | Should -Be $true
        }

        It "Ne leve pas d'erreur si le dossier existe deja" {
            # Arrange
            $logPath = Join-Path $script:testDir "ExistingLogs"
            New-Item -Path $logPath -ItemType Directory -Force | Out-Null

            # Act & Assert
            { Initialize-Log -Path $logPath -ScriptName "TestScript" } | Should -Not -Throw
        }
    }

    Context "Gestion des erreurs - BUG-001" {
        It "Leve une exception pour un chemin de lecteur inexistant" {
            # Arrange - Utiliser un lecteur qui n'existe probablement pas
            $invalidPath = "Z:\NonExistentDrive\Logs"

            # Act & Assert
            { Initialize-Log -Path $invalidPath -ScriptName "TestScript" } | Should -Throw
        }

        It "L'exception contient un message explicite avec le chemin" {
            # Arrange
            $invalidPath = "Z:\NonExistentDrive\Logs"
            $escapedPath = [regex]::Escape($invalidPath)

            # Act & Assert
            try {
                Initialize-Log -Path $invalidPath -ScriptName "TestScript"
                $false | Should -Be $true  # Ne devrait pas arriver
            }
            catch {
                $_.Exception.Message | Should -Match "Impossible de creer le dossier de logs"
                $_.Exception.Message | Should -Match $escapedPath
            }
        }

        It "Leve une exception pour un chemin UNC invalide" {
            # Arrange
            $invalidPath = "\\NonExistentServer\Share\Logs"

            # Act & Assert
            { Initialize-Log -Path $invalidPath -ScriptName "TestScript" } | Should -Throw
        }
    }

    Context "Configuration des variables" {
        It "Definit Global:LogFile avec le chemin complet" {
            # Arrange
            $logPath = Join-Path $script:testDir "VarTest"
            New-Item -Path $logPath -ItemType Directory -Force | Out-Null

            # Act
            Initialize-Log -Path $logPath -ScriptName "TestScript"

            # Assert
            $Global:LogFile | Should -Not -BeNullOrEmpty
            $Global:LogFile | Should -Match "TestScript"
            $Global:LogFile | Should -Match "\.log$"
        }

        It "Definit Global:ScriptName avec le nom fourni" {
            # Arrange
            $logPath = Join-Path $script:testDir "VarTest2"
            New-Item -Path $logPath -ItemType Directory -Force | Out-Null

            # Act
            Initialize-Log -Path $logPath -ScriptName "MonScript"

            # Assert
            $Global:ScriptName | Should -Be "MonScript"
        }

        It "Le fichier log contient la date du jour" {
            # Arrange
            $logPath = Join-Path $script:testDir "DateTest"
            New-Item -Path $logPath -ItemType Directory -Force | Out-Null
            $today = Get-Date -Format 'yyyy-MM-dd'

            # Act
            Initialize-Log -Path $logPath -ScriptName "TestScript"

            # Assert
            $Global:LogFile | Should -Match $today
        }
    }

    Context "Detection automatique du ScriptName" {
        It "Detecte automatiquement si ScriptName non fourni" {
            # Arrange
            $logPath = Join-Path $script:testDir "AutoDetect"
            New-Item -Path $logPath -ItemType Directory -Force | Out-Null

            # Act
            Initialize-Log -Path $logPath

            # Assert - Doit avoir un ScriptName (PowerShell ou nom du test)
            $Global:ScriptName | Should -Not -BeNullOrEmpty
        }

        It "Utilise le ScriptName fourni en priorite" {
            # Arrange
            $logPath = Join-Path $script:testDir "Priority"
            New-Item -Path $logPath -ItemType Directory -Force | Out-Null

            # Act
            Initialize-Log -Path $logPath -ScriptName "ExplicitName"

            # Assert
            $Global:ScriptName | Should -Be "ExplicitName"
        }
    }

    Context "Valeurs par defaut" {
        It "Utilise .\Logs comme chemin par defaut" {
            # Act - Appel sans Path (va utiliser .\Logs)
            # Note: Ce test cree un dossier dans le repertoire courant
            $currentDir = Get-Location
            $defaultPath = Join-Path $currentDir "Logs"

            try {
                Initialize-Log -ScriptName "DefaultPathTest"

                # Assert - Verifie que le LogFile contient "Logs" dans le chemin
                $Global:LogFile | Should -Match "Logs"
            }
            finally {
                # Cleanup
                if (Test-Path $defaultPath) {
                    Remove-Item -Path $defaultPath -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    Context "Integration avec Write-Log" {
        It "Write-Log utilise les variables definies par Initialize-Log" {
            # Arrange
            $logPath = Join-Path $script:testDir "Integration"
            New-Item -Path $logPath -ItemType Directory -Force | Out-Null

            # Act
            Initialize-Log -Path $logPath -ScriptName "IntegrationTest"
            Write-Log "Test message" -NoConsole

            # Assert
            $logFiles = Get-ChildItem -Path $logPath -Filter "*.log"
            $logFiles.Count | Should -BeGreaterThan 0

            $content = Get-Content $logFiles[0].FullName -Raw
            $content | Should -Match "IntegrationTest"
            $content | Should -Match "Test message"
        }
    }
}
