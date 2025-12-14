# Claude Code - Guide Complet

> Guide exhaustif des conventions Claude Code pour projets PowerShell.
> Version: Opus 4.5 - Decembre 2025

---

## Table des Matieres

### Partie A : Fondamentaux
1. [Vue d'ensemble](#1-vue-densemble)
2. [Les 4 mecanismes d'extension](#2-les-4-mecanismes-dextension)
3. [Modes de fonctionnement](#3-modes-de-fonctionnement)

### Partie B : Skills et Commands
4. [Skills (Architecture Officielle Anthropic)](#4-skills-architecture-officielle-anthropic)
5. [Slash Commands](#5-slash-commands)
6. [CLAUDE.md et imports](#6-claudemd-et-imports)

### Partie C : Agents et Subagents
7. [Custom Agents](#7-custom-agents)
8. [Subagents integres](#8-subagents-integres)

### Partie D : Securite et Controle
9. [Permissions](#9-permissions)
10. [Hooks](#10-hooks)

### Partie E : Gestion du Contexte
11. [Session Management](#11-session-management)
12. [Memory Management](#12-memory-management)
13. [Checkpoints et navigation](#13-checkpoints-et-navigation)

### Partie F : Integrations Externes
14. [MCP Servers](#14-mcp-servers)
15. [Plugins](#15-plugins-beta-publique-octobre-2025)

### Partie G : Bonnes Pratiques
16. [Style de Prompting Opus 4.5](#16-style-de-prompting-opus-45)
17. [Conventions specifiques PowerShell](#17-conventions-specifiques-powershell)
18. [Conventions de Nommage Issues](#18-conventions-de-nommage-issues)
19. [Erreurs Courantes a Eviter](#19-erreurs-courantes-a-eviter)
20. [Checklist de Decision](#20-checklist-de-decision)

### Partie H : Reference
21. [Workflow Issues du Projet](#21-workflow-issues-du-projet)
22. [Reference rapide](#22-reference-rapide)
23. [Organisation des fichiers](#23-organisation-des-fichiers)
24. [Sources](#24-sources)

---

# PARTIE A : FONDAMENTAUX

---

## 1. Vue d'ensemble

### Qu'est-ce que Claude Code ?

Claude Code est un **agent autonome** capable d'executer des taches sur l'ordinateur via le terminal :
- Lire et modifier des fichiers
- Executer des commandes shell
- Naviguer dans le systeme de fichiers
- Interagir avec Git, npm, pip, et tous les outils CLI
- Se connecter a des services externes via MCP

### Philosophie

Claude Code donne a l'IA les **memes outils qu'un developpeur humain**. Au lieu de simplement generer du code, Claude peut le tester, le debugger, le committer, et creer des pull requests.

> **"The context window is a public good."** - Anthropic Skill Creator
>
> N'ajouter QUE ce que Claude ne sait pas deja.

### Pourquoi cette philosophie ?

| Probleme | Solution Claude Code |
|----------|---------------------|
| LLM genere du code non teste | Claude execute les tests lui-meme |
| Contexte perdu entre sessions | SESSION-STATE.md preserve l'etat |
| Instructions ignorees | Hooks forcent l'execution |
| Contexte pollue (200k tokens) | Skills = progressive disclosure |

---

## 2. Les 4 mecanismes d'extension

### Tableau comparatif simple

| Mecanisme | Qui invoque | Contexte | Usage principal |
|-----------|-------------|----------|-----------------|
| **Slash Commands** | Toi (`/commande`) | Partage | Raccourcis pour prompts frequents |
| **Skills** | Claude (auto) | Partage | Expertise chargee automatiquement |
| **Subagents integres** | Claude (auto) | **Isole** | Exploration sans pollution contexte |
| **Custom Agents** | Claude ou toi | **Isole** | Specialistes avec personnalite |

### Tableau comparatif detaille

| Critere | Skill | MCP Server | Subagent | Slash Command |
|---------|-------|------------|----------|---------------|
| **Declenche par** | Agent (auto)¹ | Agent ou Toi | Agent ou Toi | Toi (manuel) |
| **Persistence Contexte** | Oui | Oui | **Non** (isole) | Oui |
| **Parallelisable** | Non | Non | **Oui** (max ~10) | Non |
| **Permissions Outils** | Configurable | Tout ou rien | Configurable | Configurable |
| **Peut appeler Subagents** | Oui | Oui | **Non** (anti-nesting) | Oui |
| **Peut utiliser Skills** | Oui | N/A² | Oui (lecture manuelle) | Oui |
| **Peut utiliser MCP** | Oui | Oui | Oui (herite) | Oui |

**Notes :**
1. L'activation automatique depend fortement de la qualite de la description. Non garantie a 100%.
2. MCP est un outil passif appele par les autres mecanismes.

### Difference cle : isolation du contexte

**Commands et Skills** = travaillent **DANS** ta conversation
- Avantage : Acces a tout le contexte
- Avantage : Acces au CLAUDE.md et ses imports
- Inconvenient : Peuvent encombrer le contexte

**Subagents et Custom Agents** = travaillent **A COTE** de ta conversation
- Avantage : Contexte propre, recherches massives sans encombrement
- Inconvenient : N'ont PAS acces au CLAUDE.md
- Inconvenient : N'ont PAS acces au contexte de conversation

### Point crucial : les agents ne chargent pas CLAUDE.md

Quand un Custom Agent ou Subagent est invoque :
1. Il demarre avec une **ardoise vierge**
2. Il n'a **QUE** son propre system prompt
3. Il **ne connait pas** les conventions du projet
4. Il doit **redecouvrir** le contexte necessaire

**Solution** : Inclure dans le system prompt de l'agent une instruction pour lire les skills pertinents (ex: `.claude/skills/powershell-development/SKILL.md`) en premiere action.

### Ce que les agents heritent vs n'heritent PAS

| Element | Herite ? |
|---------|----------|
| Outils (Read, Bash, etc.) | Oui (si non specifie) |
| Serveurs MCP | Oui |
| CLAUDE.md | **Non** |
| Contexte de conversation | **Non** |
| Fichiers importes via @ | **Non** |

### Arbre de decision : quand utiliser quoi ?

```
Tache a realiser
    │
    ├─► Tache ponctuelle (one-time) ?
    │   └─► OUI → SLASH COMMAND
    │
    ├─► Integration avec service externe (API, BDD, SaaS) ?
    │   └─► OUI → MCP SERVER
    │
    ├─► Besoin de paralleliser OU isoler le contexte ?
    │   └─► OUI → SUBAGENT
    │
    └─► Probleme recurrent a GERER (pas juste executer) ?
        └─► OUI → SKILL
```

### Distinction Critique : FAIRE vs GERER

| Action | Mecanisme | Exemple |
|--------|-----------|---------|
| **FAIRE** une fois | Slash Command | Creer UN fichier, UN commit |
| **GERER** un ensemble | Skill | Gerer les issues (creer, lister, fermer, tracker) |

> **Regle d'or** : Toujours commencer par une Slash Command. Si elle ne suffit plus, alors seulement envisager les autres mecanismes.

---

## 3. Modes de fonctionnement

### Changement de mode

`Shift+Tab` pour cycler entre les modes.

### Mode Normal (defaut)

Claude demande permission avant :
- Modifier/creer fichier
- Executer commande shell
- Acceder ressources externes

**Quand utiliser :**
- Decouverte nouveau projet
- Code critique/production
- Apprentissage
- Taches ambigues

### Mode Auto-Accept

Claude applique automatiquement les modifications de fichiers.

**Quand utiliser :**
- Taches repetitives bien definies
- Confiance etablie apres avoir vu le plan
- Iteration rapide code-test-fix
- Maintenance

**Controles :**
- `Esc` pour interrompre
- `Esc+Esc` pour checkpoints
- Certaines commandes peuvent rester bloquees

### Mode Plan

Mode **lecture seule**. Claude peut :
- Lire fichiers
- Analyser code
- Executer commandes de lecture
- Creer plans detailles

Ne peut PAS modifier quoi que ce soit.

**Quand utiliser :**
- Avant gros chantier
- Planification
- Audit
- Exploration codebase inconnu

### Mots-cles de reflexion

| Mot-cle | Niveau | Usage |
|---------|--------|-------|
| "think" | Standard | Questions simples |
| "think hard" | Approfondi | Problemes complexes |
| "think harder" | Tres approfondi | Architecture |
| "ultrathink" | Maximum | Decisions critiques |

> **Attention (Opus 4.5)** : Quand extended thinking est desactive, Claude est sensible au mot "think". Preferez "consider", "evaluate", "analyze" pour eviter des comportements inattendus.
>
> Source : [Claude 4 Best Practices](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/claude-4-best-practices)

### Workflow typique : Plan → Normal → Auto-Accept

```
1. Mode Plan      → Analyser et planifier (lecture seule)
2. Mode Normal    → Implementer avec validation (demande permission)
3. Mode Auto-Accept → Iterer rapidement (applique automatiquement)
```

**Pourquoi cet ordre ?**
- Plan : Comprendre avant d'agir, eviter erreurs couteuses
- Normal : Valider les premieres modifications critiques
- Auto-Accept : Accelerer une fois la confiance etablie

---

# PARTIE B : SKILLS ET COMMANDS

---

## 4. Skills (Architecture Officielle Anthropic)

### Definition

Un Skill est une expertise que CLAUDE decide de charger automatiquement quand ta demande correspond a sa description.

**Source officielle** : [github.com/anthropics/skills](https://github.com/anthropics/skills)

### Pourquoi les Skills ? (Design Decisions)

| Probleme | Solution Anthropic |
|----------|-------------------|
| Charger 3000+ lignes a chaque requete | Skills = ~100 lignes essentielles |
| Agents n'heritent pas du contexte | Agents lisent skills explicitement |
| Besoin de details varies | Progressive disclosure (a la demande) |

### Difference avec les commandes

| Aspect | Commands | Skills |
|--------|----------|--------|
| Invocation | Manuelle (`/commande`) | Automatique par Claude |
| Decision | Toi | Claude |
| Chargement | Immediat | Progressif (a la demande) |

### Comment Claude utilise les Skills

1. **Au demarrage** : Charge les metadonnees (nom + description)
2. **A chaque requete** : Analyse si un skill est pertinent
3. **Si pertinent** : Lit le fichier SKILL.md complet
4. **Si necessaire** : Lit les fichiers references

C'est le **progressive disclosure** : Claude ne charge que ce dont il a besoin.

### Progressive Disclosure - Les 3 Niveaux

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     PROGRESSIVE DISCLOSURE                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  NIVEAU 1 : METADATA (toujours charge)                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ name: powershell-development                                        │   │
│  │ description: "PowerShell development standards. Use when..."        │   │
│  │                                                                      │   │
│  │ Claude decide si pertinent base sur la description                  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                          │                                                  │
│                          │ Si pertinent                                     │
│                          ▼                                                  │
│  NIVEAU 2 : SKILL.md (charge si active)                                    │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ ~100 lignes : regles essentielles + index fichiers                  │   │
│  │ Recommandation Anthropic : < 500 lignes                             │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                          │                                                  │
│                          │ Si besoin de details specifiques                │
│                          ▼                                                  │
│  NIVEAU 3 : FICHIERS DETAILLES (charge a la demande)                       │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ naming.md, errors.md, performance.md, security.md, etc.             │   │
│  │ Claude lit uniquement les fichiers necessaires                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Qui charge quoi ?

| Composant | Niveau 1 (Metadata) | Niveau 2 (SKILL.md) | Niveau 3 (Details) |
|-----------|---------------------|---------------------|-------------------|
| **Contexte principal** | AUTO | AUTO si pertinent | Sur @reference |
| **Agents (isoles)** | NON (pas d'heritage) | Oui (lu explicitement) | Oui (selon besoin) |
| **Commands** | Via contexte | Rarement | Selon le workflow |

**Trade-off accepte** : Les agents doivent relire les skills (pas d'heritage), mais leur propre contexte de 200k tokens rend ce cout negligeable.

### Structure Officielle d'un Skill

```
my-skill/
├── SKILL.md              # REQUIS - Point d'entree
├── scripts/              # Scripts executables (optionnel)
│   └── helper.py         # Claude EXECUTE (output dans contexte)
├── references/           # Documentation (optionnel)
│   └── guide.md          # Claude LIT pour contexte
├── templates/            # Modeles de sortie (optionnel)
│   └── output.md         # Claude utilise comme modele
└── assets/               # Donnees statiques (optionnel)
    └── data.json         # Claude lit comme donnees
```

**Source** : [Anthropic Skill Best Practices](https://code.claude.com/docs/en/skills)

> "Sub-folders are allowed (and encouraged) for organizing helper scripts, templates, and data files."

### Scripts vs References vs Templates : QUAND utiliser quoi ?

| Type | Dossier | Claude... | QUAND utiliser |
|------|---------|-----------|----------------|
| **Scripts** | `scripts/` | Les EXECUTE via bash | Calculs, transformations, validations |
| **References** | `references/` | Les LIT pour contexte | Documentation, specifications |
| **Templates** | `templates/` | Les utilise comme modeles | Formats de sortie standardises |
| **Assets** | `assets/` | Les lit comme donnees | JSON, CSV, donnees statiques |

**Regle cle** : Le code des scripts n'entre PAS dans le contexte - seulement leur OUTPUT.

### Frontmatter YAML - Format Officiel

```yaml
---
name: skill-name              # lowercase, hyphens, max 64 chars
description: "Description"    # max 1024 chars - CRITIQUE pour activation
---
```

| Champ | Requis | Notes |
|-------|--------|-------|
| `name` | Oui | lowercase, lettres/chiffres/tirets uniquement |
| `description` | Oui | Inclure "Use when..." pour activation auto |
| `disable-model-invocation` | Non | `true` = invocation manuelle seulement |
| `allowed-tools` | Non | Limite les outils disponibles |
| `globs` | **Non** | Non supporte officiellement par Anthropic |

### Option `disable-model-invocation`

Pour forcer l'invocation manuelle d'un skill (operations dangereuses, workflows interactifs) :

```yaml
---
name: dangerous-operation
description: "Operation critique necessitant confirmation explicite"
disable-model-invocation: true
---
```

**QUAND utiliser `disable-model-invocation: true` ?**
- Operations destructives ou irreversibles
- Workflows interactifs necessitant validation humaine
- Commandes de configuration systeme
- Actions avec effets de bord importants

> **Source** : [Claude Skills Deep Dive](https://leehanchung.github.io/blogs/2025/10/26/claude-skills-deep-dive/)

### Pourquoi PAS de globs: ?

L'attribut `globs:` n'est **pas officiellement supporte** par Anthropic.

Claude decide d'activer un skill base sur :
1. La `description` du frontmatter
2. Le contexte de la requete utilisateur

**Approche Anthropic** : Ecrire une description claire qui inclut "Use when..." est plus fiable que des patterns de fichiers.

### Comment ecrire une bonne description

**Pattern recommande : WHEN + WHEN NOT**

L'activation automatique n'est pas garantie a 100%. Une description avec triggers positifs ET negatifs ameliore significativement la fiabilite.

```yaml
# EXCELLENT - pattern WHEN + WHEN NOT
description: "PowerShell development standards for this project.
Use when writing, reviewing, or debugging PowerShell code (.ps1, .psm1, .psd1).
Covers naming conventions, error handling, performance patterns, security.
Do NOT load for general scripting questions unrelated to this project."

# BON - specifique et actionnable
description: "PowerShell development standards. Use when writing, reviewing,
or debugging PowerShell code (.ps1, .psm1, .psd1). Covers naming conventions,
error handling, performance patterns, and security practices."

# MAUVAIS - trop vague
description: "PowerShell rules"
```

**Criteres d'une bonne description :**
- Commence par ce que le skill fait
- Inclut "Use when..." avec des declencheurs clairs
- Inclut "Do NOT..." pour eviter les faux positifs
- Mentionne les extensions de fichiers si applicable
- Liste les domaines couverts

> **Note pratique** : L'auto-activation depend fortement de la qualite de la description. Testez vos skills en situation reelle.

### Pattern Domain-Specific : POURQUOI separer par domaine

> **Source officielle** : [Anthropic Skill Best Practices](https://code.claude.com/docs/en/skills)
>
> *"For Skills with multiple domains, organize content by domain to avoid loading irrelevant context."*

| Benefice | Explication |
|----------|-------------|
| **Economie tokens** | Claude charge uniquement le domaine pertinent |
| **Contexte focalise** | Pas de pollution inter-langages |
| **Extensibilite** | Ajout facile d'un nouveau langage |
| **Clarte** | Separation nette commun vs specifique |

### Skills du projet

| Skill | Fichiers | Description |
|-------|----------|-------------|
| `powershell-development` | 16 | Standards PowerShell (naming, errors, performance, UI) |
| `development-workflow` | 6 | Git, TDD, issues, test data (transverse) |
| `code-audit` | 4 | Methodologie 6 phases, anti-faux-positifs, SQALE |
| `progress-tracking` | 3 | Templates progression (SESSION-STATE, issues) |

### Templates dans les Skills (Best Practice)

Les templates doivent etre places dans un sous-dossier `templates/` du skill.

**Pourquoi dans un skill plutot qu'ailleurs ?**

| Emplacement | Chargement | Probleme |
|-------------|------------|----------|
| Command (inline) | A chaque `/command` | Pollue le contexte (~50 tokens gaspilles) |
| CLAUDE.md | Toujours charge | Templates = gros fichiers = gaspillage |
| **Skill `templates/`** | **A la demande** | Progressive disclosure optimal |

---

## 5. Slash Commands

### Definition

Une commande slash est un fichier Markdown contenant un prompt que TU declenches manuellement en tapant `/nom-commande`.

### Emplacements

- **Projet** : `.claude/commands/*.md` -> `/*` (affiche `(project)` dans /help)
- **Personnel** : `~/.claude/commands/*.md` -> `/*` (affiche `(user)` dans /help)
- **Sous-dossiers** : `.claude/commands/deploy/prod.md` -> `/deploy:prod`

### Structure du fichier

```yaml
---
description: Description affichee dans /help
argument-hint: [arg1] [arg2]
allowed-tools: Tool1, Tool2          # Limite les outils
model: sonnet                        # Force un modele
disable-model-invocation: false      # true = empeche Claude d'invoquer automatiquement
---

# Instructions

Le texte apres la commande est dans $ARGUMENTS
Arguments individuels : $1, $2, $3

## Contexte dynamique
- Branche : !`git branch --show-current`
- Status : !`git status --short`
```

### Variables disponibles

| Variable | Description | Exemple |
|----------|-------------|---------|
| `$ARGUMENTS` | Tout le texte apres la commande | `/create-issue BUG-001-fix-login` → `BUG-001-fix-login` |
| `$1`, `$2`, `$3` | Arguments individuels | `/cmd arg1 arg2` → `$1`=arg1, `$2`=arg2 |
| `!`backticks | Execution dynamique | `!`git branch --show-current`` |

### Commandes du projet

| Commande | Usage |
|----------|-------|
| `/create-script ScriptName` | Cree un script PowerShell |
| `/create-function Verb-Noun` | Cree une fonction CmdletBinding |
| `/create-test FunctionName` | Cree tests Pester (TDD RED) |
| `/create-issue TYPE-XXX-titre` | Cree issue locale |
| `/implement-issue TYPE-XXX-titre` | Implemente issue (branche + commit) |
| `/run-tests [path]` | Execute tests Pester |
| `/review-code` | Review code PowerShell |
| `/audit-code [path] [focus]` | Audit 6 phases complet |
| `/session-start` | Charge contexte session |
| `/session-save` | Sauvegarde etat session |
| `/session-end` | Resume + rappel /clear |

### Commandes slash integrees

| Commande | Usage |
|----------|-------|
| `/help` | Liste toutes les commandes |
| `/init` | Cree CLAUDE.md |
| `/clear` | Efface la conversation |
| `/compact [instructions]` | Compresse le contexte |
| `/model` | Change de modele |
| `/permissions` | Gere les permissions |
| `/hooks` | Configure les hooks |
| `/rewind` | Menu des checkpoints |
| `/config` | Affiche configuration |
| `/doctor` | Diagnostic installation |
| `/bug` | Signale un bug |
| `/usage` | Consommation tokens |
| `/cost` | Cout session |
| `/resume` | Reprend session precedente |

---

## 6. CLAUDE.md et imports

### Fonctionnement

Quand Claude Code demarre dans un repertoire :
1. Cherche `CLAUDE.md` a la racine
2. Sinon cherche `.claude/CLAUDE.md`
3. Charge aussi `~/.claude/CLAUDE.md` (preferences globales)
4. Tout est injecte dans le **contexte initial**

### Syntaxe des imports @

```markdown
# Mon Projet

## Architecture
@docs/ARCHITECTURE.md

## Personal instructions (not in repo)
@~/.claude/my-project-instructions.md
```

Les fichiers references via `@` sont charges dans le contexte.

**Caracteristiques :**
- Resolution dynamique (pas seulement au demarrage)
- Profondeur max : **5 niveaux** d'imports imbriques
- Imports ignores dans les blocs de code markdown
- `CLAUDE.local.md` est **deprecated** - utiliser les imports a la place

### Imports relatifs dans les sous-fichiers

Dans les skills, les imports relatifs permettent de referencer les fichiers du meme dossier :
```markdown
## References
@naming.md              # Relatif au dossier du skill
@parameters.md          # Autre fichier du meme skill
```

### Bonnes pratiques CLAUDE.md

**A faire :**
- Garder sous 200 lignes (idealement 100)
- Mettre les informations critiques en premier
- Utiliser les imports @ pour les details
- Mettre a jour quand le projet evolue

**A eviter :**
- Copier toute la documentation
- Inclure du code source
- Mettre des informations volatiles

### Structure recommandee

```markdown
# Nom du Projet

## Context
- Stack: PowerShell 7.2+
- Purpose: [Description]
- Author: [Nom]

## Project Structure
[Arborescence simplifiee]

## Slash Commands
[Liste des commandes]

## Agents
[Liste des agents]

## Session Management
[Instructions session]

## Quick Commands
[Commandes frequentes]
```

---

# PARTIE C : AGENTS ET SUBAGENTS

---

## 7. Custom Agents

### Definition

Un agent personnalise avec sa propre personnalite, instructions, outils autorises, et **contexte isole**.

### Difference avec les Skills

| Aspect | Skills | Custom Agents |
|--------|--------|---------------|
| Focus | Savoir-faire | Personnalite + savoir-faire |
| Contexte | Partage | **Isole** |
| Outils | Herite | Configurable |
| Modele | Herite | Configurable |

### POURQUOI les agents n'heritent pas du CLAUDE.md

C'est un choix architectural d'Anthropic :
- **Isolation** : Chaque agent a son propre contexte de 200k tokens
- **Securite** : Un agent ne peut pas "voir" ce qui se passe ailleurs
- **Performance** : Pas de surcharge du contexte principal

**Consequence** : Vous devez inclure dans le system prompt de l'agent l'instruction de lire les skills necessaires.

### COMMENT faire lire les conventions a un agent

Inclure dans le system prompt de l'agent :

```markdown
## PREMIERE ETAPE OBLIGATOIRE

Avant de commencer, lis `.claude/skills/powershell-development/SKILL.md`
pour connaitre les conventions du projet.
```

### Structure du fichier agent

```yaml
---
name: identifiant-unique
description: Description de QUAND utiliser cet agent
tools: Read, Grep, Glob, Bash(git:*)
model: sonnet  # opus, sonnet, haiku (alias valides)
---

# Instructions

Tu es [role de l'agent]...

## Ton expertise
...

## Ta methode de travail
...

## Format de tes reponses
...
```

### Champs du frontmatter agent

| Champ | Requis | Description |
|-------|--------|-------------|
| `name` | **Oui** | Identifiant unique de l'agent |
| `description` | **Oui** | QUAND utiliser cet agent (critique pour decouverte auto) |
| `tools` | Non | Outils autorises (herite si omis) |
| `model` | Non | Modele a utiliser (herite si omis) |

> **Note importante** : Le champ `skills:` pour auto-charger des skills dans un agent n'est **pas confirme** dans la documentation officielle Anthropic (decembre 2025). Pour faire connaitre les conventions du projet a un agent, utiliser l'instruction explicite dans le system prompt :
>
> ```markdown
> ## PREMIERE ETAPE OBLIGATOIRE
> Avant de commencer, lis `.claude/skills/powershell-development/SKILL.md`
> pour connaitre les conventions du projet.
> ```

### Alias de modeles

Les alias `opus`, `sonnet`, `haiku` sont **officiellement supportes** et pointent vers les dernieres versions :

| Alias | Version actuelle | Usage recommande |
|-------|------------------|------------------|
| `haiku` | Claude Haiku 4.5 | Exploration, taches legeres, cout minimal |
| `sonnet` | Claude Sonnet 4.5 | **Defaut** - coding, tests, documentation |
| `opus` | Claude Opus 4.5 | Raisonnement complexe, securite critique |

### Choix du modele : MATRICE DE DECISION

| Cas d'usage | Modele | Justification |
|-------------|--------|---------------|
| **Exploration codebase** | haiku | 90% capacite, 3x moins cher, plus rapide |
| **Coding quotidien** | sonnet | Excellent rapport qualite/cout |
| **Reviews critiques** | opus | SWE-bench 80.9% (+3.7% vs Sonnet) |
| **Audit securite** | opus | Zero-tolerance sur faux negatifs |
| **Documentation** | sonnet | Suffisant pour la redaction |
| **Summarization** | haiku | Tache simple, optimiser le cout |

**Benchmarks Novembre 2025** :
- Opus 4.5 : **~80%** SWE-bench Verified (meilleur modele coding)
- Sonnet 4.5 : ~77% SWE-bench Verified
- Opus utilise significativement moins de tokens que Sonnet pour meme resultat

**Pricing** : Opus $5/$25 vs Sonnet $3/$15 (ratio 1.7x, acceptable pour taches critiques)

> Source : [Claude Opus 4.5 Announcement](https://www.anthropic.com/news/claude-opus-4-5)

### Invocation

**Automatique** : Claude decide selon la description

**Manuelle** :
```
Utilise l'agent security-auditor pour analyser ce code
```

### Agents du projet

| Agent | Model | Tools | Usage |
|-------|-------|-------|-------|
| `code-reviewer` | **opus** | Read, Grep, Glob | Review PowerShell contre standards |
| `test-writer` | sonnet | Read, Write, Glob | Ecriture tests Pester TDD |
| `context-explorer` | **haiku** | Read, Grep, Glob | Exploration sans polluer contexte |
| `session-summarizer` | sonnet | Read, Write, Glob | Capture etat session |
| `security-auditor` | **opus** | Read, Grep, Glob | Audit securite PowerShell |
| `tech-researcher` | sonnet | WebSearch, Read | Recherche technique approfondie |

### Context-explorer : POURQUOI haiku pour l'exploration

```yaml
---
name: context-explorer
tools: Read, Grep, Glob
model: haiku              # Rapide et leger
---

Explore et resume. Retourne UNIQUEMENT :
- Fichiers pertinents trouves
- Patterns identifies
- Resume concis (max 500 mots)
```

**Pourquoi haiku ?** Il economise le contexte principal en faisant l'exploration dans un contexte isole et en retournant seulement un resume.

---

## 8. Subagents integres

### Definition

Agents specialises **pre-construits par Anthropic** avec leur propre contexte isole.

### Les subagents disponibles

| Subagent | Capacites | Usage |
|----------|-----------|-------|
| **General-purpose** | Lire, modifier, executer | Taches multi-etapes |
| **Explore** | Lecture seule | Recherche/analyse codebase |
| **Plan** | Collecte info, prepare plans | Mode Plan |

### Comment Claude decide

C'est automatique. Claude evalue :
- Complexite de la tache
- Risque de pollution contexte
- Specialisation necessaire

Tu peux aussi demander explicitement :
```
Utilise un subagent pour analyser tous les fichiers d'authentification
et me faire un resume.
```

### Avantage cle : isolation du contexte

Le subagent peut lire 20 fichiers, ces 20 fichiers ne sont **PAS** dans ton contexte principal. Seul le resume revient.

**Exemple :**
```
Utilise 4 subagents en parallele pour explorer les modules.
Chaque agent retourne un resume de 200 mots.
```

Resultat : 4 contextes isoles (4 x 200k tokens), contexte principal recoit seulement les resumes.

### Regles critiques des Subagents

#### Anti-nesting (regle stricte)

Les subagents **ne peuvent PAS** appeler d'autres subagents. C'est une limitation architecturale.

> **Source officielle** : *"This prevents infinite nesting of agents (subagents cannot spawn other subagents)."* — [Claude Code Docs](https://code.claude.com/docs/en/sub-agents)

**Outils disponibles pour un subagent** : Bash, Glob, Grep, Read, Edit, Write, WebFetch, TodoWrite, WebSearch...

**Outil NON disponible** : `Task` (creation de subagents)

#### Parallelisation (cap ~10)

Claude Code supporte jusqu'a **10 subagents paralleles**. Au-dela, les taches sont mises en queue.

```
Exemple : 15 taches demandees
├─► 10 executees en parallele
└─► 5 en queue, lancees au fur et a mesure
```

> **Source** : [Subagent Deep Dive](https://cuong.io/blog/2025/06/24-claude-code-subagent-deep-dive)

**Comportement de la queue :**
- Sans parallelisme specifie : nouvelles taches lancees des qu'une se termine
- Avec parallelisme specifie (ex: 4) : attend que le batch soit termine avant le suivant

### QUAND demander explicitement un subagent

| Situation | Action |
|-----------|--------|
| Analyser >10 fichiers | Subagent Explore |
| Paralleliser (max ~10) | Multiple subagents |
| Tache en plusieurs etapes independantes | General-purpose |
| Planification avant implementation | Mode Plan + subagent |
| Proteger le contexte principal | Toujours subagent |

---

# PARTIE D : SECURITE ET CONTROLE

---

## 9. Permissions

### Philosophie

Claude Code suit le **moindre privilege** : par defaut, demande permission pour actions impactantes.

### Les outils

| Outil | Description | Risque |
|-------|-------------|--------|
| `Read` | Lire fichiers | Faible |
| `Edit` / `Write` | Modifier fichiers | Moyen |
| `Bash` | Commandes shell | Variable |
| `Glob` | Lister fichiers | Faible |
| `Grep` | Rechercher | Faible |
| `WebFetch` | Acceder URLs | Moyen |
| `Task` | Deleguer subagent | Variable |

### Configuration

**Via interface** : `/permissions`

**Via fichier** : `.claude/settings.json`

```json
{
  "permissions": {
    "allow": [
      "Read(**)",
      "Bash(npm run:*)",
      "Bash(git status)",
      "Bash(git diff:*)",
      "Bash(git log:*)",
      "Bash(Invoke-Pester:*)",
      "Bash(pwsh:*)"
    ],
    "deny": [
      "Read(.env)",
      "Read(.env.*)",
      "Read(**/*.pem)",
      "Bash(rm -rf:*)",
      "Bash(sudo:*)"
    ]
  }
}
```

### Syntaxe des patterns

**Fichiers :**
- `*` : Tout sauf `/`
- `**` : Recursif
- `Read(.env)` : Fichier exact
- `Read(src/**/*.ps1)` : Pattern glob

**Commandes Bash :**
- `Bash(npm run:*)` : Prefixe
- `Bash(git:*)` : Toute commande git
- `Bash(Invoke-Pester)` : Exact

### Section `ask` - Confirmation utilisateur

La section `ask` demande une confirmation avant execution :

```json
{
  "permissions": {
    "ask": [
      "Bash(git commit:*)",
      "Bash(git push:*)",
      "Bash(git merge:*)",
      "Write(CLAUDE.md)",
      "Write(.claude/settings.json)"
    ]
  }
}
```

**QUAND utiliser `ask`** :
- Operations Git irreversibles (commit, push, merge)
- Modification de fichiers critiques (CLAUDE.md, settings.json)

### Permissions recommandees PowerShell

```json
{
  "permissions": {
    "allow": [
      "Read(**)",
      "Bash(pwsh:*)",
      "Bash(Invoke-Pester:*)",
      "Bash(git status)",
      "Bash(git diff:*)",
      "Bash(git log:*)",
      "Bash(git branch:*)",
      "Bash(git add:*)"
    ],
    "ask": [
      "Bash(git commit:*)",
      "Bash(git push:*)",
      "Bash(git merge:*)",
      "Write(CLAUDE.md)",
      "Write(.claude/settings.json)"
    ],
    "deny": [
      "Read(Config/Settings.json)",
      "Read(**/*.key)",
      "Read(**/*.pem)",
      "Read(**/.env)",
      "Bash(Remove-Item*-Recurse*)",
      "Bash(rm -rf:*)",
      "Bash(git push --force:*)",
      "Bash(sudo:*)"
    ]
  }
}
```

### Bug Critique : `deny` potentiellement inefficace

> **AVERTISSEMENT SECURITE** (Decembre 2025)
>
> Plusieurs bugs ont ete reportes concernant les regles `deny` :
> - [Issue #6631](https://github.com/anthropics/claude-code/issues/6631) - Permission Deny Not Enforced
> - [Issue #6699](https://github.com/anthropics/claude-code/issues/6699) - Critical Security Bug
>
> **Impact** : Les fichiers dans `deny` peuvent etre accessibles malgre la configuration.
>
> **Solution recommandee** : Utiliser un hook `PreToolUse` comme protection supplementaire (voir Section 10).

Les regles `deny` restent utiles comme **premiere ligne de defense**, mais ne doivent pas etre la seule protection pour les fichiers sensibles.

---

## 10. Hooks

### Definition

Commandes shell qui s'executent automatiquement a certains moments. Contrairement aux instructions CLAUDE.md, les hooks s'executent **toujours**.

### POURQUOI les hooks vs CLAUDE.md ?

| Aspect | CLAUDE.md | Hooks |
|--------|-----------|-------|
| Nature | Instructions (suggestions) | Commandes (forcees) |
| Execution | Claude peut ignorer | Toujours execute |
| Usage | Conventions, preferences | Securite, formatage |

### Evenements disponibles

| Evenement | Declenchement | Usage |
|-----------|---------------|-------|
| `PreToolUse` | Avant outil | Bloquer, valider, **modifier inputs** |
| `PostToolUse` | Apres outil | Formater, logger, feedback |
| `Notification` | Notification Claude | Alertes |
| `Stop` | Fin generation | Actions post-reponse |

**Note importante (v2.0.10+)** : PreToolUse peut maintenant **modifier les inputs** avant execution au lieu de simplement bloquer.

### PreToolUse vs PostToolUse : QUAND utiliser lequel

| Hook | QUAND utiliser | Exemples |
|------|----------------|----------|
| **PreToolUse** | Intercepter AVANT execution | Bloquer fichiers sensibles, valider paths |
| **PostToolUse** | Reagir APRES execution | Formater code, logger, notifier |

### Configuration

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "prettier --write \"$CLAUDE_FILE_PATH\"",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

### Variables disponibles

| Variable | Description |
|----------|-------------|
| `$CLAUDE_FILE_PATH` | Chemin fichier |
| `$CLAUDE_FILE_PATHS` | Liste chemins (space-separated) |
| `$CLAUDE_TOOL_NAME` | Nom outil |
| `$CLAUDE_TOOL_INPUT` | Entree (JSON) |
| `$CLAUDE_TOOL_OUTPUT` | Sortie outil (PostToolUse only) |
| `$CLAUDE_PROJECT_DIR` | Repertoire projet |

### Exit codes (PreToolUse)

Le hook PreToolUse peut controler l'execution via des exit codes :

| Exit Code | Effet |
|-----------|-------|
| `0` | Autoriser l'operation (JSON traite) |
| `1` | Erreur non-bloquante (stderr affiche) |
| `2` | **Bloquer** l'operation (stderr utilise) |

> **Bug connu** ([#4809](https://github.com/anthropics/claude-code/issues/4809)) : Exit code 1 peut parfois bloquer l'execution malgre la documentation.

### Format de sortie JSON (PreToolUse)

Pour un message personnalise lors du blocage, utiliser le format officiel :

```json
{
  "hookSpecificOutput": {
    "permissionDecision": "deny",
    "permissionDecisionReason": "Fichier sensible bloque par hook securite"
  }
}
```

> **Note** : Les champs `decision`/`reason` sont **deprecies**. Utiliser `hookSpecificOutput.permissionDecision` ("allow" ou "deny").
>
> Source : [Hooks Reference](https://docs.claude.com/en/docs/claude-code/hooks)

### Exemple COMPLET : Hook PreToolUse de securite (RECOMMANDE)

Ce hook bloque l'acces aux fichiers sensibles, en complement des regles `deny` :

**Configuration `.claude/settings.json`** :

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Read|Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "pwsh -NoProfile -File \".claude/hooks/security-check.ps1\"",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

**Script `.claude/hooks/security-check.ps1`** :

```powershell
# Patterns de fichiers bloques
$blockedPatterns = @(
    '**/Config/Settings.json',
    '**/*.key',
    '**/*.pem',
    '**/.env',
    '**/.env.*'
)

$filePath = $env:CLAUDE_FILE_PATH

foreach ($pattern in $blockedPatterns) {
    if ($filePath -like $pattern) {
        # Format JSON officiel (hookSpecificOutput)
        $response = @{
            hookSpecificOutput = @{
                permissionDecision = "deny"
                permissionDecisionReason = "Acces bloque par hook securite: $pattern"
            }
        } | ConvertTo-Json -Compress

        Write-Output $response
        exit 2  # Bloquer
    }
}

exit 0  # Autoriser
```

**POURQUOI ce hook en plus de `deny` ?**
- Bug connu : `deny` peut etre contourne
- Hook = execution garantie
- Messages personnalises
- Logique complexe possible

### Exemple : Formatage PowerShell (PostToolUse)

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "pwsh -NoProfile -Command \"if ('$CLAUDE_FILE_PATH' -like '*.ps1') { Invoke-Formatter -ScriptDefinition (Get-Content '$CLAUDE_FILE_PATH' -Raw) | Set-Content '$CLAUDE_FILE_PATH' }\"",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

### Securite des hooks

Les hooks s'executent avec **TES privileges**. Revise toujours le code avant activation.

**Bonnes pratiques :**
- Timeout court (5-30 secondes)
- Scripts dans `.claude/hooks/` (versiones)
- Pas de secrets dans les scripts
- Tester manuellement avant activation

---

# PARTIE E : GESTION DU CONTEXTE

---

## 11. Session Management

### POURQUOI la gestion de session ?

| Probleme | Solution |
|----------|----------|
| Pollution contexte entre taches | /clear libere 200k tokens |
| Perte de decisions/progres | SESSION-STATE.md preserve l'etat |
| Re-expliquer a chaque session | /session-start charge le contexte |
| Economiser tokens | Skills = progressive disclosure |

### Workflow complet avec RAISONNEMENT

```
1. /session-start     ← POURQUOI : Eviter de re-expliquer le contexte
   │                    Claude charge SESSION-STATE.md, connait l'etat
   │
2. [Travail]          ← Mise a jour periodique SESSION-STATE.md
   │                    Sauvegarder decisions importantes
   │
3. /session-save      ← POURQUOI : Checkpoint si crash/interruption
   │                    Etat intermediaire preserve
   │
4. /session-end       ← POURQUOI : Forcer resume structure AVANT /clear
   │                    Resume complet pour prochaine session
   │
5. /clear             ← POURQUOI : Liberer 200k tokens pollues
                        Contexte propre pour prochaine tache
```

### SESSION-STATE.md - Template complet

```markdown
# Etat de Session - [Date]

## Tache en Cours
**[ID Issue]** - Description specifique
- Etape actuelle : [X/Y]
- Blocages : [Si applicable]

## Progression
- [x] Etape completee
- [-] Etape en cours
- [ ] Etape a faire

## Decisions Cles
| Decision | Justification |
|----------|---------------|
| [Choix fait] | [Pourquoi ce choix] |

## Fichiers Modifies
| Fichier | Modification |
|---------|--------------|
| path/file.ps1 | [Description] |

## Contexte a Preserver
[Informations critiques pour prochaine session]

## Blocages/Issues
[Problemes rencontres, solutions tentees]

## Prochaines Etapes
1. **Immediat** : [Action]
2. **Ensuite** : [Action suivante]
3. **Plus tard** : [Action future]
```

### Agents de session

| Agent | Usage |
|-------|-------|
| **session-summarizer** | Capture etat complet avant /clear |
| **context-explorer** | Explore sans polluer (utilise haiku) |

---

## 12. Memory Management

### Principe #1 : /clear > /compact

**Pourquoi eviter /compact ?**
- Lent (1+ minute)
- Perte de fidelite (resume approximatif)
- Accumulation de bruit

**Workflow recommande :**
```
Tache simple    → /clear apres completion
Tache complexe  → Fichier d'etat + /clear
Session longue  → Checkpoints + SESSION-STATE.md
```

### Principe #2 : Desactiver Auto-Compact

```
/config → Auto-compact → false
```

**Pourquoi ?** Auto-compact consomme ~40-45k tokens avec du vieux contexte non controle.

### Principe #3 : CLAUDE.md minimal

**Regle des 100-200 lignes :**
- **Inclure** : Ce qui est necessaire a CHAQUE session
- **Exclure** : Tout le reste → references avec `@`

### Principe #4 : Subagents pour isoler

Chaque subagent a son propre contexte de 200k tokens. Ca preserve le contexte principal.

**Exemple :**
```
Utilise 4 subagents en parallele pour explorer les modules.
Chaque agent retourne un resume de 200 mots.
```

Resultat : 4 contextes isoles, contexte principal recoit seulement les resumes.

---

## 13. Checkpoints et navigation

### Checkpoints automatiques

Avant chaque modification, Claude Code cree un checkpoint :
- Etat de tous les fichiers modifies
- Etat de la conversation
- **Retention** : 30 jours

### Acces

- **Raccourci** : `Esc + Esc`
- **Commande** : `/rewind`

### Reprendre une session precedente

| Commande | Usage |
|----------|-------|
| `claude -c` | Continue la conversation la plus recente |
| `claude --continue` | Idem |
| `claude -r "abc123"` | Reprend une session specifique par ID |
| `claude --resume` | Affiche liste des sessions recentes |

### Raccourcis utiles

| Raccourci | Action |
|-----------|--------|
| `Ctrl+R` | Historique des prompts (recherche) |
| `Ctrl+B` | Envoyer commande en background |
| `K` | Killer processus background |

### Options de restauration

| Option | Effet |
|--------|-------|
| **Code seulement** | Restaure fichiers, garde conversation |
| **Conversation seulement** | Restaure conversation, garde fichiers |
| **Les deux** | Retour complet |

### Cas d'usage

**Claude a fait une erreur :**
```
Esc+Esc → Selectionne checkpoint avant erreur → Restaure code
```

**Exploration de plusieurs approches :**
```
Claude implemente A → Note checkpoint → Restaure → Claude implemente B → Compare
```

### Background Tasks (Octobre 2025)

Plusieurs methodes pour lancer en arriere-plan :

**Methode 1 : Prefixe `&`**
```
& npm run dev
& Invoke-Pester -Path ./Tests
```

**Methode 2 : Ctrl+B**
Apres avoir tape une commande, appuie `Ctrl+B` pour la pousser en arriere-plan.

**Methode 3 : SDK**
```json
{ "run_in_background": true }
```

**Caracteristiques :**
- Les taches persistent entre sessions
- Claude monitore la sortie en temps reel
- Appuie `K` pour killer un processus background
- Ideal pour : dev servers, builds longs, tests continus

### Limitations des checkpoints

- Ne track pas les commandes bash destructives (rm, mv)
- Session-level seulement (pas cross-session)
- Complementaire a Git (pas de remplacement)

---

# PARTIE F : INTEGRATIONS EXTERNES

---

## 14. MCP Servers

### Definition

MCP (Model Context Protocol) est un standard pour connecter Claude a des services externes.

### Scopes de configuration

| Scope | Fichier | Portee |
|-------|---------|--------|
| Local | `.claude/.mcp.json` | Projet actuel |
| Project | `.mcp.json` (racine) | Equipe (partage git) |
| User | `~/.claude.json` | Tous tes projets |

Priorite : Local > Project > User

### Architecture

```
Claude Code <-> Client MCP <-> Serveur MCP <-> Service externe
                               (GitHub)        (API GitHub)
```

### Ajouter un serveur

**Transport STDIO (local)** :
```bash
claude mcp add nom-serveur -- commande-de-lancement

# Exemples
claude mcp add github -- npx @modelcontextprotocol/server-github
claude mcp add github --env GITHUB_TOKEN=ghp_xxx -- npx @modelcontextprotocol/server-github
```

**Transport HTTP (distant)** - Recommande pour serveurs cloud :
```bash
claude mcp add --transport http notion https://mcp.notion.com/mcp
claude mcp add --transport http secure-api https://api.example.com/mcp --header "Authorization: Bearer token"
```

> **Windows** : Les serveurs locaux avec `npx` necessitent le wrapper `cmd /c` :
> ```bash
> claude mcp add my-server -- cmd /c npx -y @some/package
> ```
> Sans ce wrapper, vous aurez des erreurs "Connection closed".

### Configuration via fichier

`.mcp.json` a la racine :

```json
{
  "servers": {
    "github": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

### Utilisation

Les outils MCP apparaissent comme commandes :
```
/mcp__github__create_issue "Titre" "Description"
/mcp__github__list_prs
```

Claude peut les utiliser automatiquement quand pertinent.

### Serveurs populaires

| Serveur | Usage |
|---------|-------|
| `github` | PRs, issues, repos |
| `slack` | Messages, channels |
| `postgres` | Requetes SQL |
| `puppeteer` | Automatisation web |
| `filesystem` | Fichiers etendus |
| `brave-search` | Recherche web |
| `memory` | Memoire persistante |

### Debogage

```bash
claude --mcp-debug
```

### Limites de tokens

| Parametre | Valeur | Description |
|-----------|--------|-------------|
| Seuil d'avertissement | 10,000 tokens | Alerte si sortie MCP depasse |
| Maximum par defaut | 25,000 tokens | Limite totale sortie MCP |
| Variable d'env | `MAX_MCP_OUTPUT_TOKENS` | Pour ajuster la limite |

> Source : [MCP Documentation](https://docs.anthropic.com/en/docs/claude-code/mcp)

---

## 15. Plugins (Beta Publique Octobre 2025)

### Definition

Les plugins sont des packages qui combinent slash commands, agents, MCP servers et hooks, installables en une commande.

### Installation depuis un marketplace

```bash
# Ajouter un marketplace
/plugin marketplace add user-or-org/repo-name

# Naviguer et installer
/plugin
```

### Ce que contient un plugin

- **Slash commands** (raccourcis custom)
- **Subagents** (agents specialises)
- **MCP servers** (connexions externes)
- **Hooks** (automatisations)

### Marketplaces populaires

| Marketplace | Plugins |
|-------------|---------|
| Claude Code Plugins Plus | 243 plugins |
| Claude Code Skills Hub | 185 skills + 255 plugins |
| Claude Marketplace | 140+ plugins |

### Installation directe

```bash
npx claude-plugins install @anthropics/claude-code-plugins/code-review
```

---

# PARTIE G : BONNES PRATIQUES

---

## 16. Style de Prompting Opus 4.5

### Changement majeur

Claude Opus 4.5 est **plus reactif au system prompt** que les versions precedentes. Les prompts agressifs qui fonctionnaient avant peuvent maintenant **sur-declencher**.

### Ancien style (a eviter)

```markdown
CRITICAL: You MUST use this tool when...
NEVER use vague variable names
FORBIDDEN: Hardcoded credentials
YOU MUST ALWAYS use -ErrorAction Stop
```

### Nouveau style (recommande)

```markdown
Use this tool when...

## Variable Naming
Use explicit names that describe the content.
Why? Vague names like $data or $temp reduce clarity and cause bugs.

## Credentials
Store credentials in environment variables or SecureString.
Hardcoded credentials in code are a security risk.

## Error Handling
Use -ErrorAction Stop on cmdlets in try-catch blocks.
Why? Non-terminating errors bypass the catch block silently.
```

### Principes cles

1. **Expliquer le POURQUOI** plutot que donner des ordres
2. **Langage naturel** plutot que directives en majuscules
3. **Contexte et consequences** plutot que "NEVER" ou "MUST"
4. **Dial back any aggressive language** (citation Anthropic)

### Comportements Opus 4.5

- Plus concis et direct
- Ton plus naturel, moins robotique
- Focus efficacite (peut skip les resumes apres actions)
- Sensible au mot "think" - utiliser "consider", "evaluate" si extended thinking desactive

### Gestion du sur-engineering

Opus 4.5 peut parfois :
- Creer des fichiers supplementaires
- Ajouter des abstractions inutiles
- Builder de la flexibilite non demandee

**Solution** : Inclure dans les instructions :
```markdown
Avoid over-engineering. Only make changes that are directly requested.
Keep solutions simple and focused.
```

### Lire le code avant de proposer

Opus 4.5 peut proposer des solutions sans lire le code ou faire des suppositions sur des fichiers non lus.

**Solution** : Inclure dans les instructions :
```markdown
Always read and understand relevant files before proposing code edits.
Do not speculate about code you have not inspected.
If the user references a specific file, you MUST open and inspect it first.
```

> Source : [Claude Opus 4.5 Migration Plugin](https://github.com/anthropics/claude-code/blob/main/plugins/claude-opus-4-5-migration/skills/claude-opus-4-5-migration/references/prompt-snippets.md)

---

## 17. Conventions specifiques PowerShell

### Regles critiques

Ces regles sont expliquees en detail dans `.claude/skills/powershell-development/` :

#### Initialisation
```powershell
#Requires -Version 7.2
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
```

#### Nommage
- `[CmdletBinding()]` sur toutes fonctions
- `Verb-Noun` avec Noun **singulier**
- PascalCase fonctions/parametres
- Variables explicites (pas `$data`, `$temp`, `$i`, `$obj`)

#### Error Handling
```powershell
# -ErrorAction Stop dans try-catch (sinon catch jamais atteint)
try {
    Get-Item $path -ErrorAction Stop
} catch [System.IO.FileNotFoundException] {
    Write-Log "File not found" -Level ERROR
}
```

**POURQUOI `-ErrorAction Stop` ?** PowerShell a des erreurs non-terminantes qui ne declenchent pas le catch. Sans `-ErrorAction Stop`, votre catch est inutile.

#### Performance
```powershell
# List<T> au lieu de @() +=
$list = [System.Collections.Generic.List[string]]::new()

# .Where() au lieu de Where-Object
$active = $users.Where({ $_.Status -eq 'Active' })
```

**POURQUOI ?** `@() +=` recree le tableau entier a chaque ajout = O(n^2). `List<T>` = O(1) amorti.

#### User Input
```powershell
# TryParse au lieu de cast direct
$index = 0
if (-not [int]::TryParse($userInput, [ref]$index)) {
    Write-Error "Valeur numerique attendue"
}
```

**POURQUOI ?** Le cast direct `[int]$userInput` lance une exception si invalide. TryParse retourne un booleen.

#### UI Console
```powershell
# Brackets, PAS emoji
Write-Host "[+] " -NoNewline -ForegroundColor Green; Write-Host "Success"
Write-Host "[-] " -NoNewline -ForegroundColor Red; Write-Host "Error"
Write-Host "[!] " -NoNewline -ForegroundColor Yellow; Write-Host "Warning"
Write-Host "[i] " -NoNewline -ForegroundColor Cyan; Write-Host "Info"
```

**POURQUOI pas d'emoji ?** Compatibilite terminaux, encodage, lisibilite.

#### Git
- Commits atomiques : 1 commit = 1 changement logique
- Format : `type(scope): description`
- Pas de Co-Authored-By, mention AI/Claude, emoji

#### TDD
1. **RED** : Tests AVANT le code (doivent echouer)
2. **GREEN** : Minimum pour passer
3. **REFACTOR** : Ameliorer sans casser

### References detaillees

| Domaine | Fichier |
|---------|---------|
| Nommage | `.claude/skills/powershell-development/naming.md` |
| Parametres | `.claude/skills/powershell-development/parameters.md` |
| Erreurs | `.claude/skills/powershell-development/errors.md` |
| Performance | `.claude/skills/powershell-development/performance.md` |
| Securite | `.claude/skills/powershell-development/security.md` |
| Tests | `.claude/skills/powershell-development/pester.md` |
| TDD | `.claude/skills/development-workflow/tdd.md` |
| Workflow | `.claude/skills/development-workflow/workflow.md` |
| UI | `.claude/skills/powershell-development/ui-console.md` |
| Logging | `.claude/skills/powershell-development/logging.md` |
| Anti-patterns | `.claude/skills/powershell-development/anti-patterns.md` |

---

## 18. Conventions de Nommage Issues

### Format Unifie

Tous les elements lies aux issues suivent ces conventions :

| Contexte | Format | Exemple |
|----------|--------|---------|
| **Fichier** | `TYPE-XXX-titre.md` | `FIX-005-references-obsoletes.md` |
| **Titre H1** | `# [PRIORITE] TYPE-XXX Titre \| Effort: Xh` | `# [!] FIX-005 Corriger references \| Effort: 15min` |
| **GitHub title** | `[TYPE-XXX] Titre` | `[FIX-005] Corriger references obsoletes` |
| **Branche** | `feature/TYPE-XXX-titre` ou `fix/TYPE-XXX-titre` | `fix/FIX-005-references-obsoletes` |
| **Tableau** | `\| [TYPE-XXX](TYPE-XXX-titre.md) \| Titre \| Date \|` | Voir ci-dessous |
| **Checkbox** | `- [x] **TYPE-XXX** - Titre (Date)` | Pour les phases uniquement |

### Types d'Issue

| Type | Prefixe branche | Usage |
|------|-----------------|-------|
| `BUG` | `fix/` | Correction de bug |
| `FIX` | `fix/` | Correction mineure |
| `FEAT` | `feature/` | Nouvelle fonctionnalite |
| `REFACTOR` | `feature/` | Amelioration du code |
| `PERF` | `feature/` | Performance |
| `ARCH` | `feature/` | Architecture |
| `SEC` | `fix/` | Securite |
| `TEST` | `feature/` | Tests |
| `DOC` | `feature/` | Documentation |

### Priorites (dans le titre)

| Symbole | Niveau | Description |
|---------|--------|-------------|
| `!!` | Critique | Bloquant, hotfix immediat |
| `!` | Elevee | Sprint courant |
| `~` | Moyenne | Sprint suivant |
| `-` | Faible | Backlog |

### Exemple Complet

```
Fichier     : docs/issues/FIX-005-references-obsoletes.md
Titre H1    : # [!] FIX-005 Corriger references obsoletes | Effort: 15min
GitHub      : [FIX-005] Corriger references obsoletes
Branche     : fix/FIX-005-references-obsoletes
Commit      : fix(docs): correct obsolete references

            Fixes #XX
```

### Format Tableau (Issues Terminees)

```markdown
| ID | Titre | Date |
|----|-------|------|
| [FIX-005](FIX-005-references-obsoletes.md) | Corriger references obsoletes | 2025-12-10 |
```

### Format Checkbox (Phases uniquement)

```markdown
## Phase A : Infrastructure
- [x] **FEAT-001** - Structure projet (2025-12-08)
- [x] **FEAT-002** - Configuration (2025-12-09)
- [ ] **FEAT-003** - Tests
```

---

## 19. Erreurs Courantes a Eviter

### Convertir toutes ses Commands en Skills

> "Je vais tout mettre en Skill pour que ce soit automatique"

**Probleme** : Tu perds le controle et la visibilite. L'activation automatique n'est pas garantie a 100%. Garde tes primitives (Commands).

### Creer un Skill pour une tache one-shot

> "Je cree un Skill pour generer ce fichier de config"

**Probleme** : Sur-ingenierie. Une Command suffit. Rappel : FAIRE une fois = Command, GERER un ensemble = Skill.

### Utiliser MCP pour de la logique interne

> "Je vais creer un MCP server pour mes conventions de code"

**Probleme** : Un Skill est plus approprie et plus context-efficient. MCP = integrations externes (APIs, BDD, SaaS).

### Oublier d'instruire les Subagents

> "Mon subagent ne suit pas les conventions du projet"

**Probleme** : Les subagents n'heritent pas de CLAUDE.md.

**Solution** : Ajouter dans le system prompt de l'agent :
```markdown
## PREMIERE ETAPE OBLIGATOIRE
Avant de commencer, lis `.claude/skills/powershell-development/SKILL.md`
pour connaitre les conventions du projet.
```

### Faire des subagents qui appellent des subagents

> "Mon orchestrateur va deleguer a des sous-orchestrateurs"

**Probleme** : Impossible. Regle anti-nesting stricte. Les subagents n'ont pas acces a l'outil `Task`.

### Compter sur l'activation automatique a 100%

> "Je n'ai pas besoin de tester, Claude va forcement utiliser mon Skill"

**Probleme** : L'activation depend fortement de la qualite de la description.

**Solution** : Utiliser le pattern WHEN + WHEN NOT :
```yaml
description: "PowerShell standards. Use when writing .ps1/.psm1 files.
Do NOT load for general scripting questions."
```

### Vouloir paralleliser avec autre chose que Subagent

> "Je veux lancer 3 Skills en parallele"

**Probleme** : Seuls les Subagents peuvent etre parallelises (cap ~10 simultanes).

---

## 20. Checklist de Decision

Avant de creer un nouveau mecanisme, pose-toi ces questions :

**1. Est-ce une tache ponctuelle ?**
- OUI → Slash Command
- NON → Continue

**2. Est-ce une integration avec un service externe ?**
- OUI → MCP Server
- NON → Continue

**3. Ai-je besoin de paralleliser ou d'isoler le contexte ?**
- OUI → Subagent
- NON → Continue

**4. Est-ce un probleme recurrent avec plusieurs facettes a GERER ?**
- OUI → Skill
- NON → Reviens a Slash Command

**5. Ma Command actuelle est-elle appelee plus de 5x/jour ?**
- OUI → Considere la convertir en Skill
- NON → Garde la Command

**6. Ai-je besoin d'un controle explicite sur l'invocation ?**
- OUI → Command OU Skill avec `disable-model-invocation: true`
- NON → Skill standard

---

# PARTIE H : REFERENCE

---

## 21. Workflow Issues du Projet

### CONCEPT : docs/issues/README.md comme index central

Le projet utilise `docs/issues/README.md` comme **index central** des issues, combinant :
- Vue d'ensemble avec phases
- Issues terminees / en cours / a faire
- Progression avec barre et indicateurs

### Structure docs/issues/README.md

```markdown
# Issues - Phases

## Workflow
| Commande | Usage |
|----------|-------|
| `/create-issue TYPE-XXX-titre` | Creer une issue locale |
| `/implement-issue TYPE-XXX-titre` | Implementer une issue |

**Regle** : 1 issue = 1 branche = 1 commit atomique

## Vue d'ensemble
| Phase | Status | Issues |
|-------|--------|--------|
| Setup | Done | - |
| A - [Nom] | Todo | 0/X |
| B - [Nom] | Todo | 0/X |

## Phase A : [Nom]
- [ ] **A1** : [Description]
- [ ] **A2** : [Description]

## Issues Terminees
| ID | Titre | Date |
|----|-------|------|

## Progression
Phases : [----------] 0% (0/X issues)
Active  : [Aucune]
Next    : [Premiere issue]
```

### Workflow complet

```
┌─────────────────────────────────────────────────────────────────┐
│                    WORKFLOW ISSUES                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. ANALYSER      →  Identifier probleme                        │
│  2. DOCUMENTER    →  /create-issue TYPE-XXX-titre               │
│  3. STOP          →  Attendre validation explicite              │
│  4. IMPLEMENTER   →  /implement-issue TYPE-XXX-titre            │
│                      (sync GitHub automatique a la fin)         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**POURQUOI ce workflow ?**
- **ANALYSER** : Comprendre avant d'agir
- **DOCUMENTER** : Tracabilite, specification claire
- **STOP** : Validation humaine obligatoire
- **IMPLEMENTER** : Execution structuree (branche + commit)

### Commands impliquees

| Commande | Action |
|----------|--------|
| `/create-issue TYPE-XXX-titre` | Cree fichier dans `docs/issues/` |
| `/implement-issue TYPE-XXX-titre` | Cree branche, implemente, commit + sync GitHub auto |
| `/sync-issue TYPE-XXX-titre` | Sync GitHub standalone (pour discussion avant implementation) |

### Skills impliques

| Skill | Role |
|-------|------|
| `progress-tracking` | Templates + MAJ automatique README |
| `development-workflow` | Git, TDD, conventions issues |

### Regle fondamentale

**1 issue = 1 branche = 1 commit atomique**

Chaque commit doit etre :
- Autonome (fonctionne seul)
- Reversible (peut etre revert)
- Focalize (un seul changement logique)

### Phases vs Issues hors-phases

| Type | Usage | Exemple |
|------|-------|---------|
| **Phases** | Progression structuree du projet | Phase A : Infrastructure |
| **Hors-phases** | Corrections/ameliorations ponctuelles | FIX-006 : Bug mineur |

Les issues hors-phases apparaissent dans une section separee du README.

---

## 22. Reference rapide

### Raccourcis clavier

| Raccourci | Action |
|-----------|--------|
| `Shift+Tab` | Cycler modes |
| `Esc` | Interrompre |
| `Esc+Esc` | Menu checkpoints |
| `Ctrl+C` | Quitter |
| `Ctrl+R` | Historique prompts |
| `Ctrl+B` | Background task |
| `K` | Kill background process |

### Commandes essentielles

| Commande | Usage |
|----------|-------|
| `/help` | Liste commandes |
| `/clear` | Efface conversation |
| `/compact` | Compresse contexte |
| `/model` | Change modele |
| `/rewind` | Checkpoints |
| `/session-start` | Charge session |
| `/session-save` | Sauvegarde session |
| `/session-end` | Termine session |

### Workflow nouveau projet

1. `/init` - Creer CLAUDE.md
2. `/permissions` - Configurer permissions
3. Creer `.claude/commands/` avec workflows
4. Configurer MCP si necessaire
5. `Shift+Tab x2` (Plan) - Analyser architecture
6. `Shift+Tab` (Normal) - Implementer
7. `Shift+Tab` (Auto-Accept) - Iterer

### Workflow session typique

```
/session-start           # Charger contexte
[Travail...]
/session-save            # Sauvegarder progres
[Travail...]
/session-end             # Resume final
/clear                   # Liberer memoire
```

### Fichiers importants

| Fichier | Role |
|---------|------|
| `CLAUDE.md` | Contexte projet |
| `.claude/settings.json` | Permissions, hooks |
| `.claude/skills/` | Standards Anthropic |
| `docs/SESSION-STATE.md` | Etat session |
| `docs/issues/README.md` | Index issues |

---

## 23. Organisation des fichiers

### Emplacements projet (partages via git)

```
.claude/
├── settings.json              # Permissions, hooks (partage equipe)
├── settings.local.json        # Overrides locaux (gitignore)
├── hooks/                     # Scripts de hooks
│   └── security-check.ps1
├── commands/
│   ├── create-script.md       # /create-script
│   ├── create-function.md     # /create-function
│   ├── create-test.md         # /create-test
│   ├── create-issue.md        # /create-issue
│   ├── implement-issue.md     # /implement-issue
│   ├── run-tests.md           # /run-tests
│   ├── review-code.md         # /review-code
│   ├── audit-code.md          # /audit-code
│   ├── session-start.md       # /session-start
│   ├── session-save.md        # /session-save
│   └── session-end.md         # /session-end
├── agents/
│   ├── code-reviewer.md       # Review PowerShell
│   ├── test-writer.md         # Ecriture tests TDD
│   ├── context-explorer.md    # Exploration legere (haiku)
│   ├── session-summarizer.md  # Sauvegarde session
│   ├── security-auditor.md    # Audit securite
│   └── tech-researcher.md     # Recherche technique
└── skills/                        # Skills officiels Anthropic
    ├── powershell-development/    # Standards PowerShell (16 fichiers)
    │   ├── SKILL.md
    │   ├── naming.md
    │   ├── errors.md
    │   ├── performance.md
    │   └── ...
    ├── development-workflow/      # Git, TDD, issues (6 fichiers)
    │   ├── SKILL.md
    │   ├── git.md
    │   ├── tdd.md
    │   └── workflow.md
    ├── code-audit/                # Methodologie audit (4 fichiers)
    │   └── SKILL.md
    └── progress-tracking/         # Templates progression (3 fichiers)
        ├── SKILL.md
        └── templates/
            ├── ISSUES-README.md
            └── SESSION-STATE.md
```

### Emplacements personnels (tous projets)

```
~/.claude/
├── CLAUDE.md                  # Preferences globales
├── settings.json              # Config globale
├── settings.local.json        # Config locale (non versionnee)
├── commands/                  # Commandes personnelles (/user:*)
└── agents/                    # Agents personnels
```

### Hierarchie de chargement (ordre de priorite)

Les parametres de niveau superieur **overrident** ceux de niveau inferieur.

```
┌─────────────────────────────────────────────────────────────────┐
│  1. ENTERPRISE        managed-settings.json (systeme)           │  ← PRIORITE MAX
├─────────────────────────────────────────────────────────────────┤
│  2. LOCAL             .claude/settings.local.json (.gitignore)  │
├─────────────────────────────────────────────────────────────────┤
│  3. PROJET            .claude/settings.json (versionne/equipe)  │
├─────────────────────────────────────────────────────────────────┤
│  4. UTILISATEUR       ~/.claude/settings.json (global)          │  ← PRIORITE MIN
└─────────────────────────────────────────────────────────────────┘
```

| Niveau | Fichier | Usage |
|--------|---------|-------|
| **Enterprise** | Voir ci-dessous | Politiques imposees par l'admin |
| **Local** | `.claude/settings.local.json` | Preferences perso (non partagees) |
| **Projet** | `.claude/settings.json` | Config equipe (versionnee) |
| **Utilisateur** | `~/.claude/settings.json` | Defaults pour tous projets |

**Chemins Enterprise (managed-settings.json) :**
- **Windows** : `C:\Program Files\ClaudeCode\managed-settings.json`
- **macOS** : `/Library/Application Support/ClaudeCode/managed-settings.json`
- **Linux/WSL** : `/etc/claude-code/managed-settings.json`

**Comportement de fusion :**
- Les settings sont **fusionnes** (merged)
- Un setting plus specifique **override** un setting plus general
- Exemple : Si User autorise `Bash(npm run:*)` mais Projet le deny → **Projet gagne**

> **Source** : [Claude Code Settings](https://docs.claude.com/en/docs/claude-code/settings)

---

## 24. Sources

### Documentation officielle Anthropic
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices) - Anthropic Engineering
- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code) - Docs officielles
- [Agent Skills Documentation](https://code.claude.com/docs/en/skills) - Pattern domain-specific
- [GitHub anthropics/skills](https://github.com/anthropics/skills) - Repository officiel skills
- [Skill Creator (meta-skill)](https://github.com/anthropics/skills/tree/main/skills/skill-creator) - Best practices
- [Subagents](https://code.claude.com/docs/en/sub-agents) - Documentation subagents
- [Hooks Reference](https://code.claude.com/docs/en/hooks) - Reference hooks
- [Slash Commands](https://docs.claude.com/en/docs/claude-code/slash-commands) - Reference commands
- [MCP Documentation](https://modelcontextprotocol.io) - Model Context Protocol

### Articles Anthropic
- [How Anthropic teams use Claude Code](https://www.anthropic.com/news/how-anthropic-teams-use-claude-code)
- [Enabling Claude Code to work more autonomously](https://www.anthropic.com/news/enabling-claude-code-to-work-more-autonomously)
- [Building agents with Claude Agent SDK](https://www.anthropic.com/engineering/building-agents-with-the-claude-agent-sdk)
- [Claude Opus 4.5 Announcement](https://www.anthropic.com/news/claude-opus-4-5)
- [Claude 4.5 Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-4-best-practices)
- [Equipping Agents for the Real World with Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) - Progressive disclosure
- [MCP Announcement](https://www.anthropic.com/news/model-context-protocol) - Model Context Protocol (Nov 2024)
- [Code Execution with MCP](https://www.anthropic.com/engineering/code-execution-with-mcp) - Optimisation contexte MCP

### Guides communautaires
- [Memory Management Best Practices](https://cuong.io/blog/2025/06/15-claude-code-best-practices-memory-management)
- [Plan Mode Guide](https://cuong.io/blog/2025/07/15-claude-code-best-practices-plan-mode)
- [Subagent Deep Dive](https://cuong.io/blog/2025/06/24-claude-code-subagent-deep-dive) - Parallelisation, cap ~10
- [Inside Claude Code Skills](https://mikhail.io/2025/10/claude-code-skills/)
- [Claude Skills Deep Dive](https://leehanchung.github.io/blogs/2025/10/26/claude-skills-deep-dive/) - disable-model-invocation

---

*Document pour Claude Code - Opus 4.5 - Decembre 2025*
*Derniere mise a jour : 12 decembre 2025*
*Migration vers Skills officiels Anthropic : REFACTOR-006*
*Integration mecanismes revises : DOCS-001*
