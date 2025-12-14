# Sauvegarde de Session

Sauvegarde l'etat de session actuel pour une restauration future.

## Processus

1. **Mettre a jour docs/SESSION-STATE.md** avec :

```markdown
# Etat de Session - [Date Actuelle]

## Tache en Cours
[Ce sur quoi nous travaillons - etre specifique]

## Issue Active
Aucune issue en cours.
<!-- Si issue en cours :
**TYPE-XXX - Titre** | Branche: feature/TYPE-XXX | GitHub: #XX
- [x] Etape 1 : Description
- [-] Etape 2 : Description (en cours)
- [ ] Etape 3 : Description
-->

## Resume Phases
- [x] Phase A : [Nom] (X/X issues)
- [-] Phase B : [Nom] (X/X issues)
- [ ] Phase C : [Nom] (0/X issues)

## Progression
- [x] Etape terminee (ajouter details)
- [-] Etape en cours
- [ ] Etape restante

## Decisions Cles
| Decision | Justification |
|----------|---------------|
| [Choix fait] | [Pourquoi] |

## Fichiers Modifies
| Fichier | Modifications |
|---------|---------------|
| path/fichier.ps1 | [Description breve] |

## Contexte a Preserver
[Informations critiques dont Claude a besoin pour se souvenir]
- Details techniques
- Contraintes decouvertes
- Dependances identifiees

## Blocages/Problemes
- [Problemes rencontres]

## Prochaines Etapes
1. [Prochaine action immediate]
2. [Action suivante]
```

2. **Le skill `progress-tracking` gere la mise a jour** :
   - Rappel systematique de mettre a jour `docs/issues/README.md`
   - Templates disponibles dans `.claude/skills/progress-tracking/templates/`

3. **Confirmer la sauvegarde** :
```
===================================
[+] SESSION SAUVEGARDEE
===================================
Etat : docs/SESSION-STATE.md mis a jour
Taches : [X] terminees, [Y] en cours
Pret pour /clear quand vous avez fini.
===================================
```

## Principes

Etre specifique dans les descriptions car le futur Claude a besoin de contexte.
Inclure les chemins de fichiers avec numeros de ligne si pertinent.
Noter les hypotheses faites.
Enregistrer pourquoi les decisions ont ete prises, pas seulement quoi.
