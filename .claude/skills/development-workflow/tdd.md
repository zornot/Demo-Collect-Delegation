# Test-Driven Development (TDD)

## Cycle Obligatoire

```
1. RED    -> Ecrire les tests AVANT le code (ils doivent echouer)
2. GREEN  -> Implementer le minimum pour faire passer les tests
3. REFACTOR -> Ameliorer le code sans casser les tests
```

> **Regle** : Tout nouveau code suit le cycle TDD. Tests EN PREMIER, toujours.

## Pourquoi TDD ?

| Benefice | Explication |
|----------|-------------|
| **Design** | Force a penser a l'API avant l'implementation |
| **Confiance** | Regression detectee immediatement |
| **Documentation** | Tests = specifications executables |
| **Simplicite** | Implemente uniquement le necessaire (YAGNI) |

## Workflow TDD

```
1. ISSUE      -> Documenter probleme + solution (AVANT/APRES)
2. BRANCHE    -> git checkout -b feature/issue-XX
3. TEST       -> Ecrire tests EN PREMIER (RED - doivent echouer)
4. CODE       -> Implementer le minimum pour passer les tests (GREEN)
5. REFACTOR   -> Ameliorer le code sans casser les tests
6. COMMIT     -> Issue + Tests + Code ensemble (atomique)
7. PUSH       -> git push -u origin feature/issue-XX
8. MERGE      -> Merger dans main + supprimer branche
```

## Commit TDD

```
feat(module): add NomFonction (TDD)

Implemented using Test-Driven Development:
- RED: X tests written first (all failed)
- GREEN: Function implemented, all tests pass

Fixes #XX
```

## Convention Nommage Tests

| Element | Convention | Exemple |
|---------|------------|---------|
| Fichier | `NomFonction.Tests.*` | `Get-UserMailbox.Tests.ps1` |
| Suite | `"NomFonction"` | `Describe "Get-UserMailbox"` |
| Groupe | `"Scenario ou condition"` | `Context "Quand l'utilisateur existe"` |
| Test | `"Comportement attendu"` | `It "Retourne l'objet mailbox"` |

## Tags Tests Recommandes

| Tag | Usage |
|-----|-------|
| `Unit` | Tests unitaires isoles |
| `Integration` | Tests avec dependances reelles |
| `Slow` | Tests lents (> 5s) |
| `RequiresAdmin` | Necessite elevation |
| `RequiresNetwork` | Necessite connexion |
| `BUG-XXX` | Test lie a une issue |

## Anti-Patterns TDD

```
# [-] Ecrire le code puis les tests (pas TDD)
# [-] Tests qui testent l'implementation, pas le comportement
# [-] Tests qui dependent d'autres tests
# [-] Tests avec donnees de production (utiliser contoso.com)
```
