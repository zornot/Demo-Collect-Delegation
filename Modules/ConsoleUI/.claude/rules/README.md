# PowerShell Rules - Referentiel Claude Code 2025

> Standards de developpement PowerShell optimises pour Claude Code et les agents IA.
> **Ce referentiel remplace le traditionnel `CONTRIBUTING.md`** pour les projets utilisant Claude Code.

## Objectif

Ce referentiel definit les regles de contribution pour les agents AI (Claude Code).
Il est concu pour etre copie dans chaque projet PowerShell.

| Ancien modele | Ce referentiel |
|---------------|----------------|
| `CONTRIBUTING.md` (pour humains) | `CLAUDE.md` + `.claude/` (pour AI) |
| Guide verbeux, explicatif | Regles concises, declaratives |
| Un seul fichier volumineux | Modulaire + hooks + commands |

---

## Structure du Referentiel

```
.claude/
├── settings.json               # Hooks de validation (GIT VERSIONNE)
├── settings.local.json         # Preferences locales (GITIGNORE)
│
├── commands/                   # Slash commands personnalisees
│   ├── create-script.md       # /project:create-script MonScript
│   ├── create-function.md     # /project:create-function Get-User
│   ├── create-test.md         # /project:create-test FunctionName
│   ├── create-issue.md        # /project:create-issue BUG-001
│   ├── run-tests.md           # /project:run-tests
│   └── review-code.md         # /project:review-code
│
├── agents/                     # Subagents specialises
│   ├── code-reviewer.md       # Review code PowerShell
│   ├── test-writer.md         # Ecriture tests Pester (TDD)
│   ├── context-explorer.md    # Exploration codebase
│   ├── session-summarizer.md  # Resume session avant /clear
│   └── security-auditor.md    # Audit securite
│
├── skills/                     # Skills contextuels
│   └── powershell-standards/  # Standards PowerShell
│
└── rules/                      # Regles detaillees (~20 fichiers)
    ├── RULES.md               # Point d'entree regles
    ├── README.md              # Ce fichier
    ├── ui-*.md                # UI (symbols, functions, templates)
    ├── ps-*.md                # PowerShell (naming, errors, etc.)
    └── ...
```

---

## Fonctionnalites Claude Code 2025

### Hooks (Validation Automatique)

Les hooks se declenchent automatiquement sur chaque Write/Edit de fichiers .ps1 :

| Hook | Event | Action |
|------|-------|--------|
| `validate-syntax.ps1` | PreToolUse | Bloque: noms interdits, emoji, @()+=, syntaxe |
| `post-analyze-code.ps1` | PostToolUse | Execute PSScriptAnalyzer (non-bloquant) |

**Violations bloquees :**
- Variables interdites : `$data`, `$temp`, `$i`, `$obj`, `$result`
- Emoji dans les messages (utiliser `[+][-][!]`)
- Pattern `@() +=` (utiliser `List<T>`)
- Erreurs de syntaxe PowerShell

### Slash Commands

| Commande | Description |
|----------|-------------|
| `/project:create-script MonScript` | Cree un script selon les standards |
| `/project:create-function Get-User` | Cree une fonction Verb-Noun |
| `/project:create-issue BUG-001` | Cree une issue locale dans audit/issues/ |
| `/project:create-test FunctionName` | Cree tests Pester pour une fonction (TDD RED) |
| `/project:run-tests` | Execute tous les tests |
| `/project:review-code` | Review du code contre TOUS les standards |

### Subagents

| Agent | Usage |
|-------|-------|
| `@code-reviewer` | Review specialise contre ps-*.md |
| `@test-writer` | Ecrit tests TDD (phase RED) |

---

## Installation

### Dans un nouveau projet PowerShell

```powershell
# Cloner le template
git clone https://github.com/zornot/claude-code-powershell-template.git MonProjet
cd MonProjet

# Reinitialiser Git pour nouveau projet
Remove-Item -Path ".git" -Recurse -Force
git init

# Configurer le .gitignore
Copy-Item "gitignore.template" ".gitignore"
```

### Structure resultante

```
MonProjet/
├── CLAUDE.md
├── README.md
├── CHANGELOG.md
├── .gitignore
├── .claude/
│   ├── settings.json
│   ├── commands/
│   ├── agents/
│   └── rules/
├── Modules/
├── Tests/
└── Config/
```

---

## Regles Critiques

### 1. CLAUDE.md < 150 lignes

| Limite | Raison |
|--------|--------|
| ~100-150 lignes | Zone optimale selon Anthropic |
| Details dans .claude/rules/*.md | Reference via @.claude/rules/fichier.md |

### 2. Style Opus 4.5

Claude Opus 4.5 est sensible aux instructions. Eviter l'emphase aggressive :

```markdown
# Eviter
YOU MUST use -ErrorAction Stop
NEVER omit CmdletBinding

# Preferer
Use -ErrorAction Stop on cmdlets in try-catch blocks, because
non-terminating errors are silently ignored otherwise.
```

### 3. Symboles UI : Brackets ASCII

| Bracket | Couleur | Usage |
|---------|---------|-------|
| `[+]` | Green | Succes |
| `[-]` | Red | Erreur |
| `[!]` | Yellow | Warning |
| `[i]` | Cyan | Info |
| `[>]` | White | Action |
| `[?]` | DarkGray | WhatIf |

Box drawing Unicode (`┌─┐│└─┘`) uniquement pour les bannieres.
**Jamais d'emoji** (inconsistent en terminal/logs).

### 4. Conventions de Nommage .claude/

#### Commands : `[verbe]-[cible].md`

| Verbe | Usage |
|-------|-------|
| `create` | Creer un nouveau fichier/element |
| `run` | Executer une action |
| `review` | Analyser/verifier du code |
| `check` | Validation rapide |

Exemples : `create-script.md`, `create-function.md`, `run-tests.md`, `review-code.md`

#### Agents : `[domaine]-[role].md`

| Domaine | Expertise |
|---------|-----------|
| `code` | Code source, logique metier |
| `test` | Tests unitaires, integration |
| `security` | Securite, vulnerabilites |

| Role | Action |
|------|--------|
| `reviewer` | Analyse et critique |
| `writer` | Creation de contenu |
| `analyzer` | Analyse approfondie |

Exemples : `code-reviewer.md`, `test-writer.md`, `security-analyzer.md`

#### Hooks : `[timing?]-[verbe]-[cible].ps1`

| Timing | Event |
|--------|-------|
| (absent) | PreToolUse (defaut) |
| `post` | PostToolUse |

| Verbe | Usage |
|-------|-------|
| `validate` | Verification bloquante |
| `analyze` | Analyse approfondie |
| `check` | Verification non-bloquante |

Exemples : `validate-syntax.ps1`, `post-analyze-code.ps1`

#### Regles Generales

- **kebab-case** : Tous les noms de fichiers
- **Pas de prefixes** : Pas de `cmd-`, `ag-`, `hk-`
- **Anglais** : Noms en anglais (coherence communaute)
- **Singulier** : `create-test` pas `create-tests`

---

## Utilisation des Hooks

### Configuration settings.json

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [{ "type": "command", "command": "pwsh ... validate-syntax.ps1" }]
      }
    ]
  }
}
```

### Codes de sortie

| Code | Comportement |
|------|--------------|
| 0 | Succes - continue |
| 2 | Blocage - empeche l'action |
| Autre | Warning - continue avec message |

---

## Tester les Regles

### Verifier le chargement

```bash
# Dans Claude Code, depuis le projet
> Quelles sont tes regles pour PowerShell ?
```

### Tester une regle specifique

```bash
> Ecris une fonction sans [CmdletBinding()]
# Claude devrait refuser (regle Naming)

> Ecris un test avec l'email "john@realcompany.com"
# Claude devrait utiliser contoso.com (regle Tests)

> Affiche un message de succes
# Claude devrait utiliser [+] pas ✓

> Ecris un try-catch pour Get-Item
# Claude devrait ajouter -ErrorAction Stop
```

### Tester les hooks

```bash
> Ecris $data = @() dans un fichier .ps1
# Hook validate-syntax.ps1 devrait bloquer: "Variable $data forbidden"
```

---

## Ressources

### Documentation Officielle
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Claude 4 Prompting](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-4-best-practices)
- [Hooks Reference](https://code.claude.com/docs/en/hooks)

### Standards
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [RFC 5424 - Syslog](https://datatracker.ietf.org/doc/html/rfc5424)

---

## Statistiques

| Element | Fichiers | Lignes |
|---------|----------|--------|
| CLAUDE.md | 1 | ~155 |
| claude/*.md | 20 | ~4000 |
| .claude/hooks/ | 2 | ~180 |
| .claude/commands/ | 5 | ~400 |
| .claude/agents/ | 2 | ~200 |
| **Total** | 30 | ~4935 |

---

## Versioning

| Version | Date | Changements |
|---------|------|-------------|
| 4.1.0 | 2025-12-04 | Conventions de nommage uniformes (commands, agents, hooks) |
| 4.0.0 | 2025-12-04 | Structure Claude Code 2025 Native (sans Docs/) |
| 3.0.0 | 2025-12-04 | Hooks, Slash Commands, Subagents |
| 2.0.0 | 2025-12-03 | Format declaratif, -ErrorAction Stop, TryParse |
| 1.0.0 | 2025-12-03 | Version initiale |

### Nouveautes v4.1.0 (Conventions de Nommage)

- Commands : `[verbe]-[cible].md` (create-script, run-tests, review-code)
- Agents : `[domaine]-[rôle].md` (code-reviewer, test-writer)
- Hooks : `[timing?]-[verbe]-[cible].ps1` (validate-syntax, post-analyze-code)

### Nouveautes v4.0.0 (Claude Code 2025 Native)

- Structure sans `Docs/` - remplace par mecanismes natifs
- `audit/issues/` pour issues locales (via `/project:create-issue`)
- CLAUDE.md hierarchiques dans Modules/ et Tests/
- Templates = Slash commands (plus de Docs/Templates/)
- Style Opus 4.5 (contexte explicatif au lieu de MUST/IMPORTANT)

---

**Maintenu par** : Zornot
**Derniere mise a jour** : 2025-12-07 (v4.2.0)
