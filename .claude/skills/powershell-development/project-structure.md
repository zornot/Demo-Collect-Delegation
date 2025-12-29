# Structure Projet PowerShell - Claude Code 2025 Native

## Principe Fondamental

Claude Code 2025 utilise des **CLAUDE.md hierarchiques** et des **slash commands** pour remplacer
la documentation traditionnelle. Le dossier `Docs/` n'est plus necessaire car les mecanismes
natifs offrent une meilleure automatisation.

---

## Arborescence Standard

```
[NomProjet]/
│
├── CLAUDE.md                    # Auto-charge par Claude Code
├── README.md                    # Documentation pour humains
├── CHANGELOG.md                 # Historique versions (Keep a Changelog)
├── LICENSE                      # Licence (MIT, Apache, etc.)
├── .gitignore                   # Fichiers ignores
│
├── .claude/                     # CONFIGURATION CLAUDE CODE
│   ├── settings.json           # Hooks PreToolUse/PostToolUse
│   ├── commands/               # Slash commands (templates)
│   ├── agents/                 # Subagents specialises
│   ├── hooks/                  # Scripts PreToolUse/PostToolUse
│   └── skills/                 # Skills avec standards detailles
│       ├── powershell-development/  # Standards PowerShell
│       ├── development-workflow/    # Git, TDD, workflow
│       ├── code-audit/              # Methodologie audit
│       ├── knowledge-verification/  # Verification temporelle
│       └── progress-tracking/       # Templates progression
│
├── audit/                       # RAPPORTS D'AUDIT
│   └── AUDIT-*.md              # Rapports d'audit AI uniquement
│
├── docs/                        # DOCUMENTATION
│   ├── issues/                 # Issues locales (workflow local-first)
│   │   ├── README.md           # Index + Roadmap
│   │   └── TYPE-XXX-*.md       # Issues individuelles
│   ├── SESSION-STATE.md
│   ├── MEMORY-GUIDE.md
│   └── CLAUDE-CODE-GUIDE.md
│
├── Modules/                     # MODULES POWERSHELL
│   └── [NomModule]/
│       ├── CLAUDE.md           # Instructions specifiques module
│       ├── [NomModule].psd1    # Manifest
│       ├── [NomModule].psm1    # Module principal
│       ├── Public/             # Fonctions exportees
│       ├── Private/            # Fonctions internes
│       └── README.md           # Documentation module
│
├── Tests/                       # TESTS PESTER
│   ├── CLAUDE.md               # Instructions tests (optionnel)
│   ├── Unit/                   # Tests unitaires
│   ├── Integration/            # Tests integration
│   ├── Fixtures/               # Donnees de test (mocks)
│   └── Coverage/               # Rapports couverture (gitignore)
│
├── Config/                      # CONFIGURATION
│   ├── README.md                # Workflow documentation
│   ├── Settings.example.json    # Template complet (versionne)
│   └── Settings.json            # Production (gitignore, genere par /bootstrap)
│
├── Scripts/                     # SCRIPTS UTILITAIRES (dev)
│   ├── Build.ps1               # Script de build
│   └── Deploy.ps1              # Script de deploiement
│
├── Logs/                        # LOGS RUNTIME (gitignore)
│   └── README.md
│
├── Output/                      # SORTIES GENEREES (gitignore)
│   └── README.md
│
└── .github/                     # GITHUB SPECIFIQUE
    ├── ISSUE_TEMPLATE/         # Templates issues GitHub
    └── workflows/              # GitHub Actions
```

---

## Scripts Utilitaires vs Scripts AI Temporaires

| Dossier | Usage | Exemples | Git |
|---------|-------|----------|-----|
| `Scripts/` | Scripts utilitaires reutilisables | Build.ps1, Deploy.ps1, helpers | Versionne |
| `.temp/` | Scripts AI jetables (debug, validation) | validate-syntax.ps1, test-*.ps1 | Ignore |

### Regles pour scripts generes par AI

**Scripts temporaires** (validation syntaxe, exploration, tests rapides) :
- Placer dans `.temp/`
- Supprimer apres usage
- Non versionnes (gitignore)

**Scripts utilitaires** (helpers, build, deploy) :
- Placer dans `Scripts/`
- Revus avant commit
- Versionnes

Ne jamais laisser de scripts temporaires AI a la racine du projet.
Utiliser systematiquement `.temp/` pour eviter les commits accidentels.

---

## CLAUDE.md Hierarchiques

Claude Code charge automatiquement les CLAUDE.md selon le contexte de travail :

| Emplacement | Chargement | Usage |
|-------------|------------|-------|
| `./CLAUDE.md` | Toujours | Instructions projet globales |
| `Modules/X/CLAUDE.md` | En contexte | Instructions specifiques module |
| `Tests/CLAUDE.md` | En contexte | Instructions tests |
| `.claude/skills/*/SKILL.md` | Auto (description) | Standards de developpement |

### Exemple CLAUDE.md de Module

```markdown
# Module [NomModule]

## Purpose
[Description courte du module]

## Key Functions
- `Get-Something` - [description]
- `Set-Something` - [description]

## Dependencies
- Module X
- Module Y

## Testing
Run tests with: `Invoke-Pester -Path ./Tests/Unit/[NomModule].Tests.ps1`
```

---

## Templates via Slash Commands

Les templates sont dans `.claude/commands/` et s'utilisent comme slash commands :

| Commande | Fichier | Description |
|----------|---------|-------------|
| `/create-script MonScript` | create-script.md | Initialise un script (architecture) |
| `/create-issue FEAT-XXX` | create-issue.md | Ajoute une fonctionnalite |
| `/review-code` | review-code.md | Review code complet |
| `/create-test FunctionName` | create-test.md | Cree tests Pester |

Cela remplace le besoin d'un dossier `Docs/Templates/`.

---

## Dossier audit/

Le dossier `audit/` contient uniquement des rapports d'audit AI :

```
audit/
├── archive/                    # Anciennes propositions
└── AUDIT-*.md                  # Rapports d'audit
```

Les issues sont dans `docs/issues/` (voir arborescence docs/ ci-dessus).

---

## Ce qui N'Existe Plus

| Ancien (`Docs/`) | Remplacant Natif | Raison |
|------------------|------------------|--------|
| `Docs/Architecture.md` | `.claude/skills/powershell-development/*.md` | Skills officiels Anthropic |
| `Docs/Templates/` | `.claude/commands/` | Slash commands actives |
| `Docs/Issues/TEMPLATE.md` | `.claude/commands/create-issue.md` | `/create-issue` |
| `Docs/Issues/ISSUES.md` | `.github/ISSUE_TEMPLATE/` | GitHub natif |
| `Docs/API/` | `Modules/*/README.md` + CLAUDE.md | Hierarchique |

---

## Regles par Dossier

| Dossier | Git | README.md |
|---------|-----|-----------|
| `.claude/` | Versionne | Optionnel |
| `audit/` | Versionne | Optionnel |
| `Modules/` | Versionne | Par module |
| `Tests/` | Versionne (sauf Coverage/) | Optionnel |
| `Config/` | `.example.json` uniquement | Optionnel |
| `Scripts/` | Versionne | Optionnel |
| `Logs/` | **Ignore** | .gitkeep |
| `Output/` | **Ignore** | .gitkeep |

---

## Convention PowerShell

> **PAS de dossier `src/`** en PowerShell.
> Le code source va dans :
> - **Script principal** : A la racine du projet
> - **Modules** : Dans `Modules/NomModule/` avec structure `Public/Private`

---

## Initialisation Nouveau Projet

```powershell
# 1. Cloner le template
git clone https://github.com/zornot/claude-code-powershell-template.git MonProjet
Set-Location ".\MonProjet"

# 2. Reinitialiser Git pour nouveau projet
Remove-Item -Path ".git" -Recurse -Force
git init

# 3. Le .gitignore est deja present (telecharge par init.ps1)

# 4. Personnaliser CLAUDE.md avec nom du projet

# 5. Premier commit
git add .
git commit -m "feat: initial project from template"
```

---

## Conservation Structure Git

Chaque dossier ignore doit contenir un README.md :

```gitignore
# .gitignore
Logs/
!Logs/README.md

Output/
!Output/README.md

Config/Settings.json
!Config/Settings.example.json
```

---

## Index des Templates

Les templates suivent deux patterns distincts :

### Pattern A : SKILL TEMPLATES

Templates techniques dans `.claude/skills/*/templates/` :

| Skill | Template | Usage |
|-------|----------|-------|
| `progress-tracking` | `ISSUES-README.md` | Format index issues avec phases |
| `progress-tracking` | `SESSION-STATE.md` | Format etat session avec handover |
| `powershell-development/ui` | `templates.md` | 6 templates scripts PowerShell |

Ces templates sont references par les commandes, pas copies directement.

### Pattern B : EXAMPLE FILES

Fichiers d'exemple a personnaliser :

| Fichier | Emplacement | Usage |
|---------|-------------|-------|
| `README.example.md` | Racine | Modele README projet |
| `ARCHITECTURE.example.md` | `docs/` | Modele documentation architecture |
| `README.example.md` | `docs/issues/` | Modele suivi issues |
| `Settings.example.json` | `Config/` | Modele configuration |

Pattern GitHub Template : fichiers a leur emplacement final, pas de centralisation.

> **Note** : `scripts/init.ps1` cree des fichiers README simplifies.
> Pour la version complete avec phases, utiliser les templates dans
> `.claude/skills/progress-tracking/templates/`.

---

## Classification Sections CLAUDE.md

Critique pour `/update-assistant` qui preserve les sections projet :

| Section | Type | Action update-assistant |
|---------|------|-------------------------|
| `# [Nom du Projet]` | **PROJET** | PRESERVER (identite) |
| `## Context` | **PROJET** | PRESERVER (Purpose, Author) |
| `## Modules` | **PROJET** | PRESERVER (genere par /bootstrap) |
| `## Project Structure` | MIXTE | Preserver Modules seulement |
| `## Slash Commands` | TEMPLATE | Mettre a jour |
| `## Agents` | TEMPLATE | Mettre a jour |
| `## Skills` | TEMPLATE | Mettre a jour |
| `## Workflow` | TEMPLATE | Mettre a jour |
| `## Session Management` | TEMPLATE | Mettre a jour |
| `## Quick Commands` | TEMPLATE | Mettre a jour |

---

## Workflow Initialisation Projet

```
~/.claude/commands/init-project.md     <- User command (pre-installe)
        |
        |-- Telecharge scripts/init.ps1 via gh api
        |-- Execute pwsh -File init.ps1
        |-- Cree structure (.claude/, Config/, Modules/, Tests/, docs/)
        '-- Prochaine etape : /bootstrap-project
        |
        v
.claude/commands/bootstrap-project.md  <- Project command (disponible)
        |
        |-- Verifie template.json
        |-- Collecte infos (nom, description, auteur)
        |-- Clone modules optionnels
        |-- Personnalise CLAUDE.md (remplace placeholders)
        '-- git init + commit
        |
        v
[Developpement normal]
        |
        v
.claude/commands/update-assistant.md   <- Sync depuis template source
        |
        |-- Copie .claude/{skills,agents,commands,hooks}
        |-- Sync docs/referentiel/
        |-- Merge settings.json
        '-- MAJ CLAUDE.md (preserve projet, update template)
```

---

## Fichiers Gitignored

| Pattern | Raison |
|---------|--------|
| `Logs/*` | Fichiers runtime |
| `Output/*` | Fichiers generes |
| `Config/Settings.json` | Contient secrets |
| `.claude/settings.local.json` | Preferences locales |
| `Tests/Coverage/` | Rapports temporaires |

Les dossiers vides conservent un `.gitkeep` pour preserver la structure Git.
