# Demarrage de Session

Initialise la session avec le contexte du travail precedent.

## Processus

1. **Verifier l'etat existant** :
   - Lire `@docs/SESSION-STATE.md` s'il existe
   - Lire `@docs/ROADMAP.md` pour le statut du projet

2. **Afficher le statut actuel** :
```
===================================
[i] SESSION RESTAUREE
===================================
Derniere session : [date de SESSION-STATE.md]
Tache active : [tache en cours]
Progression : [X/Y etapes terminees]
===================================
```

3. **Montrer les elements en attente** :
   - Taches marquees `[-]` (en cours)
   - Taches marquees `[ ]` (a faire)
   - Blocages notes

4. **Demander a l'utilisateur** :
   "Sur quoi souhaitez-vous travailler ? Continuer [tache active] ou commencer autre chose ?"

## Si SESSION-STATE.md n'existe pas

Creer l'etat initial :
```markdown
# Etat de Session

## Tache en Cours
Aucune tache active

## Progression
(vide)

## Prochaines Etapes
1. Definir la premiere tache
```

Puis demander : "Ceci semble etre une nouvelle session. Sur quoi souhaitez-vous travailler ?"
