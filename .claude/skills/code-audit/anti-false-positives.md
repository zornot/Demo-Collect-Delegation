# Protocole Anti-Faux-Positifs

> Methodologie pour eliminer les faux positifs des rapports d'audit.

---

## Principe Fondamental

> **Un finding non prouve est un faux positif potentiel.**

Avant de reporter TOUT bug, vulnerabilite ou probleme de performance :
1. Verifier les protections existantes
2. Prouver que le chemin d'execution est atteignable
3. Simuler mentalement le scenario d'echec
4. Documenter la preuve ou ecarter comme faux positif

---

## Checklist 4 Etapes (OBLIGATOIRE)

Pour CHAQUE finding potentiel, executer cette checklist :

```
+-------------------------------------------------------------+
|           CHECKLIST ANTI-FAUX-POSITIFS                      |
+-------------------------------------------------------------+
|                                                             |
|  1. GUARD CLAUSES EN AMONT ?                               |
|     [ ] Verifier les fonctions APPELANTES                  |
|     [ ] Y a-t-il validation des inputs AVANT l'appel ?     |
|     > Si OUI : Pattern defensif = NE PAS REPORTER          |
|                                                             |
|  2. PROTECTION FRAMEWORK ?                                  |
|     [ ] Le framework gere-t-il automatiquement ce cas ?    |
|     [ ] Y a-t-il une convention implicite ?                |
|     > Si OUI : Protection framework = NE PAS REPORTER      |
|                                                             |
|  3. CHEMIN D'EXECUTION ATTEIGNABLE ?                       |
|     [ ] Le chemin menant au bug est-il REELLEMENT          |
|         executable avec des donnees realistes ?            |
|     [ ] Y a-t-il des conditions impossibles a reunir ?     |
|     > Si IMPOSSIBLE : Faux positif = NE PAS REPORTER       |
|                                                             |
|  4. CODE DEFENSIF EXISTANT ?                               |
|     [ ] Try-catch englobant ?                              |
|     [ ] Valeurs par defaut securisees ?                    |
|     [ ] Validation dans le constructeur/init ?             |
|     > Si protection existe = NE PAS REPORTER               |
|                                                             |
+-------------------------------------------------------------+
```

### Resultat de la Checklist

| Resultat | Action |
|----------|--------|
| 4 etapes PASSEES (aucune protection) | REPORTER le finding |
| Au moins 1 protection trouvee | ECARTER et documenter en Analyse Negative |

---

## Consultation Registre Phase 2 (OBLIGATOIRE)

Avant d'appliquer la checklist, **toujours consulter le Registre Patterns Defensifs** cree en Phase 2.

### Format du Registre

```markdown
| ID | Type | Localisation | Description |
|----|------|--------------|-------------|
| D-001 | Guard Clause | fichier.ps1:L42 | Validation $null |
| D-002 | Try-Catch | fichier.ps1:L50-65 | Bloc englobant |
| D-003 | Default Value | fichier.ps1:L30 | Fallback securise |
```

### Verification

Pour chaque finding potentiel :

```
1. Rechercher dans le registre : "D-XXX couvre-t-il ce cas ?"
2. Si OUI -> Pattern defensif existe -> NE PAS REPORTER
3. Si NON -> Continuer avec checklist 4 etapes
```

---

## Simulation Mentale (OBLIGATOIRE pour BUG/SEC)

Pour chaque bug ou vulnerabilite potentiel, executer une simulation mentale prouvant que le probleme est atteignable.

### Template Simulation

```
+-------------------------------------------------------------+
|                    SIMULATION MENTALE                       |
+-------------------------------------------------------------+
|                                                             |
|  CONTEXTE : [Description du scenario teste]                |
|                                                             |
|  INPUT    : [Valeur d'entree realiste]                     |
|                                                             |
|  TRACE :                                                    |
|    L.XX : $variable = [valeur initiale]                    |
|    L.YY : condition = [true/false] car [raison]            |
|    L.ZZ : [operation effectuee]                            |
|    L.WW : $resultat = [valeur finale]                      |
|                                                             |
|  ATTENDU  : [Comportement correct]                         |
|  OBTENU   : [Comportement reel]                            |
|                                                             |
|  VERDICT  : [ ] PROBLEME CONFIRME                          |
|             [ ] FAUX POSITIF - [raison]                    |
|                                                             |
+-------------------------------------------------------------+
```

### Exemples de Simulation

#### Exemple 1 : Bug CONFIRME

```
SIMULATION MENTALE - Division par zero

CONTEXTE : Calcul moyenne des scores utilisateurs
INPUT    : $scores = @() (liste vide)

TRACE :
  L.42 : $total = ($scores | Measure-Object -Sum).Sum  # = 0
  L.43 : $count = $scores.Count                        # = 0
  L.44 : $average = $total / $count                    # DIVISION PAR ZERO

ATTENDU  : Gestion du cas liste vide
OBTENU   : Exception "Attempted to divide by zero"

PROTECTIONS VERIFIEES :
  [x] Guard clauses : AUCUNE (L.40-41 verifiees)
  [x] Registre D-XXX : NON APPLICABLE
  [x] Chemin atteignable : OUI (appele par Get-UserStats sans validation)

VERDICT  : [x] PROBLEME CONFIRME
```

#### Exemple 2 : FAUX POSITIF

```
SIMULATION MENTALE - Null reference

CONTEXTE : Acces propriete utilisateur
INPUT    : $userId = "USER001"

TRACE :
  L.30 : $user = Get-User -Id $userId
  L.31 : if ($null -eq $user) { return $null }    # GUARD CLAUSE
  L.32 : $name = $user.DisplayName                 # Acces sur non-null garanti

ATTENDU  : Erreur si $user null
OBTENU   : Protection par guard clause L.31

PROTECTIONS VERIFIEES :
  [x] Guard clauses : OUI (L.31)
  [x] Registre D-003 : Guard clause documentee

VERDICT  : [x] FAUX POSITIF - Guard clause L.31 protege
```

---

## Documentation Analyses Negatives

### Pourquoi Documenter les Faux Positifs ?

1. **Transparence** : Prouver que l'analyse a ete rigoureuse
2. **Non-regression** : Ne pas re-analyser les memes patterns
3. **Confiance** : Le lecteur sait que les protections ont ete verifiees
4. **Completude** : Equation `Suspects = Confirmes + Ecartes` doit etre verifiee

### Format Section Analyses Negatives

```markdown
## Analyses Negatives ([X] patterns ecartes)

| Pattern Suspect | Localisation | Simulation | Protection Trouvee | Verdict |
|-----------------|--------------|------------|--------------------| --------|
| Division zero | L.45 | 3 scenarios | if(count > 0) L.42 | FAUX POSITIF |
| Null reference | L.78 | 2 scenarios | Guard clause L.75 | FAUX POSITIF |
| SQL Injection | L.120 | 1 scenario | ORM parametrise | FAUX POSITIF |
| Path traversal | L.95 | 2 scenarios | Test-SafePath L.90 | FAUX POSITIF |

### Compteur de Verification
- Patterns suspects identifies : [X]
- Simulations effectuees : [Y]
- Confirmes (reportes) : [Z]
- Ecartes (faux positifs) : [W]
- **Verification** : X = Z + W -> [OUI/NON]
```

### Importance de l'Equation

```
Suspects = Confirmes + Ecartes
```

Si l'equation n'est pas verifiee :
- Il manque des analyses negatives
- Certains patterns n'ont pas ete traites
- L'audit est incomplet

---

## Integration avec les Phases d'Audit

### Phase 3 (Bugs)

```markdown
## PHASE 3 : DETECTION BUGS

### Pre-requis
- [x] Registre Phase 2 charge
- [x] Protocole anti-FP lu

### Bugs CONFIRMES
[Findings ayant passe la checklist 4 etapes + simulation]

### Analyses Negatives
[Patterns suspects ecartes avec justification]
```

### Phase 4 (Securite)

```markdown
## PHASE 4 : SECURITE

### Pre-requis
- [x] Registre Phase 2 charge
- [x] Protocole anti-FP lu

### Vulnerabilites CONFIRMEES
[Findings ayant passe la checklist + Trust Boundary evalue]

### Vecteurs Ecartes
[Scenarios d'attaque non exploitables avec justification]
```

---

## Erreurs Courantes a Eviter

### [-] Reporter sans simulation

```
BUG : Division par zero possible ligne 45
```

Manque : Preuve que le denominateur peut etre zero.

### [+] Reporter avec simulation

```
BUG : Division par zero CONFIRMEE ligne 45

SIMULATION :
  Input: $items = @()
  L.43: $count = 0
  L.45: $avg = $total / $count  # ECHEC

Protections verifiees : AUCUNE
VERDICT : CONFIRME
```

### [-] Ignorer les guard clauses

```
BUG : $user.Name peut lever NullReferenceException
```

Manque : Verification des lignes precedentes.

### [+] Verifier les guard clauses

```
ANALYSE : $user.Name ligne 50

Verification :
  L.48: if ($null -eq $user) { throw }  # GUARD CLAUSE

VERDICT : FAUX POSITIF - Guard clause L.48 protege
```

---

## Checklist Finale Avant Report

Avant de soumettre un rapport d'audit, verifier :

- [ ] Tous les findings ont passe la checklist 4 etapes
- [ ] Tous les findings BUG/SEC ont une simulation mentale
- [ ] Le registre Phase 2 a ete consulte pour chaque finding
- [ ] Les analyses negatives sont documentees
- [ ] L'equation Suspects = Confirmes + Ecartes est verifiee
- [ ] Aucun finding n'est "potentiel" ou "possible" sans preuve

---

## References

- Methodologie : [methodology.md](methodology.md)
- Metriques : [metrics-sqale.md](metrics-sqale.md)
- Securite PowerShell : `.claude/skills/powershell-development/security.md`
