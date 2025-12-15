# [~] [BUG-003] Condition finally trop restrictive pour dernier element - Effort: 5min

## PROBLEME

La condition du bloc finally qui sauvegarde le checkpoint en cas d'interruption
utilise `<` au lieu de `<=`, ce qui empeche la sauvegarde si l'interruption
survient au dernier element de la liste.

Consequence : Si Ctrl+C au dernier element, les elements 50-98 (par exemple)
sont retraites au prochain run, causant des doublons dans le CSV.

## LOCALISATION

- Fichier : Get-ExchangeDelegation.ps1:925
- Fonction : Bloc finally de la boucle principale
- Module : Script principal

## OBJECTIF

La sauvegarde checkpoint doit se declencher meme si l'interruption
survient au dernier element de la liste.

---

## IMPLEMENTATION

### Etape 1 : Corriger la condition du finally - 5min

Fichier : Get-ExchangeDelegation.ps1

AVANT (L925) :
```powershell
if ($checkpointState -and $currentIndex -lt ($mailboxCount - 1)) {
    Save-CheckpointAtomic -LastProcessedIndex $currentIndex -Force
    Write-Status -Type Warning -Message "Interruption - checkpoint sauvegarde (index $currentIndex)" -Indent 1
}
```

APRES :
```powershell
if ($checkpointState -and $currentIndex -lt $mailboxCount) {
    Save-CheckpointAtomic -LastProcessedIndex $currentIndex -Force
    Write-Status -Type Warning -Message "Interruption - checkpoint sauvegarde (index $currentIndex)" -Indent 1
}
```

---

## VALIDATION

### Criteres d'Acceptation

- [ ] Interruption au dernier element sauvegarde le checkpoint
- [ ] Pas de doublons au prochain run apres interruption
- [ ] Complete-Checkpoint fonctionne toujours (pas de save inutile)
- [ ] Pas de regression sur les autres scenarios

### Tests Manuels

```powershell
# Test 1: Interruption au dernier element
# Configurer un petit jeu de test (ex: 5 mailboxes)
# Ctrl+C pendant traitement du 5eme
# Verifier: checkpoint sauvegarde avec index 4

# Test 2: Completion normale
.\Get-ExchangeDelegation.ps1  # Laisser terminer
# Verifier: checkpoint supprime (Complete-Checkpoint appele)

# Test 3: Reprise sans doublons
# Interrompre, reprendre, verifier CSV sans doublons
```

## CHECKLIST

- [ ] Code AVANT = code reel verifie
- [ ] Tests manuels passes
- [ ] Code review

Labels : bug moyenne checkpoint

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | # (apres gh issue create) |
| Statut | DRAFT |
| Branche | fix/BUG-003-finally-condition-lastindex |

---

## NOTES

### Decouverte

Bug decouvert lors de l'audit de code approfondi (2025-12-15).
Simulation du scenario d'interruption au dernier element.

### Impact

- Severite : MOYENNE
- Cas rare (interruption au dernier element) mais possible
- Cause doublons dans CSV, pas de perte de donnees

### Reference

- Audit : audit/AUDIT-2025-12-15-Get-ExchangeDelegation.md (Phase 3, BUG-002)
