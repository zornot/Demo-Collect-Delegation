---
description: Review le code PowerShell selon les standards du projet
---

Effectuer une review de code avec processus d'evaluation temporelle.

## Arguments

- `$ARGUMENTS` : Chemin du fichier ou dossier a reviewer (defaut: repertoire courant)

## Workflow

### Etape 1 : Evaluation temporelle

**Lire** `.claude/skills/knowledge-verification/SKILL.md` et appliquer le processus.

Date du jour : !`pwsh -NoProfile -c "(Get-Date).ToString('yyyy-MM-dd')"`

| Action | Description |
|--------|-------------|
| Identifier | Technologies (modules, APIs, frameworks) dans $ARGUMENTS |
| Evaluer | Auto-evaluation (seuil 9/10) + risque obsolescence |
| Rechercher | Si condition → `[i] Invocation de l'agent tech-researcher...` |
| Noter | Points cles pour l'agent code-reviewer |

### Etape 2 : Deleguer a @code-reviewer (APRES Etape 1)

**BLOCKER** : Ne pas deleguer sans avoir identifie les technologies presentes.

Afficher : `[i] Invocation de l'agent code-reviewer...`

Invoquer `@code-reviewer` avec le contexte :

```
Review le code dans $ARGUMENTS.

[Si recherche tech-researcher effectuee :]
Note : Recherche prealable effectuee sur [techno].
Points cles : [resume des resultats pertinents]

Retourner un rapport structure (CRITIQUE/WARNING/INFO).
```

### Etape 3 : Afficher rapport (APRES Etape 2)

L'agent retourne un rapport structure. Afficher au format :

```
=====================================
[+] REVIEW TERMINEE
=====================================
Fichier(s) : $ARGUMENTS
Findings   : X CRITIQUE, Y WARNING, Z INFO

[Details du rapport agent]
=====================================
```

## Exemple

```
/review-code ./Modules/MonModule
/review-code ./Script.ps1
```
