---
description: Execute tous les tests Pester et rapporte les resultats
argument-hint: (optionnel) chemin ou tag
allowed-tools: Bash, Read, Glob
---

Executer les tests Pester et rapporter les resultats.

## Utilisation

- `/run-tests` - Executer tous les tests
- `/run-tests Unit` - Executer uniquement les tests unitaires
- `/run-tests Integration` - Executer les tests d'integration

## Execution

```powershell
# Executer tous les tests
Invoke-Pester -Path ./Tests -Output Detailed

# Avec couverture de code
Invoke-Pester -Path ./Tests -CodeCoverage ./Modules/**/*.ps1 -Output Detailed

# Chemin specifique
Invoke-Pester -Path ./Tests/$ARGUMENTS -Output Detailed
```

## Format du Rapport

```
[i] Resultats des Tests
    [+] Passes : X
    [-] Echoues : Y
    [!] Ignores : Z

    Total : X tests en Y secondes
```

## En Cas d'Echec des Tests

1. Lister les tests echoues avec fichier:ligne
2. Afficher les messages d'erreur
3. Suggerer des corrections basees sur `.claude/skills/powershell-development/errors.md`
