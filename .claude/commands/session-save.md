---
description: Sauvegarde l'etat de session actuel pour une restauration future
---

# Sauvegarde de Session

Sauvegarde l'etat de session actuel pour une restauration future.

## Processus

1. **Mettre a jour docs/SESSION-STATE.md** avec le template ci-dessous.

2. **Confirmer la sauvegarde** :
```
===================================
[+] SESSION SAUVEGARDEE
===================================
Etat : docs/SESSION-STATE.md mis a jour
Taches : [X] terminees, [Y] en cours
Pret pour /clear quand vous avez fini.
===================================
```

## Template SESSION-STATE.md

```markdown
# Etat de Session - [YYYY-MM-DD HH:MM]

## Tache en Cours
[Description specifique - 1 phrase]

## Issue Active
[Si applicable : TYPE-XXX | Branche | Etape X/Y]

---

## Resume Executif

| Metrique | Valeur |
|----------|--------|
| Duree | ~Xh |
| Fichiers touches | X |
| Issues implementees | X |
| Commits (non pushes) | X |

---

## Decisions Cles Cette Session

| Decision | Justification | Impact |
|----------|---------------|--------|
| [Choix fait] | [Pourquoi] | [Effet] |

## Alternatives Rejetees (CRITIQUE)

| Alternative | Pourquoi Rejetee | Contexte |
|-------------|------------------|----------|
| [Solution ecartee] | [Raison technique] | [Quand/ou testee] |

> **But** : Eviter que la prochaine session re-explore ces dead ends.

---

## Decouvertes Techniques

### Valide (a reutiliser)
- [Pattern/approche qui fonctionne] : [Pourquoi]

### Invalide (a eviter)
- [Pattern/approche qui ne fonctionne pas] : [Pourquoi]

### Contraintes Decouvertes
- [Limitation technique] : [Implication]

---

## Fichiers Modifies

| Fichier | Action | Description |
|---------|--------|-------------|
| [path] | Cree/Modifie | [Quoi] |

---

## Git Status

```
[Resultat de git status --short]
[Resultat de git log --oneline -5]
```

---

## Blocages

### Non Resolus
- [Probleme actif] : [Contexte]

### Resolus Cette Session
- ~~[Ex-probleme]~~ : [Solution trouvee]

---

## Prochaines Etapes

1. **Immediat** (<5min) : [Action]
2. **Court terme** : [Action]
3. **A considerer** : [Action]

---

## HANDOVER PROMPT (Copier-Coller)

```bash
# 1. Charger le contexte
/session-start

# 2. Contexte cle a retenir :
# - [Point critique 1]
# - [Point critique 2]
# - [Decision importante]

# 3. NE PAS re-explorer :
# - [Alternative rejetee 1]
# - [Alternative rejetee 2]

# 4. Commande pour reprendre :
[Commande exacte a taper]
```

*Temps estime reprise : <2 min*
```

## Instructions pour Claude

Lors de la sauvegarde, TOUJOURS :

1. **Lister les alternatives rejetees** :
   - "Quelles approches avons-nous ecartees ?"
   - Documenter POURQUOI (evite re-exploration)

2. **Separer decouvertes valides/invalides** :
   - "Qu'avons-nous appris qui FONCTIONNE ?"
   - "Qu'avons-nous appris qui NE FONCTIONNE PAS ?"

3. **Generer git status** :
   - Executer `git status --short` et `git log --oneline -5`
   - Inclure le resultat

4. **Ecrire handover prompt copiable** :
   - Derniere section = prompt pour reprendre
   - Inclure "NE PAS re-explorer : [liste dead ends]"

## Principes

**Priorite : Completude > Concision** - Mieux vaut trop de details que perdre du contexte entre sessions.

1. **Etre specifique** - Les resumes vagues n'aident pas les futures sessions
2. **Inclure le POURQUOI** - Pas seulement CE QUI a ete decide, mais la justification
3. **Documenter les dead ends** - Evite 30-40% perte productivite (source: best practices 2025)
4. **Handover prompt copiable** - Permet reprise <2 minutes

## Reference

Le skill `progress-tracking` gere la mise a jour de `docs/issues/README.md`.
Templates disponibles dans `.claude/skills/progress-tracking/templates/`.
