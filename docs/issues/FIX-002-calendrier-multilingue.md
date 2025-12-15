# [~] [FIX-002] Corriger detection calendrier multilingue | Effort: 1h

## PROBLEME

Le script utilise un chemin code en dur `:\Calendar` pour acceder au dossier calendrier des mailboxes. Or, le nom du dossier est localise selon la langue de la mailbox (Calendar, Calendrier, Kalender, Calendario, etc.). Cela provoque des erreurs "introuvable" pour les mailboxes non-anglaises.

## LOCALISATION
- Fichier : Get-ExchangeDelegation.ps1:L450-496
- Fonction : Get-MailboxCalendarDelegation()
- Fonction : Remove-OrphanedDelegation()

## OBJECTIF

Detecter automatiquement le nom localise du dossier calendrier via `FolderType` (toujours en anglais) pour supporter les environnements multilingues.

---

## ANALYSE IMPACT

### Fichiers Impactes
| Fichier | Raison | Action Requise |
|---------|--------|----------------|
| Get-ExchangeDelegation.ps1 | Fonction Get-MailboxCalendarDelegation | Modifier |
| Get-ExchangeDelegation.ps1 | Fonction Remove-OrphanedDelegation | Modifier |
| CSV Export | Colonne FolderPath | Contient maintenant le nom localise |

### References
- [Evotec - Multilanguage Office 365 tenants](https://evotec.xyz/powershell-changing-exchange-folder-permissions-in-multilanguage-office-365-tenants/)
- [Exchange PowerShell - Calendar in any language](https://itsallinthecode.com/exchange-powershell-get-calendar-folder-permissions-in-any-language/)

---

## IMPLEMENTATION

### Etape 1 : Modifier Get-MailboxCalendarDelegation - 30min
Fichier : Get-ExchangeDelegation.ps1
Lignes 450-496 - MODIFIER

AVANT :
```powershell
$calendarFolderPath = "$($Mailbox.PrimarySmtpAddress):\Calendar"

$permissions = Get-MailboxFolderPermission -Identity $calendarFolderPath -ErrorAction Stop
```

APRES :
```powershell
# Detecter le nom localise du calendrier via FolderType (toujours en anglais)
$calendarFolder = Get-MailboxFolderStatistics -Identity $Mailbox.PrimarySmtpAddress -FolderScope Calendar -ErrorAction Stop |
    Where-Object { $_.FolderType -eq 'Calendar' } |
    Select-Object -First 1

if (-not $calendarFolder) {
    Write-Log "Calendrier non trouve pour $($Mailbox.PrimarySmtpAddress)" -Level DEBUG
    return $delegationList
}

# Construire le chemin avec le nom localise (ex: \Calendrier -> Calendrier)
$folderName = $calendarFolder.FolderPath.TrimStart('\')
$calendarFolderPath = "$($Mailbox.PrimarySmtpAddress):\$folderName"

$permissions = Get-MailboxFolderPermission -Identity $calendarFolderPath -ErrorAction Stop
```

Justification : `FolderType` est toujours en anglais peu importe la langue de la mailbox, ce qui permet une detection fiable.

### Etape 2 : Modifier Remove-OrphanedDelegation - 15min
Fichier : Get-ExchangeDelegation.ps1
Lignes 279-286 - MODIFIER

AVANT :
```powershell
'Calendar' {
    $calendarPath = "${mailbox}:\Calendar"
    Remove-MailboxFolderPermission -Identity $calendarPath `
        -User $trustee -Confirm:$false -ErrorAction Stop
}
```

APRES :
```powershell
'Calendar' {
    # Utiliser le FolderPath stocke (nom localise: Calendar, Calendrier, etc.)
    $folderPath = $Delegation.FolderPath
    if ([string]::IsNullOrEmpty($folderPath)) { $folderPath = 'Calendar' }
    $calendarPath = "${mailbox}:\$folderPath"
    Remove-MailboxFolderPermission -Identity $calendarPath `
        -User $trustee -Confirm:$false -ErrorAction Stop
}
```

Justification : Reutilise le FolderPath stocke lors de la collecte pour garantir la coherence.

### Etape 3 : Mettre a jour la version - 5min
Fichier : Get-ExchangeDelegation.ps1

Version : 1.2.0 -> 1.3.0

---

## VALIDATION

### Criteres d'Acceptation
- [x] Les mailboxes en francais (Calendrier) sont traitees correctement
- [x] Les mailboxes en anglais (Calendar) continuent de fonctionner
- [x] Le CSV contient le nom localise dans FolderPath
- [x] La suppression d'orphelins utilise le bon chemin localise
- [x] Pas de regression sur les autres types de delegation

---

## DEPENDANCES
- Bloquee par : Aucune
- Bloque : Aucune

## POINTS ATTENTION
- 2 fonctions modifiees
- +15 lignes ajoutees
- Impact performance : +1 appel API (Get-MailboxFolderStatistics) par mailbox
- Risques : Aucun - fallback vers "Calendar" si detection echoue

## CHECKLIST
- [x] Code AVANT = code reel verifie
- [x] Tests manuels effectues
- [x] Code review effectuee

Labels : fix moyenne exchange calendar i18n

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | #4 |
| Statut | **CLOSED** |
| Branche | fix/FIX-002-calendrier-multilingue (merged) |
| Date | 2025-12-15 |
