---
description: Cree des tests Pester pour une fonction (phase RED du TDD)
argument-hint: NomFonction [ISSUE-ID]
---

# Creation de Tests Pester

Utiliser l'agent @test-writer pour creer des tests Pester.

## Syntaxe

```
/create-test FunctionName [ISSUE-ID]
```

| Argument | Requis | Description |
|----------|--------|-------------|
| FunctionName | Oui | Nom de la fonction a tester |
| ISSUE-ID | Non | Reference issue (ex: FEAT-XXX) pour contexte DESIGN |

## Workflow

### Etape 1 : Extraire les arguments

Parser $ARGUMENTS :
- `$FunctionName` = premier mot de $ARGUMENTS
- `$IssueId` = deuxieme mot de $ARGUMENTS (optionnel)

| Argument | Extraction | Exemple |
|----------|------------|---------|
| FunctionName | `$ARGUMENTS.Split()[0]` | `Get-UserInfo` |
| IssueId | `$ARGUMENTS.Split()[1]` | `FEAT-XXX` |

**BLOCKER** : STOP si $FunctionName est vide.

### Etape 2 : Invoquer @test-writer (APRES Etape 1)

Afficher : `[i] Invocation de l'agent test-writer...`

Invoquer `@test-writer` avec le prompt :

```
Creer des tests Pester pour la fonction "$FunctionName".

## Contexte Issue (si $IssueId fourni)
Issue : $IssueId
- Lire docs/issues/$IssueId.md
- Extraire section DESIGN > Tests Attendus
- Aligner les tests sur les specifications

## Contexte Modules
- Lister Modules/*.psd1 pour identifier les fonctions internes
- Ces fonctions devront etre mockees dans les tests

## Standards
- Phase TDD : RED (tests qui echouent)
- Emplacement : Tests/Unit/$FunctionName.Tests.ps1
- Style : Arrange-Act-Assert
- Donnees : contoso.com (jamais de vraies donnees)

## Sortie attendue
- Chemin du fichier cree
- Nombre de tests (Describe/Context/It)
- Rappel : "/run-tests pour valider"
```

### Etape 3 : Afficher resume (APRES Etape 2)

L'agent retourne un resume. Afficher :

```
=====================================
[+] TESTS CREES
=====================================
Fichier : Tests/Unit/$FunctionName.Tests.ps1
Tests   : X Describe, Y Context, Z It

Prochaine etape : /run-tests
=====================================
```
