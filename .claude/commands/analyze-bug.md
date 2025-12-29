---
description: Analyse un bug avec investigation profonde multi-phases
argument-hint: description du bug
model: opus
allowed-tools: Read, Grep, Glob, WebSearch, Task
---

Analyser le bug decrit via une investigation en 5 phases.

## Usage

```bash
/analyze-bug [description du bug]
```

Cette commande est pour **l'investigation profonde** d'un bug. Pour documenter, utiliser `/create-issue`.

---

## Phase 0 : Triage

Evaluer la complexite du bug pour adapter le niveau de raisonnement.

### 0.1 Extraction Contexte

Extraire du bug report :

| Element | Quoi chercher |
|---------|---------------|
| **Message d'erreur** | Texte exact de l'erreur |
| **Technologie** | PowerShell, Module, API, Framework |
| **Version** | Version du runtime, module, API |
| **Contexte** | Quand ca a commence, ce qui a change |

Afficher :

```
=====================================
[i] PHASE 0 : TRIAGE
=====================================
Erreur    : [message]
Techno    : [technologie]
Version   : [version]
Contexte  : [ce qui a change]
=====================================
```

### 0.2 Scoring Complexite

Evaluer chaque critere de 0 a 3 :

| Critere | 0 | 1 | 2 | 3 |
|---------|---|---|---|---|
| Multi-fichiers | 1 fichier | 2-3 fichiers | 4-5 fichiers | >5 fichiers |
| Dependances externes | Aucune | 1 API | 2-3 APIs | >3 APIs |
| Logique asynchrone | Sync | Timer | Parallel | Multi-thread |
| Intermittent | Toujours | 80%+ | 50% | Aleatoire |

Calculer le score total (0-12).

### 0.3 Decision Mode Thinking

| Score | Mode | Action |
|-------|------|--------|
| 0-3 | Standard | Continuer normalement |
| 4-7 | Approfondi | Utiliser "think hard" pour les phases critiques |
| 8-12 | Maximum | Utiliser "ultrathink" pour simulation et resolution |

Afficher :

```
=====================================
[i] SCORE COMPLEXITE : [X]/12
=====================================
| Critere | Score |
|---------|-------|
| Multi-fichiers | [X] |
| Dependances | [X] |
| Async | [X] |
| Intermittent | [X] |
-------------------------------------
Mode : [Standard/Approfondi/Maximum]
=====================================
```

---

## Phase 1 : Cartographie (APRES Phase 0)

Tracer le chemin d'execution et les dependances.

### 1.1 Charger les standards

Lire ces fichiers pour connaitre les conventions :
1. `.claude/skills/powershell-development/SKILL.md`
2. `.claude/skills/knowledge-verification/SKILL.md`

### 1.2 Evaluation temporelle

Appliquer le processus de `knowledge-verification` :

| Technologie | Confiance (0-10) | Risque | Decision |
|-------------|------------------|--------|----------|
| [Techno] | [X] | [Eleve/Moyen/Faible] | [Recherche/OK] |

Si confiance < 9/10 OU risque eleve :
```
[i] Invocation de l'agent tech-researcher...
```

### 1.3 Tracer le flux

Identifier :
- **Point d'origine** : Fichier et ligne de l'erreur
- **Flux de donnees** : Entree → Transformations → Sortie
- **Dependances** : Modules, APIs, fichiers config

### 1.4 Analyse Ripple Effect

Evaluer les zones d'impact potentiel :

| Zone | Distance | Impact | Fichiers |
|------|----------|--------|----------|
| Appelants directs | 1 | Eleve | [liste] |
| Modules dependants | 2 | Moyen | [liste] |
| Effets de bord | 3+ | A verifier | [liste] |

Afficher :

```
=====================================
[i] PHASE 1 : CARTOGRAPHIE
=====================================
Point d'origine : [fichier:ligne]
Fonction : [nom]

Flux : [Source] → [Traitement] → [Erreur]

Ripple Effect :
- Zone 1 : [X] fichiers (impact eleve)
- Zone 2 : [Y] fichiers (impact moyen)
=====================================
```

---

## Phase 2 : Hypotheses Paralleles (APRES Phase 1)

Lancer 3 sous-agents pour explorer differentes pistes simultanement.

### 2.1 Lancement des agents

Utiliser l'outil Task pour lancer 3 agents en parallele :

**Agent 1 - Syntaxique** :
```
Analyser le fichier [source] pour :
- Erreurs de syntaxe, typos
- Types incorrects
- Imports manquants

Premiere etape : Lire .claude/skills/powershell-development/SKILL.md

Retourner : Liste des problemes syntaxiques potentiels avec localisation
```

**Agent 2 - Logique** :
```
Analyser le flux de [fonction] pour :
- Conditions edge cases non gerees
- Logique incorrecte
- Valeurs null/undefined non testees

Premiere etape : Lire .claude/skills/powershell-development/SKILL.md

Retourner : Liste des problemes logiques potentiels avec scenario de reproduction
```

**Agent 3 - Contextuel** :
```
Analyser l'environnement pour :
- Configuration incorrecte
- Dependances manquantes ou obsoletes
- Problemes d'API externe

Premiere etape : Lire .claude/skills/powershell-development/SKILL.md

Retourner : Liste des problemes contextuels potentiels avec verification
```

### 2.2 Consolidation

Attendre les resultats des 3 agents et consolider :

| # | Hypothese | Source | Probabilite | Evidence |
|---|-----------|--------|-------------|----------|
| H1 | [Description] | Agent [X] | [Haute/Moyenne/Faible] | [Preuve] |
| H2 | [Description] | Agent [Y] | [Haute/Moyenne/Faible] | [Preuve] |
| H3 | [Description] | Agent [Z] | [Haute/Moyenne/Faible] | [Preuve] |

Afficher :

```
=====================================
[i] PHASE 2 : HYPOTHESES
=====================================
3 agents ont analyse le bug en parallele.

Hypotheses consolidees :
1. [H1] - Probabilite [X] - Source: Agent [Y]
2. [H2] - Probabilite [X] - Source: Agent [Y]
3. [H3] - Probabilite [X] - Source: Agent [Y]
=====================================
```

> **CHECKPOINT** : Avant de continuer vers Phase 3
>
> Verifier :
> - [ ] Au moins 1 hypothese avec probabilite Haute ou Moyenne
> - [ ] Chaque hypothese a une evidence documentee
>
> SI aucune hypothese viable : STOP et demander plus d'informations.

---

## Phase 3 : Simulation & Validation (APRES Phase 2)

Prouver ou infirmer chaque hypothese via simulation mentale.

### 3.1 Charger le protocole

Lire `.claude/skills/code-audit/anti-false-positives.md` pour le protocole de validation.

### 3.2 Simulation par hypothese

Pour chaque hypothese (de la plus probable a la moins probable) :

```
+-------------------------------------------------------------+
|              SIMULATION : Hypothese [N]                     |
+-------------------------------------------------------------+
|                                                             |
|  Description : [hypothese]                                  |
|                                                             |
|  Scenario de test :                                         |
|    Input : [valeur realiste reproduisant le bug]            |
|                                                             |
|  Trace d'execution :                                        |
|    L.[XX] : $var = [valeur]                                 |
|    L.[YY] : condition = [true/false] car [raison]           |
|    L.[ZZ] : [operation] -> [resultat]                       |
|                                                             |
|  Attendu : [comportement correct]                           |
|  Obtenu  : [comportement observe]                           |
|                                                             |
+-------------------------------------------------------------+
```

### 3.3 Protocole Anti-Faux-Positifs

Pour chaque hypothese confirmee par simulation, appliquer la checklist :

1. **Guard clauses en amont ?**
   - Verifier les fonctions appelantes
   - Y a-t-il validation des inputs avant l'appel ?

2. **Protection framework ?**
   - Le runtime gere-t-il automatiquement ce cas ?

3. **Chemin atteignable ?**
   - Ce scenario peut-il arriver en production ?

4. **Code defensif existant ?**
   - Try-catch englobant ?
   - Valeurs par defaut securisees ?

### 3.4 Verdict

| # | Hypothese | Simulation | Anti-FP | Verdict |
|---|-----------|------------|---------|---------|
| H1 | [Desc] | [OK/KO] | [X/4] | [Confirme/Infirme] |
| H2 | [Desc] | [OK/KO] | [X/4] | [Confirme/Infirme] |
| H3 | [Desc] | [OK/KO] | [X/4] | [Confirme/Infirme] |

Afficher :

```
=====================================
[i] PHASE 3 : SIMULATION
=====================================
Hypotheses testees : [N]
Confirmees : [X]
Infirmees : [Y]

Cause racine identifiee : [Oui/Non]
=====================================
```

---

## Phase 4 : Resolution (APRES Phase 3)

**BLOCKER** : Ne pas proposer de modifications de code si :
- Aucune hypothese confirmee en Phase 3
- Score anti-faux-positifs < 3/4 pour toutes les hypotheses

Proposer la correction avec analyse d'impact.

### 4.1 Cause racine

Si une ou plusieurs hypotheses sont confirmees :

```
=====================================
[i] PHASE 4 : RESOLUTION
=====================================

## Cause Racine
- Localisation : [fichier:ligne]
- Type : [Syntaxe/Logique/Config/Dependance]
- Description : [explication claire]

## Code AVANT
```powershell
[code problematique]
```

## Code APRES
```powershell
[code corrige]
```

## Analyse d'Impact
| Fichier | Modification | Priorite |
|---------|--------------|----------|
| [fichier1] | [Aucune/Adapter] | [Haute/Moyenne/Faible] |

## Verification
- [ ] Executer tests : Invoke-Pester -Path ./Tests
- [ ] Test manuel du scenario bug
- [ ] Review fichiers impactes

=====================================
```

### 4.2 Si aucune cause trouvee

```
=====================================
[!] AUCUNE CAUSE IDENTIFIEE
=====================================
Hypotheses testees : [N]
Toutes infirmees ou faux positifs.

Recommandations :
1. Collecter plus d'informations (logs, stack trace)
2. Reproduire le bug dans un environnement isole
3. Ajouter instrumentation temporaire

Prochaine etape : Creer issue de suivi
> /create-issue BUG-XXX-investigation-[titre]
=====================================
```

### 4.3 Prochaines etapes

Si bug confirme et corrigeable :
```
=====================================
[+] BUG CONFIRME
=====================================
Correction proposee ci-dessus.

Pour documenter et tracker :
> /create-issue BUG-XXX-[titre]

Pour appliquer directement (si simple) :
> Confirmer pour appliquer le code APRES
=====================================
```

---

## Exemple

```
/analyze-bug Get-EXOMailbox retourne erreur InvalidProperties sur LastLogonTime
```

Output resume :
```
Phase 0 : Score 4/12 → Mode Approfondi
Phase 1 : Flux trace, 2 fichiers en zone 1
Phase 2 : 3 hypotheses generees
Phase 3 : H1 confirmee (propriete inexistante)
Phase 4 : Correction → Get-EXOMailboxStatistics
```
