---
name: code-audit
description: "Code audit methodology and metrics. Use when performing code reviews, security audits, or quality assessments. Covers 6-phase audit methodology, anti-false-positives protocol, SQALE metrics, Big O complexity analysis, and severity classification."
---

# Code Audit Standards

Methodologie d'audit de code professionnel.

## Quick Reference

### 6 Phases Sequentielles
```
Phase 0: EVALUATION   -> Scope, strategie (5min)
Phase 1: CARTOGRAPHIE -> Flux, dependances (10min)
Phase 2: ARCHITECTURE -> SOLID, patterns defensifs (15min)
Phase 3: BUGS         -> Detection + simulation (20min)
Phase 4: SECURITE     -> OWASP, Trust Boundaries (20min)
Phase 5: PERFORMANCE  -> Big O, quantification (15min)
Phase 6: DRY          -> Duplications, maintenabilite (15min)
```

**Regle critique** : Executer les phases dans l'ordre. JAMAIS sauter une phase.

### Protocole Anti-Faux-Positifs (OBLIGATOIRE)

Pour CHAQUE finding potentiel :
1. Guard clauses en amont ?
2. Protection framework ?
3. Chemin execution atteignable ?
4. Code defensif existant ?

> **Un finding non prouve est un faux positif potentiel.**

### Verification Temporelle des Connaissances

Voir `.claude/skills/knowledge-verification/SKILL.md` pour le protocole complet.

> Pour technos evolutives, invoquer @tech-researcher.

### Severites

| Symbole | Niveau | Action |
|---------|--------|--------|
| `[!!]` | Critique | P1 immediat |
| `[!]` | Elevee | P2 sprint courant |
| `[~]` | Moyenne | P3 planifier |
| `[-]` | Faible | P4 backlog |

### Simulation Mentale (OBLIGATOIRE pour BUG/SEC)

```
CONTEXTE : [Description scenario]
INPUT    : [Valeur entree]
TRACE    :
  L.XX : $variable = [valeur]
  L.YY : condition = [true/false]
ATTENDU  : [Comportement correct]
OBTENU   : [Comportement reel]
VERDICT  : [ ] CONFIRME  [ ] FAUX POSITIF
```

### Metriques SQALE

| Note | Ratio Dette | Action |
|------|-------------|--------|
| A | < 5% | Maintenance preventive |
| B | 5-10% | Traiter critiques |
| C | 10-20% | Dedicacer 20% temps |
| D | 20-50% | Plan remediation |
| E | > 50% | Evaluer refonte |

### Complexite Big O

| Notation | Verdict | Seuil |
|----------|---------|-------|
| O(1) | [+] Excellent | Infini |
| O(n) | [+] Bon | Millions |
| O(n log n) | [~] OK | 100k |
| O(n^2) | [!] Probleme | 1000 |
| O(2^n) | [!!] Critique | 20 |

## Detailed Standards

| Domaine | Fichier |
|---------|---------|
| Methodologie 6 phases | [methodology.md](methodology.md) |
| Protocole anti-FP | [anti-false-positives.md](anti-false-positives.md) |
| Metriques SQALE | [metrics-sqale.md](metrics-sqale.md) |
