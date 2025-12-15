# [~] FEAT-003 Detecter les permissions calendrier orphelines cachees | Effort: 2h

## PROBLEME

Les permissions calendrier peuvent etre orphelines meme si elles affichent un nom (pas un SID). Exchange cache le `DisplayName` dans la permission au moment de sa creation. Apres suppression du compte, le nom reste affiche mais `ADRecipient` est null. Ces permissions ne sont pas detectees par le script actuel.

## LOCALISATION

- Fichier : Get-ExchangeDelegation.ps1:L453-512
- Fonction : Get-MailboxCalendarDelegation()
- Fonction : New-DelegationRecord()
- Fonction : Remove-OrphanedDelegation()

## OBJECTIF

1. Ajouter colonne `IsOrphan` dans l'export CSV
2. Detecter permissions calendrier avec `ADRecipient = $null`
3. Permettre suppression via `-CleanupOrphans -Force`
4. Logger ces permissions meme sans action

---

## IMPLEMENTATION

### Etape 1 : Ajouter parametre IsOrphan a New-DelegationRecord - 15min
Fichier : Get-ExchangeDelegation.ps1:L314-339

AVANT :
```powershell
function New-DelegationRecord {
    param(
        [string]$MailboxEmail,
        [string]$MailboxDisplayName,
        [string]$TrusteeEmail,
        [string]$TrusteeDisplayName,
        [string]$DelegationType,
        [string]$AccessRights,
        [string]$FolderPath = ''
    )

    [PSCustomObject]@{
        MailboxEmail       = $MailboxEmail
        MailboxDisplayName = $MailboxDisplayName
        TrusteeEmail       = $TrusteeEmail
        TrusteeDisplayName = $TrusteeDisplayName
        DelegationType     = $DelegationType
        AccessRights       = $AccessRights
        FolderPath         = $FolderPath
        CollectedAt        = Get-Date -Format 'o'
    }
}
```

APRES :
```powershell
function New-DelegationRecord {
    param(
        [string]$MailboxEmail,
        [string]$MailboxDisplayName,
        [string]$TrusteeEmail,
        [string]$TrusteeDisplayName,
        [string]$DelegationType,
        [string]$AccessRights,
        [string]$FolderPath = '',
        [bool]$IsOrphan = $false
    )

    [PSCustomObject]@{
        MailboxEmail       = $MailboxEmail
        MailboxDisplayName = $MailboxDisplayName
        TrusteeEmail       = $TrusteeEmail
        TrusteeDisplayName = $TrusteeDisplayName
        DelegationType     = $DelegationType
        AccessRights       = $AccessRights
        FolderPath         = $FolderPath
        IsOrphan           = $IsOrphan
        CollectedAt        = Get-Date -Format 'o'
    }
}
```

### Etape 2 : Detecter ADRecipient null dans Get-MailboxCalendarDelegation - 30min
Fichier : Get-ExchangeDelegation.ps1:L453-512

Ajouter detection orphelin dans la boucle foreach des permissions :

```powershell
# Detecter si orphelin (ADRecipient null = compte supprime mais nom cache)
$isOrphan = $null -eq $permission.User.ADRecipient -and $trusteeIdentity -notmatch '^S-1-5-21-'
if ($isOrphan) {
    Write-Log "Permission calendrier orpheline (nom cache): $trusteeIdentity sur $($Mailbox.PrimarySmtpAddress)" -Level DEBUG
}

$delegationRecord = New-DelegationRecord `
    -MailboxEmail $Mailbox.PrimarySmtpAddress `
    -MailboxDisplayName $Mailbox.DisplayName `
    -TrusteeEmail $trusteeEmail `
    -TrusteeDisplayName $trusteeIdentity `
    -DelegationType 'Calendar' `
    -AccessRights ($permission.AccessRights -join ', ') `
    -FolderPath $folderName `
    -IsOrphan $isOrphan
```

### Etape 3 : Mettre a jour le filtre des orphelins - 15min
Fichier : Get-ExchangeDelegation.ps1 (section cleanup ~L708)

AVANT :
```powershell
$orphanDelegations = $allDelegations | Where-Object {
    $_.TrusteeEmail -match '^S-1-5-21-'
}
```

APRES :
```powershell
$orphanDelegations = $allDelegations | Where-Object {
    ($_.TrusteeEmail -match '^S-1-5-21-') -or ($_.IsOrphan -eq $true)
}
```

### Etape 4 : Logger les stats orphelins - 15min
Fichier : Get-ExchangeDelegation.ps1 (section resume)

```powershell
$sidOrphans = ($orphanDelegations | Where-Object { $_.TrusteeEmail -match '^S-1-5-21-' }).Count
$cachedOrphans = ($orphanDelegations | Where-Object { $_.IsOrphan -and $_.TrusteeEmail -notmatch '^S-1-5-21-' }).Count
Write-Log "Orphelins: $($orphanDelegations.Count) total (SID: $sidOrphans, Noms caches: $cachedOrphans)" -Level INFO
```

---

## VALIDATION

### Criteres d'Acceptation

- [ ] Export CSV contient colonne `IsOrphan` (True/False)
- [ ] Permissions calendrier avec ADRecipient=null ont IsOrphan=True
- [ ] `-CleanupOrphans` liste les permissions orphelines cachees (ex: Carol PINKUS)
- [ ] `-CleanupOrphans -Force` supprime ces permissions
- [ ] Log differencie SID vs noms caches
- [ ] Pas de regression sur SID orphelins existants

---

## DEPENDANCES

- Bloquee par : Aucune
- Bloque : Aucune

## POINTS ATTENTION

- 1 fichier modifie
- ~50 lignes modifiees
- Risques : Changement format CSV (nouvelle colonne) - non breaking

## CHECKLIST

- [ ] Code AVANT = code reel verifie
- [ ] Tests passent
- [ ] Code review

Labels : feat moyenne calendar orphan

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | # |
| Statut | IN_PROGRESS |
| Branche | feature/FEAT-003-calendar-orphelins-caches |
