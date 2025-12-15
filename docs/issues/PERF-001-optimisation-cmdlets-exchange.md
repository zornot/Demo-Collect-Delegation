# [~] PERF-001 - Optimisation des cmdlets Exchange Online - Effort: 4h

## PROBLEME

Le script utilise des cmdlets legacy (Get-MailboxPermission, Get-MailboxStatistics) au lieu des cmdlets EXO* optimisees REST. De plus, `Get-Recipient` est appele pour CHAQUE trustee sans cache, causant des milliers d'appels redondants sur gros tenants.

**Impact** : Performance degradee sur tenants > 500 mailboxes. Temps d'execution 3-4x plus long que necessaire.

## LOCALISATION

- Fichier : Get-ExchangeDelegation.ps1
- Lignes : 299 (Resolve-TrusteeInfo), 443, 483, 566, 579, 874

## OBJECTIF

1. Migrer vers cmdlets EXO* (REST-based, 3-4x plus rapide)
2. Implementer cache pour Get-Recipient (reduit 50-80% des appels)
3. Utiliser PropertySets optimises pour Get-EXOMailbox

---

## ANALYSE

### Sources

| Source | Recommandation |
|--------|----------------|
| [Microsoft PropertySets](https://learn.microsoft.com/en-us/powershell/exchange/cmdlet-property-sets) | Utiliser Minimum+Delivery |
| [Get-ExoMailbox vs Get-Mailbox](https://office365itpros.com/2024/09/19/get-exomailbox/) | EXO* 3-4x plus rapide |
| [Get-EXOMailboxPermission](https://learn.microsoft.com/en-us/powershell/module/exchangepowershell/get-exomailboxpermission) | Recommande pour performance |

### Etat actuel vs cible

| Cmdlet actuel | Cmdlet cible | Gain estime |
|---------------|--------------|-------------|
| Get-MailboxPermission | Get-EXOMailboxPermission | 3-4x |
| Get-MailboxFolderStatistics | Get-EXOMailboxFolderStatistics | REST natif |
| Get-MailboxFolderPermission | Get-EXOMailboxFolderPermission | REST natif |
| Get-MailboxStatistics | Get-EXOMailboxStatistics | REST natif |
| Get-Recipient (N appels) | Cache + fallback | -50% a -80% |

### Impact estime (1000 mailboxes)

| Scenario | Avant | Apres |
|----------|-------|-------|
| Appels Get-Recipient | 5,000+ | ~1,000 |
| Temps total | ~30 min | ~10 min |

---

## IMPLEMENTATION

### Etape 1 : Cache Recipients global - 2h

Fichier : Get-ExchangeDelegation.ps1

**Ajouter au debut du script (apres connexion Exchange) :**

```powershell
# Cache global des recipients pour eviter appels redondants
$script:RecipientCache = @{}

function Initialize-RecipientCache {
    [CmdletBinding()]
    param()

    Write-Status -Type Info -Message "Chargement cache recipients..." -Indent 1
    $recipients = Get-EXORecipient -ResultSize Unlimited -Properties DisplayName,PrimarySmtpAddress

    foreach ($r in $recipients) {
        if ($r.PrimarySmtpAddress) {
            $script:RecipientCache[$r.PrimarySmtpAddress.ToLower()] = $r
        }
        if ($r.DisplayName) {
            $script:RecipientCache[$r.DisplayName] = $r
        }
    }

    Write-Status -Type Success -Message "Cache: $($script:RecipientCache.Count) recipients" -Indent 1
}
```

**Modifier Resolve-TrusteeInfo (ligne ~299) :**

AVANT :
```powershell
function Resolve-TrusteeInfo {
    param([string]$Identity)
    try {
        $recipient = Get-Recipient -Identity $Identity -ErrorAction Stop
        # ...
    }
}
```

APRES :
```powershell
function Resolve-TrusteeInfo {
    param([string]$Identity)

    # Verifier cache d'abord
    $cacheKey = $Identity.ToLower()
    if ($script:RecipientCache.ContainsKey($cacheKey)) {
        $cached = $script:RecipientCache[$cacheKey]
        return @{
            Email = $cached.PrimarySmtpAddress
            DisplayName = $cached.DisplayName
            IsOrphan = $false
        }
    }

    # Fallback API si pas en cache (nouveau recipient ou SID)
    try {
        $recipient = Get-Recipient -Identity $Identity -ErrorAction Stop
        # Ajouter au cache pour prochaine fois
        if ($recipient.PrimarySmtpAddress) {
            $script:RecipientCache[$recipient.PrimarySmtpAddress.ToLower()] = $recipient
        }
        return @{
            Email = $recipient.PrimarySmtpAddress
            DisplayName = $recipient.DisplayName
            IsOrphan = $false
        }
    }
    catch {
        return @{
            Email = $null
            DisplayName = $Identity
            IsOrphan = $true
        }
    }
}
```

### Etape 2 : Migrer vers Get-EXOMailboxPermission - 30min

Fichier : Get-ExchangeDelegation.ps1 (ligne ~443)

AVANT :
```powershell
$permissions = Get-MailboxPermission -Identity $mailbox.PrimarySmtpAddress -ErrorAction Stop
```

APRES :
```powershell
$permissions = Get-EXOMailboxPermission -Identity $mailbox.PrimarySmtpAddress -ErrorAction Stop
```

### Etape 3 : Migrer vers Get-EXOMailboxFolderStatistics - 30min

Fichier : Get-ExchangeDelegation.ps1 (ligne ~566)

AVANT :
```powershell
$folderStats = Get-MailboxFolderStatistics -Identity $mailbox.PrimarySmtpAddress -FolderScope Calendar
```

APRES :
```powershell
$folderStats = Get-EXOMailboxFolderStatistics -Identity $mailbox.PrimarySmtpAddress -FolderScope Calendar
```

### Etape 4 : Migrer vers Get-EXOMailboxFolderPermission - 30min

Fichier : Get-ExchangeDelegation.ps1 (ligne ~579)

AVANT :
```powershell
$calendarPerms = Get-MailboxFolderPermission -Identity $calendarPath -ErrorAction Stop
```

APRES :
```powershell
$calendarPerms = Get-EXOMailboxFolderPermission -Identity $calendarPath -ErrorAction Stop
```

### Etape 5 : Migrer vers Get-EXOMailboxStatistics - 30min

Fichier : Get-ExchangeDelegation.ps1 (ligne ~874)

AVANT :
```powershell
$stats = Get-MailboxStatistics -Identity $mailbox.PrimarySmtpAddress -ErrorAction SilentlyContinue
```

APRES :
```powershell
$stats = Get-EXOMailboxStatistics -Identity $mailbox.PrimarySmtpAddress -ErrorAction SilentlyContinue
```

### Etape 6 : PropertySets pour Get-EXOMailbox (optionnel) - 15min

Fichier : Get-ExchangeDelegation.ps1 (ligne ~736)

AVANT :
```powershell
-Properties DisplayName, PrimarySmtpAddress, ExchangeObjectId, RecipientTypeDetails, GrantSendOnBehalfTo, ForwardingAddress, ForwardingSmtpAddress
```

APRES :
```powershell
-PropertySets Minimum,Delivery
```

Note: Verifier que toutes les proprietes necessaires sont incluses dans ces PropertySets.

---

## VALIDATION

### Criteres d'Acceptation

- [ ] Cache recipients charge au demarrage
- [ ] Cmdlets EXO* utilisees (pas de Get-Mailbox* legacy)
- [ ] Meme resultat CSV qu'avant (regression test)
- [ ] Temps d'execution reduit (mesurer avant/apres)
- [ ] Pas d'erreur sur mailboxes avec caracteres speciaux

### Tests de performance

```powershell
# Mesurer temps avant
Measure-Command { .\Get-ExchangeDelegation.ps1 -IncludeSharedMailbox }

# Comparer avec apres optimisation
```

### Regression test

```powershell
# Comparer hash des CSV avant/apres
Get-FileHash .\Output\before.csv
Get-FileHash .\Output\after.csv
```

## CHECKLIST

- [ ] Initialize-RecipientCache implementee
- [ ] Resolve-TrusteeInfo utilise cache
- [ ] Get-MailboxPermission → Get-EXOMailboxPermission
- [ ] Get-MailboxFolderStatistics → Get-EXOMailboxFolderStatistics
- [ ] Get-MailboxFolderPermission → Get-EXOMailboxFolderPermission
- [ ] Get-MailboxStatistics → Get-EXOMailboxStatistics
- [ ] Tests regression passes
- [ ] Mesure performance documentee

Labels : performance optimization exchange-online

---

## RISQUES

| Risque | Mitigation |
|--------|------------|
| Get-EXORecipient n'existe pas | Utiliser Get-Recipient avec -ResultSize |
| PropertySets manque propriete | Tester et ajouter -Properties si besoin |
| Caracteres speciaux dans noms | EXO* gere mieux, mais tester |
| Cache trop gros (100k recipients) | Limiter ou lazy-load |

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | # (apres gh issue create) |
| Statut | DRAFT |
| Branche | feature/PERF-001-optimisation-cmdlets-exchange |
