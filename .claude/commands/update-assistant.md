---
description: Met a jour le referentiel .claude/ depuis le template source
argument-hint: [template-path] [--dry-run]
---

# /update-assistant

Met a jour le referentiel `.claude/` et `CLAUDE.md` depuis un template source.

## Arguments

- `$1` : Chemin du template source (obligatoire)
- `--dry-run` : Si present dans $ARGUMENTS, afficher les changements sans les appliquer

## Workflow

### Etape 1 : Validation

Verifier que le chemin template existe :
```powershell
Test-Path "$1\.claude"
```

Si invalide, afficher :
```
[!] Chemin template invalide : $1
    Usage : /update-assistant <chemin-template> [--dry-run]
    Exemple : /update-assistant "D:\Templates\powershell-project-template"
```

### Etape 2 : Backup settings.json

```powershell
Copy-Item ".claude\settings.json" ".claude\settings.json.bak" -Force
```

Afficher : `[i] Backup cree : .claude/settings.json.bak`

### Etape 3 : Analyser les differences settings.json

Comparer les deux fichiers settings.json :
1. Lire `.claude/settings.json` (local)
2. Lire `$1\.claude\settings.json` (source)

Identifier :
- **Permissions locales ajoutees** : dans local mais pas dans source
- **Nouvelles permissions source** : dans source mais pas dans local
- **Hooks modifies** : differences dans la section hooks

Afficher un rapport :
```
=====================================
ANALYSE SETTINGS.JSON
=====================================
Permissions locales (allow) : [liste]
Permissions locales (ask)   : [liste]
Permissions locales (deny)  : [liste]
Nouveaux hooks source       : [liste]
=====================================
```

### Etape 4 : Copier les fichiers (ou simuler si --dry-run)

Si `--dry-run` present dans $ARGUMENTS :
```
[DRY-RUN] Les fichiers suivants seraient copies :
- .claude/skills/* (ecrasement)
- .claude/agents/* (ecrasement)
- .claude/commands/* (ecrasement)
- .claude/hooks/* (ecrasement)
```

Sinon, executer :
```powershell
# Skills
Remove-Item ".claude\skills" -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item "$1\.claude\skills" ".claude\skills" -Recurse -Force

# Agents
Remove-Item ".claude\agents" -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item "$1\.claude\agents" ".claude\agents" -Recurse -Force

# Commands
Remove-Item ".claude\commands" -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item "$1\.claude\commands" ".claude\commands" -Recurse -Force

# Hooks
Remove-Item ".claude\hooks" -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item "$1\.claude\hooks" ".claude\hooks" -Recurse -Force
```

### Etape 5 : Merge settings.json

Strategie de merge :
- `permissions.allow` : **Union** (garder local + ajouter source)
- `permissions.ask` : **Union** (garder local + ajouter source)
- `permissions.deny` : **Source prioritaire** (securite)
- `hooks` : **Source prioritaire** (nouvelles fonctionnalites)

Afficher les permissions locales preservees :
```
[+] Permissions locales preservees dans allow : [liste]
[+] Permissions locales preservees dans ask   : [liste]
[!] Permissions deny ecrasees par source (securite)
[!] Hooks ecrases par source
```

### Etape 6 : Proposer mise a jour CLAUDE.md

Comparer les sections de CLAUDE.md :
- **Slash Commands** : Lister nouvelles commandes disponibles
- **Agents** : Lister nouveaux agents disponibles
- **Skills** : Lister nouveaux skills disponibles

Demander a l'utilisateur :
```
Mettre a jour les sections Commands/Agents/Skills de CLAUDE.md ? (oui/non)
```

Si oui, remplacer ces sections par celles du template source.
Si non, afficher les sections a copier manuellement.

### Etape 7 : Rapport final

```
=====================================
[+] MISE A JOUR TERMINEE
=====================================
Fichiers mis a jour :
- .claude/skills/     [X fichiers]
- .claude/agents/     [X fichiers]
- .claude/commands/   [X fichiers]
- .claude/hooks/      [X fichiers]
- .claude/settings.json (merge)

Backup disponible : .claude/settings.json.bak

Actions manuelles si necessaire :
- Verifier CLAUDE.md sections mises a jour
- Supprimer .claude/settings.json.bak apres validation
=====================================
```

## Restauration en cas de probleme

```powershell
# Restaurer settings.json
Copy-Item ".claude\settings.json.bak" ".claude\settings.json" -Force
```
