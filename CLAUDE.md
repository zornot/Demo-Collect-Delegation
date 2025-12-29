# [Nom du Projet]

## Context
- **Stack**: PowerShell 7.2+, Windows Terminal
- **Purpose**: Récupération des délégations sur les boîtes emails.
- **Author**: Zornot

## Project Structure
- Script principal : `./Script.ps1`
- Modules : `Modules/`
- Tests : `Tests/`
- Configuration : `Config/Settings.json`

<!-- MODULES_SECTION_PLACEHOLDER -->

## Slash Commands

### Development
- `/create-script ScriptName` - Initialize a new script (architecture required)
- `/create-test FunctionName` - Create Pester tests (TDD RED phase)
- `/create-issue TYPE-XXX-titre` - Create a local issue
- `/implement-issue TYPE-XXX-titre` - Implement + auto GitHub sync
- `/sync-issue TYPE-XXX-titre` - Sync to GitHub for discussion (without implementing)
- `/run-tests` - Run all Pester tests
- `/review-code` - Review code against standards
- `/analyze-bug description` - Analyze bug with tech research

### Audit
- `/audit-code [chemin] [focus]` - Professional 6-phase code audit with anti-false-positives protocol
- `/audit-assistant [scope]` - Audit structure assistant (map, check, all)

### Session Management
- `/session-start` - Load context from previous session
- `/session-save` - Save current state
- `/session-end` - Final save + summary before /clear

### Maintenance
- `/update-assistant <template-path> [--dry-run]` - Update .claude/ from template source
- `/bootstrap-project` - Configure project after /init-project (modules, settings)

## Agents
- `code-reviewer` - Reviews PowerShell code for compliance
- `test-writer` - Writes Pester tests following TDD
- `context-explorer` - Explore codebase without polluting main context (haiku)
- `session-summarizer` - Capture session state before /clear
- `security-auditor` - Security audit for credentials, input validation, paths
- `tech-researcher` - Deep technical research for undocumented concepts
- `assistant-auditor` - Cartographie et audit de l'assistant (haiku)

### Usage Recommande (agents manuels)

| Agent | Utiliser quand | NE PAS utiliser quand |
|-------|----------------|----------------------|
| `context-explorer` | Exploration >10 fichiers, decouverte architecture | Lecture fichier specifique |
| `security-auditor` | Review securite rapide hors audit | Pendant /audit-code (contexte 6 phases requis) |

Note : Ces agents sont a invocation manuelle (`@nom-agent`). L'auto-invocation n'est pas garantie.

## Skills

Skills actives automatiquement par Claude selon leur description :

| Skill | Description |
|-------|-------------|
| `powershell-development` | Standards PowerShell (naming, errors, performance, security, UI) |
| `development-workflow` | Git, TDD, workflow issues, anonymisation donnees |
| `code-audit` | Methodologie audit 6 phases, anti-faux-positifs, metriques SQALE |
| `progress-tracking` | Templates issues README et SESSION-STATE |
| `knowledge-verification` | Verification temporelle pour technos evolutives |
| `external-apis` | Meta-patterns pour APIs cloud (connexion, imports, proprietes) |

## Hooks

Protection et qualite automatiques (voir guide section 10) :

| Evenement | Script | Action |
|-----------|--------|--------|
| PreToolUse | `security-check.ps1` | Bloque fichiers sensibles (.key, .pem, .env) |
| PostToolUse | `format-powershell.ps1` | Formate code PowerShell |
| PostToolUse | `analyze-powershell.ps1` | Analyse PSScriptAnalyzer |

## Workflow

Toute modification de code ou configuration suit le workflow d'issues :

1. **Analyser** : Identifier le probleme, proposer des solutions
2. **Designer** : Section DESIGN si FEAT ou SEC
3. **Documenter** : `/create-issue TYPE-XXX-titre`
4. **STOP - Attendre validation** : Ne pas implementer sans accord explicite
5. **Implementer** : `/implement-issue TYPE-XXX-titre` (apres validation)

**Ne jamais modifier directement sans issue. 1 issue = 1 branche = 1 commit.**

## Session Management

Before starting work:
- Run `/session-start` to load context from previous session

During work:
- Update `docs/SESSION-STATE.md` after major progress
- Use `@context-explorer` for large codebase exploration

Before ending:
- Run `/session-save` to preserve state
- Run `/session-end` for final summary
- Run `/clear` to free context

Reference: @docs/SESSION-STATE.md

## Quick Commands
```powershell
Invoke-Pester -Path ./Tests -Output Detailed
```
