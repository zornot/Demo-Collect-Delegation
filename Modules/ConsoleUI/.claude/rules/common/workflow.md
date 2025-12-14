# Workflow de Developpement

## Issues Local-First

Les issues sont gerees localement dans `audit/issues/` avant synchronisation GitHub.
Cela permet de documenter le probleme et la solution AVANT de coder.

### Etape 1 : Creer l'issue localement

Creer manuellement dans :

```
audit/issues/
+-- ISSUE-XXX-titre.md  # Issues individuelles
```

### Etape 2 : Synchroniser GitHub au commit

```bash
gh issue create --title "[TYPE-XXX] Titre" --body-file audit/issues/ISSUE-XXX-titre.md
# Noter le numero GitHub dans l'issue locale (champ "GitHub: #XXX")
```

## Workflow Synchronisation Bidirectionnelle

### Phase 1 : Creation et Push

1. Creer issue locale dans `audit/issues/`
2. Documenter probleme + solution
3. Push vers GitHub :
   ```bash
   gh issue create --title "[TYPE-XXX] Titre" \
     --body-file audit/issues/ISSUE-XXX-titre.md
   ```
4. Mettre a jour issue locale avec numero GitHub :
   ```markdown
   GitHub Issue: #42
   Statut: OPEN
   ```

### Phase 2 : Developpement

1. Creer branche :
   ```bash
   git checkout -b fix/BUG-001
   ```

2. Mettre a jour statut dans issue locale :
   ```markdown
   Statut: IN_PROGRESS
   ```

3. Committer avec reference :
   ```bash
   git commit -m "fix(validation): correct input check

   Fixes #42"
   ```

### Phase 3 : Resolution

1. Mettre a jour issue locale :
   ```markdown
   Statut: RESOLVED
   Commit Resolution: abc1234
   ```

2. Fermer issue GitHub :
   ```bash
   gh issue close 42 --comment "Resolu dans commit abc1234"
   ```

3. Merge et cleanup :
   ```bash
   git checkout main
   git merge fix/BUG-001
   git push origin main
   git branch -d fix/BUG-001
   ```

4. Mettre a jour statut final :
   ```markdown
   Statut: CLOSED
   ```

## Template Issue

```markdown
# [!!|!|~|-] [TYPE-ID] Titre Imperatif | Effort: Xh

## PROBLEME
[Description technique 2-3 phrases]

## LOCALISATION
- Fichier : path/to/file.ext:L[debut]-[fin]
- Fonction : nomFonction()
- Module : NomComposant

## OBJECTIF
[Etat cible apres correction]

---

## ANALYSE IMPACT

### Fichiers Impactes
| Fichier | Raison | Action Requise |
|---------|--------|----------------|
| [fichier] | [appelle fonction modifiee] | [verifier/adapter] |

### Code Mort a Supprimer

**Methode d'identification :**

1. **Analyse statique** - Executer PSScriptAnalyzer :
   ```powershell
   # Variables declarees mais jamais utilisees
   Invoke-ScriptAnalyzer -Path ./fichier.ps1 -IncludeRule PSUseDeclaredVarsMoreThanAssignments

   # Parametres non utilises
   Invoke-ScriptAnalyzer -Path ./fichier.ps1 -IncludeRule PSReviewUnusedParameter
   ```

2. **Tracage des dependances** - Rechercher les appels a la fonction/variable modifiee :
   ```powershell
   # Trouver tous les appels a une fonction
   Get-ChildItem -Path . -Filter *.ps1 -Recurse |
       Select-String -Pattern 'NomFonction' -List
   ```

3. **Execution virtuelle** - Simuler le flux avec les modifications :
   ```
   Entree : [donnees test]
   L[X] : $variable = [valeur] --> [SUPPRIME car plus appele]
   Sortie : [resultat inchange]
   ```

| Ligne | Code | Raison | Methode |
|-------|------|--------|---------|
| [X] | `[extrait]` | [plus utilise apres correction] | [Analyse\|Tracage\|Exec] |

---

## IMPLEMENTATION

### Etape 1 : [Action] - [X]min
Fichier : path/to/file.ext
Lignes [X-Y] - [AJOUTER | MODIFIER | SUPPRIMER]

AVANT :
```
[code exact tel qu'il existe]
```

APRES :
```
[code corrige]
```

Justification : [explication technique]

---

## VALIDATION

### Execution Virtuelle (optionnel)
```
Entree : [donnees test]
L[X] : [variable] = [valeur]
Sortie : [resultat]
```
[>] VALIDE - Le code APRES couvre tous les cas

### Criteres d'Acceptation
- [ ] [Condition specifique et verifiable]
- [ ] [Comportement attendu mesurable]
- [ ] Pas de regression sur [fonctionnalite liee]

---

## DEPENDANCES
- Bloquee par : #[XXX] | Aucune
- Bloque : #[YYY]

## POINTS ATTENTION
- [X] fichiers modifies
- [Y] lignes ajoutees/supprimees
- Risques : [liste avec mitigation]

## CHECKLIST
- [ ] Code AVANT = code reel verifie
- [ ] Tests unitaires passent
- [ ] Code review effectuee

Labels : [type] [priorite] [module] [effort]
```

## Niveaux de Priorite

| Symbole | Niveau | Description |
|---------|--------|-------------|
| `!!` | Critique | Bloquant, hotfix immediat |
| `!` | Elevee | Sprint courant |
| `~` | Moyenne | Sprint suivant |
| `-` | Faible | Backlog |

## Types d'Issue

| Type | Usage |
|------|-------|
| `BUG` | Correction de bug |
| `FEAT` | Nouvelle fonctionnalite |
| `REFACTOR` | Amelioration du code |
| `PERF` | Amelioration performance |
| `ARCH` | Architecture/SOLID |
| `DRY` | Elimination duplication |
| `MAIN` | Maintenabilite |
| `TEST` | Ajout/correction de tests |

---

## Diagramme Workflow

```
┌─────────────────────────────────────────────────────────────┐
│  0. ISSUE        Documenter probleme + solution (AVANT/APRES)│
├─────────────────────────────────────────────────────────────┤
│  1. BRANCHE      git checkout -b feature/issue-XX           │
├─────────────────────────────────────────────────────────────┤
│  2. CODE         Appliquer les modifications de l'issue     │
├─────────────────────────────────────────────────────────────┤
│  3. TEST         Invoke-Pester / validation syntaxe         │
├─────────────────────────────────────────────────────────────┤
│  4. COMMIT       Issue + Code corrige ensemble              │
├─────────────────────────────────────────────────────────────┤
│  5. PUSH         git push -u origin feature/issue-XX        │
├─────────────────────────────────────────────────────────────┤
│  6. MERGE        Merger dans main + supprimer branche       │
└─────────────────────────────────────────────────────────────┘
```
