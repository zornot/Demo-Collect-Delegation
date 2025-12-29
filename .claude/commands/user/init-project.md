---
description: Initialise un nouveau projet PowerShell via telechargement selectif
argument-hint: [technologie]
---

# /init-project $ARGUMENTS

Initialiser un nouveau projet PowerShell en telechargeant les fichiers necessaires depuis GitHub.

**Methode** : Telechargement et execution de `scripts/init.ps1`

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
- `gh` CLI doit etre installe et authentifie

Verifier avec :
```bash
ls -la
gh auth status
```

Si le repertoire n'est pas vide, demander confirmation avant de continuer.

### 2. Telecharger et executer le script d'init

Telecharger le script depuis GitHub et l'executer :

```bash
gh api -H "Accept: application/vnd.github.v3.raw" repos/zornot/claude-code-powershell-template/contents/scripts/init.ps1 > init.ps1 && pwsh -File init.ps1
```

Le script va :
- Telecharger `.claude/` recursivement (agents, commands, hooks, skills)
- Creer les repertoires vides (Config, Modules, Tests, docs, Logs, Output)
- Telecharger les fichiers de configuration (CLAUDE.md, README.md, etc.)
- Verifier la structure
- Se supprimer automatiquement

**EXCLURE automatiquement** : `.claude/commands/user/` (deja dans ~/.claude/)

### 3. Verifier le resultat

Le script affiche un resume. Verifier que tous les fichiers cles sont presents :
- `.claude/template.json`
- `.claude/settings.json`
- `.claude/commands/bootstrap-project.md`
- `CLAUDE.md`

### 4. Afficher les prochaines etapes

```
[+] Projet initialise !

    Structure creee :
      .claude/           (agents, commands, hooks, skills)
      Config/            (Settings.example.json)
      Modules/           (vide - rempli par /bootstrap-project)
      Tests/             (CLAUDE.md + sous-dossiers)
      docs/              (ARCHITECTURE.md, issues/, referentiel/)
      CLAUDE.md, README.md, CHANGELOG.md, .gitignore

    Prochaine etape :
    /bootstrap-project

    Cette commande va :
    - Demander nom/description/auteur
    - Proposer des modules optionnels
    - Personnaliser CLAUDE.md
    - Initialiser Git
```

## Fichiers NON telecharges

Ces fichiers restent dans le repo template (pas dans le projet genere) :

| Categorie | Fichiers |
|-----------|----------|
| Issues | `docs/issues/*.md` (sauf README.md) |
| Meta-docs | `docs/referentiel/BOOTSTRAP-QUICK-START.md` |
| Meta-docs | `docs/referentiel/MEMORY-GUIDE.md` |
| Session | `docs/SESSION-STATE.md` |
| Audit | `audit/*.md` |
| Scripts | `scripts/` (utilise puis supprime) |
| User cmd | `.claude/commands/user/` |
