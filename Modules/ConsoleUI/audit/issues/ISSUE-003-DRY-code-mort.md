# [~] [DRY-002] Resoudre code mort (70 lignes) | Effort: 30min OU inclus dans DRY-001

## PROBLEME
3 fonctions privees (70 lignes) ont ete creees pour une refactorisation DRY
mais ne sont jamais appelees. Ce code mort represente 6% du module et cree
de la confusion sur l'intention du code.

## LOCALISATION
- Fichier : Modules/ConsoleUI/ConsoleUI.psm1:L22-93
- Fonctions :
  - Write-PaddedLine (L22-55, 34 lignes)
  - Write-BoxBorder (L57-79, 23 lignes)
  - Write-EmptyLine (L81-93, 13 lignes)
- Module : ConsoleUI

## OBJECTIF
Eliminer le code mort soit en le supprimant (Option A) soit en l'utilisant
via la refactorisation DRY-001 (Option B - RECOMMANDE).

---

## ANALYSE IMPACT

### Fichiers Impactes
| Fichier | Raison | Action Requise |
|---------|--------|----------------|
| ConsoleUI.psm1 | Fonctions privees | Supprimer OU utiliser |

### Code Mort a Supprimer (Option A uniquement)

**Methode d'identification :**

1. **Analyse statique** :
   ```powershell
   # Recherche d'appels
   Select-String -Path .\Modules\ConsoleUI\ConsoleUI.psm1 -Pattern 'Write-PaddedLine|Write-BoxBorder|Write-EmptyLine'
   # Resultat : 3 occurrences (definitions uniquement)
   ```

2. **Tracage des dependances** :
   ```
   Write-PaddedLine : 0 appelants
   Write-BoxBorder  : 0 appelants
   Write-EmptyLine  : 0 appelants
   ```

| Ligne | Code | Raison | Methode |
|-------|------|--------|---------|
| L22-55 | `function Write-PaddedLine {...}` | 0 appelants | Tracage |
| L57-79 | `function Write-BoxBorder {...}` | 0 appelants | Tracage |
| L81-93 | `function Write-EmptyLine {...}` | 0 appelants | Tracage |

---

## OPTIONS D'IMPLEMENTATION

### Option A : Supprimer le code mort - 30min

**A utiliser si DRY-001 n'est pas prevu.**

Fichier : Modules/ConsoleUI/ConsoleUI.psm1
Lignes L17-95 - SUPPRIMER

AVANT :
```powershell
#region Private Functions
#═══════════════════════════════════════════════════════════════════════════════
#  PRIVATE FUNCTIONS (Issue 035 - DRY padding pattern)
#═══════════════════════════════════════════════════════════════════════════════

function Write-PaddedLine {
    # ... 34 lignes
}

function Write-BoxBorder {
    # ... 23 lignes
}

function Write-EmptyLine {
    # ... 13 lignes
}

#endregion Private Functions
```

APRES :
```powershell
# (supprimer completement la region Private Functions)
```

**NOTE IMPORTANTE** : Ces fonctions contiennent des patterns defensifs :
- D-004 : ValidateSet sur $Position
- D-005 : [Math]::Max(0, x) protection padding
- D-007 : AllowEmptyString sur $Content

Si Option A choisie, s'assurer que ces protections existent ailleurs dans le code
(elles sont deja presentes dans les fonctions publiques via Math.Max).

### Option B : Utiliser via DRY-001 - RECOMMANDE

**Cette option est resolue par l'implementation de ISSUE-002 (DRY-001).**

Avantages :
- Resout le code mort ET la duplication simultanement
- Conserve les patterns defensifs
- Meilleure maintenabilite

---

## VALIDATION

### Criteres d'Acceptation (Option A)
- [ ] Aucune fonction privee non utilisee
- [ ] PSScriptAnalyzer clean :
  ```powershell
  Invoke-ScriptAnalyzer -Path .\Modules\ConsoleUI\ConsoleUI.psm1 -IncludeRule PSUseDeclaredVarsMoreThanAssignments
  ```
- [ ] Module fonctionne toujours

### Criteres d'Acceptation (Option B)
- [ ] Voir ISSUE-002 (DRY-001)

---

## DEPENDANCES

### Option A
- Bloquee par : Aucune
- Bloque : Aucune

### Option B
- Bloquee par : ISSUE-002 (DRY-001)
- Bloque : Aucune
- Note : Cette issue est **automatiquement resolue** par DRY-001

## POINTS ATTENTION
- 1 fichier modifie
- Option A : 70 lignes supprimees
- Option B : 0 lignes supprimees (code utilise)
- Risques : Aucun (code mort, pas d'appelant)

## CHECKLIST
- [x] Code AVANT = code reel verifie
- [x] Tests unitaires passent
- [x] Code review effectuee

Labels : refactoring code-mort maintenabilite effort-30min

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | # |
| Statut | RESOLVED |
| Commit Resolution | (resolu via ISSUE-002 - Option B) |
