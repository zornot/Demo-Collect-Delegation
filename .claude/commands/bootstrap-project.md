---
description: Configure un projet PowerShell apres initialisation avec /init-project
---

# /bootstrap-project

Configurer un projet PowerShell apres avoir execute /init-project.

**Prerequis** : Projet initialise avec `/init-project powershell`

---

## Phase A : Verification et Collecte

### Etape 1 : Verifier le template

**1.1** : Verifier le fichier marqueur `.claude/template.json`

```powershell
$templateFile = ".claude/template.json"
$hasTemplate = Test-Path $templateFile
```

| Condition | Action |
|-----------|--------|
| `template.json` absent | Afficher erreur et **ARRETER** |
| `template.json` present | Continuer verification fichiers |

**BLOCKER** : Si template.json absent, afficher et ARRETER :
```
[-] Template non trouve.

Initialisez d'abord le projet :
  /init-project powershell
```

**1.2** : Verifier les fichiers critiques

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

**1.3** : Verifier les outils

```powershell
git --version
```

- Git doit etre installe
- Acces internet requis (pour cloner les modules)

### Etape 2 : Collecter les informations (APRES Etape 1)

Demander a l'utilisateur :
- **Nom du projet** (defaut: nom du dossier courant)
- **Description courte** (1 ligne)
- **Auteur** (defaut: `git config user.name` ou "[Nom]")

**BLOCKER** : Ne pas continuer si nom projet vide ou non fourni.

---

## Phase B : Installation et Configuration

### Etape 3 : Initialiser les modules (APRES Etape 2)

**Table des modules disponibles** (REFERENCE UNIQUE) :

| # | Module | Repository | Description |
|---|--------|------------|-------------|
| 1 | Write-Log | `https://github.com/zornot/Module-Write-Log` | Logging SIEM (recommande) |
| 2 | ConsoleUI | `https://github.com/zornot/Module-ConsoleUI` | UI console avancee |
| 3 | GraphConnection | `https://github.com/zornot/Module-GraphConnection` | Microsoft Graph API |
| 4 | EXOConnection | `https://github.com/zornot/Module-EXOConnection` | Exchange Online API |
| 5 | Checkpoint | `https://github.com/zornot/Module-Checkpoint` | Reprise apres interruption |

**Format** : Tous les modules utilisent le format standard `Module/` avec Settings.example.json integre.

**Afficher le menu** :
```
Modules disponibles :

[1] Write-Log        - Logging SIEM (recommande)
[2] ConsoleUI        - UI console avancee
[3] GraphConnection  - Microsoft Graph API
[4] EXOConnection    - Exchange Online API
[5] Checkpoint       - Reprise apres interruption

Quels modules installer ? (ex: 1,2,4 ou "all" ou "none")
> _
```

**Interpreter la reponse** :

| Input | Action |
|-------|--------|
| Numeros (ex: `1,2,4`) | Cloner les modules correspondants dans la table ci-dessus |
| `all` | Cloner TOUS les modules de la table (1 a 5) |
| `none` | Aucun module (dossier Modules/ vide) |
| `Enter` (vide) | Defaut = module 1 (Write-Log) |

**BLOCKER** : Si modules selectionnes (pas "none"), verifier acces internet avant clonage.

**Pour CHAQUE module selectionne, utiliser l'URL de la table** :

```powershell
# Cloner le module temporairement
git clone <repo_url> ".temp-module"

$moduleName = "<ModuleName>"
$sourceModule = ".temp-module/Module"  # Nouveau format standard
$destModule = "Modules/$moduleName"

# Creer le dossier destination
New-Item -Path $destModule -ItemType Directory -Force

# Copier les fichiers essentiels (nouveau format)
$essentialFiles = @("*.psd1", "*.psm1", "CLAUDE.md", "README.md", "Settings.example.json")
foreach ($pattern in $essentialFiles) {
    $files = Get-ChildItem -Path $sourceModule -Filter $pattern -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        Copy-Item -Path $file.FullName -Destination $destModule
    }
}

# Supprimer le clone temporaire
Remove-Item -Recurse -Force ".temp-module"
```

> **Fichiers copies** : `.psd1`, `.psm1`, `CLAUDE.md`, `README.md`, `Settings.example.json`
> Les `.claude/`, `audit/`, `docs/`, `Tests/`, `Config/`, `Examples/` du repo source sont exclus.

### Etape 4 : Generer Settings.json (APRES Etape 3)

Apres avoir installe les modules, generer `Config/Settings.json` :

**Logique de generation** :

1. **Sections BASE** (toujours incluses) :
   - `Application` : Avec nom/description saisis
   - `Paths` : Chemins standards
   - `Retention` : Valeurs par defaut

2. **Sections MODULES** (selon selection) :

| Module installe | Section(s) ajoutees |
|-----------------|---------------------|
| Write-Log | (aucune - utilise Initialize-Log) |
| ConsoleUI | (aucune - module UI) |
| GraphConnection | `GraphConnection` |
| EXOConnection | (aucune - utilise parametres directs) |
| Checkpoint | `Checkpoint` |

> **Note** : Seuls GraphConnection et Checkpoint ont des Settings.example.json avec configuration.
> Les autres modules documentent leur usage sans necessiter de configuration.

3. **Personnalisation** :
   - Remplacer `[NomProjet]` par nom saisi
   - Remplacer `[Description]` par description saisie
   - Supprimer les `_section_*` (commentaires)
   - Supprimer les `_comment`, `_version`, `_generatedBy`

**Workflow de fusion** :

```powershell
# Initialiser avec les sections BASE
$settings = @{
    Application = @{
        Name = "{{PROJECT_NAME}}"
        Description = "{{PROJECT_DESCRIPTION}}"
        Environment = "DEV"
        LogLevel = "Info"
    }
    Paths = @{
        Logs = "./Logs"
        Output = "./Output"
        Checkpoints = "./Checkpoints"
        Temp = "./.temp"
    }
    Retention = @{
        LogDays = 30
        OutputDays = 7
        CheckpointDays = 7
    }
}

# Pour CHAQUE module installe, fusionner son Settings.example.json
$installedModules = Get-ChildItem -Path "Modules" -Directory
foreach ($module in $installedModules) {
    $settingsFile = Join-Path $module.FullName "Settings.example.json"

    if (Test-Path $settingsFile) {
        $moduleSettings = Get-Content $settingsFile -Raw | ConvertFrom-Json

        # Fusionner chaque section (sauf meta-donnees _*)
        foreach ($prop in $moduleSettings.PSObject.Properties) {
            if ($prop.Name -notmatch '^_') {
                if (-not $settings.ContainsKey($prop.Name)) {
                    $settings[$prop.Name] = $prop.Value
                    Write-Host "[+] Section '$($prop.Name)' ajoutee ($($module.Name))"
                }
            }
        }
    }
}

# Sauvegarder
$settings | ConvertTo-Json -Depth 10 | Set-Content "Config/Settings.json" -Encoding UTF8
```

**Exemple** : Modules GraphConnection + Checkpoint selectionnes

```json
{
    "Application": {
        "Name": "MonSuperProjet",
        "Description": "Outil de gestion automatisee",
        "Environment": "DEV",
        "LogLevel": "Info"
    },
    "Paths": {
        "Logs": "./Logs",
        "Output": "./Output",
        "Checkpoints": "./Checkpoints",
        "Temp": "./.temp"
    },
    "Retention": {
        "LogDays": 30,
        "OutputDays": 7,
        "CheckpointDays": 7
    },
    "GraphConnection": {
        "clientId": "00000000-0000-0000-0000-000000000000",
        "tenantId": "00000000-0000-0000-0000-000000000000",
        "defaultScopes": ["User.Read"],
        "maxRetries": 3,
        "retryDelaySeconds": 5,
        "autoDisconnect": true
    },
    "Checkpoint": {
        "KeyProperty": "Id",
        "Interval": 50,
        "MaxAgeHours": 24
    }
}
```

**Afficher** :
```
[+] Config/Settings.json genere :
    Base : Application, Paths, Retention
    + GraphConnection (Microsoft Graph)
    + Checkpoint (reprise)
```

**BLOCKER** : Ne pas continuer si Settings.json non genere (erreur ecriture ou modules non installes).

> **CHECKPOINT** : A ce stade, verifier :
> - [ ] Modules installes dans Modules/
> - [ ] Settings.json genere dans Config/
>
> SI erreur : corriger avant de continuer.

---

## Phase C : Personnalisation

### Etape 5 : Personnaliser CLAUDE.md (APRES Etape 4)

Remplacer les placeholders dans CLAUDE.md :
- `[Nom du Projet]` -> Nom du projet saisi
- `[Description courte du projet]` -> Description saisie
- `[Nom]` -> Auteur saisi

**Ajouter section Modules** (remplacer `<!-- MODULES_SECTION_PLACEHOLDER -->`) :

Pour CHAQUE module installe, generer la section suivante :

```markdown
## Modules

See @Modules/<ModuleName>/CLAUDE.md for <description>
[... repeter pour chaque module ...]

### Import Pattern

```powershell
#region Modules
$modulePath = "$PSScriptRoot\Modules"
Import-Module "$modulePath\<ModuleName>\<ModuleName>.psd1" -Force -ErrorAction Stop
[... repeter pour chaque module ...]
#endregion
```
```

**Exemple** avec ConsoleUI et Checkpoint :

```markdown
## Modules

See @Modules/ConsoleUI/CLAUDE.md for UI console avancee
See @Modules/Checkpoint/CLAUDE.md for reprise apres interruption

### Import Pattern

```powershell
#region Modules
$modulePath = "$PSScriptRoot\Modules"
Import-Module "$modulePath\ConsoleUI\ConsoleUI.psd1" -Force -ErrorAction Stop
Import-Module "$modulePath\Checkpoint\Checkpoint.psd1" -Force -ErrorAction Stop
#endregion
```
```

Si aucun module installe (`none`), supprimer le placeholder sans rien ajouter.

### Etape 6 : Creer le script principal (APRES Etape 5)

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

### Etape 7 : Creer SESSION-STATE.md (APRES Etape 6)

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
3. **Plus tard** : Ajouter des fonctionnalites avec /create-issue → /implement-issue
```

---

## Phase D : Finalisation

### Etape 8 : Reinitialiser Git (APRES Etape 7)

**BLOCKER** : Verifier que tous les fichiers critiques sont crees avant git init :
- [ ] CLAUDE.md personnalise
- [ ] Config/Settings.json genere
- [ ] Script.ps1 cree
- [ ] docs/SESSION-STATE.md cree

```powershell
git init
git add .
git commit -m "chore: initial project setup from powershell-template"
```

### Etape 9 : Afficher le resume (APRES Etape 8)

Afficher :

```
[+] Projet configure : {{PROJECT_NAME}} (PowerShell)

Structure :
  .claude/           (commands, agents, skills, hooks)
  Config/            (Settings.json genere selon modules)
  Modules/           (modules PowerShell)
  Tests/             (tests Pester)
  docs/              (SESSION-STATE.md, issues/)
  CLAUDE.md          (personnalise)
  .gitignore
  Script.ps1         (script principal)

Modules installes :
  {{LISTE_MODULES}}

Commandes disponibles :
  /create-script     Initialiser un script (architecture complete)
  /create-test       Creer des tests Pester
  /run-tests         Executer les tests
  /review-code       Review code PowerShell
  /audit-code        Audit complet 6 phases
  /analyze-bug       Analyse bug avec recherche

Prochaines etapes :
  1. Personnaliser CLAUDE.md si besoin
  2. Implementer Script.ps1
  3. Pour ajouter des fonctionnalites : /create-issue FEAT-XXX
```
