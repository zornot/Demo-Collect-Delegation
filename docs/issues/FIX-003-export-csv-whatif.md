# [CLOSED] FIX-003 Export CSV non genere en mode WhatIf | Effort: 5min

## PROBLEME

En mode `-CleanupOrphans` sans `-Force`, le script active `$WhatIfPreference = $true` pour simuler les suppressions. Cependant, cette preference affecte aussi `Export-Csv`, empechant la generation du fichier CSV meme si l'export n'est pas une operation destructive.

## LOCALISATION

- Fichier : Get-ExchangeDelegation.ps1:L699
- Fonction : Export CSV (bloc principal)
- Module : Script principal

## OBJECTIF

L'export CSV doit toujours se faire, meme en mode WhatIf. Seules les suppressions de delegations orphelines doivent etre affectees par WhatIf.

---

## ANALYSE IMPACT

### Fichiers Impactes

| Fichier | Raison | Action Requise |
|---------|--------|----------------|
| Get-ExchangeDelegation.ps1 | Export-Csv | Ajouter -WhatIf:$false |

---

## IMPLEMENTATION

### Etape 1 : Forcer l'export CSV - 5min
Fichier : Get-ExchangeDelegation.ps1
Ligne 699 - MODIFIER

AVANT :
```powershell
$allDelegations | Export-Csv -Path $exportFilePath -NoTypeInformation -Encoding UTF8
```

APRES :
```powershell
# -WhatIf:$false : L'export CSV doit se faire meme en mode simulation
# (WhatIf ne concerne que les suppressions de delegations orphelines)
$allDelegations | Export-Csv -Path $exportFilePath -NoTypeInformation -Encoding UTF8 -WhatIf:$false
```

Justification : `-WhatIf:$false` override explicitement la preference globale pour cette cmdlet specifique.

---

## VALIDATION

### Criteres d'Acceptation

- [x] Fichier CSV genere en mode `-CleanupOrphans` (sans -Force)
- [x] Fichier CSV genere en mode normal (sans -CleanupOrphans)
- [x] Mode WhatIf affiche toujours les suppressions simulees

---

## DEPENDANCES

- Bloquee par : Aucune
- Bloque : Aucune

## POINTS ATTENTION

- 1 fichier modifie
- 1 ligne modifiee
- Risques : Aucun

## CHECKLIST

- [x] Code AVANT = code reel verifie
- [x] Test manuel effectue
- [x] Code review effectuee

Labels : fix faible script-principal effort-5min

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | #5 |
| Statut | **CLOSED** |
| Branche | - (hotfix direct sur master) |
| Date | 2025-12-15 |
| Commit | 9402f9a |
