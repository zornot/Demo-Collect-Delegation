# [ABANDONNEE] PERF-001 Paralleliser la collecte des delegations par mailbox

> **Statut : ABANDONNEE** - ROI insuffisant pour la complexite technique identifiee

## PROBLEME

La collecte des delegations effectue 5 appels API Exchange sequentiels par mailbox (FullAccess, SendAs, SendOnBehalf, Calendar, Forwarding). Pour un tenant de 1000 mailboxes avec une latence de 500ms/appel, l'execution prend ~42 minutes. La parallelisation pourrait reduire ce temps de 3-5x.

## LOCALISATION

- Fichier : Get-ExchangeDelegation.ps1:L654-687
- Fonction : Boucle principale `foreach ($mailbox in $allMailboxes)`
- Module : Script principal

## OBJECTIF

Reduire le temps d'execution de la collecte en parallelisant le traitement des mailboxes avec `ForEach-Object -Parallel`, tout en respectant les limites de throttling Exchange Online.

---

## BLOCAGE TECHNIQUE IDENTIFIE (Recherche Microsoft 2024)

> **Source** : [More Efficient Bulk Operations with PowerShell Parallelism - Microsoft Tech Community](https://techcommunity.microsoft.com/blog/exchange/more-efficient-bulk-operations-with-powershell-parallelism/4409693)

### Isolation des Runspaces

> "Parallel sessions run in their own isolated spaces and do not share dependencies amongst themselves. Therefore, you will need to define all necessary elements, such as authentication tokens, and modules."

**Implications pour ce script** :

1. **Connexion Exchange isolee** : Chaque runspace parallele doit appeler `Connect-ExchangeOnline`
2. **Fonctions non partagees** : `Get-MailboxFullAccessDelegation`, etc. ne sont PAS disponibles dans -Parallel
3. **Risky Sign-Ins** : Connexions multiples simultanees declenchent des alertes Azure AD
4. **WAM errors** : Windows Account Manager peut echouer avec connexions simultanees

### Approche Microsoft Recommandee

```powershell
# DANS le scriptblock -Parallel :
$conn = Get-Mailbox -Identity [test-account] -ErrorAction SilentlyContinue
if ($null -eq $conn) {
    Connect-ExchangeOnline -ShowBanner:$false
}
```

### Verdict

| Aspect | Impact |
|--------|--------|
| Effort reel | **8h+** (vs 4h initialement estime) |
| Complexite | **ELEVEE** - Refactoring majeur requis |
| Risques | Risky Sign-Ins, WAM errors, debugging difficile |
| ROI | **FAIBLE** pour usage occasionnel (audits mensuels) |

**Recommandation : REPORTER ou ABANDONNER** - Le gain ne justifie pas la complexite pour un script d'audit occasionnel.

---

## ANALYSE IMPACT

### Fichiers Impactes

| Fichier | Raison | Action Requise |
|---------|--------|----------------|
| Get-ExchangeDelegation.ps1 | Refactoring majeur | Recrire toute la logique de collecte |

### Contraintes Techniques (MISE A JOUR)

| Contrainte | Valeur | Impact |
|------------|--------|--------|
| Sessions Exchange/tenant | 5 max | Limite ThrottleLimit |
| **Isolation runspaces** | **BLOQUANT** | Connect-ExchangeOnline dans chaque thread |
| **Fonctions parent** | **NON PARTAGEES** | Inline ou module requis |
| Rate limiting API | Variable | Gestion backoff |
| Risky Sign-Ins Azure AD | Probable | Alertes securite |

---

## IMPLEMENTATION

### Etape 1 : Creer fonction thread-safe - 1h
Fichier : Get-ExchangeDelegation.ps1

Extraire la logique de collecte dans une fonction autonome pour le contexte -Parallel :

```powershell
function Get-MailboxAllDelegations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Mailbox
    )

    $delegations = [System.Collections.Generic.List[PSCustomObject]]::new()

    $delegations.AddRange((Get-MailboxFullAccessDelegation -Mailbox $Mailbox))
    $delegations.AddRange((Get-MailboxSendAsDelegation -Mailbox $Mailbox))
    $delegations.AddRange((Get-MailboxSendOnBehalfDelegation -Mailbox $Mailbox))
    $delegations.AddRange((Get-MailboxCalendarDelegation -Mailbox $Mailbox))
    $delegations.AddRange((Get-MailboxForwardingDelegation -Mailbox $Mailbox))

    return $delegations
}
```

### Etape 2 : Remplacer boucle sequentielle - 2h
Fichier : Get-ExchangeDelegation.ps1
Lignes 654-687 - MODIFIER

AVANT :
```powershell
    foreach ($mailbox in $allMailboxes) {
        $mailboxIndex++

        # Progression tous les 10 elements ou a la fin
        if ($mailboxIndex % 10 -eq 0 -or $mailboxIndex -eq $mailboxCount) {
            $percent = [math]::Round(($mailboxIndex / $mailboxCount) * 100)
            Write-Host "`r    [>] Analyse mailboxes : $mailboxIndex/$mailboxCount ($percent%)" -NoNewline -ForegroundColor White
        }

        # FullAccess
        $fullAccessDelegations = Get-MailboxFullAccessDelegation -Mailbox $mailbox
        $statsPerType.FullAccess += $fullAccessDelegations.Count
        foreach ($delegation in $fullAccessDelegations) { $allDelegations.Add($delegation) }

        # SendAs
        $sendAsDelegations = Get-MailboxSendAsDelegation -Mailbox $mailbox
        $statsPerType.SendAs += $sendAsDelegations.Count
        foreach ($delegation in $sendAsDelegations) { $allDelegations.Add($delegation) }

        # SendOnBehalf
        $sendOnBehalfDelegations = Get-MailboxSendOnBehalfDelegation -Mailbox $mailbox
        $statsPerType.SendOnBehalf += $sendOnBehalfDelegations.Count
        foreach ($delegation in $sendOnBehalfDelegations) { $allDelegations.Add($delegation) }

        # Calendar
        $calendarDelegations = Get-MailboxCalendarDelegation -Mailbox $mailbox
        $statsPerType.Calendar += $calendarDelegations.Count
        foreach ($delegation in $calendarDelegations) { $allDelegations.Add($delegation) }

        # Forwarding
        $forwardingDelegations = Get-MailboxForwardingDelegation -Mailbox $mailbox
        $statsPerType.Forwarding += $forwardingDelegations.Count
        foreach ($delegation in $forwardingDelegations) { $allDelegations.Add($delegation) }
    }
```

APRES :
```powershell
    # Parallelisation avec throttling Exchange-safe
    $ThrottleLimit = 5  # Limite Exchange Online sessions/tenant

    $results = $allMailboxes | ForEach-Object -ThrottleLimit $ThrottleLimit -Parallel {
        $mailbox = $_
        $delegations = [System.Collections.Generic.List[PSCustomObject]]::new()

        # Import des fonctions dans le contexte parallele
        # Note: Les fonctions doivent etre definies dans le scriptblock ou importees via module

        try {
            $delegations.AddRange((Get-MailboxFullAccessDelegation -Mailbox $mailbox))
            $delegations.AddRange((Get-MailboxSendAsDelegation -Mailbox $mailbox))
            $delegations.AddRange((Get-MailboxSendOnBehalfDelegation -Mailbox $mailbox))
            $delegations.AddRange((Get-MailboxCalendarDelegation -Mailbox $mailbox))
            $delegations.AddRange((Get-MailboxForwardingDelegation -Mailbox $mailbox))
        }
        catch {
            Write-Warning "Erreur mailbox $($mailbox.PrimarySmtpAddress): $_"
        }

        return $delegations
    }

    # Aggregation des resultats
    foreach ($result in $results) {
        $allDelegations.AddRange($result)
    }

    # Calcul stats (post-traitement)
    $statsPerType.FullAccess = ($allDelegations | Where-Object DelegationType -eq 'FullAccess').Count
    $statsPerType.SendAs = ($allDelegations | Where-Object DelegationType -eq 'SendAs').Count
    $statsPerType.SendOnBehalf = ($allDelegations | Where-Object DelegationType -eq 'SendOnBehalf').Count
    $statsPerType.Calendar = ($allDelegations | Where-Object DelegationType -eq 'Calendar').Count
    $statsPerType.Forwarding = ($allDelegations | Where-Object DelegationType -eq 'Forwarding').Count
```

### Etape 3 : Tests et ajustements throttling - 1h

Tester avec differentes valeurs de ThrottleLimit (3, 5, 10) et observer :
- Temps d'execution
- Erreurs throttling Exchange
- Stabilite connexion

---

## VALIDATION

### Criteres d'Acceptation

- [ ] Temps d'execution reduit d'au moins 2x pour >100 mailboxes
- [ ] Pas d'erreur throttling Exchange avec ThrottleLimit = 5
- [ ] Resultats identiques au mode sequentiel (meme nombre de delegations)
- [ ] Pas de regression sur les autres fonctionnalites

### Benchmarks Attendus

| N mailboxes | Actuel (500ms/appel) | Attendu (TL=5) | Gain |
|-------------|----------------------|----------------|------|
| 100 | 250s | ~60s | 4x |
| 500 | 1250s | ~300s | 4x |
| 1000 | 2500s | ~600s | 4x |

---

## DEPENDANCES

- Bloquee par : Aucune
- Bloque : Aucune

## POINTS ATTENTION

- 1 fichier modifie
- ~150+ lignes modifiees (refactoring majeur)
- Risques **ELEVES** :
  - **Isolation runspaces** : Chaque thread doit Connect-ExchangeOnline
  - **Risky Sign-Ins Azure AD** : Alertes securite possibles
  - **WAM errors** : Windows Account Manager peut echouer
  - Fonctions parent non partagees -> Inline ou module requis
  - Debugging complexe en contexte parallele
  - Progression UI non compatible -> Affichage post-traitement

## CHECKLIST

- [x] Code AVANT = code reel verifie (L654-687)
- [x] Recherche Microsoft effectuee (blocage identifie)
- [ ] Tests unitaires passent
- [ ] Code review effectuee
- [ ] Benchmark avant/apres documente

Labels : perf faible script-principal effort-8h complexite-elevee

## ALTERNATIVE RECOMMANDEE

Pour ameliorer les performances sans parallelisation :

1. **Filtrage serveur** : Reduire le nombre de mailboxes en amont
2. **Batch processing** : Traiter par lots de 100 avec pause
3. **Cache local** : Eviter les re-executions frequentes
4. **Export incremental** : Ne collecter que les changements depuis dernier audit

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | #10 |
| Statut | **ABANDONNEE** |
| Branche | - |
| Date abandon | 2025-12-15 |
| Raison | Isolation runspaces Exchange incompatible avec architecture actuelle |
