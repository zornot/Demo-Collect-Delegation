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
│   ├── skills/                 # Skills contextuels
│   └── rules/                  # Regles detaillees
│       └── *.md               # Ref via @.claude/rules/fichier.md
│
├── audit/                       # RAPPORTS ET ISSUES
│   ├── issues/                 # Issues locales (workflow local-first)
│   │   └── ISSUE-XXX-titre.md # Issues individuelles
│   └── *.md                    # Rapports d'audit AI
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
│   ├── Settings.example.json   # Template (versionne)
│   └── Settings.json           # Production (gitignore)
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
| `.claude/rules/RULES.md` | Reference | Regles de developpement |

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
| `/project:create-script MonScript` | create-script.md | Cree un script complet |
| `/project:create-function Get-User` | create-function.md | Cree une fonction Verb-Noun |
| `/project:create-issue BUG-001` | create-issue.md | Cree une issue locale |
| `/project:review-code` | review-code.md | Review code complet |
| `/project:create-test FunctionName` | create-test.md | Cree tests Pester |

Cela remplace le besoin d'un dossier `Docs/Templates/`.

---

## Dossier audit/ (remplace Docs/)

Le dossier `audit/` contient uniquement :
- **Issues locales** : Workflow local-first avant GitHub
- **Rapports d'audit** : Analyses AI, reviews
- **Documents d'analyse** : ANALYSIS-*.md

```
audit/
├── issues/
│   ├── ISSUE-001-fix-validation.md
│   └── ISSUE-002-add-export.md
├── AUDIT-2025-12-04.md
└── ANALYSIS-PERFORMANCE.md
```

Les issues sont creees via `/project:create-issue`.

---

## Ce qui N'Existe Plus

| Ancien (`Docs/`) | Remplacant Natif | Raison |
|------------------|------------------|--------|
| `Docs/Architecture.md` | `.claude/rules/powershell/*.md` | Auto-reference via @.claude/rules/ |
| `Docs/Templates/` | `.claude/commands/` | Slash commands actives |
| `Docs/Issues/TEMPLATE.md` | `.claude/commands/create-issue.md` | `/project:create-issue` |
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

# 3. Configurer le .gitignore
Copy-Item "gitignore.template" ".gitignore"

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
