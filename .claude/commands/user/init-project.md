---
description: Initialise un nouveau projet PowerShell via telechargement selectif
argument-hint: [technologie]
---

# /init-project $ARGUMENTS

Initialiser un nouveau projet PowerShell en telechargeant les fichiers necessaires depuis GitHub.

**Methode** : Generation a la volee via `gh api` (pas de clone complet)

## Technologie

**Argument** : $ARGUMENTS (optionnel)
**Supportee** : `powershell` (defaut)

## URL du template

```
https://github.com/zornot/claude-code-powershell-template
```

## Workflow

### 1. Verifier les prerequis

- Le repertoire courant doit etre VIDE
- `gh` CLI doit etre installe et authentifie (`gh auth login`)

Verifier avec :
```powershell
Get-ChildItem -Force | Measure-Object
gh auth status
```

Si le repertoire n'est pas vide, demander confirmation avant de continuer.

### 2. Telecharger .claude/ depuis GitHub

Telecharger recursivement via gh api :

```powershell
# Fonction de telechargement recursif
function Download-GitHubFolder {
    param([string]$Path, [string]$Destination)

    $Owner = "zornot"
    $Repo = "claude-code-powershell-template"

    $contents = gh api "repos/$Owner/$Repo/contents/$Path" | ConvertFrom-Json

    foreach ($item in $contents) {
        $destPath = Join-Path $Destination $item.name

        if ($item.type -eq "dir") {
            New-Item -ItemType Directory -Path $destPath -Force | Out-Null
            Download-GitHubFolder -Path $item.path -Destination $destPath
        }
        else {
            gh api -H "Accept: application/vnd.github.v3.raw" "repos/$Owner/$Repo/contents/$($item.path)" | Out-File $destPath -Encoding UTF8
        }
    }
}
```

Telecharger :
- `.claude/agents/` (6 fichiers)
- `.claude/commands/` (12 fichiers dont bootstrap-project.md)
- `.claude/hooks/` (1 fichier)
- `.claude/skills/` (26 fichiers)
- `.claude/settings.json`
- `.claude/template.json`

**EXCLURE** : `.claude/commands/user/` (deja dans ~/.claude/)

### 3. Creer les repertoires vides

```powershell
$directories = @(
    "Config",
    "Modules",
    "Tests/Fixtures",
    "Tests/Integration",
    "Tests/Unit",
    "docs/issues",
    "docs/referentiel",
    "Logs",
    "Output"
)

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}
```

### 4. Telecharger les fichiers de configuration

Fichiers individuels a telecharger :

```powershell
$files = @{
    "Config/Settings.example.json" = "Config/Settings.example.json"
    "Tests/CLAUDE.md" = "Tests/CLAUDE.md"
    "docs/ARCHITECTURE.md" = "docs/ARCHITECTURE.md"
    "docs/issues/README.md" = "docs/issues/README.md"
    "docs/referentiel/CLAUDE-CODE-GUIDE.md" = "docs/referentiel/CLAUDE-CODE-GUIDE.md"
    "CLAUDE.md" = "CLAUDE.md"
    "README.md" = "README.md"
    "CHANGELOG.md" = "CHANGELOG.md"
    ".gitignore" = ".gitignore"
}

$Owner = "zornot"
$Repo = "claude-code-powershell-template"

foreach ($file in $files.Keys) {
    $destPath = $files[$file]
    gh api -H "Accept: application/vnd.github.v3.raw" "repos/$Owner/$Repo/contents/$file" | Out-File $destPath -Encoding UTF8
}
```

### 5. Fichiers NON telecharges (restent dans le repo template)

Ces fichiers ne sont PAS telecharges car specifiques au template :

| Categorie | Fichiers |
|-----------|----------|
| Issues | `docs/issues/*.md` (sauf README.md) |
| Meta-docs | `docs/referentiel/BOOTSTRAP-QUICK-START.md` |
| Meta-docs | `docs/referentiel/MEMORY-GUIDE.md` |
| Session | `docs/SESSION-STATE.md` |
| Audit | `audit/*.md` |
| User cmd | `.claude/commands/user/` |

### 6. Verification finale

Verifier que la structure est correcte :

```powershell
# Verifier fichiers cles
$required = @(
    ".claude/template.json",
    ".claude/settings.json",
    ".claude/commands/bootstrap-project.md",
    "CLAUDE.md"
)

foreach ($file in $required) {
    if (-not (Test-Path $file)) {
        Write-Error "Fichier manquant : $file"
    }
}
```

### 7. Afficher le resume et prochaines etapes

```
[+] Projet initialise !

    Fichiers crees : ~50
    Methode : Telechargement selectif (gh api)

    Structure creee :
      .claude/           (agents, commands, hooks, skills)
      Config/            (Settings.example.json)
      Modules/           (vide - rempli par /bootstrap-project)
      Tests/             (CLAUDE.md + sous-dossiers)
      docs/              (ARCHITECTURE.md, issues/, referentiel/)
      CLAUDE.md          (avec placeholders)
      README.md, CHANGELOG.md, .gitignore

    Prochaine etape :
    /bootstrap-project

    Cette commande va :
    - Demander nom/description/auteur
    - Proposer des modules optionnels
    - Personnaliser CLAUDE.md
    - Initialiser Git
```
