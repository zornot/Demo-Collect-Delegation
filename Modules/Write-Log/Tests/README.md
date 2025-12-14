# Tests

Ce dossier contient les tests Pester pour le projet.

## Structure

```
Tests/
+-- Unit/           # Tests unitaires isoles
+-- Integration/    # Tests avec dependances
+-- Fixtures/       # Donnees de test (mocks)
+-- Coverage/       # Rapports couverture (gitignore)
```

## Execution

```powershell
# Tous les tests
Invoke-Pester -Path ./Tests

# Tests avec details
Invoke-Pester -Path ./Tests -Output Detailed

# Tests unitaires uniquement
Invoke-Pester -Path ./Tests/Unit

# Avec couverture
Invoke-Pester -Path ./Tests -CodeCoverage ./Modules/**/*.psm1
```

## Conventions

- Fichiers: `{Module}.Tests.ps1`
- Tags: `Unit`, `Integration`, `Slow`
- Donnees: utiliser `contoso.com` / `fabrikam.com` (pas de donnees reelles)
