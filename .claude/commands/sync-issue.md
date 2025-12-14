---
description: Synchronise une issue locale vers GitHub (sans implementer)
argument-hint: TYPE-XXX-titre
allowed-tools: Read, Edit, Bash
---

# Synchronisation Issue vers GitHub (standalone)

Cette commande synchronise une issue locale vers GitHub SANS l'implementer.
Cas d'usage : Creer l'issue GitHub pour discussion/review avant implementation.

## Etape 1 : Lire l'issue locale

Lire `docs/issues/$ARGUMENTS.md` et extraire le titre.

## Etape 2 : Verifier si deja synchronisee

Si GitHub Issue contient un numero (#XX) :
- STOP - "Issue deja synchronisee : #XX"

## Etape 3 : Pousser vers GitHub

```bash
gh issue create --title "[TYPE-XXX] Titre" --body-file docs/issues/$ARGUMENTS.md
```

## Etape 4 : Mettre a jour le fichier local

- GitHub Issue : #XX
- Statut : DRAFT → OPEN

## Etape 5 : Confirmation

```
=====================================
[+] ISSUE SYNCHRONISEE
=====================================
Fichier : docs/issues/$ARGUMENTS.md
GitHub  : #XX
Statut  : OPEN

Note : Issue creee mais NON implementee.
Pour implementer : /implement-issue $ARGUMENTS
=====================================
```
