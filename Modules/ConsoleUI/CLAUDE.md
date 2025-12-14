# [Nom du Projet]

## Context
- **Stack**: PowerShell 7.2+, Windows Terminal
- **Purpose**: Creation dynamique des banières dans la console
- **Author**: Zornot

## Project Structure
- Script principal : `./Script.ps1`
- Modules : `Modules/`
- Tests : `Tests/`
- Configuration : `Config/Settings.json`

## Rules
@.claude/rules/RULES.md

## Slash Commands

### Development
- `/project:create-script ScriptName` - Create a new script
- `/project:create-function Verb-Noun` - Create a new function
- `/project:create-test FunctionName` - Create Pester tests (TDD RED phase)
- `/project:create-issue TYPE-XXX-titre` - Create a local issue
- `/project:run-tests` - Run all Pester tests
- `/project:review-code` - Review code against standards

### Audit
- `/project:audit-code [chemin] [focus]` - Professional 6-phase code audit with anti-false-positives protocol

### Session Management
- `/project:session-start` - Load context from previous session
- `/project:session-save` - Save current state
- `/project:session-end` - Final save + summary before /clear

## Agents
- `code-reviewer` - Reviews PowerShell code for compliance
- `test-writer` - Writes Pester tests following TDD
- `context-explorer` - Explore codebase without polluting main context (haiku)
- `session-summarizer` - Capture session state before /clear
- `security-auditor` - Security audit for credentials, input validation, paths

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

Reference: @docs/MEMORY-GUIDE.md

## Quick Commands
```powershell
Invoke-Pester -Path ./Tests -Output Detailed
```
