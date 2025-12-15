# [~] UI-001-amelioration-affichage-console - Effort: 15min

## PROBLEME

Les logs DEBUG et INFO s'affichent en console et interrompent la barre de progression. Le parametre `-NoConsole` existe deja dans Write-Log mais n'est pas utilise.

Exemple du probleme :
```
    [>] Analyse mailboxes : 10/24 (42%)2025-12-15T14:28:50 | DEBUG | Trustee introuvable...
```

## LOCALISATION

- Fichier : Get-ExchangeDelegation.ps1
- Lignes DEBUG : 178, 302, 306, 558, 582, 601, 931 (7 appels)
- Lignes INFO : 175, 375, 683, 697, 701, 711, 727, 853, 878 (9 appels)
- Module : Write-Log (parametre -NoConsole existe deja)

## OBJECTIF

Console propre avec uniquement :
- Write-Status [+][>][i] (progression utilisateur)
- Write-Box (resume, statistiques)
- WARNING/ERROR (alertes importantes)

Fichier log inchange (tous niveaux).

---

## IMPLEMENTATION

### Etape 1 : Ajouter -NoConsole aux DEBUG - 5min

| Ligne | Code a modifier |
|-------|-----------------|
| 178 | `Write-Log "Configuration par defaut..." -Level DEBUG` |
| 302 | `Write-Log "Trustee ambigu..." -Level DEBUG` |
| 306 | `Write-Log "Trustee introuvable..." -Level DEBUG` |
| 558 | `Write-Log "Calendrier non trouve..." -Level DEBUG` |
| 582 | `Write-Log "Permission calendrier orpheline..." -Level DEBUG` |
| 601 | `Write-Log "Erreur Calendar..." -Level DEBUG` |
| 931 | `Write-Log "StackTrace..." -Level DEBUG` |

AVANT :
```powershell
Write-Log "Message" -Level DEBUG
```

APRES :
```powershell
Write-Log "Message" -Level DEBUG -NoConsole
```

### Etape 2 : Ajouter -NoConsole aux INFO (optionnel) - 5min

INFO a masquer (redondants avec Write-Status) :

| Ligne | Message | Raison |
|-------|---------|--------|
| 175 | "Configuration chargee depuis..." | Redondant au demarrage |
| 701 | "Demarrage collecte..." | Redondant avec banner |
| 711 | "Connexion Exchange Online..." | Redondant avec [+] |
| 727 | "Mailboxes recuperees..." | Redondant avec [+] |

INFO a conserver en console :

| Ligne | Message | Raison |
|-------|---------|--------|
| 375 | "Delegation orpheline supprimee" | Action importante |
| 683 | "Mode Force annule" | Feedback utilisateur |
| 697 | "Mode CleanupOrphans..." | Feedback utilisateur |
| 853 | "Orphelins detectes..." | Resume important |
| 878 | "Nettoyage orphelins..." | Resume important |

---

## VALIDATION

### Criteres d'Acceptation

- [x] Progression non interrompue par DEBUG
- [x] WARNING/ERROR visibles en console
- [x] Fichier log complet (tous niveaux)
- [x] Pas de regression fonctionnelle

## CHECKLIST

- [x] 7 DEBUG avec -NoConsole
- [x] 4 INFO avec -NoConsole (redondants)
- [x] Test manuel execution

Labels : ui moyenne logging

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | # (apres gh issue create) |
| Statut | RESOLVED |
| Branche | feature/UI-001-amelioration-affichage-console |
