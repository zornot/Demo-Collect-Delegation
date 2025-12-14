# Fin de Session

Ferme proprement la session avant /clear.

## Processus

1. **Executer /session-save d'abord** (automatique)

2. **Generer le resume de session** :
```
===================================
[i] RESUME DE SESSION
===================================
Duree : ~[estimation]
Taches Terminees : [liste]
Fichiers Modifies : [nombre]
Decisions Prises : [nombre]

Accomplissements Cles :
- [Realisation principale 1]
- [Realisation principale 2]

Etat sauvegarde dans : docs/SESSION-STATE.md
===================================
```

3. **Rappeler /clear** :
```
[i] Pret a liberer le contexte.
    Executer /clear pour liberer la memoire.
    Prochaine session : executer /session-start pour restaurer le contexte.
```

## Pourquoi c'est important

Cela previent la pollution du contexte entre les taches.
Les decisions et la progression importantes sont preservees.
Un redemarrage propre devient possible sans tout re-expliquer.
Economise des tokens et ameliore la concentration de Claude.

## Reference Rapide

```
/session-start  -> Charger l'etat precedent
/session-save   -> Sauvegarder l'etat actuel (peut etre execute plusieurs fois)
/session-end    -> Sauvegarde finale + resume + rappel /clear
/clear          -> Reinitialiser le contexte (faire ceci !)
```
