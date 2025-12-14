# [~] [PERF-001] Documenter obligation Initialize-Log pour performance | Effort: 5min

## PROBLEME
Sans appel a `Initialize-Log`, `Get-PSCallStack` est execute a chaque appel de `Write-Log`
pour detecter automatiquement le nom du script. Cette operation coute ~2-4ms par appel,
rendant le logging environ 30x plus lent que lorsque `Initialize-Log` est appele au demarrage.

## LOCALISATION
- Fichier : Modules/Write-Log/Write-Log.psm1 (header + .NOTES de Write-Log)
- Fonction : Write-Log
- Module : Write-Log

## OBJECTIF
Documenter clairement que `Initialize-Log` DOIT etre appele au demarrage du script
pour des performances optimales.

---

## ANALYSE IMPACT

### Quantification
| N appels | Sans Initialize-Log | Avec Initialize-Log | Gain |
|----------|---------------------|---------------------|------|
| 100 | ~300ms | ~10ms | 30x |
| 1 000 | ~3s | ~100ms | 30x |
| 10 000 | ~30s | ~1s | 30x |
| 100 000 | ~5min | ~10s | 30x |

### Fichiers Impactes
| Fichier | Raison | Action Requise |
|---------|--------|----------------|
| Write-Log.psm1 | Documentation header | Ajouter note performance |
| README module | Documentation utilisateur | Mentionner Initialize-Log |

---

## IMPLEMENTATION

### Etape 1 : Ajouter note dans header module - 3min
Fichier : Modules/Write-Log/Write-Log.psm1
Ajouter apres la description existante

AJOUTER :
```powershell
# PERFORMANCE
# -----------
# Appeler Initialize-Log au demarrage du script pour des performances optimales.
# Sans Initialize-Log, Get-PSCallStack est appele a chaque Write-Log (~30x plus lent).
#
# Exemple :
#   Initialize-Log -Path ".\Logs"
#   Write-Log "Message"  # Utilise les variables initialisees
```

### Etape 2 : Ajouter .NOTES dans Write-Log - 2min
Fichier : Modules/Write-Log/Write-Log.psm1
Dans le bloc .NOTES de Write-Log

AJOUTER :
```powershell
.NOTES
    PERFORMANCE : Appeler Initialize-Log au demarrage du script.
    Sans cela, Get-PSCallStack est appele a chaque Write-Log (~30x plus lent).
```

---

## VALIDATION

### Criteres d'Acceptation
- [ ] Documentation performance ajoutee dans header module
- [ ] .NOTES de Write-Log mis a jour
- [ ] Get-Help Write-Log affiche la note performance

## CHECKLIST
- [x] Documentation claire et concise
- [x] Exemple d'usage inclus
- [x] Tests passent (16/16, pas de regression)

Labels : documentation performance write-log effort-5min

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | #5 |
| Statut | CLOSED |
| Commit Resolution | 6b488f5 |
| Date Resolution | 2025-12-08 |
