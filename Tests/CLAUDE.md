# Tests Pester

## Context
Ce dossier contient les tests Pester du projet.
Structure : Unit/ pour tests unitaires, Integration/ pour tests d'integration.

## Structure
```
Tests/
├── Unit/           # Tests unitaires (1 fonction = 1 fichier)
│   └── NomFonction.Tests.ps1
├── Integration/    # Tests d'integration
├── Fixtures/       # Donnees de test (mocks JSON)
└── Coverage/       # Rapports couverture (gitignore)
```

## Conventions TDD

Ce projet suit le Test-Driven Development :
1. **RED** : Ecrire tests AVANT le code (doivent echouer)
2. **GREEN** : Implementer le minimum pour passer
3. **REFACTOR** : Ameliorer sans casser les tests

## Conventions Nommage Tests

| Element | Convention | Exemple |
|---------|------------|---------|
| Fichier | `NomFonction.Tests.ps1` | `Get-User.Tests.ps1` |
| Describe | `"NomFonction"` | `Describe "Get-User"` |
| Context | `"Scenario"` | `Context "Quand utilisateur existe"` |
| It | `"Comportement attendu"` | `It "Retourne l'objet user"` |

## Donnees de Test

TOUJOURS utiliser des donnees anonymes :
- Domaine : `contoso.com`, `fabrikam.com`
- Email : `jean.dupont@contoso.com`
- GUID : `00000000-0000-0000-0000-000000000001`

JAMAIS de donnees de production dans les tests.

## References
- Pester : @.claude/skills/powershell-development/pester.md
- TDD : @.claude/skills/development-workflow/tdd.md
- Anonymisation : @.claude/skills/development-workflow/testing-data.md

## Quick Commands
```powershell
# Executer tous les tests
Invoke-Pester -Path ./Tests -Output Detailed

# Tests unitaires uniquement
Invoke-Pester -Path ./Tests/Unit -Output Detailed

# Avec couverture
$config = New-PesterConfiguration
$config.Run.Path = './Tests'
$config.CodeCoverage.Enabled = $true
Invoke-Pester -Configuration $config
```
