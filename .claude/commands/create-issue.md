---
description: Cree une issue locale suivant le workflow du projet
argument-hint: TYPE-XXX-titre
allowed-tools: Write, Read
---

# /create-issue - DOCUMENTATION UNIQUEMENT

Cette commande cree un fichier d'issue. Elle ne modifie pas le code source.

## Pourquoi ce workflow ?

| Etape | Commande | But |
|-------|----------|-----|
| 1. Documenter | `/create-issue` | Tracabilite, specification claire |
| 2. Valider | Reponse utilisateur | Revue humaine avant action |
| 3. Implementer | `/implement-issue` | Execution structuree (branche + commit) |

Modifier directement le code sans issue supprime la tracabilite et empeche la revue.
Meme si le fix semble evident, le workflow existe pour l'equipe, pas pour l'efficacite individuelle.

## Outils autorises

| Outil | Autorise | Usage |
|-------|----------|-------|
| Read | Oui | Lire fichiers existants |
| Write | Oui | Creer l'issue dans docs/issues/ |
| Edit | Non | Reserve pour /implement-issue |
| Bash | Non | Reserve pour /implement-issue |

Note technique : `allowed-tools` dans le frontmatter ne garantit pas le blocage (bugs connus).
Cette restriction depend de votre comprehension du workflow.

---

## Phase A : Preparation

### Etape 1 : Verifier docs/issues/README.md

Avant de creer l'issue, verifier si `docs/issues/README.md` existe :

1. **Si n'existe pas** :
   - Lire `.claude/skills/progress-tracking/templates/ISSUES-README.md`
   - Creer `docs/issues/README.md` depuis le template
   - Personnaliser avec le nom du projet (depuis CLAUDE.md ou package.json)

2. **Si existe** :
   - Ajouter l'issue dans la section "Issues A Faire" :
   ```markdown
   | [TYPE-XXX](TYPE-XXX-titre.md) | Titre descriptif | ~ |
   ```

### Etape 2 : Determiner le type et la priorite (APRES Etape 1)

Extraire de $ARGUMENTS :
- **Type** : Premier segment (FEAT, BUG, FIX, etc.)
- **Priorite** : Evaluer selon contexte

#### Types d'Issue

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

#### Niveaux de Priorite

Utiliser ces symboles dans le titre :
- \`!!\` = Critique - Bloquant
- \`!\` = Elevee - Sprint courant
- \`~\` = Moyenne - Sprint suivant
- \`-\` = Faible - Backlog

**BLOCKER** : Ne pas continuer sans type valide.

### Etape 3 : Preparer la section DESIGN si applicable (APRES Etape 2)

#### Quand est-ce obligatoire ?

| Type Issue | Section DESIGN | Raison |
|------------|----------------|--------|
| FEAT | OBLIGATOIRE | Nouvelle fonctionnalite = architecture |
| SEC | OBLIGATOIRE | Securite = surface d'attaque a analyser |
| BUG | Optionnelle | Analyse cause racine si complexe |
| FIX | Non requise | Correction simple |
| REFACTOR | Si >100 lignes | Refactoring majeur = impact architecture |

**SI type dans [FEAT, SEC]** :
- Section DESIGN **OBLIGATOIRE**
- Utiliser le template DESIGN ci-dessous

**SI type dans [BUG, FIX, REFACTOR, PERF, ARCH, TEST, DOC]** :
- Section DESIGN optionnelle
- Continuer directement

#### Template DESIGN

```markdown
## DESIGN

### Objectif
[Quel probleme ce code resout-il ? 1-2 phrases]

### Architecture
- **Module concerne** : [NomModule existant ou "nouveau"]
- **Dependances** : [Modules/APIs utilises]
- **Impact** : [Fichiers/composants affectes]
- **Pattern** : [Pipeline, Repository, Factory, etc.]

### Interface
[Comment ce code sera-t-il utilise ?]
```powershell
# Signature de la fonction/API
function Verb-Noun {
    [CmdletBinding()]
    [OutputType([TypeRetour])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Param1
    )
}

# Exemple d'utilisation
$result = Verb-Noun -Param1 "valeur"
```

### Tests Attendus
- [ ] Cas nominal : [description]
- [ ] Cas erreur : [description]
- [ ] Cas limite : [description]

### Considerations
- **Performance** : [si applicable]
- **Securite** : [si applicable]
- **Retrocompatibilite** : [si applicable]
```

Note : Pour generer les tests, utiliser `/create-test NomFonction` apres validation du design.

### Etape 4 : Verifier les modules existants (APRES Etape 3)

Avant de proposer du code dans APRES, verifier `Modules/` :

```powershell
Get-ChildItem -Path Modules -Directory
```

Pour chaque module trouve, lire `Modules/[NomModule]/CLAUDE.md` ou le `.psd1`
pour connaitre les fonctions exportees.

**BLOCKER** : Ne pas proposer de code dupliquant une fonction existante.
Utiliser l'existant plutot que recreer.

---

## Phase B : Redaction

### Etape 5 : Rediger l'issue (APRES Etape 4)

Creer `docs/issues/$ARGUMENTS.md` avec le template suivant.

Le code dans la section APRES doit respecter les conventions du projet.
Consulter `.claude/skills/powershell-development/SKILL.md` pour :
- Nommage (Verb-Noun, CmdletBinding, Noun singulier)
- Error handling (-ErrorAction Stop)
- Variables explicites (pas $data, $temp, $i)
- UI console (brackets, pas emoji)

#### Template d'Issue

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

#### Sections obligatoires

- PROBLEME
- LOCALISATION
- OBJECTIF
- IMPLEMENTATION (AVANT/APRES)
- VALIDATION
- SYNCHRONISATION GITHUB

### Etape 6 : Afficher et attendre validation (APRES Etape 5)

Apres creation de l'issue, afficher :

```
=====================================
[i] ISSUE CREEE : $ARGUMENTS
=====================================
Statut  : DRAFT
Fichier : docs/issues/$ARGUMENTS.md
=====================================

Pour implementer : /implement-issue $ARGUMENTS
Pour arreter     : repondre "non"
=====================================
```

**BLOCKER** : NE PAS implementer sans reponse utilisateur explicite.
Attendre la reponse de l'utilisateur.
Le workflow existe pour permettre la revue humaine.
