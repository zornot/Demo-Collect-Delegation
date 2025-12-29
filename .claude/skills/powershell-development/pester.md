# Tests Unitaires Pester

## Installation
```powershell
Install-Module -Name Pester -Force -SkipPublisherCheck
Import-Module Pester
```

## TDD - Cycle Obligatoire (MUST)

```
1. RED    → Écrire les tests AVANT le code (ils doivent échouer)
2. GREEN  → Implémenter le minimum pour faire passer les tests
3. REFACTOR → Améliorer le code sans casser les tests
```

> **Règle** : Tout nouveau code DOIT suivre le cycle TDD. Tests EN PREMIER, toujours.

## Structure tests
```
Tests/
├── Unit/                    # Tests unitaires (1 fonction = 1 fichier test)
│   └── NomFonction.Tests.ps1
├── Integration/             # Tests d'intégration
│   └── EndToEnd.Tests.ps1
├── Fixtures/                # Données de test (mocks)
│   └── MockData.json
└── TestHelpers/
    └── MockData.ps1
```

## Convention Nommage (MUST)

| Élément | Convention | Exemple |
|---------|------------|---------|
| Fichier | `NomFonction.Tests.ps1` | `Get-UserMailbox.Tests.ps1` |
| Describe | `"NomFonction"` | `Describe "Get-UserMailbox"` |
| Context | `"Scénario ou condition"` | `Context "Quand l'utilisateur existe"` |
| It | `"Comportement attendu"` | `It "Retourne l'objet mailbox"` |

## Template test basique
```powershell
#Requires -Modules Pester

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..' '..' 'Modules' 'MonModule' 'MonModule.psd1'
    Import-Module $modulePath -Force
}

Describe 'Get-Something' {
    
    Context 'Cas nominal' {
        
        It 'Retourne le résultat attendu' {
            # Arrange
            $input = "valeur"
            
            # Act
            $result = Get-Something -Param $input
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Property | Should -Be "expected"
        }
        
        It 'Accepte le pipeline' {
            $results = @('a', 'b') | Get-Something
            $results | Should -HaveCount 2
        }
    }
    
    Context 'Gestion des erreurs' {
        
        It 'Lève une exception pour null' {
            { Get-Something -Param $null } | Should -Throw
        }
        
        It 'Lève une exception avec message spécifique' {
            { Get-Something -Param 'bad' } | 
                Should -Throw -ExpectedMessage '*invalid*'
        }
    }
}
```

## Mocking
```powershell
Describe 'Get-UserReport' {
    
    BeforeAll {
        # Mock données anonymisées (contoso.com)
        Mock Get-ADUser {
            [PSCustomObject]@{ 
                Name = 'Jean Dupont'
                Email = 'jean.dupont@contoso.com' 
            }
        }
        
        # Mock avec filtre paramètres
        Mock Get-ADUser -ParameterFilter { $Identity -eq 'admin' } {
            [PSCustomObject]@{ 
                Name = 'Admin Contoso'
                Email = 'admin@contoso.com' 
            }
        }
    }
    
    It 'Appelle Get-ADUser une fois' {
        $result = Get-UserReport -UserId 'test'
        
        Should -Invoke Get-ADUser -Times 1 -ParameterFilter {
            $Identity -eq 'test'
        }
    }
}
```

## Tests paramétrés (TestCases)
```powershell
Describe 'Test-Email' {
    
    It 'Valide correctement: <Email>' -TestCases @(
        @{ Email = 'valid@contoso.com'; Expected = $true }
        @{ Email = 'invalid@'; Expected = $false }
        @{ Email = ''; Expected = $false }
    ) {
        param($Email, $Expected)
        
        Test-Email -Email $Email | Should -Be $Expected
    }
}
```

## Tags Recommandés (SHOULD)

| Tag | Usage |
|-----|-------|
| `Unit` | Tests unitaires isolés |
| `Integration` | Tests avec dépendances réelles |
| `Slow` | Tests lents (> 5s) |
| `RequiresAdmin` | Nécessite élévation |
| `RequiresNetwork` | Nécessite connexion |
| `BUG-XXX` | Test lié à une issue |

## Code Coverage
```powershell
$config = New-PesterConfiguration
$config.Run.Path = '.\Tests'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = '.\MyModule.psm1'
$config.CodeCoverage.OutputFormat = 'JaCoCo'
$config.CodeCoverage.OutputPath = '.\coverage.xml'

$results = Invoke-Pester -Configuration $config -PassThru
Write-Host "Coverage: $($results.CodeCoverage.CoveragePercent)%"
```

## Test intégration
```powershell
Describe 'Integration' -Tag 'Integration' {
    
    BeforeAll {
        $testPath = Join-Path $TestDrive 'TestData'
        New-Item -Path $testPath -ItemType Directory -Force
    }
    
    It 'Traite le workflow de bout en bout' {
        $result = Invoke-Workflow -Path $testPath
        $result.Success | Should -Be $true
    }
    
    AfterAll {
        Remove-Item -Path $testPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}
```

## PSScriptAnalyzer et Pester

### Faux Positif : PSUseDeclaredVarsMoreThanAssignments

PSScriptAnalyzer ne comprend pas le scope Pester. Les variables declarees dans
`BeforeEach` sont signalees comme "non utilisees" alors qu'elles sont utilisees
dans les blocs `It`.

**Solution standard** - Ajouter en debut de fichier test :
```powershell
#Requires -Modules Pester

# PSScriptAnalyzer ne comprend pas le scope Pester (BeforeEach -> It)
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

BeforeAll { ... }
```

> Reference complete : [psscriptanalyzer.md](psscriptanalyzer.md)

## Exécution
```powershell
Invoke-Pester                              # Tous
Invoke-Pester -Path .\Tests\Unit           # Dossier spécifique
Invoke-Pester -Tag 'Unit'                  # Par tag
Invoke-Pester -ExcludeTag 'Integration'    # Exclure tag

# Avec détails
Invoke-Pester -Path ./Tests -Output Detailed

# CI/CD output
Invoke-Pester -OutputFile Results.xml -OutputFormat NUnitXml
```

## Commit TDD

```
feat(module): add NomFonction (TDD)

Implemented using Test-Driven Development:
- RED: X tests written first (all failed)
- GREEN: Function implemented, all tests pass

Fixes #XX
```
