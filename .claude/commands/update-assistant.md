---
description: Met a jour le referentiel .claude/ depuis GitHub ou un chemin local
argument-hint: [--dry-run] [chemin-local]
---

# /update-assistant

Met a jour le referentiel `.claude/` et `CLAUDE.md` depuis GitHub (par defaut) ou un chemin local.

## Arguments

| Argument | Description |
|----------|-------------|
| (aucun) | Telecharge depuis GitHub |
| `--dry-run` | Simule sans modifier |
| `chemin` | Utilise un chemin local |
| `chemin --dry-run` | Simule depuis chemin local |

## URL du Template

```
https://github.com/zornot/claude-code-powershell-template
```

## Workflow

### Etape 1 : Determiner la source

**Analyser $ARGUMENTS** :

| $ARGUMENTS | Source | Action |
|------------|--------|--------|
| (vide) | GitHub | Telecharger depuis repo |
| `--dry-run` | GitHub | Simulation depuis repo |
| `chemin` | Local | Utiliser chemin fourni |
| `chemin --dry-run` | Local | Simulation depuis chemin |

**Si GitHub (par defaut)** :

Verifier l'authentification :
```bash
gh auth status
```

Si non authentifie, afficher :
```
[!] GitHub CLI non authentifie
    Executez : gh auth login
    Ou fournissez un chemin local : /update-assistant "D:\MonTemplate"
```

**Si chemin local** :

Verifier que le chemin existe :
```powershell
Test-Path "$chemin\.claude"
```

Si invalide, afficher :
```
[!] Chemin template invalide : $chemin
    Usage : /update-assistant [--dry-run] [chemin-local]
    Exemple : /update-assistant "D:\Templates\powershell-project-template"
```

### Etape 2 : Backup settings.json (APRES Etape 1)

**BLOCKER** : Ne pas continuer si backup echoue.

```powershell
Copy-Item ".claude\settings.json" ".claude\settings.json.bak" -Force
```

Afficher : `[i] Backup cree : .claude/settings.json.bak`

### Etape 3 : Lister les fichiers source (APRES Etape 2)

**Si GitHub** :

Utiliser l'API GitHub pour lister les fichiers :
```bash
gh api repos/zornot/claude-code-powershell-template/git/trees/main?recursive=1
```

Filtrer les chemins commencant par :
- `.claude/` (skills, agents, commands, hooks)
- `docs/referentiel/`

**Si local** :

Lister les fichiers locaux :
```powershell
Get-ChildItem -Path "$chemin\.claude", "$chemin\docs\referentiel" -Recurse -File
```

Afficher :
```
[i] Fichiers source : XX fichiers dans .claude/, YY dans docs/referentiel/
```

### Etape 4 : Analyser les differences settings.json (APRES Etape 3)

**Si GitHub** :
```bash
gh api -H "Accept: application/vnd.github.v3.raw" \
  repos/zornot/claude-code-powershell-template/contents/.claude/settings.json
```

**Si local** :
```powershell
Get-Content "$chemin\.claude\settings.json"
```

Comparer avec le settings.json local et identifier :
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

### Etape 5 : Copier les fichiers (APRES Etape 4)

**BLOCKER** : Confirmer avec utilisateur si `--dry-run` n'est pas actif.

Si `--dry-run` present dans $ARGUMENTS :
```
[DRY-RUN] Les fichiers suivants seraient copies :
- .claude/skills/* (ecrasement)
- .claude/agents/* (ecrasement)
- .claude/commands/* (ecrasement, sauf .old/)
- .claude/hooks/* (ecrasement)
- docs/referentiel/* (ecrasement)
```

Sinon :

**Pour chaque dossier a synchroniser** :

| Dossier | Strategie |
|---------|-----------|
| `.claude/skills/` | Supprimer local, copier source |
| `.claude/agents/` | Supprimer local, copier source |
| `.claude/commands/` | Supprimer local (sauf .old/), copier source |
| `.claude/hooks/` | Supprimer local, copier source |
| `docs/referentiel/` | Supprimer local, copier source |

**Si GitHub** : Pour chaque fichier, telecharger avec :
```bash
gh api -H "Accept: application/vnd.github.v3.raw" \
  repos/zornot/claude-code-powershell-template/contents/[path]
```

Puis ecrire le contenu dans le fichier local correspondant.

**Si local** : Copier avec :
```powershell
Copy-Item -Path "$chemin\[path]" -Destination "[path]" -Force
```

> **CHECKPOINT CRITIQUE** : Point de non-retour
>
> A ce stade, les fichiers .claude/ ont ete modifies.
> - [ ] Backup settings.json.bak existe
> - [ ] Fichiers source copies
>
> SI interruption apres ce point : restaurer avec
> ```powershell
> Copy-Item ".claude\settings.json.bak" ".claude\settings.json" -Force
> ```

### Etape 6 : Mise a jour intelligente Config/ (APRES Etape 5)

**Strategie** : Merge des nouvelles sections sans ecraser les valeurs existantes.

1. **Telecharger/lire Settings.example.json source** :

**Si GitHub** :
```bash
gh api -H "Accept: application/vnd.github.v3.raw" \
  repos/zornot/claude-code-powershell-template/contents/Config/Settings.example.json
```

**Si local** :
```powershell
Get-Content "$chemin\Config\Settings.example.json"
```

2. **Comparer avec local** et identifier nouvelles sections

3. **Proposer les options** :
```
Nouvelles sections disponibles dans le template :
  [1] GraphConnection - Connexion Microsoft Graph
  [2] Checkpoint - Reprise apres interruption

Actions possibles :
  A) Ajouter les nouvelles sections a Settings.example.json
  B) Ignorer (garder mon template actuel)
  C) Remplacer entierement par la version source

Choix ? [A/B/C] > _
```

4. **Ne JAMAIS toucher Settings.json** (contient secrets de production)

### Etape 7 : Merge settings.json (APRES Etape 6)

**BLOCKER** : Verifier que backup .claude/settings.json.bak existe avant merge.

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

### Etape 8 : Proposer mise a jour CLAUDE.md (APRES Etape 7)

#### Classification des sections

| Section | Type | Action |
|---------|------|--------|
| `# [Nom du Projet]` | **PROJET** | PRESERVER (identite) |
| `## Context` | **PROJET** | PRESERVER (Purpose, Author) |
| `## Modules` | **PROJET** | PRESERVER (genere par /bootstrap-project) |
| `## Slash Commands` | TEMPLATE | Mettre a jour |
| `## Agents` | TEMPLATE | Mettre a jour |
| `## Skills` | TEMPLATE | Mettre a jour |
| `## Workflow` | TEMPLATE | Mettre a jour |
| `## Session Management` | TEMPLATE | Mettre a jour |
| `## Quick Commands` | MIXTE | Preserver si personnalise |

**Note** : `## Project Structure` est generique et peut etre mis a jour.
`## Modules` n'existe que si `/bootstrap-project` a ete execute avec des modules.

#### Processus de mise a jour

1. **Telecharger/lire CLAUDE.md source** :

**Si GitHub** :
```bash
gh api -H "Accept: application/vnd.github.v3.raw" \
  repos/zornot/claude-code-powershell-template/contents/CLAUDE.md
```

**Si local** :
```powershell
Get-Content "$chemin\CLAUDE.md"
```

2. **Extraire sections PROJET** du CLAUDE.md local :
   - Titre (`# ...`)
   - `## Context` (lignes 3-7 typiquement)
   - `## Modules` (si present, genere par bootstrap)

3. **Afficher rapport** :
   ```
   =====================================
   ANALYSE CLAUDE.MD
   =====================================
   Sections PROJET (preservees) :
   - # [Nom actuel]
   - ## Context (Purpose: ..., Author: ...)
   - ## Modules (X modules references) [si present]

   Sections TEMPLATE (a mettre a jour) :
   - ## Slash Commands : +N nouvelles commandes
   - ## Agents : +N nouveaux agents
   - ## Skills : +N nouveaux skills
   =====================================
   ```

4. **Demander confirmation** :
   ```
   Mettre a jour les sections Template de CLAUDE.md ? (oui/non)
   Les sections Projet seront PRESERVEES.
   ```

5. **Si oui** : Reconstruire CLAUDE.md :
   - Sections PROJET du local
   - Sections TEMPLATE du source

6. **Si non** : Afficher les sections a copier manuellement

### Etape 9 : Rapport final (APRES Etape 8)

**BLOCKER** : Si erreur lors des etapes precedentes, afficher la commande de restauration.

```
=====================================
[+] MISE A JOUR TERMINEE
=====================================
Source : [GitHub / Chemin local]

Fichiers MIS A JOUR (template) :
- .claude/skills/     [X fichiers]
- .claude/agents/     [X fichiers]
- .claude/commands/   [X fichiers]
- .claude/hooks/      [X fichiers]
- .claude/settings.json (merge)
- docs/referentiel/   [X fichiers]

Fichiers PRESERVES (projet) :
- CLAUDE.md : # Titre, ## Context, ## Modules
- docs/SESSION-STATE.md
- docs/issues/*

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

## Exemples

```bash
# Mise a jour depuis GitHub (par defaut)
/update-assistant

# Simulation sans modification
/update-assistant --dry-run

# Mise a jour depuis un chemin local
/update-assistant "D:\Templates\powershell-project-template"

# Simulation depuis chemin local
/update-assistant "D:\Templates\powershell-project-template" --dry-run
```
