---
description: Cree des tests Pester pour une fonction (phase RED du TDD)
argument-hint: NomFonction
allowed-tools: Read, Write, Glob
---

Creer des tests Pester pour la fonction `$ARGUMENTS` en suivant les principes TDD.

## References Requises

1. `.claude/skills/powershell-development/pester.md` - Structure des tests, Mocks
2. `.claude/skills/development-workflow/testing-data.md` - Donnees anonymes
3. `.claude/skills/development-workflow/tdd.md` - Cycle TDD

## Emplacement du Fichier Test

Creer : `Tests/Unit/$ARGUMENTS.Tests.ps1`

## Structure du Test

```powershell
#Requires -Modules Pester

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..' '..' 'Modules' 'NomModule' 'NomModule.psd1'
    Import-Module $modulePath -Force
}

Describe '$ARGUMENTS' {

    Context 'Cas nominal' {

        It 'Retourne le resultat attendu pour un input valide' {
            # Arrange
            $inputValue = "valeur-test"

            # Act
            $actualResult = $ARGUMENTS -Param $inputValue

            # Assert
            $actualResult | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Gestion des erreurs' {

        It 'Leve une exception pour input null' {
            { $ARGUMENTS -Param $null } | Should -Throw
        }

        It 'Leve une exception pour chaine vide' {
            { $ARGUMENTS -Param '' } | Should -Throw
        }
    }

    Context 'Cas limites' {

        It 'Gere les caracteres speciaux' {
            $specialInput = "test`tavec`ttabulations"
            { $ARGUMENTS -Param $specialInput } | Should -Not -Throw
        }
    }
}
```

## Donnees de Test

| Type | Valeur |
|------|--------|
| Domaine | `contoso.com`, `fabrikam.com` |
| Email | `jean.dupont@contoso.com` |
| GUID | `00000000-0000-0000-0000-000000000001` |

Les donnees de production reelles ne doivent jamais apparaitre dans les tests.
Elles pourraient finir dans le controle de version ou les logs.

## Cycle TDD

1. **RED** : Ecrire le test d'abord - il DOIT echouer
2. **GREEN** : Implementer le minimum de code
3. **REFACTOR** : Ameliorer en gardant les tests verts

## Checklist

- [ ] Fichier test dans `Tests/Unit/`
- [ ] BeforeAll avec import du module
- [ ] Describe nomme d'apres la fonction
- [ ] Blocs Context (nominal, erreur, limites)
- [ ] Uniquement des donnees de test anonymes
