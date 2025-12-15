---
description: Implemente une issue existante (cree branche, suit le plan, met a jour statut)
argument-hint: TYPE-XXX-titre
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Implementation d'Issue

## Etape 1 : Lecture de l'issue

Lire le fichier `docs/issues/$ARGUMENTS.md` et extraire :
- Le statut actuel (section SYNCHRONISATION GITHUB)
- Le numero GitHub (doit etre renseigne)
- Les etapes d'IMPLEMENTATION (sections AVANT/APRES)
- Les criteres d'acceptation

## Etape 2 : Verifications pre-implementation

Verifier le statut :

| Statut actuel | Action |
|---------------|--------|
| DRAFT | OK - Sync automatique a la fin |
| OPEN | OK - Continuer |
| IN_PROGRESS | WARNING - "Issue deja en cours. Continuer ?" |
| RESOLVED | STOP - "Issue deja resolue." |
| CLOSED | STOP - "Issue fermee." |

Note : Le # GitHub n'est plus requis ici. La sync se fait automatiquement a la fin.

## Etape 3 : Creation de branche

```bash
git checkout main
git pull origin main
git checkout -b feature/$ARGUMENTS
```

Si le type est BUG, utiliser `fix/$ARGUMENTS` au lieu de `feature/`.

## Etape 4 : Mise a jour de l'issue

Modifier le fichier `docs/issues/$ARGUMENTS.md` :
- Changer Statut : OPEN → IN_PROGRESS
- Renseigner Branche : feature/$ARGUMENTS (ou fix/$ARGUMENTS)

## Etape 5 : Afficher le plan

Afficher clairement pour l'utilisateur :

```
=====================================
PLAN D'IMPLEMENTATION : $ARGUMENTS
=====================================

## Etapes a realiser :
[Lister les etapes de la section IMPLEMENTATION]

## Criteres d'acceptation :
[Lister les criteres de la section VALIDATION]

## Apres implementation :
git add . && git commit -m "type(scope): description

Fixes #XX"
=====================================
```

## Etape 6 : Executer les modifications

Pour chaque etape d'IMPLEMENTATION :

1. **Verifier AVANT** : Le code AVANT doit correspondre exactement au fichier actuel
   - Si different : STOP et signaler l'ecart
2. **Appliquer APRES** : Remplacer le code AVANT par le code APRES
3. **Cocher l'etape** : Marquer comme fait dans l'issue

> **ATTENTION Issues Parasites** : Si vous voyez d'autres fichiers `docs/issues/*.md`
> dans `git status`, verifiez leur statut. Ne commitez que l'issue en cours.

## Etape 7 : Finalisation

Apres toutes les modifications :

1. **Verifier les criteres d'acceptation** avant de continuer

2. **Mettre a jour l'issue locale** (statut → RESOLVED) :
   - Modifier `docs/issues/$ARGUMENTS.md`
   - Changer Statut : IN_PROGRESS → RESOLVED
   - Ajouter Commit Resolution : [hash]

2.5. **Verification issues stagees** (OBLIGATOIRE avant commit) :

   Avant de commiter, verifier les fichiers `docs/issues/*.md` stages :

   ```bash
   git diff --cached --name-only | grep "docs/issues/"
   ```

   Pour CHAQUE issue trouvee :
   - Si c'est `$ARGUMENTS.md` : OK (issue en cours)
   - Si c'est une AUTRE issue : Verifier son statut

   **Regle** : Ne JAMAIS commiter une issue avec statut DRAFT ou OPEN
   sauf si c'est l'issue en cours d'implementation.

   Si issue non liee detectee :
   ```bash
   git reset docs/issues/[issue-non-liee].md
   ```

3. **Commit atomique** (inclut l'issue mise a jour) :
   ```bash
   git add .
   git commit -m "type(scope): description

   Fixes #[numero]"
   ```

4. **Merge et push** :
   ```bash
   git checkout main
   git merge feature/$ARGUMENTS
   git push origin main
   git branch -d feature/$ARGUMENTS
   ```

   Note: `Fixes #XX` ferme automatiquement l'issue GitHub au push.

5. **Mettre a jour l'issue locale** (statut → CLOSED) + SESSION-STATE :
   - Modifier `docs/issues/$ARGUMENTS.md` : Statut → CLOSED
   - Modifier `docs/SESSION-STATE.md` : Issue Active → Aucune
   - Mettre a jour `docs/issues/README.md` (progression)

## Etape 8 : Post-implementation

Le skill `progress-tracking` gere automatiquement :
- Mise a jour de `docs/issues/README.md` (section Issues Terminees)
- Format : `[TYPE-XXX](TYPE-XXX-*.md) | Titre | YYYY-MM-DD`

**Analyser les issues restantes** :
   - Lister les issues dans `docs/issues/` avec statut DRAFT ou OPEN
   - Identifier la prochaine priorite selon :
     - Symbole priorite : \`!!\` > \`!\` > \`~\` > \`-\`
     - Dependances (bloquee par)
     - Effort (preferer les rapides pour momentum)

3. **Proposer la suite** :
   ```
   =====================================
   ISSUE TERMINEE : [TYPE-XXX]
   =====================================

   Issues restantes : [N]
   Prochaine recommandee : TYPE-YYY - [Titre]
   Raison : [Priorite / Pas de dependance / Effort court]

   > Implementer avec : /implement-issue TYPE-YYY
   > Ou : /session-save pour sauvegarder et /clear
   =====================================
   ```

## Etape 9 : Synchronisation GitHub finale (AUTOMATIQUE)

### 9.1 Creer l'issue GitHub (si pas de #)

Si GitHub Issue = # (vide) :
```bash
gh issue create --title "[TYPE-XXX] Titre" --body-file docs/issues/$ARGUMENTS.md
```
Capturer le numero retourne et mettre a jour le fichier local.

### 9.2 Fermer l'issue GitHub

```bash
gh issue close [numero] --comment "Resolved in commit [hash]

Implementation complete.
See: docs/issues/$ARGUMENTS.md"
```

### 9.3 Mettre a jour le fichier local

- GitHub Issue : #XX (si nouveau)
- Statut : RESOLVED → CLOSED
- Commit : [hash]

### 9.4 Confirmation

```
=====================================
[+] ISSUE IMPLEMENTEE ET SYNCHRONISEE
=====================================
Fichier : docs/issues/$ARGUMENTS.md
GitHub  : #XX (closed)
Commit  : abc1234
=====================================
```
