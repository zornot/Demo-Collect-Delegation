# [-] BUG-010 Ajouter valeur par defaut pour Config.Interval | Effort: 15min

## PROBLEME

Si `Config.Interval` est absent de la configuration, la valeur devient `$null` et aucune sauvegarde periodique n'est effectuee. Le comportement est silencieux, l'utilisateur croit avoir des checkpoints alors qu'ils ne sont jamais crees automatiquement.

## LOCALISATION

- Fichier : Modules/Checkpoint/Modules/Checkpoint/Checkpoint.psm1:L184
- Fonction : Initialize-Checkpoint
- Module : Checkpoint

## OBJECTIF

Ajouter une valeur par defaut (50) pour `Interval` comme c'est deja fait pour `MaxAgeHours` (L185), garantissant une sauvegarde periodique meme si la config est incomplete.

---

## ANALYSE IMPACT

### Fichiers Impactes

| Fichier | Raison | Action Requise |
|---------|--------|----------------|
| Checkpoint.psm1 | Modification Initialize-Checkpoint | Ajouter defaut |
| Get-ExchangeDelegation.ps1 | Appelant du module | Aucune (compatible) |

### Code Mort a Supprimer

Aucun code mort identifie.

---

## IMPLEMENTATION

### Etape 1 : Ajouter valeur par defaut - 5min

Fichier : Modules/Checkpoint/Modules/Checkpoint/Checkpoint.psm1
Ligne 184 - MODIFIER

AVANT :
```powershell
Interval       = $Config.Interval
```

APRES :
```powershell
Interval       = if ($Config.ContainsKey('Interval')) { $Config.Interval } else { 50 }
```

Justification : Pattern identique a L185 pour MaxAgeHours. Valeur 50 est un bon compromis (sauvegarde toutes les 50 mailboxes).

---

## VALIDATION

### Execution Virtuelle

```
Entree : $Config = @{ KeyProperty = "PrimarySmtpAddress" }  # Interval absent
L184  : Interval = if ($false) { $null } else { 50 } = 50
L302  : if (50 -gt 0 -and ...) -> TRUE (sauvegarde periodique active)
Sortie : Checkpoints crees tous les 50 elements
```
[>] VALIDE - Le comportement par defaut est maintenant securise

### Criteres d'Acceptation

- [x] Interval = 50 si Config.Interval absent
- [x] Interval = valeur config si Config.Interval present
- [x] Sauvegardes periodiques fonctionnent avec config incomplete
- [x] Pas de regression avec config complete

---

## DEPENDANCES

- Bloquee par : Aucune
- Bloque : Aucune

## POINTS ATTENTION

- 1 fichier modifie
- 1 ligne modifiee
- Risques : Aucun (ajout de robustesse uniquement)

## CHECKLIST

- [x] Code AVANT = code reel verifie
- [x] Tests unitaires passent
- [x] Code review effectuee

Labels : bug faible checkpoint 15min

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | # |
| Statut | RESOLVED |
| Branche | fix/BUG-010-config-interval-valeur-defaut |

---

## SOURCE

Issue detectee lors de l'audit du module Checkpoint (2025-12-16).
Voir : audit/AUDIT-2025-12-16-Checkpoint.md - Phase 3 - SIMULATION 3
