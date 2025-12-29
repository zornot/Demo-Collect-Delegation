---
name: progress-tracking
description: "Track project progress via docs/issues/README.md and SESSION-STATE.md. Use when completing issues, using /session-save or /session-end, mentioning phases or progression, or updating project milestones. Provides templates for issue tracking and session state management."
---

## ATTENTION - Role du Skill

Ce skill fournit des **TEMPLATES** et **FORMATS** de reference.
Il ne s'execute **PAS automatiquement**.

Les commandes `/create-issue` et `/implement-issue` doivent
appliquer ces formats **EXPLICITEMENT** dans leurs instructions.

# Progress Tracking

Skill pour la gestion de la progression projet (docs/issues/README.md et SESSION-STATE.md).

## REGLE CRITIQUE

Apres CHAQUE issue terminee, AVANT tout autre chose :
1. Ouvrir `docs/issues/README.md`
2. Trouver l'issue correspondante
3. Deplacer dans la section "Issues Terminees"
4. Ajouter la date : `[TYPE-XXX](TYPE-XXX-*.md) | Titre | YYYY-MM-DD`
5. Mettre a jour le compteur "Progression"

## Templates

Si `docs/issues/README.md` n'existe pas :
- Copier depuis [templates/ISSUES-README.md](templates/ISSUES-README.md)
- Personnaliser avec le nom du projet et les phases

Si `docs/SESSION-STATE.md` n'existe pas :
- Copier depuis [templates/SESSION-STATE.md](templates/SESSION-STATE.md)
- Remplir avec l'etat actuel

## Format de mise a jour README

### Avant issue
- `[ ] **TYPE-XXX** - Titre`

### Apres issue
- `[x] **TYPE-XXX** - Titre (YYYY-MM-DD)` + commit hash si disponible

### Section Progression
Mettre a jour la barre et les indicateurs :
- Calculer le pourcentage (issues terminees / total)
- Mettre a jour "Active" avec l'issue en cours
- Mettre a jour "Next" avec la prochaine issue

## Notation des etapes

| Symbole | Signification |
|---------|---------------|
| `[ ]` | A faire |
| `[-]` | En cours |
| `[x]` | Fait |

Cette notation est utilisee dans :
- Issue Active (SESSION-STATE.md)
- Checklist des issues
- Resume Phases

## Quand ce skill est active

| Trigger | Action |
|---------|--------|
| `/implement-issue` termine | Mettre a jour docs/issues/README.md |
| `/session-save` | Mettre a jour SESSION-STATE |
| `/session-end` | Mettre a jour les deux |
| Issue fermee dans `docs/issues/` | Rappeler de mettre a jour docs/issues/README.md |

## Verification

Avant de confirmer la fin d'une tache :
1. Verifier que docs/issues/README.md est a jour
2. Verifier que l'issue est dans "Issues Terminees"
3. Verifier que la date est presente
