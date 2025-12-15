# FEAT-011 : Ajouter colonne MailboxType

## Statut
CLOSED

## Branche
feature/FEAT-011-colonne-mailboxtype

## Contexte

Pour une analyse complète des délégations, il est utile de connaître le type de chaque mailbox (UserMailbox, SharedMailbox, RoomMailbox, etc.).

## Objectif

Ajouter une colonne `MailboxType` après `IsInactive` dans l'export CSV.

## Ordre des colonnes (après modification)

```
MailboxEmail, MailboxDisplayName, TrusteeEmail, TrusteeDisplayName,
DelegationType, AccessRights, FolderPath, IsOrphan,
IsInactive, MailboxType, MailboxLastLogon, CollectedAt
```

## Implémentation

### 1. Modifier New-DelegationRecord (ligne ~387)

Ajouter le paramètre et la propriété :

```powershell
param(
    # ... existing params ...
    [bool]$IsInactive = $false,
    [string]$MailboxType = '',        # NOUVEAU
    [string]$MailboxLastLogon = ''
)

[PSCustomObject]@{
    # ... existing properties ...
    IsInactive         = $IsInactive
    MailboxType        = $MailboxType  # NOUVEAU
    MailboxLastLogon   = $MailboxLastLogon
    CollectedAt        = $script:CollectionTimestamp
}
```

### 2. Modifier le header CSV (ligne ~806)

```powershell
$csvHeader = @(
    'MailboxEmail', 'MailboxDisplayName', 'TrusteeEmail', 'TrusteeDisplayName',
    'DelegationType', 'AccessRights', 'FolderPath', 'IsOrphan',
    'IsInactive', 'MailboxType', 'MailboxLastLogon', 'CollectedAt'
)
```

### 3. Passer MailboxType lors de la création des délégations (ligne ~850+)

```powershell
$delegation.MailboxType = $mailbox.RecipientTypeDetails
```

### 4. Récupérer RecipientTypeDetails dans Get-EXOMailbox (ligne ~723)

Ajouter `RecipientTypeDetails` aux propriétés demandées :

```powershell
Get-EXOMailbox -ResultSize Unlimited -RecipientTypeDetails $mailboxTypes `
    -Properties DisplayName, PrimarySmtpAddress, ExchangeObjectId, RecipientTypeDetails, ...
```

## Valeurs possibles

| MailboxType | Description |
|-------------|-------------|
| UserMailbox | Boîte utilisateur standard |
| SharedMailbox | Boîte partagée |
| RoomMailbox | Salle de réunion |
| EquipmentMailbox | Équipement |

## Critères d'acceptation

- [ ] Colonne MailboxType présente dans le CSV
- [ ] Position : après IsInactive, avant MailboxLastLogon
- [ ] Valeur correcte pour chaque type de mailbox
- [ ] Tests avec -IncludeSharedMailbox et -IncludeRoomMailbox
