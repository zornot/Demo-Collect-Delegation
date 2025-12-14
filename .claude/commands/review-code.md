---
description: Review le code PowerShell selon les standards du projet
---

Utiliser l'agent @code-reviewer pour effectuer une review de code
dans un contexte isole (preserve les tokens du contexte principal).

## Arguments

- `$ARGUMENTS` : Chemin du fichier ou dossier a reviewer (defaut: repertoire courant)

## Comportement

1. L'agent `code-reviewer` est invoque dans un contexte isole
2. Il lit les standards PowerShell et analyse le code
3. Il retourne un rapport structure (CRITIQUE/WARNING/INFO)

## Exemple

```
/review-code ./Modules/MonModule
/review-code ./Script.ps1
```
