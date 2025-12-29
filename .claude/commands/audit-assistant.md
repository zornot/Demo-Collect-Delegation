---
description: Audite l'assistant avec cartographie et verification coherence
argument-hint: [all|map|check]
---

# Audit Assistant

Auditer la structure de l'assistant Claude.

## Arguments

| Argument | Description |
|----------|-------------|
| `all` (defaut) | Cartographie + Coherence |
| `map` | Cartographie seule (diagrammes) |
| `check` | Coherence seule (necessite mapping recent) |

## Usage

```
/audit-assistant          # Audit complet
/audit-assistant map      # Diagrammes seulement
/audit-assistant check    # Verification coherence seulement
```

---

## Phase 1 : Cartographie

Afficher : `[i] Invocation de l'agent assistant-auditor...`

Invoquer `@assistant-auditor` avec :

```
Analyser la structure complete de l'assistant.

Collecter :
- Tous les agents dans .claude/agents/
- Tous les skills dans .claude/skills/*/SKILL.md
- Toutes les commands dans .claude/commands/
- Tous les hooks dans .claude/hooks/

Pour chaque element :
- Extraire description (frontmatter ou 1ere ligne)
- Identifier references sortantes (@agent, /command, skill/*.md)
- Noter le trigger si applicable

Retourner :
1. Inventaire par type (tableau)
2. Graphe de dependances (JSON)
3. Diagramme Mermaid
4. Diagramme ASCII
```

Si $ARGUMENTS = "check" : sauter cette phase, utiliser le dernier rapport existant.

---

## Phase 2 : Coherence

Avec le resultat de Phase 1, verifier :

### 2.1 References valides

Pour chaque reference dans le graphe :

```
[ ] Cible existe ?
    +-- Agent : .claude/agents/[nom].md existe
    +-- Skill : .claude/skills/[nom]/SKILL.md existe
    +-- Command : .claude/commands/[nom].md existe
```

### 2.2 Elements orphelins

```
[ ] Element reference par au moins un autre ?
    +-- Si jamais reference : WARNING "orphelin"
```

### 2.3 Classification

| Status | Critere |
|--------|---------|
| OK | Reference valide, cible existe |
| WARNING | Orphelin ou reference unidirectionnelle |
| ERROR | Reference cassee (cible inexistante) |

Si $ARGUMENTS = "map" : sauter cette phase.

---

## Rapport Final

Creer le fichier : `audit/AUDIT-ASSISTANT-YYYY-MM-DD.md`

### Structure du rapport

```markdown
# Audit Assistant - YYYY-MM-DD

## 1. Resume Executif

| Metrique | Valeur |
|----------|--------|
| Elements analyses | X |
| References totales | Y |
| References valides | Z (%) |
| Warnings | W |
| Errors | E |

## 2. Diagramme Mermaid

[Diagramme interactif]

## 3. Diagramme ASCII

[Diagramme terminal]

## 4. Matrice de References

| Source | Type | Cible | Relation | Valide |
|--------|------|-------|----------|--------|
| ... | ... | ... | ... | ... |

## 5. Findings

### OK (N)
[Liste condensee ou "Voir matrice"]

### Warnings (N)
- [ ] [Element] : [Description du warning]

### Errors (N)
- [ ] [Element] : [Description de l'erreur]

## 6. Recommandations

[Actions suggerees pour corriger warnings/errors]
```

---

## Sortie

```
=====================================
[+] AUDIT ASSISTANT TERMINE
=====================================
Rapport : audit/AUDIT-ASSISTANT-YYYY-MM-DD.md
Elements : X agents, Y skills, Z commands, W hooks
References : N valides, M warnings, P errors
=====================================
```

## Notes

- Le rapport est persistant dans `audit/`
- Les diagrammes Mermaid peuvent etre visualises sur mermaid.live
- Les diagrammes ASCII sont optimises pour terminal (largeur < 120)
