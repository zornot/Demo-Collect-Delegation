# PowerShell Development Standards

## Context
- **Stack**: PowerShell 7.2+, Windows Terminal
- **Purpose**: Scripts robustes avec UI moderne et logging structure
- **Author**: Zornot (code et issues) | Claude Code Opus 4.5 (audits)

---

## Structure des Regles (Domain-Specific)

Organisation par domaine selon [Anthropic Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices).

```
.claude/rules/
├── RULES.md                    # Ce fichier (index)
├── common/                     # Regles transversales (tout langage)
│   ├── git.md                  # Commits, branches, workflow Git
│   ├── tdd.md                  # Test-Driven Development
│   ├── workflow.md             # Issues local-first
│   ├── testing-data.md         # Anonymisation donnees
│   └── documentation.md        # CHANGELOG, SemVer, README
└── powershell/                 # Regles specifiques PowerShell
    ├── naming.md
    ├── parameters.md
    ├── errors.md
    ├── performance.md
    ├── security.md
    ├── pester.md
    ├── modules.md
    ├── config.md
    ├── logging.md
    ├── patterns.md
    ├── anti-patterns.md
    ├── project-structure.md
    └── ui/
        ├── symbols.md
        ├── functions.md
        └── templates.md
```

---

## Critical Rules

### Init
- `#Requires -Version 7.2` | `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8`
- `$ProgressPreference = 'SilentlyContinue'`
- Organiser : Configuration -> Classes -> Helpers -> Main

### Naming
- `[CmdletBinding()]` sur toutes fonctions
- `Verb-Noun` verbes approuves (`Get-Verb`), **Noun toujours singulier**
- PascalCase fonctions/parametres, MAJUSCULES constantes
- Noms explicites (eviter `$data`, `$temp`, `$i` - preferer `$userData`, `$tempFilePath`)

### Parameters
- Typer tous parametres : `[string]$Name`
- Valider : `[ValidateNotNullOrEmpty()]`, `[ValidateSet()]`, `[ValidatePattern()]`
- `TryParse` pour input utilisateur runtime (pas cast direct)

### Error Handling
Use `-ErrorAction Stop` on cmdlets in try-catch blocks, because non-terminating
errors are silently ignored otherwise and the catch block is never reached.
- Catch specifique avant generique | Cleanup dans `finally`

### Performance
- `List<T>` au lieu de `@() +=` | `.Where()` et `.ForEach()` methods
- `[void]` supprimer output | `StringBuilder` concatenation | `foreach` pas pipeline

### Security
- Eviter credentials en dur (finissent dans Git) | Valider inputs | `Test-SafePath` | Requetes parametrees

### UI Console
| `[+]` Green | `[-]` Red | `[!]` Yellow | `[i]` Cyan | `[>]` White | `[?]` DarkGray |
- Box drawing : `┌─┐│└─┘` | Indentation 2 espaces | Write-Host modulo 100
- Do not use emoji (they render inconsistently in terminals and logs)

### Logging (Module Write-Log)
- `Import-Module "$PSScriptRoot\Modules\Write-Log\Write-Log.psm1"` -> `Initialize-Log -Path ".\Logs"`
- Format : `yyyy-MM-ddTHH:mm:ss.fffzzz | LEVEL | HOST | SCRIPT | PID | Message`
- Niveaux : DEBUG, INFO, SUCCESS, WARNING, ERROR, FATAL | UTF-8 sans BOM

### Git & Workflow
- Issue locale avant dev (`audit/issues/`)
- Atomic commits (1 = 1 changement)
- Conventional Commits : `type(scope): description` | Branche `feature/issue-XX`

### Authorship
- **Code + Issues** : Auteur = Zornot (jamais Co-Authored-By, jamais mention AI/Claude)
- **Rapports d'audit** : Auditeur = Claude Code (Opus 4.5)
- Jamais d'emoji dans les commits

### Project Structure
- Script principal a la racine | `Modules/` (Public/Private) | Pas de `src/`
- `Config/`, `Tests/`, `audit/`, `Logs/`, `Output/` | `.temp/` gitignore
- `Settings.example.json` versionne, `Settings.json` gitignore
- CLAUDE.md hierarchiques dans Modules/ et Tests/ (charges selon contexte)

### Development Workflow
Follow TDD (Test-Driven Development) for all new code:
1. RED: Write failing tests first
2. GREEN: Implement minimum code to pass
3. REFACTOR: Improve while keeping tests green

Reference: @common/tdd.md @powershell/pester.md

### Documentation
- CHANGELOG.md Keep a Changelog | Commentaires POURQUOI pas QUOI
- Anonymiser donnees tests : `contoso.com`, `fabrikam.com`

---

## Recommended
- Une fonction = une responsabilite (SRP) | `[OutputType()]` sur fonctions
- `.SYNOPSIS` et `.EXAMPLE`

### Simplicite
- Minimum de code pour resoudre le probleme
- Pas d'abstraction avant 3 repetitions (Rule of Three)
- Pas de fonctionnalites "au cas ou"
- Supprimer le code mort (pas de commentaires `// removed`)

---

## Quick Patterns

```powershell
# Collections
$list = [System.Collections.Generic.List[string]]::new()
$dict = [System.Collections.Generic.Dictionary[string,object]]::new()

# Status messages (brackets, not emoji)
Write-Host "[+] " -NoNewline -ForegroundColor Green; Write-Host "Success"
Write-Host "[-] " -NoNewline -ForegroundColor Red; Write-Host "Error"

# Error handling (use -ErrorAction Stop because non-terminating errors are ignored)
try {
    Get-Item $path -ErrorAction Stop
} catch [System.IO.FileNotFoundException] {
    Write-Log "File not found" -Level ERROR
} catch {
    Write-Log $_.Exception.Message -Level ERROR
}

# TryParse for user input (direct cast throws on invalid input)
$index = 0
if (-not [int]::TryParse($userInput, [ref]$index)) { Write-Error "Valeur attendue" }

# Performance (.Where instead of Where-Object for large collections)
$active = $users.Where({ $_.Status -eq 'Active' })

# Progress (modulo 100 to avoid console flooding)
foreach ($item in $items) {
    $itemIndex++
    if ($itemIndex % 100 -eq 0) { Write-Host "`r[>] $itemIndex/$total" -NoNewline }
}
```

---

## Anti-Patterns

```powershell
# [-] Vague variable names (use explicit names like $userData, $tempFilePath)
$data = @(); $temp = $null; $i = 0

# [-] Missing -ErrorAction Stop (catch block never reached for non-terminating errors)
try { Get-Item $path } catch { }

# [-] Direct cast on user input (throws exception if invalid)
$index = [int]$userInput

# [-] Pipeline for large collections / Array += (O(n) reallocation each time)
$filtered = $data | Where-Object { $_.Status -eq 'Active' }
$arr = @(); $arr += "item"

# [-] Emoji / Production data / AI mention
Write-Host "Success"                    # Use [+] bracket instead
$email = "real.user@company.com"         # Use contoso.com
# Co-Authored-By: Claude                 # Never include
```

---

## References

### Common (all languages)
@common/git.md @common/tdd.md @common/workflow.md
@common/testing-data.md @common/documentation.md
@common/audit-methodology.md @common/anti-false-positives.md @common/metrics-sqale.md

### PowerShell Specific
@powershell/naming.md @powershell/parameters.md @powershell/errors.md
@powershell/performance.md @powershell/security.md @powershell/modules.md
@powershell/pester.md @powershell/config.md @powershell/logging.md
@powershell/patterns.md @powershell/anti-patterns.md @powershell/project-structure.md

### UI
@powershell/ui/symbols.md @powershell/ui/functions.md @powershell/ui/templates.md
