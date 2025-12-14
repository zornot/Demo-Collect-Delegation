---
description: Cree une issue locale suivant le workflow du projet
argument-hint: TYPE-XXX-titre
allowed-tools: Write, Read
---

Creer un fichier issue dans `docs/issues/$ARGUMENTS.md` en utilisant le template du projet.

## Reference

Lire `.claude/skills/development-workflow/workflow.md` pour le template complet des issues.

## Template d'Issue

```markdown
# [PRIORITE] [$ARGUMENTS] - Effort: Xh

<!-- Priorite: !! (critique), ! (elevee), ~ (moyenne), - (faible) -->

## PROBLEME
[Description technique 2-3 phrases]

## LOCALISATION
- Fichier : path/to/file.ext:L[debut]-[fin]
- Fonction : nomFonction()
- Module : NomComposant

## OBJECTIF
[Etat cible apres correction]

---

## IMPLEMENTATION

### Etape 1 : [Action] - [X]min
Fichier : path/to/file.ext

AVANT :
```powershell
[code exact]
```

APRES :
```powershell
[code corrige]
```

---

## VALIDATION

### Criteres d'Acceptation
- [ ] [Condition specifique]
- [ ] Pas de regression

## CHECKLIST
- [ ] Code AVANT = code reel
- [ ] Tests passent
- [ ] Code review

Labels : [type] [priorite] [module]

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | # (apres gh issue create) |
| Statut | DRAFT / OPEN / IN_PROGRESS / RESOLVED / CLOSED |
| Branche | (feature/TYPE-XXX-titre ou fix/TYPE-XXX-titre) |
```

## Niveaux de Priorite

Utiliser ces symboles dans le titre :
- Double exclamation = Critique - Bloquant
- Simple exclamation = Elevee - Sprint courant
- Tilde = Moyenne - Sprint suivant
- Tiret = Faible - Backlog

## Types d'Issue

| Type | Branche | Usage |
|------|---------|-------|
| BUG | fix/ | Correction de bug |
| FIX | fix/ | Correction mineure |
| FEAT | feature/ | Nouvelle fonctionnalite |
| REFACTOR | feature/ | Amelioration du code |
| PERF | feature/ | Performance |
| ARCH | feature/ | Architecture |
| SEC | fix/ | Securite |
| TEST | feature/ | Tests |
| DOC | feature/ | Documentation |
