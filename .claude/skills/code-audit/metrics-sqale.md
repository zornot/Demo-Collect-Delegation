# Metriques et Quantification SQALE

> Standards de quantification pour audits de code professionnels.

---

## Principe Fondamental

> **Un finding sans quantification n'est pas actionnable.**

Chaque probleme identifie doit inclure :
1. **Severite** : Impact sur le systeme
2. **Effort** : Temps de remediation
3. **ROI** : Rentabilite de la correction
4. **Priorite** : Ordre de traitement

---

## Complexite Algorithmique Big O

### Table de Reference

| Notation | Nom | Verdict | Seuil N | Exemple |
|----------|-----|---------|---------|---------|
| O(1) | Constant | [+] Excellent | Infini | Acces dictionnaire par cle |
| O(log n) | Logarithmique | [+] Excellent | Milliards | Recherche binaire |
| O(n) | Lineaire | [+] Bon | Millions | Parcours de liste |
| O(n log n) | Log-lineaire | [~] Acceptable | 100 000 | Tri efficace (quicksort) |
| O(n^2) | Quadratique | [!] Probleme | 1 000 | Boucles imbriquees |
| O(n^3) | Cubique | [!!] Critique | 100 | Triple boucle |
| O(2^n) | Exponentiel | [!!] Inacceptable | 20 | Force brute combinatoire |
| O(n!) | Factoriel | [!!] Inacceptable | 10 | Permutations completes |

### Calcul de Complexite

#### Regles de base

```
Sequence     : O(f) + O(g) = O(max(f, g))
Boucle       : O(n) x O(corps)
Imbrication  : O(n) x O(m) = O(n x m)
Recursion    : Depends de l'arbre d'appels
```

#### Patterns PowerShell Courants

| Pattern | Complexite | Note |
|---------|------------|------|
| `foreach ($x in $list)` | O(n) | Lineaire |
| `$list \| Where-Object` | O(n) | Pipeline overhead |
| `$list.Where({})` | O(n) | Plus rapide que pipeline |
| `foreach` imbrique | O(n x m) | Attention si grands N |
| `@() +=` en boucle | O(n^2) | Reallocation a chaque += |
| `[List].Add()` | O(1) amorti | Optimal |
| `Sort-Object` | O(n log n) | Tri natif |
| `Group-Object` | O(n) | Parcours + hashtable |

### Quantification Performance

Pour chaque finding PERF, fournir :

```
+-------------------------------------------------------------+
|              QUANTIFICATION PERFORMANCE                     |
+-------------------------------------------------------------+
|                                                             |
|  COMPLEXITE ACTUELLE  : O([notation])                      |
|  COMPLEXITE OPTIMISEE : O([notation])                      |
|                                                             |
|  MESURES :                                                  |
|  | N elements | Actuel | Optimise | Gain |                 |
|  |------------|--------|----------|------|                 |
|  | 100        | [X]ms  | [Y]ms    | [Z]x |                 |
|  | 1 000      | [X]ms  | [Y]ms    | [Z]x |                 |
|  | 10 000     | [X]ms  | [Y]ms    | [Z]x |                 |
|                                                             |
|  EFFORT CORRECTION : [X] heures                            |
|  FREQUENCE EXECUTION : [X] fois/jour                       |
|  GAIN ANNUEL : [X] heures                                  |
|  ROI : Rentable apres [X] executions                       |
|                                                             |
+-------------------------------------------------------------+
```

---

## Modele SQALE (Software Quality Assessment based on Lifecycle Expectations)

### Caracteristiques de Qualite

| Caracteristique | Description | Impact |
|-----------------|-------------|--------|
| **Fiabilite** | Absence de bugs | Crashes, donnees corrompues |
| **Securite** | Resistance aux attaques | Breaches, data leaks |
| **Maintenabilite** | Facilite de modification | Temps developpement |
| **Efficacite** | Performance | Temps execution, ressources |
| **Portabilite** | Adaptabilite | Effort migration |

### Calcul Dette Technique

```
Dette = Somme (Effort_remediation x Nombre_occurrences)
```

#### Efforts de Remediation Standards

| Type de Probleme | Effort Unitaire | Exemple |
|------------------|-----------------|---------|
| **Bugs** | | |
| Bug critique (crash) | 4h | Null reference non geree |
| Bug majeur | 2h | Logic error |
| Bug mineur | 30min | Edge case |
| **Securite** | | |
| Vulnerabilite critique | 8h | Injection SQL |
| Vulnerabilite majeure | 4h | XSS |
| Vulnerabilite mineure | 1h | Information disclosure |
| **Maintenabilite** | | |
| Fonction trop longue (>100 LOC) | 2h | Refactoring split |
| Duplication (>20 lignes) | 1h | Factorisation |
| Complexite cyclomatique >15 | 3h | Simplification |
| Nom non explicite | 15min | Renommage |
| **Performance** | | |
| Algorithme O(n^2) -> O(n) | 4h | Optimisation |
| Collection inefficace | 30min | @() += -> List |
| Requete N+1 | 2h | Batch/Join |

### Exemple Calcul

```
DETTE TECHNIQUE - Rapport Audit

| Categorie | Findings | Effort/U | Total |
|-----------|----------|----------|-------|
| Bugs critiques | 2 | 4h | 8h |
| Bugs majeurs | 5 | 2h | 10h |
| Securite majeure | 1 | 4h | 4h |
| Duplications | 8 | 1h | 8h |
| Perf O(n^2) | 3 | 4h | 12h |

DETTE TOTALE : 42h (~5 jours developpeur)
```

---

## Notation A-E

### Echelle de Notation

| Note | Ratio Dette/Effort | Interpretation |
|------|-------------------|----------------|
| **A** | < 5% | Excellent - Dette negligeable |
| **B** | 5-10% | Bon - Dette controlee |
| **C** | 10-20% | Moyen - Dette a surveiller |
| **D** | 20-50% | Mauvais - Dette significative |
| **E** | > 50% | Critique - Refonte necessaire |

### Calcul du Ratio

```
Ratio = (Dette_technique / Effort_developpement_initial) x 100

Effort_initial = Lignes_code x 0.5h / 100
```

#### Exemple

```
Lignes de code : 2000
Effort initial estime : 2000 x 0.5 / 100 = 10h
Dette technique : 42h

Ratio = 42 / 10 = 420% -> Note E (Critique)
```

### Interpretation par Note

| Note | Action Recommandee |
|------|-------------------|
| **A** | Maintenance preventive, pas d'urgence |
| **B** | Traiter les critiques, planifier le reste |
| **C** | Dedicacer 20% du temps a la dette |
| **D** | Plan de remediation obligatoire |
| **E** | Evaluer refonte vs maintenance |

---

## Priorisation des Findings

### Matrice Severite x Effort

```
                    EFFORT
              Faible    Moyen    Eleve
           +---------+---------+---------+
  Critique |   P1    |   P1    |   P2    |
           +---------+---------+---------+
SEVERITE   |   P1    |   P2    |   P3    |
  Elevee   +---------+---------+---------+
           |   P2    |   P3    |   P4    |
  Moyenne  +---------+---------+---------+
           |   P3    |   P4    |   P5    |
  Faible   +---------+---------+---------+
```

### Definition des Priorites

| Priorite | Delai | Action |
|----------|-------|--------|
| **P1** | Immediat | Bloquer le deploiement |
| **P2** | Sprint courant | Traiter avant release |
| **P3** | Sprint suivant | Planifier |
| **P4** | Backlog | A prioriser si temps |
| **P5** | Optionnel | Nice-to-have |

### Seuils d'Effort

| Categorie | Heures |
|-----------|--------|
| Faible | < 1h |
| Moyen | 1-4h |
| Eleve | > 4h |

---

## Calcul ROI

### Formule

```
ROI = (Gain_annuel - Cout_correction) / Cout_correction x 100

Gain_annuel = Frequence x Temps_economise x 220 jours
```

### Exemple : Optimisation Performance

```
AVANT : 10 secondes par execution
APRES : 1 seconde par execution
GAIN  : 9 secondes

Frequence : 50 fois/jour
Temps economise : 50 x 9s = 450s/jour = 7.5min/jour
Gain annuel : 7.5 x 220 = 1650 min = 27.5h

Cout correction : 4h

ROI = (27.5 - 4) / 4 x 100 = 587%
Rentabilise apres : 4h / (7.5min/jour) = 32 jours
```

### Seuils de Rentabilite

| ROI | Recommandation |
|-----|----------------|
| > 200% | Priorite haute |
| 100-200% | Rentable, a planifier |
| 50-100% | Marginal, selon contexte |
| < 50% | Reporter sauf critique |

---

## Format Rapport Metriques

```markdown
## Metriques Globales

### Dette Technique SQALE

| Categorie | Findings | Dette |
|-----------|----------|-------|
| Fiabilite | [X] | [Y]h |
| Securite | [X] | [Y]h |
| Maintenabilite | [X] | [Y]h |
| Efficacite | [X] | [Y]h |
| **TOTAL** | **[X]** | **[Y]h** |

### Notation

| Metrique | Valeur | Seuil | Status |
|----------|--------|-------|--------|
| Dette totale | [X]h | <40h | [+]/[-] |
| Ratio dette | [X]% | <20% | [+]/[-] |
| Note | [A-E] | >=B | [+]/[-] |

### Repartition Severite

[!!] Critique : X findings (Y%)
[!]  Elevee   : X findings (Y%)
[~]  Moyenne  : X findings (Y%)
[-]  Faible   : X findings (Y%)

### Top 5 ROI

| Finding | ROI | Priorite |
|---------|-----|----------|
| [Description] | [X]% | P[N] |
```

---

## Complexite Cyclomatique

### Definition

Nombre de chemins independants dans le code.

```
CC = Edges - Nodes + 2P

Ou plus simplement :
CC = 1 + Nombre de (if, else, case, while, for, &&, ||, catch)
```

### Seuils

| CC | Risque | Action |
|----|--------|--------|
| 1-10 | Faible | OK |
| 11-20 | Modere | Surveiller |
| 21-50 | Eleve | Refactoring |
| > 50 | Tres eleve | Urgent |

---

## Complexite Cognitive

### Definition

Mesure la difficulte de comprehension du code (plus pertinente que CC).

### Facteurs

| Facteur | Increment |
|---------|-----------|
| Imbrication (if dans if) | +1 par niveau |
| Rupture de flux (break, continue, goto) | +1 |
| Recursion | +1 |
| Conditions multiples (&&, \|\|) | +1 par operateur |

### Seuils

| Score | Verdict |
|-------|---------|
| < 15 | [+] Bon |
| 15-25 | [~] A surveiller |
| > 25 | [-] Refactoring |

---

## References

- Methodologie : [methodology.md](methodology.md)
- Anti-FP : [anti-false-positives.md](anti-false-positives.md)
- Performance PS : `.claude/skills/powershell-development/performance.md`
