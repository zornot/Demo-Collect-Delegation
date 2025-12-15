---
description: Lance un audit de code complet en 6 phases avec protocole anti-faux-positifs
argument-hint: [chemin] [focus]
model: opus
allowed-tools: Read, Grep, Glob, WebSearch
---

Realiser un audit de code professionnel en 6 phases sequentielles.

## Arguments

- `$1` : Chemin du fichier ou dossier a auditer (defaut: .)
- `$2` : Focus optionnel : `ALL` | `BUG` | `SEC` | `PERF` | `ARCH` | `DRY`

## Fichier de Rapport (OBLIGATOIRE)

Des la Phase 0, creer le fichier de rapport dans `audit/` :

```
audit/AUDIT-{YYYY-MM-DD}-{nom-cible}.md
```

Exemple : `audit/AUDIT-2025-12-07-Script.md`

### Workflow d'ecriture incrementale

| Phase | Action sur le fichier |
|-------|----------------------|
| Phase 0 | **Creer** le fichier avec en-tete et evaluation initiale |
| Phase 1-6 | **Ajouter** la section correspondante a la fin du fichier |
| Pause | Le fichier contient l'etat actuel (reprise possible si interruption) |
| Fin | Le fichier EST le rapport final complet |

### En-tete initial (Phase 0)

```markdown
# Rapport d'Audit - [Nom Cible]

**Date** : YYYY-MM-DD
**Scope** : [chemin audite]
**Focus** : [ALL/BUG/SEC/PERF/ARCH/DRY]
**Auditeur** : Claude Code (Opus 4.5)

---

## Phase 0 : Evaluation Initiale
[contenu phase 0]
```

> **IMPORTANT** : Le rapport doit etre persistant. Si l'audit est interrompu,
> le fichier contient tout le travail effectue jusqu'a ce point.

## Premiere Etape (OBLIGATOIRE)

Lire les fichiers de methodologie AVANT de commencer :

1. `.claude/skills/code-audit/methodology.md` - Structure 6 phases
2. `.claude/skills/code-audit/anti-false-positives.md` - Protocole validation
3. `.claude/skills/code-audit/metrics-sqale.md` - Quantification metriques
4. `.claude/skills/knowledge-verification/SKILL.md` - Verification temporelle

Puis lire les regles specifiques :
- `.claude/skills/powershell-development/security.md` - OWASP, Trust Boundaries
- `.claude/skills/powershell-development/performance.md` - Big O, parallelisation
- `.claude/skills/powershell-development/patterns.md` - SOLID, anti-patterns architecture

## Execution des 6 Phases

### Phase 0 : Evaluation Initiale
- Compter les lignes precisement
- Identifier langage/framework/version
- Evaluer connaissance technologie (0-10)
- Decider strategie : complete (<1500 lignes) ou iterative

#### Verification Connaissance (si < 9/10)

Si la connaissance evaluee est inferieure a 9/10 :

1. **Lister les concepts non maitrises**
   ```
   | Concept | Connaissance | Critique pour l'audit ? |
   |---------|--------------|------------------------|
   | [Ex: Pester 5] | 7/10 | Oui |
   ```

2. **Appeler l'agent `tech-researcher`** pour chaque concept critique
   ```
   Utilise @tech-researcher pour rechercher : [concept]
   ```

3. **Integrer les resultats** dans la section Phase 0 du rapport

4. **Re-evaluer** : La connaissance doit atteindre >= 9/10 avant de continuer

> **IMPORTANT** : Ne jamais auditer une technologie mal maitrisee.
> La recherche prealable evite les faux positifs et faux negatifs.

### Phase 1 : Cartographie
- Tracer les flux de donnees (entree -> traitement -> sortie)
- Produire diagramme Mermaid si >500 lignes
- Identifier modules critiques et points d'entree

### Phase 2 : Architecture & Patterns Defensifs
- Analyser violations SOLID (metriques proxy)
- Detecter anti-patterns architecture (God Object, Spaghetti, etc.)
- **CREER REGISTRE PATTERNS DEFENSIFS** :
  - Guard clauses existantes
  - Validations en place
  - Try-catch englobants
  - Valeurs par defaut securisees

> **CRITIQUE** : Ce registre sera consulte pour TOUTES les phases suivantes.

### Phase 3 : Detection Bugs
- Appliquer protocole anti-faux-positifs (4 etapes)
- Simulation mentale obligatoire pour chaque bug potentiel
- Documenter analyses negatives (patterns suspects ecartes)
- Consulter registre Phase 2 avant de reporter

### Phase 4 : Securite
- Checklist OWASP Top 10
- Evaluer Trust Boundaries
- Tracer flux donnees sensibles
- Consulter registre Phase 2 pour validations existantes

### Phase 5 : Performance
- Identifier complexite Big O de chaque algorithme
- Quantifier : temps actuel, temps optimise, gain, effort
- Identifier opportunites parallelisation
- Consulter registre Phase 2 pour optimisations presentes

### Phase 6 : DRY & Maintenabilite
- Detecter duplications (Types 1-4)
- Evaluer complexite cognitive
- Identifier code mort
- Consulter registre Phase 2 pour code defensif a conserver

## Pauses Inter-Phases

Apres chaque phase, afficher :

```
================================================================
[>] FIN PHASE [N] - [NOM]
================================================================

### Resume
- Findings : [!!] X critiques | [!] Y eleves | [~] Z moyens | [-] W faibles
- Patterns defensifs identifies : [N] (Phase 2 uniquement)
- Analyses negatives documentees : [N]

### Prochaine Etape
Phase suivante : PHASE [N+1] - [Nom]
Progression : [N]/6 phases

### Commandes
CONTINUER : Lance Phase [N+1]
RAPPORT   : Genere rapport consolide etat actuel
STOP      : Arrete et genere rapport partiel

[...] EN ATTENTE COMMANDE...
```

## Protocole Anti-Faux-Positifs (OBLIGATOIRE)

Pour CHAQUE finding potentiel, executer cette checklist :

```
CHECKLIST ANTI-FAUX-POSITIFS :

1. GUARD CLAUSES EN AMONT ?
   [ ] Verifier les fonctions APPELANTES
   [ ] Y a-t-il validation des inputs AVANT l'appel ?
   > Si OUI : Pattern defensif = NE PAS REPORTER

2. PROTECTION FRAMEWORK ?
   [ ] Le framework gere-t-il automatiquement ce cas ?
   > Si OUI : Protection framework = NE PAS REPORTER

3. CHEMIN D'EXECUTION ATTEIGNABLE ?
   [ ] Le chemin menant au bug est-il REELLEMENT executable ?
   > Si IMPOSSIBLE : Faux positif = NE PAS REPORTER

4. CODE DEFENSIF EXISTANT ?
   [ ] Try/catch englobant ?
   [ ] Valeurs par defaut securisees ?
   > Si protection existe = NE PAS REPORTER
```

### Simulation Mentale (OBLIGATOIRE pour BUG/SEC)

```
SIMULATION :
Input  : [valeur test realiste]
Ligne X: variable = [valeur calculee]
Ligne Y: condition = [true/false]
Ligne Z: [etat resultant]
> Resultat attendu vs obtenu
> VERDICT : [PROBLEME CONFIRME | FAUX POSITIF - raison]
```

## Format Rapport Final

Generer rapport structure avec sections :

```markdown
# Rapport d'Audit - [Nom Projet/Fichier]

## 1. Synthese Executive
- Scope : [X fichiers, Y lignes]
- Duree : [estimation]
- Verdict global : [NOTE A-E selon SQALE]

## 2. Metriques Globales
| Metrique | Valeur | Seuil | Status |
|----------|--------|-------|--------|
| Dette technique | Xh | <8h | [+]/[-] |
| Complexite cyclomatique | X | <10 | [+]/[-] |
| Couverture tests | X% | >80% | [+]/[-] |

## 3. Top 10 Priorites
[Findings classes par severite * effort, quadruple validation]

## 4. Transparence - Analyses Ecartees
[Analyses negatives documentees pour prouver la rigueur]

## 5. Plan d'Implementation
[Ordre recommande avec estimation effort]

## 6. Proposition Issues
[Issues GitHub formatees pret-a-creer]
```

## Exemple d'Utilisation

```
# Audit complet d'un fichier
/audit-code ./Script.ps1

# Audit d'un module complet
/audit-code ./Modules/MonModule

# Audit avec focus securite uniquement
/audit-code ./Script.ps1 SEC

# Audit avec focus performance
/audit-code ./Modules/MonModule PERF
```

## Regles Critiques

1. **Sequentiel** : Phase 0 > 1 > 2 > 3 > 4 > 5 > 6 > Rapport. JAMAIS sauter.
2. **Registre Phase 2** : TOUJOURS consulter avant de reporter un finding.
3. **Protocole Anti-FP** : OBLIGATOIRE pour chaque finding potentiel.
4. **Quantification** : Chaque finding DOIT avoir metriques (Big O, effort, impact).
5. **Transparence** : Documenter TOUTES les analyses negatives.
6. **Pauses** : Attendre commande utilisateur entre chaque phase.
