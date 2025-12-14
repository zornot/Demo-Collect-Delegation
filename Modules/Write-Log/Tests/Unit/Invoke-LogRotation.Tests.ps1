#Requires -Modules Pester
<#
.SYNOPSIS
    Tests unitaires pour Invoke-LogRotation
.DESCRIPTION
    TDD - Ces tests sont ecrits AVANT l'implementation.
    Basés sur les criteres d'acceptation de FEAT-002.
#>

BeforeAll {
    # Charger le module
    $modulePath = Join-Path $PSScriptRoot "..\..\Modules\Write-Log\Write-Log.psd1"
    Import-Module $modulePath -Force
}

Describe "Invoke-LogRotation" {
    BeforeAll {
        # Creer un dossier temporaire pour les tests
        $script:testDir = Join-Path $env:TEMP "LogRotationTests_$(Get-Random)"
        New-Item -Path $script:testDir -ItemType Directory -Force | Out-Null
    }

    AfterAll {
        # Nettoyer le dossier temporaire
        if (Test-Path $script:testDir) {
            Remove-Item -Path $script:testDir -Recurse -Force
        }
    }

    BeforeEach {
        # Nettoyer le contenu du dossier avant chaque test
        Get-ChildItem -Path $script:testDir -File | Remove-Item -Force
    }

    Context "Suppression des fichiers anciens" {
        It "Supprime les fichiers plus anciens que RetentionDays" {
            # Arrange - Creer un fichier ancien (40 jours)
            $oldFile = Join-Path $script:testDir "old.log"
            New-Item -Path $oldFile -ItemType File -Force | Out-Null
            (Get-Item $oldFile).LastWriteTime = (Get-Date).AddDays(-40)

            # Act
            Invoke-LogRotation -Path $script:testDir -RetentionDays 30

            # Assert
            Test-Path $oldFile | Should -Be $false
        }

        It "Conserve les fichiers plus recents que RetentionDays" {
            # Arrange - Creer un fichier recent (10 jours)
            $recentFile = Join-Path $script:testDir "recent.log"
            New-Item -Path $recentFile -ItemType File -Force | Out-Null
            (Get-Item $recentFile).LastWriteTime = (Get-Date).AddDays(-10)

            # Act
            Invoke-LogRotation -Path $script:testDir -RetentionDays 30

            # Assert
            Test-Path $recentFile | Should -Be $true
        }

        It "Supprime uniquement les fichiers correspondant au filtre" {
            # Arrange
            $logFile = Join-Path $script:testDir "test.log"
            $txtFile = Join-Path $script:testDir "test.txt"
            New-Item -Path $logFile -ItemType File -Force | Out-Null
            New-Item -Path $txtFile -ItemType File -Force | Out-Null
            (Get-Item $logFile).LastWriteTime = (Get-Date).AddDays(-40)
            (Get-Item $txtFile).LastWriteTime = (Get-Date).AddDays(-40)

            # Act
            Invoke-LogRotation -Path $script:testDir -RetentionDays 30 -Filter "*.log"

            # Assert
            Test-Path $logFile | Should -Be $false
            Test-Path $txtFile | Should -Be $true
        }
    }

    Context "Mode WhatIf" {
        It "N'effectue pas de suppression avec -WhatIf" {
            # Arrange
            $oldFile = Join-Path $script:testDir "whatif.log"
            New-Item -Path $oldFile -ItemType File -Force | Out-Null
            (Get-Item $oldFile).LastWriteTime = (Get-Date).AddDays(-40)

            # Act
            Invoke-LogRotation -Path $script:testDir -RetentionDays 30 -WhatIf

            # Assert - Le fichier doit toujours exister
            Test-Path $oldFile | Should -Be $true
        }
    }

    Context "Gestion des erreurs" {
        It "Ne genere pas d'erreur sur un dossier vide" {
            # Act & Assert - Ne doit pas lever d'exception
            { Invoke-LogRotation -Path $script:testDir -RetentionDays 30 } | Should -Not -Throw
        }

        It "Valide que le chemin existe" {
            # Arrange
            $fakePath = Join-Path $env:TEMP "NonExistentFolder_$(Get-Random)"

            # Act & Assert
            { Invoke-LogRotation -Path $fakePath -RetentionDays 30 } | Should -Throw
        }
    }

    Context "Validation des parametres" {
        It "RetentionDays doit etre entre 1 et 365" {
            { Invoke-LogRotation -Path $script:testDir -RetentionDays 0 } | Should -Throw
            { Invoke-LogRotation -Path $script:testDir -RetentionDays 366 } | Should -Throw
        }

        It "Path est obligatoire" {
            { Invoke-LogRotation -RetentionDays 30 } | Should -Throw
        }
    }

    Context "Valeur par defaut" {
        It "RetentionDays par defaut est 30" {
            # Arrange - Creer un fichier de 25 jours (doit etre conserve avec defaut 30)
            $file25days = Join-Path $script:testDir "25days.log"
            New-Item -Path $file25days -ItemType File -Force | Out-Null
            (Get-Item $file25days).LastWriteTime = (Get-Date).AddDays(-25)

            # Creer un fichier de 35 jours (doit etre supprime avec defaut 30)
            $file35days = Join-Path $script:testDir "35days.log"
            New-Item -Path $file35days -ItemType File -Force | Out-Null
            (Get-Item $file35days).LastWriteTime = (Get-Date).AddDays(-35)

            # Act - Appel sans specifier RetentionDays
            Invoke-LogRotation -Path $script:testDir

            # Assert
            Test-Path $file25days | Should -Be $true
            Test-Path $file35days | Should -Be $false
        }

        It "Filter par defaut est *.log" {
            # Arrange
            $logFile = Join-Path $script:testDir "default.log"
            $txtFile = Join-Path $script:testDir "default.txt"
            New-Item -Path $logFile -ItemType File -Force | Out-Null
            New-Item -Path $txtFile -ItemType File -Force | Out-Null
            (Get-Item $logFile).LastWriteTime = (Get-Date).AddDays(-40)
            (Get-Item $txtFile).LastWriteTime = (Get-Date).AddDays(-40)

            # Act - Appel sans specifier Filter
            Invoke-LogRotation -Path $script:testDir -RetentionDays 30

            # Assert - Seul .log doit etre supprime
            Test-Path $logFile | Should -Be $false
            Test-Path $txtFile | Should -Be $true
        }
    }
}
