---
description: Initialise un nouveau script PowerShell avec architecture complete
argument-hint: NomScript
allowed-tools: Read, Write, Glob, Bash
---

Initialiser un script PowerShell nomme `$ARGUMENTS.ps1` avec une architecture complete.

## Usage

Cette commande est pour **l'initialisation** d'un nouveau script :
- Point de depart solide avec tous les standards
- Architecture reflechie des le debut
- Une seule fois par script

Apres initialisation, toute evolution passe par le workflow issue :
```
/create-issue FEAT-XXX → /implement-issue FEAT-XXX
```

---

## Phase A : Analyse Prealable

### Etape 1 : Comprendre le besoin

Avant de coder, clarifier avec l'utilisateur :
- **Objectif** : Quel probleme ce script resout-il ?
- **Inputs** : Quelles donnees en entree ?
- **Outputs** : Quelles donnees en sortie ? → Utiliser `$Settings.Paths.Output` (voir config.md)
- **Dependances** : Quels modules/APIs necessaires ?

### Etape 2 : Utiliser les modules existants (APRES Etape 1)

**2.1** Lister les modules installes

```powershell
Get-ChildItem -Path ".\Modules" -Directory
```

**2.2** Pour CHAQUE module, lire son `README.md`

Les README des modules sont la source de verite pour les fonctions disponibles.

**2.3** Appliquer le pattern Prefer

| Besoin | Prefer (utiliser) | Reference |
|--------|-------------------|-----------|
| Banniere, Box, UI | Module ConsoleUI | `Modules/ConsoleUI/README.md` |
| Logging structure | Module Write-Log | `Modules/Write-Log/README.md` |
| Connexion Graph | Module GraphConnection | `Modules/GraphConnection/README.md` |
| Connexion Exchange | Module EXOConnection | `Modules/EXOConnection/README.md` |
| Checkpoint/Resume | Module Checkpoint | `Modules/Checkpoint/README.md` |

**Avoid** (si le module correspondant est present) :
- Avoid recreating UI functions → use ConsoleUI
- Avoid custom logging → use Write-Log
- Avoid custom connection logic → use *Connection modules
- Avoid repetition → reuse existing utilities

**Import** : Si un module est utilise, l'importer dans `#region Modules` :

```powershell
$modulePath = "$PSScriptRoot\Modules"
Import-Module "$modulePath\ConsoleUI\ConsoleUI.psm1" -ErrorAction Stop
```

> **Reference** : Voir CLAUDE-CODE-GUIDE.md section 25 pour les patterns complets.

### Etape 3 : Synchroniser Settings.json (APRES Etape 2)

#### Principe

Chaque module peut declarer ses besoins de configuration dans son `CLAUDE.md`
(section "Configuration Requise"). Cette etape decouvre dynamiquement ces besoins
et synchronise `Settings.json`.

#### Workflow

**3.1** Lister les modules dans `Modules/`

```powershell
Get-ChildItem -Path "Modules" -Directory | Select-Object -ExpandProperty Name
```

**3.2** Identifier les modules utilises par le script

Demander a l'utilisateur ou deduire des specs. Pour chaque module identifie,
lire son `CLAUDE.md` pour verifier s'il a des besoins de configuration.

**3.3** Pour CHAQUE module utilise, lire son CLAUDE.md

```
Modules/[Module]/CLAUDE.md
└─> Section "## Configuration Requise"
    └─> Extraire : section, template JSON, obligatoire
```

Si le module n'a pas de section "Configuration Requise", il n'a pas de besoins
de configuration centralises (pas d'action requise).

**3.4** Synchroniser Settings.json

| Condition | Action |
|-----------|--------|
| Settings.json absent | Creer depuis Settings.example.json |
| Section requise absente | Ajouter depuis template du module |
| Section existe deja | Conserver (pas d'ecrasement) |

**3.5** Afficher le resultat

```
[+] Config/Settings.json synchronise :
    + GraphConnection (Microsoft Graph)
    + Checkpoint (reprise)
    ✓ Paths (base)
```

**BLOCKER** : Ne pas continuer si Settings.json n'est pas pret.
Un script sans configuration valide echouera au runtime.
Voir Reference 7 (`config.md`) pour les details.

### Etape 4 : Convention des sorties (APRES Etape 3)

Si le script genere des fichiers (rapports, exports, CSV, JSON) :

**Regle** : Toujours utiliser `$Settings.Paths.Output`, jamais de chemin hardcode.

```powershell
# [-] INCORRECT
$reportPath = "$env:USERPROFILE\Desktop\rapport.csv"
$reportPath = "C:\Temp\export.json"

# [+] CORRECT
$outputPath = $Settings.Paths.Output
$reportPath = Join-Path $outputPath "rapport_$(Get-Date -Format 'yyyyMMdd').csv"
```

**Verification** : S'assurer que `Paths.Output` existe dans Settings.json :

```json
"Paths": {
    "Output": "./Output"
}
```

> **Reference** : `.claude/skills/powershell-development/config.md` et `project-structure.md` (ligne 73).

---

## Phase B : Verification des Connaissances

### Etape 5 : Charger les references (APRES Etape 4)

Lire ces fichiers d'abord :
1. `.claude/skills/powershell-development/SKILL.md` - Standards PowerShell
2. `.claude/skills/powershell-development/project-modules.md` - Modules du projet
3. `.claude/skills/powershell-development/ui/templates.md` - Template de script
4. `.claude/skills/powershell-development/naming.md` - Conventions de nommage
5. `.claude/skills/powershell-development/logging.md` - Configuration du logging
6. `.claude/skills/powershell-development/patterns.md` - Patterns de construction (Structured Result, Fallback, Throttle, Validation)
7. `.claude/skills/powershell-development/config.md` - Gestion Config/Settings.json (OBLIGATOIRE pour parametres)

### Etape 6 : Extraire les elements techniques (APRES Etape 5)

Si le script utilise des APIs ou modules externes :

| Categorie | Quoi extraire |
|-----------|---------------|
| **Sorties** | Chaque colonne/champ de sortie demande |
| **Entrees** | Chaque parametre demande |
| **Comportements** | Chaque fonctionnalite demandee |
| **Sources** | Chaque API/cmdlet/service externe |

### Etape 7 : Evaluer le niveau de confiance (APRES Etape 6)

Lire `.claude/skills/knowledge-verification/SKILL.md` puis evaluer CHAQUE technologie.

**BLOCKER** : Afficher OBLIGATOIREMENT le tableau d'evaluation.

```
=====================================
[i] EVALUATION DES CONNAISSANCES
=====================================
| Technologie | Confiance | Risque | Decision |
|-------------|-----------|--------|----------|
| [API/Module] | X/10 | [Eleve/Moyen/Faible] | [Recherche/OK] |
=====================================
```

### Etape 8 : Invoquer @tech-researcher si necessaire (APRES Etape 7)

Si au moins une ligne a "Recherche" dans Decision :

1. **Afficher** : `[i] Invocation de l'agent tech-researcher...`
2. **Invoquer** @tech-researcher avec :
```
Elements a verifier individuellement :
- [Element 1] : Quelle cmdlet/API ? Quelle propriete exacte ?
- [Element 2] : Existe nativement ? Alternative ?
- [Element N] : ...

Pour CHAQUE element, confirmer :
- Faisabilite (oui/non/partiel)
- Source exacte (cmdlet, propriete, methode)
- Limitations connues
```

3. **Attendre les resultats** : Ne pas ecrire de code avant d'avoir valide tous les elements.
   Une recherche globale ("Exchange Online") ne suffit pas - chaque element doit etre verifie.

### Etape 9 : Afficher les fonctionnalites enrichies (APRES Etape 8)

Apres retour de @tech-researcher, **OBLIGATOIRE** :

1. **Consolider** les decouvertes avec les specs initiales
2. **Afficher** la liste complete enrichie :

```
=====================================
[+] FONCTIONNALITES ENRICHIES
=====================================
Specs initiales : X elements
Enrichissement  : +Y elements (tech-researcher)
Total           : Z fonctionnalites

Liste complete :
1. [Fonctionnalite] - [Source: spec/enrichi]
2. [Fonctionnalite] - [Source: spec/enrichi]
...
=====================================
```

3. **Valider avec l'utilisateur** avant de continuer

> **Pourquoi ?** Les specs utilisateur sont souvent incompletes.
> L'enrichissement ajoute des elements techniques necessaires (connexion, gestion erreurs, formats).

---

## Phase C : Tracking et Implementation

### Etape 10 : Tracker les fonctionnalites avec TodoWrite (APRES Etape 9)

**BLOCKER** : Si @tech-researcher a ete invoque, la liste enrichie (Etape 9) doit etre affichee AVANT cette etape.

Lister TOUTES les fonctionnalites (specs + enrichissement) avec TodoWrite :

| Categorie | Quoi extraire |
|-----------|---------------|
| **Sorties** | Colonnes, fichiers, formats |
| **Entrees** | Parametres, options |
| **Comportements** | Features, modes, filtres |
| **Robustesse** | Gestion erreurs, reprise, logging |

Afficher la checklist a l'utilisateur avant de coder.

### Etape 11 : Implementer le script (APRES Etape 10)

**BLOCKER** : Ne pas coder si TodoWrite non complete.

Pour chaque fonctionnalite :
1. Marquer `in_progress`
2. Implementer
3. Marquer `completed`

**Template du script** :

```powershell
#Requires -Version 7.2

<#
.SYNOPSIS
    [Description claire du script]
.DESCRIPTION
    [Description detaillee incluant architecture]
.PARAMETER NomParam
    [Description du parametre]
.EXAMPLE
    .\$ARGUMENTS.ps1 -Param "valeur"
.NOTES
    Author: [Auteur]
    Version: 1.0.0
    Dependencies: [Liste modules]
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "$PSScriptRoot\Config\Settings.json"
)

#region Configuration
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$script:Version = "1.0.0"
$script:ScriptName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)
#endregion

#region Modules
$modulePath = "$PSScriptRoot\Modules"
# Importer les modules necessaires (adapter selon besoins)
# Import-Module "$modulePath\Write-Log\Write-Log.psm1" -Force -ErrorAction Stop
#endregion

#region Functions
# Fonctions privees du script (si necessaire)
#endregion

#region Main
try {
    Write-Host "[i] $script:ScriptName v$script:Version" -ForegroundColor Cyan

    # Charger configuration (si sorties fichiers)
    # $settings = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    # $outputPath = $settings.Paths.Output

    # Votre logique principale ici

    Write-Host "[+] Script termine avec succes" -ForegroundColor Green
    exit 0
}
catch {
    Write-Host "[-] Erreur: $($_.Exception.Message)" -ForegroundColor Red
    throw
}
#endregion
```

---

## Phase D : Validation

### Etape 12 : Valider la syntaxe (APRES Etape 11)

**BLOCKER** : Ne pas terminer si syntaxe invalide.

```powershell
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile("$ARGUMENTS.ps1", [ref]$null, [ref]$errors)
if ($errors) { $errors | ForEach-Object { Write-Host "[-] $($_.Message)" } }
else { Write-Host "[+] Syntaxe valide" }
```

### Etape 13 : Verification TDD (APRES Etape 12)

Detecter les fonctions du script :

1. Scanner toutes les fonctions du script (pattern `function\s+\w+-\w+`)
2. Si fonctions trouvees, afficher :
   ```
   [i] Fonctions detectees dans [Script].ps1 :
       - Get-Config
       - Test-Prerequisites
       Creer tests : /create-test <FunctionName>
   ```
3. Rappeler : "Tests recommandes AVANT implementation complete (TDD)"

**HORS SCOPE** : Les modules installes via `/bootstrap-project` sont deja testes dans leurs repos sources.

### Etape 14 : Checklist finale (APRES Etape 13)

Valider que 100% des fonctionnalites sont completees avant de terminer.
Si < 100%, implementer les manquantes.

**Checklist** :

- [ ] Besoin clarifie avec utilisateur (objectif, I/O, dependances)
- [ ] Modules existants verifies (pas de duplication)
- [ ] **Settings.json synchronise** avec sections requises par les modules
- [ ] `#Requires -Version 7.2`
- [ ] `[CmdletBinding()]` avec parametres documentes
- [ ] `$ErrorActionPreference = 'Stop'`
- [ ] Encodage UTF-8
- [ ] try-catch avec `-ErrorAction Stop`
- [ ] Brackets [+][-][!][i][>] (pas d'emoji)
- [ ] Noms de variables explicites
- [ ] .SYNOPSIS, .DESCRIPTION, .EXAMPLE, .NOTES complets

**Prochaine evolution** : Utiliser le workflow issue
```
/create-issue FEAT-XXX-ajouter-fonctionnalite → /implement-issue
```
