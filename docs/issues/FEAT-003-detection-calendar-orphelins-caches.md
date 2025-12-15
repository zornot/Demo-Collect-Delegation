# [~] FEAT-003 Colonne IsOrphan pour toutes les delegations orphelines | Effort: 2h

## PROBLEME

Les permissions orphelines n'etaient pas marquees de maniere coherente dans l'export CSV :
- **SID orphelins** (S-1-5-21-*) : Detectes pour cleanup mais pas marques IsOrphan
- **Noms caches** (ex: "Carol PINKUS") : Non detectes car `ADRecipient` est null mais nom affiche

## LOCALISATION

- Fichier : Get-ExchangeDelegation.ps1
- Fonctions : Get-MailboxFullAccessDelegation(), Get-MailboxSendAsDelegation(), Get-MailboxSendOnBehalfDelegation(), Get-MailboxCalendarDelegation()
- Fonction : New-DelegationRecord()

## OBJECTIF

1. Ajouter colonne `IsOrphan` dans l'export CSV
2. Marquer IsOrphan=True pour tous les orphelins (SID et noms caches)
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
# Detecter si orphelin : SID (S-1-5-21-*) OU ADRecipient null (nom cache)
$isOrphan = ($trusteeEmail -match '^S-1-5-21-') -or ($null -eq $permission.User.ADRecipient)
if ($isOrphan -and $trusteeEmail -notmatch '^S-1-5-21-') {
    Write-Log "Permission calendrier orpheline (nom cache): $trusteeDisplayName sur $($Mailbox.PrimarySmtpAddress)" -Level DEBUG
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

### Etape 5 : Etendre IsOrphan a FullAccess/SendAs/SendOnBehalf - 15min (AJOUT)
Fichier : Get-ExchangeDelegation.ps1

Ajouter detection SID dans les 3 autres fonctions de collecte :

```powershell
# Dans Get-MailboxFullAccessDelegation, Get-MailboxSendAsDelegation, Get-MailboxSendOnBehalfDelegation
$isOrphan = $trusteeInfo.Email -match '^S-1-5-21-'

$delegationRecord = New-DelegationRecord `
    # ... autres parametres ...
    -IsOrphan $isOrphan
```

---

## VALIDATION

### Criteres d'Acceptation

- [x] Export CSV contient colonne `IsOrphan` (True/False)
- [x] Permissions calendrier avec ADRecipient=null ont IsOrphan=True
- [x] Permissions FullAccess/SendAs/SendOnBehalf avec SID ont IsOrphan=True
- [x] `-CleanupOrphans` liste les permissions orphelines cachees (ex: Carol PINKUS)
- [x] `-CleanupOrphans -Force` supprime ces permissions
- [x] Log differencie SID vs noms caches
- [x] Pas de regression sur SID orphelins existants

---

## DEPENDANCES

- Bloquee par : Aucune
- Bloque : Aucune

## POINTS ATTENTION

- 1 fichier modifie
- ~60 lignes modifiees (4 fonctions)
- Risques : Changement format CSV (nouvelle colonne) - non breaking

## CHECKLIST

- [x] Code AVANT = code reel verifie
- [x] Tests manuels effectues
- [x] Code review

Labels : feat moyenne delegation orphan

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | #6 |
| Statut | CLOSED |
| Branche | feature/FEAT-003-calendar-orphelins-caches |
