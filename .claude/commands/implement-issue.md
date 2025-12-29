---
description: Implemente une issue existante (cree branche, suit le plan, met a jour statut)
argument-hint: TYPE-XXX-titre
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Implementation d'Issue

Workflow structure en 5 phases et 13 etapes pour implementer une issue.

---

## Phase A : Preparation

### Etape 1 : Lecture de l'issue

Lire le fichier `docs/issues/$ARGUMENTS.md` et extraire :
- Le statut actuel (section SYNCHRONISATION GITHUB)
- Le numero GitHub (si renseigne)
- Les etapes d'IMPLEMENTATION (sections AVANT/APRES)
- Les criteres d'acceptation

### Etape 2 : Verifications pre-implementation (APRES Etape 1)

Verifier le statut :

| Statut actuel | Action |
|---------------|--------|
| DRAFT | OK - Sync automatique a la fin |
| OPEN | OK - Continuer |
| IN_PROGRESS | WARNING - "Issue deja en cours. Continuer ?" |
| RESOLVED | **STOP** - "Issue deja resolue." |
| CLOSED | **STOP** - "Issue fermee." |

**BLOCKER** : STOP si statut RESOLVED ou CLOSED. Ne pas continuer.

### Etape 3 : Creation de branche (APRES Etape 2)

```bash
git checkout main
git pull origin main
git checkout -b [type]/$ARGUMENTS
```

| Type issue | Prefixe branche |
|------------|-----------------|
| BUG, FIX, SEC | `fix/` |
| FEAT, REFACTOR, PERF, ARCH, TEST, DOC | `feature/` |

### Etape 4 : Rappel TDD (APRES Etape 3) - Conditionnel

Extraire le type d'issue depuis $ARGUMENTS (premier segment, ex: FEAT-025 → FEAT).

**Si type dans [FEAT, BUG, SEC]**, afficher :

```
=====================================
[i] TDD RECOMMANDE
=====================================
Type d'issue : [TYPE]

| Type | Raison |
|------|--------|
| FEAT | Nouveau comportement = test = specification |
| BUG  | Test reproduit le bug avant fix |
| SEC  | Test prouve la faille puis sa correction |

Creer les tests avant implementation ?
> /create-test [FunctionName] $ARGUMENTS

Ou repondre "skip" pour continuer sans TDD
=====================================
```

Attendre reponse utilisateur :
- Si `/create-test` → executer la commande
- Si "skip" ou "non" → continuer

**Si type dans [REFACTOR, PERF, DOC, TEST, ARCH]** : continuer directement.

---

## Phase B : Standards

### Etape 5 : Charger les standards (APRES Etape 4)

Pour garantir le respect des conventions :

1. Lire `.claude/skills/powershell-development/SKILL.md` pour :
   - Nommage Verb-Noun, CmdletBinding, PascalCase
   - Error handling (-ErrorAction Stop dans try-catch)
   - Performance (List<T>, .Where())
   - UI console (brackets, pas emoji)

2. Lire `.claude/skills/development-workflow/SKILL.md` pour :
   - Commits atomiques
   - Donnees test anonymisees (contoso.com)

> **Pourquoi ?** L'auto-activation des skills n'est pas garantie a 100%.

---

## Phase C : Implementation

### Etape 6 : Afficher le plan (APRES Etape 5)

Afficher clairement pour l'utilisateur :

```
=====================================
PLAN D'IMPLEMENTATION : $ARGUMENTS
=====================================

## Etapes a realiser :
[Lister les etapes de la section IMPLEMENTATION]

## Criteres d'acceptation :
[Lister les criteres de la section VALIDATION]
=====================================
```

### Etape 7 : Executer les modifications (APRES Etape 6)

**BLOCKER** : Ne pas modifier de code sans avoir affiche le plan a l'utilisateur.

Pour chaque etape d'IMPLEMENTATION :

1. **Verifier AVANT** : Le code AVANT doit correspondre exactement au fichier actuel
   - Si different : STOP et signaler l'ecart
2. **Appliquer APRES** : Remplacer le code AVANT par le code APRES
3. **Cocher l'etape** : Marquer comme fait dans l'issue

> **ATTENTION Issues Parasites** : Si vous voyez d'autres fichiers `docs/issues/*.md`
> dans `git status`, verifiez leur statut. Ne commitez que l'issue en cours.

### Etape 8 : Validation du code (APRES Etape 7)

Avant de continuer vers les tests, verifier rapidement :

**Checklist PowerShell (si code .ps1/.psm1 modifie) :**
- [ ] Fonctions avec `[CmdletBinding()]`
- [ ] Nommage `Verb-Noun` avec Noun singulier
- [ ] Variables explicites (pas `$data`, `$temp`, `$i`)
- [ ] `-ErrorAction Stop` dans les try-catch
- [ ] UI console avec brackets (pas emoji)

**Modules existants :**
- Verifier `Modules/` avant de creer une nouvelle fonction
- Eviter de dupliquer une fonction existante

**Checklist TDD (si fichiers .ps1/.psm1 crees) :**
- [ ] Tests nouveau code : Si fichiers .ps1/.psm1 crees, tests existent ?
- [ ] Tests passent : `Invoke-Pester -Path ./Tests` sans erreur

Si tests manquants pour nouveau code :
```
[!] Code cree sans tests :
    - [NomScript].ps1 (X fonctions)
    Creer tests : /create-test <FunctionName>
```

**Si violation detectee** : Corriger avant de continuer.

> **HORS SCOPE** : Les modules installes via `/bootstrap-project` sont deja testes.

### Etape 9 : Execution des tests (APRES Etape 8)

**BLOCKER** : Ne pas continuer si validation code a detecte des violations.

Si le projet contient des tests Pester (`Tests/` non vide) :

```powershell
Invoke-Pester -Path ./Tests -Output Detailed
```

| Resultat | Action |
|----------|--------|
| Tous passent | Continuer vers finalisation |
| Echecs | Corriger avant de continuer |
| Pas de tests et type FEAT/BUG/SEC | Warning - proposer /create-test |

---

## Phase D : Finalisation

### Etape 10 : Mise a jour issue RESOLVED (APRES Etape 9)

1. Verifier les criteres d'acceptation de l'issue
2. Modifier `docs/issues/$ARGUMENTS.md` :
   - Statut : IN_PROGRESS → RESOLVED

### Etape 11 : Commit et merge (APRES Etape 10)

**BLOCKER** : Ne pas commit si tests echouent (Etape 9).

**11.1 Verification issues parasites (OBLIGATOIRE)** :

```bash
git diff --cached --name-only | grep "docs/issues/"
```

Pour CHAQUE issue trouvee :
- Si c'est `$ARGUMENTS.md` : OK (issue en cours)
- Si c'est une AUTRE issue : Verifier son statut

**Regle** : Ne JAMAIS commiter une issue DRAFT ou OPEN sauf l'issue en cours.

Si issue non liee detectee :
```bash
git reset docs/issues/[issue-non-liee].md
```

**11.2 Commit atomique** :

```bash
git add .
git commit -m "type(scope): description

Fixes #[numero]"
```

**11.3 Merge et push** :

```bash
git checkout main
git merge [type]/$ARGUMENTS
git push origin main
git branch -d [type]/$ARGUMENTS
```

### Etape 12 : Mise a jour README (APRES Etape 11)

1. Ouvrir `docs/issues/README.md`
2. Deplacer l'issue de "A Faire" vers "Terminees"
3. Ajouter la date : `| [TYPE-XXX](...) | Titre | YYYY-MM-DD |`
4. Mettre a jour la section Progression

**Analyser les issues restantes** :
- Lister les issues avec statut DRAFT ou OPEN
- Identifier la prochaine priorite : \`!!\` > \`!\` > \`~\` > \`-\`

**Proposer la suite** :
```
=====================================
ISSUE TERMINEE : [TYPE-XXX]
=====================================

Issues restantes : [N]
Prochaine recommandee : TYPE-YYY - [Titre]
Raison : [Priorite / Effort court]

> /implement-issue TYPE-YYY
> ou /session-save puis /clear
=====================================
```

---

## Phase E : Synchronisation

### Etape 13 : Sync GitHub (APRES Etape 12)

**BLOCKER** : Verifier que push main reussi avant sync GitHub.

**13.1 Creer l'issue GitHub (si pas de #)** :

```bash
gh issue create --title "[TYPE-XXX] Titre" --body-file docs/issues/$ARGUMENTS.md
```

Capturer le numero retourne.

**13.2 Fermer l'issue GitHub** :

```bash
gh issue close [numero] --comment "Resolved in commit [hash]

Implementation complete.
See: docs/issues/$ARGUMENTS.md"
```

**13.3 Mettre a jour le fichier local** :

- GitHub Issue : #XX (si nouveau)
- Statut : RESOLVED → CLOSED
- Commit : [hash]

**13.4 Confirmation finale** :

```
=====================================
[+] ISSUE IMPLEMENTEE ET SYNCHRONISEE
=====================================
Fichier : docs/issues/$ARGUMENTS.md
GitHub  : #XX (closed)
Commit  : [hash]
=====================================
```
