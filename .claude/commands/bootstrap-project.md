---
description: Configure un projet PowerShell apres initialisation avec /init-project
---

# /bootstrap-project

Configurer un projet PowerShell apres avoir execute /init-project.

**Prerequis** : Projet initialise avec `/init-project powershell`

## Workflow

### 1. Verifier le template

**Etape 1a** : Verifier le fichier marqueur `.claude/template.json`

```powershell
$templateFile = ".claude/template.json"
$hasTemplate = Test-Path $templateFile
```

| Condition | Action |
|-----------|--------|
| `template.json` absent | Afficher erreur et **ARRETER** |
| `template.json` present | Continuer verification fichiers |

Si absent, afficher :
```
[-] Template non trouve.

Initialisez d'abord le projet :
  /init-project powershell
```

**Etape 1b** : Verifier les fichiers critiques

Lire `template.json` et verifier chaque fichier dans `requiredFiles` :

```powershell
$template = Get-Content $templateFile | ConvertFrom-Json
$missingFiles = @()
foreach ($file in $template.requiredFiles) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
    }
}
```

| Condition | Action |
|-----------|--------|
| Tous fichiers presents | Template OK, continuer etape 2 |
| Fichiers manquants | Afficher liste et **ARRETER** |

**Etape 1c** : Verifier les outils

```powershell
git --version
```

- Git doit etre installe
- Acces internet requis (pour cloner les modules)

### 2. Collecter les informations

Demander a l'utilisateur :
- **Nom du projet** (defaut: nom du dossier courant)
- **Description courte** (1 ligne)
- **Auteur** (defaut: `git config user.name` ou "[Nom]")

### 3. Initialiser les modules

Proposer les modules disponibles avec menu interactif :

```
Modules disponibles :

[1] Write-Log     - Logging centralise compatible SIEM (recommande)
[2] ConsoleUI     - UI console avancee (bannieres, menus, barres de progression)
[3] MgConnection  - Connexion Microsoft Graph (si API Microsoft)

Quels modules installer ? (ex: 1,2 ou "all" ou "none")
> _
```

| Input | Action |
|-------|--------|
| `1` | Clone Write-Log uniquement |
| `1,2` | Clone Write-Log + ConsoleUI |
| `1,3` | Clone Write-Log + MgConnection |
| `all` | Clone les 3 modules |
| `none` | Aucun module (dossier Modules/ vide) |
| `Enter` (vide) | Defaut = `1` (Write-Log recommande) |

**URLs des modules** :

| Module | Repository |
|--------|------------|
| Write-Log | https://github.com/zornot/Module-Write-Log |
| ConsoleUI | https://github.com/zornot/Module-ConsoleUI |
| MgConnection | https://github.com/zornot/Module-MgConnection |

**Pour chaque module selectionne** :

```powershell
# Cloner le module
git clone <repo_url> Modules/<ModuleName>

# Supprimer le .git du module (copie, pas submodule)
Remove-Item -Recurse -Force "Modules/<ModuleName>/.git"
```

### 4. Personnaliser CLAUDE.md

Remplacer les placeholders dans CLAUDE.md :
- `[Nom du Projet]` -> Nom du projet saisi
- `[Description courte du projet]` -> Description saisie
- `[Nom]` -> Auteur saisi

### 5. Creer le script principal

Creer `Script.ps1` avec le contenu suivant (remplacer les placeholders) :

```powershell
#Requires -Version 7.2
<#
.SYNOPSIS
    {{PROJECT_DESCRIPTION}}
.DESCRIPTION
    Script principal du projet {{PROJECT_NAME}}.
.NOTES
    Author: {{AUTHOR_NAME}}
    Date: {{DATE}}
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# TODO: Implementer la logique principale
Write-Host "[i] " -NoNewline -ForegroundColor Cyan
Write-Host "{{PROJECT_NAME}} - Script principal"
```

### 6. Creer SESSION-STATE.md vide

Creer `docs/SESSION-STATE.md` avec le template initial :

```markdown
# Etat de Session - {{DATE}}

## Tache en Cours

Aucune tache en cours.

## Progression

- [ ] Configuration initiale du projet

## Decisions Cles

| Decision | Justification |
|----------|---------------|

## Fichiers Modifies

| Fichier | Modification |
|---------|--------------|

## Prochaines Etapes

1. **Immediat** : Personnaliser CLAUDE.md si besoin
2. **Ensuite** : Implementer Script.ps1
3. **Plus tard** : Ajouter des fonctions avec /create-function
```

### 7. Reinitialiser Git

```powershell
git init
git add .
git commit -m "chore: initial project setup from powershell-template"
```

### 8. Afficher le resume

Afficher :

```
[+] Projet configure : {{PROJECT_NAME}} (PowerShell)

Structure :
  .claude/           (commands, agents, skills, hooks)
  Config/            (configuration runtime)
  Modules/           (modules PowerShell)
  Tests/             (tests Pester)
  docs/              (SESSION-STATE.md, issues/)
  CLAUDE.md          (personnalise)
  .gitignore
  Script.ps1         (script principal)

Modules installes :
  {{LISTE_MODULES}}

Commandes disponibles :
  /create-script     Creer un nouveau script
  /create-function   Creer une fonction
  /create-test       Creer des tests Pester
  /run-tests         Executer les tests
  /review-code       Review code PowerShell
  /audit-code        Audit complet 6 phases

Prochaines etapes :
  1. Personnaliser CLAUDE.md si besoin
  2. Implementer Script.ps1
  3. /create-function Verb-Noun pour ajouter des fonctions
```
