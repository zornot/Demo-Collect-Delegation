# Workflow de Developpement

## Issues Local-First

Les issues sont gerees localement dans `docs/issues/` avant synchronisation GitHub.
Cela permet de documenter le probleme et la solution AVANT de coder.

### Etape 1 : Creer l'issue localement

Creer manuellement dans :

```
docs/issues/
├── README.md           # Index + Phases
└── TYPE-XXX-titre.md   # Issues individuelles
```

### Etape 2 : Synchronisation GitHub (optionnelle avant implementation)

Pour discuter sur GitHub AVANT d'implementer :
```bash
# Commande standalone : /sync-issue TYPE-XXX-titre
gh issue create --title "[TYPE-XXX] Titre" --body-file docs/issues/TYPE-XXX-titre.md
```

Note : La sync principale se fait automatiquement A LA FIN de `/implement-issue`.

## Workflow Synchronisation Bidirectionnelle

### Phase 1 : Creation et Push

1. Creer issue locale dans `docs/issues/`
2. Documenter probleme + solution
3. Push vers GitHub :
   ```bash
   gh issue create --title "[TYPE-XXX] Titre" \
     --body-file docs/issues/TYPE-XXX-titre.md
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

1. Mettre a jour issue locale (statut → RESOLVED) :
   ```markdown
   Statut: RESOLVED
   Commit Resolution: [hash]
   ```

2. Commit atomique (inclut l'issue mise a jour) :
   ```bash
   git add .
   git commit -m "fix(validation): correct input check

   Fixes #42"
   ```

3. Merge et push :
   ```bash
   git checkout main
   git merge fix/BUG-001
   git push origin main
   git branch -d fix/BUG-001
   ```
   → `Fixes #42` ferme automatiquement l'issue GitHub au push.

4. Mettre a jour issue locale (statut → CLOSED) + README :
   ```markdown
   Statut: CLOSED
   ```
   → Mettre a jour `docs/issues/README.md` (progression)

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

   > **Reference complete** : `.claude/skills/powershell-development/psscriptanalyzer.md`

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
| \`!!\` | Critique | Bloquant, hotfix immediat |
| \`!\` | Elevee | Sprint courant |
| \`~\` | Moyenne | Sprint suivant |
| \`-\` | Faible | Backlog |

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

## Section DESIGN - Template

Pour les issues FEAT ou SEC, utiliser ce template :

```markdown
## DESIGN

### Objectif
[1-2 phrases : quel probleme ce code resout]

### Architecture
- Module : [NomModule ou "nouveau"]
- Dependances : [liste modules/APIs]
- Pattern : [ex: Pipeline, Repository, Factory]

### Interface
```powershell
# Signature
function Verb-Noun {
    [CmdletBinding()]
    [OutputType([TypeRetour])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Param1
    )
}

# Usage
$result = Verb-Noun -Param1 "valeur"
```

### Tests Attendus
- [ ] Cas nominal
- [ ] Cas erreur (input invalide)
- [ ] Cas limite (vide, null, max)
```

Pourquoi cette section ?
- Spec-Driven Development : definir l'interface AVANT le code
- Evite le refactoring post-implementation
- Facilite la review (on valide le design, pas le code)

Note : Pour generer les tests, utiliser `/create-test NomFonction` apres validation du design.

---

## Trigger Implementation

Quand l'utilisateur demande d'implementer une issue (mots-cles : "implemente", "implement", "applique", "execute issue", "lance issue") :

→ **TOUJOURS** utiliser `/implement-issue TYPE-XXX-titre`
→ **NE JAMAIS** proceder manuellement meme si l'issue a deja ete lue

Cette regle est **non-negociable**. Elle garantit :
- Creation systematique de branche
- Mise a jour des statuts (IN_PROGRESS → RESOLVED → CLOSED)
- Affichage du plan avant execution
- Proposition du commit (pas execution directe)

---

## Diagramme Workflow

```
┌─────────────────────────────────────────────────────────────┐
│  0. ISSUE        /create-issue TYPE-XXX (fichier local)     │
│                  + Section DESIGN si FEAT/SEC               │
├─────────────────────────────────────────────────────────────┤
│  1. [SYNC]       /sync-issue TYPE-XXX (optionnel, pour      │
│                  discussion avant implementation)            │
├─────────────────────────────────────────────────────────────┤
│  ═══════════════════════════════════════════════════════════│
│  ║  STOP - ATTENDRE VALIDATION UTILISATEUR                 ║│
│  ║  Ne JAMAIS implementer sans accord explicite            ║│
│  ═══════════════════════════════════════════════════════════│
├─────────────────────────────────────────────────────────────┤
│  2. IMPLEMENT    /implement-issue TYPE-XXX          │
├─────────────────────────────────────────────────────────────┤
│  3. BRANCHE      git checkout -b feature/issue-XX           │
├─────────────────────────────────────────────────────────────┤
│  4. CODE         Appliquer les modifications de l'issue     │
├─────────────────────────────────────────────────────────────┤
│  5. TEST         Invoke-Pester / validation syntaxe         │
├─────────────────────────────────────────────────────────────┤
│  6. COMMIT       Issue (RESOLVED) + Code corrige            │
├─────────────────────────────────────────────────────────────┤
│  7. MERGE        git merge + push (Fixes #XX ferme auto)    │
├─────────────────────────────────────────────────────────────┤
│  8. MAJ          Issue (CLOSED) + README (progression)      │
├─────────────────────────────────────────────────────────────┤
│  9. SYNC         gh issue create + close (AUTOMATIQUE)      │
└─────────────────────────────────────────────────────────────┘
```
