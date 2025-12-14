# Git & Version Control

## .gitignore Standard

```gitignore
# ========================================
# SORTIES GENEREES
# ========================================
Output/
Logs/
Reports/
*.log
*.csv
*.xlsx
*.html

# ========================================
# TESTS
# ========================================
Tests/Coverage/
TestResults/
*.trx
coverage.xml

# ========================================
# FICHIERS TEMPORAIRES
# ========================================
*.tmp
*.temp
~$*
.temp/
*.checkpoint.json

# ========================================
# IDE ET EDITEURS
# ========================================
.vscode/
.idea/
*.swp
*.swo
*~
*.suo
*.user

# ========================================
# OS WINDOWS
# ========================================
Thumbs.db
ehthumbs.db
Desktop.ini
$RECYCLE.BIN/
*.lnk

# ========================================
# OS MACOS
# ========================================
.DS_Store
.AppleDouble
.LSOverride
._*

# ========================================
# SECRETS ET CREDENTIALS
# ========================================
*.credentials
*.secret
*.key
*.pfx
*.cer
appsettings.Development.json
Settings.json
!Settings.example.json
.env
.env.*
!.env.example

# ========================================
# SAUVEGARDES
# ========================================
*.bak
*.backup
*.old
Backups/
.backup/

# ========================================
# POWERSHELL DEBUG
# ========================================
*.pdb
*.TempPoint.ps1
*.RestorePoint.ps1

# ========================================
# DEPENDANCES
# ========================================
node_modules/
packages/

# ========================================
# CONSERVATION STRUCTURE (README.md)
# ========================================
!Output/README.md
!Logs/README.md
!Backups/README.md
!.temp/README.md
!Tests/Coverage/.gitkeep
```

## Strategie de Branches (GitHub Flow)

```
main (production stable)
  |
  +-- feature/issue-XX (developpement)
  |     |
  |     +-- Commits atomiques
  |     |
  |     +-- Merge vers main
  |
  +-- hotfix/issue-YY (correction urgente)
        |
        +-- Merge direct vers main
```

### Regles
- `main` = toujours deployable
- 1 branche = 1 issue
- Merge frequent (quotidien si possible)
- Supprimer les branches mergees

### Commandes

```bash
# Creer branche feature
git checkout main
git pull origin main
git checkout -b feature/issue-XX

# Push
git push -u origin feature/issue-XX

# Merge et nettoyage
git checkout main
git merge feature/issue-XX
git push origin main
git branch -d feature/issue-XX
git push origin --delete feature/issue-XX
```

## Commandes Git Utiles

```bash
# Status et historique
git status
git log --oneline -10
git diff

# Branches
git branch -a
git checkout -b feature/issue-XX
git branch -d feature/issue-XX

# Nettoyage
git remote prune origin
git branch --merged | grep -v main | xargs git branch -d
```

## GitHub CLI

```bash
# Issues
gh issue list
gh issue create --title "[TYPE] Description" --body "Details..."
gh issue view 42
gh issue close 42 --comment "Resolu dans commit abc123"

# Pull Requests
gh pr create --title "Fix #42" --body "Description"
gh pr list
gh pr merge 42
```

## Atomic Commits

Un commit = un changement logique. Chaque commit doit etre autonome et reversible.

```
# [+] Commits atomiques - 1 changement par commit
git commit -m "fix(auth): correct token expiration check"
git commit -m "feat(export): add CSV export for reports"
git commit -m "refactor(config): rename Settings to AppConfig"

# [-] Commit fourre-tout - plusieurs changements melanges
git commit -m "fix auth + add export + refactor config + update docs"
```

### Regles

| Regle | Exemple BON | Exemple MAUVAIS |
|-------|-------------|-----------------|
| 1 fonctionnalite = 1 commit | `feat(user): add password reset` | `feat: add reset + validation + email` |
| 1 bugfix = 1 commit | `fix(api): handle null response` | `fix: null response + timeout + retry` |
| Refactoring separe | `refactor(naming): rename vars` | Melange avec nouvelle feature |

### Avantages
- `git revert` cible uniquement le probleme
- `git bisect` trouve rapidement le commit fautif
- Historique lisible et comprehensible
- Code review plus facile

## Conventional Commits

### Format
```
type(scope): description imperative

Corps optionnel expliquant le POURQUOI.
Limite 72 caracteres par ligne.

Fixes #XX
```

### Types de commit

| Type | SemVer | Usage |
|------|--------|-------|
| `fix` | PATCH | Correction de bug |
| `feat` | MINOR | Nouvelle fonctionnalite |
| `refactor` | - | Refactoring sans changement fonctionnel |
| `perf` | PATCH | Amelioration performance |
| `test` | - | Ajout/modification de tests |
| `docs` | - | Documentation uniquement |
| `style` | - | Formatage, espaces, virgules |
| `chore` | - | Maintenance, dependances |
| `build` | - | Systeme de build, CI/CD |

### Regles
- Mode imperatif : "Add" pas "Added" ou "Adding"
- Sujet <= 50 caracteres
- Corps <= 72 caracteres/ligne
- `!` apres type = BREAKING CHANGE (ex: `feat!:`)
- **Auteur commits** : Zornot (jamais Co-Authored-By, jamais mention AI/Claude, jamais emoji)

## Rollback et Experimentation

Utiliser Git plutot que des backups locaux :

```bash
# Annuler modifications non commitees sur un fichier
git checkout -- path/to/file.ps1

# Sauvegarder travail en cours temporairement
git stash
git stash pop  # Restaurer

# Branche experimentale (exploration sans risque)
git checkout -b experiment/test-idea
# Si echec : revenir et supprimer
git checkout main
git branch -D experiment/test-idea

# Tag avant gros changement
git tag pre-refactor-v2
# Restaurer si besoin : git checkout pre-refactor-v2
```

Les checkpoints Claude Code (`Esc+Esc` ou `/rewind`) permettent aussi un rollback rapide pendant une session.
