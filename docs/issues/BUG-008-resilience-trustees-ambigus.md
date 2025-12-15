# [!] BUG-008 - Resilience aux trustees ambigus (regression performance 7x) - Effort: 2h

## PROBLEME

Apres implementation PERF-001 (migration vers cmdlets EXO*), le script passe de **1:30 a 10:23** (7x plus lent) sur un tenant avec des recipients ambigus.

**Cause racine** : `Get-EXOMailboxPermission` fait des **retries internes REST** quand un trustee a un DisplayName ambigu (ex: "IT-Metrics contact" existe en doublon). Ces retries ajoutent ~1:40 par erreur.

**Contrainte** : Le script est un outil d'audit qui doit etre **resilient a tout type de tenant**, independamment de la qualite des donnees.

## LOCALISATION

- Fichier : Get-ExchangeDelegation.ps1
- Fonctions : `Get-MailboxFullAccessDelegation` (ligne 512), `Get-MailboxCalendarDelegation` (lignes 635, 648)
- Cmdlets : `Get-EXOMailboxPermission`, `Get-EXOMailboxFolderStatistics`, `Get-EXOMailboxFolderPermission`

## CONTEXTE MICROSOFT 2025

| Fait | Source |
|------|--------|
| RPS desactive Oct 2023 | [MS Tech Community](https://techcommunity.microsoft.com/t5/exchange-team-blog/deprecation-of-remote-powershell-in-exchange-online-re-enabling/ba-p/3779692) |
| EXO* cmdlets obligatoires | [MS Learn](https://learn.microsoft.com/en-us/powershell/exchange/exchange-online-powershell-v2) |
| Utiliser ExternalDirectoryObjectId | [MS Learn - Get-EXOMailboxPermission](https://learn.microsoft.com/en-us/powershell/module/exchangepowershell/get-exomailboxpermission) |
| REST retry interne non configurable | Comportement observe |

## OBJECTIF

- Garder les cmdlets EXO* (obligatoire MS)
- Temps d'execution comparable a avant (~2-3 min pour 24 mailboxes)
- Resilience aux trustees ambigus sans blocage
- Collecter un maximum de donnees meme en cas d'erreurs partielles

---

## ANALYSE APPROFONDIE

### Erreurs observees

```
'IT-Metrics contact' doesn't represent a unique recipient.
'Issam KHOULANI' doesn't represent a unique recipient.
```

### Timeline observee

| Phase | Duree | Mailboxes | Moyenne |
|-------|-------|-----------|---------|
| Start -> 1ere erreur | 1:15 | ~10 | 7.5s |
| 1ere erreur -> 83% | 1:52 | ~10 | 11s |
| 83% -> 100% | **7:12** | 4 | **1:48** |

### Hypothese validee

Le REST API de `Get-EXOMailboxPermission` fait des retries internes (non configurables) quand il rencontre un trustee ambigu. Chaque retry ajoute ~20-30 secondes, et plusieurs retries s'accumulent.

---

## SOLUTIONS A INVESTIGUER

### Option A : Timeout wrapper avec PowerShell Jobs (Effort: 1h)

```powershell
$job = Start-Job -ScriptBlock {
    param($Identity)
    Get-EXOMailboxPermission -Identity $Identity -ErrorAction Stop
} -ArgumentList $Mailbox.ExternalDirectoryObjectId

$result = $job | Wait-Job -Timeout 30 | Receive-Job
if ($job.State -eq 'Running') {
    $job | Stop-Job | Remove-Job
    Write-Log "Timeout FullAccess sur $($Mailbox.PrimarySmtpAddress)" -Level WARNING
}
```

**Avantages** : Timeout garanti, resilience
**Inconvenients** : Overhead job creation, complexite

### Option B : Utiliser ExternalDirectoryObjectId + SilentlyContinue (Effort: 30min)

```powershell
$permissions = Get-EXOMailboxPermission -Identity $Mailbox.ExternalDirectoryObjectId -ErrorAction SilentlyContinue
if (-not $permissions -and $Error[0]) {
    Write-Log "Erreur FullAccess: $($Error[0].Exception.Message)" -Level WARNING
}
```

**Avantages** : Simple, best practice MS
**Inconvenients** : Ne resout pas les retries internes

### Option C : Parallelisation avec ForEach-Object -Parallel (Effort: 2h)

```powershell
$mailboxes | ForEach-Object -Parallel {
    # Traitement parallele masque la latence des retries
} -ThrottleLimit 5
```

**Avantages** : Masque la latence, moderne (PS 7.2+)
**Inconvenients** : Complexite checkpoint, gestion erreurs

### Option D : Runspace pool avec timeout individuel (Effort: 3h)

**Avantages** : Controle fin, performance optimale
**Inconvenients** : Complexite elevee

---

## IMPLEMENTATION RECOMMANDEE

### Phase 1 : Quick win (30min)

1. Utiliser `ExternalDirectoryObjectId` au lieu de `Identity`
2. Changer `-ErrorAction Stop` en `SilentlyContinue` avec gestion manuelle
3. Mesurer l'impact

### Phase 2 : Si insuffisant (1h30)

1. Implementer timeout wrapper avec Jobs
2. Timeout de 30 secondes par mailbox pour FullAccess
3. Log et continue sur timeout

---

## VALIDATION

### Criteres d'Acceptation

- [ ] Temps d'execution < 3 min pour 24 mailboxes (meme avec trustees ambigus)
- [ ] Aucun blocage > 30 secondes sur une mailbox
- [ ] Toutes les delegations valides sont collectees
- [ ] Les erreurs sont loggees (WARNING) sans bloquer
- [ ] PSScriptAnalyzer : aucune erreur

### Tests

```powershell
# Test sur tenant avec trustees ambigus
.\Get-ExchangeDelegation.ps1 -IncludeSharedMailbox -IncludeLastLogon
# Attendu : < 3 min, 64 delegations, warnings pour mailboxes problematiques
```

---

## CHECKLIST

- [ ] Phase 1 implementee et testee
- [ ] Phase 2 si necessaire
- [ ] Documentation mise a jour
- [ ] SESSION-STATE.md mis a jour

Labels: bug performance resilience exchange-online critical

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | # (apres gh issue create) |
| Statut | RESOLVED |
| Branche | fix/BUG-008-resilience-trustees-ambigus |
