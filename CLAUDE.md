# Demo Collect Delegation

## Context
- **Stack**: PowerShell 7.2+, Windows Terminal
- **Purpose**: Récupération de toutes les délégations existantes sur une organisation Exchange Online
- **Author**: zornot

## Project Structure
- Script principal : `./Get-ExchangeDelegation.ps1`
- Modules : `Modules/`
- Tests : `Tests/`
- Configuration : `Config/Settings.json`

## Slash Commands

### Development
- `/create-script ScriptName` - Create a new script
- `/create-function Verb-Noun` - Create a new function
- `/create-test FunctionName` - Create Pester tests (TDD RED phase)
- `/create-issue TYPE-XXX-titre` - Create a local issue
- `/implement-issue TYPE-XXX-titre` - Implement + auto GitHub sync
- `/sync-issue TYPE-XXX-titre` - Sync to GitHub for discussion (without implementing)
- `/run-tests` - Run all Pester tests
- `/review-code` - Review code against standards

### Audit
- `/audit-code [chemin] [focus]` - Professional 6-phase code audit with anti-false-positives protocol

### Session Management
- `/session-start` - Load context from previous session
- `/session-save` - Save current state
- `/session-end` - Final save + summary before /clear

## Agents
- `code-reviewer` - Reviews PowerShell code for compliance
- `test-writer` - Writes Pester tests following TDD
- `context-explorer` - Explore codebase without polluting main context (haiku)
- `session-summarizer` - Capture session state before /clear
- `security-auditor` - Security audit for credentials, input validation, paths

## Skills

Skills actives automatiquement par Claude selon leur description :

| Skill | Description |
|-------|-------------|
| `powershell-development` | Standards PowerShell (naming, errors, performance, security, UI) |
| `development-workflow` | Git, TDD, workflow issues, anonymisation donnees |
| `code-audit` | Methodologie audit 6 phases, anti-faux-positifs, metriques SQALE |
| `progress-tracking` | Templates issues README et SESSION-STATE |

## Workflow

Toute modification de code ou configuration suit le workflow d'issues :

1. **Analyser** : Identifier le probleme, proposer des solutions
2. **Documenter** : `/create-issue TYPE-XXX-titre`
3. **STOP - Attendre validation** : Ne pas implementer sans accord explicite
4. **Implementer** : `/implement-issue TYPE-XXX-titre` (apres validation)

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
