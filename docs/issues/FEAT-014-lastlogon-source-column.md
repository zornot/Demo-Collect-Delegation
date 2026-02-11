# [~] FEAT-014-lastlogon-source-column - Effort: 30min

## PROBLEME

Sans licence P1, le script utilise `LastInteractionTime` (EXO Statistics) qui inclut les processus background Exchange, pas uniquement l'activite utilisateur reelle. L'utilisateur n'a aucune indication dans le CSV sur la fiabilite des donnees LastLogon.

## LOCALISATION

- Fichier : Get-ExchangeDelegation.ps1:711-746
- Fonction : New-DelegationRecord
- Variable : $Script:LastLogonStrategy

## OBJECTIF

Ajouter une colonne `LastLogonSource` dans l'export CSV indiquant la methode utilisee pour collecter le LastLogon. Permet a l'utilisateur de savoir si les donnees sont fiables (SignInActivity) ou approximatives (EXO).

---

## DESIGN

### Objectif
Tracer la source des donnees LastLogon pour permettre a l'utilisateur d'evaluer leur fiabilite.

### Architecture
- **Module concerne** : Script principal (pas de module)
- **Dependances** : Variable existante `$Script:LastLogonStrategy`
- **Impact** : New-DelegationRecord, tous les appels a cette fonction
- **Pattern** : Ajout parametre + propriete

### Interface
```powershell
# Signature mise a jour
function New-DelegationRecord {
    param(
        # ... parametres existants ...
        [string]$MailboxLastLogon = '',
        [string]$LastLogonSource = ''  # Nouveau
    )
}

# Valeurs possibles pour LastLogonSource
# - "SignInActivity" : Azure AD P1/P2, donnees fiables
# - "GraphReports"   : Graph Reports API, bon compromis
# - "EXO"            : EXO Statistics, inclut background
# - ""               : Non collecte
```

### Tests Attendus
- [ ] Cas nominal : Export CSV contient colonne LastLogonSource
- [ ] Valeur correcte selon $Script:LastLogonStrategy
- [ ] Colonne vide si MailboxLastLogon vide

### Considerations
- **Retrocompatibilite** : Nouvelle colonne en fin de CSV, pas d'impact sur imports existants

---

## IMPLEMENTATION

### Etape 1 : Ajouter parametre a New-DelegationRecord - 10min
Fichier : Get-ExchangeDelegation.ps1:728-729

AVANT :
```powershell
        [string]$MailboxType = '',
        [string]$MailboxLastLogon = ''
    )
```

APRES :
```powershell
        [string]$MailboxType = '',
        [string]$MailboxLastLogon = '',
        [string]$LastLogonSource = ''
    )
```

### Etape 2 : Ajouter propriete dans l'objet - 5min
Fichier : Get-ExchangeDelegation.ps1:743-745

AVANT :
```powershell
        MailboxLastLogon   = $MailboxLastLogon
        CollectedAt        = $script:CollectionTimestamp
    }
```

APRES :
```powershell
        MailboxLastLogon   = $MailboxLastLogon
        LastLogonSource    = $LastLogonSource
        CollectedAt        = $script:CollectionTimestamp
    }
```

### Etape 3 : Passer la valeur dans les appels - 15min
Fichier : Get-ExchangeDelegation.ps1

Rechercher tous les appels `New-DelegationRecord` et ajouter :
```powershell
-LastLogonSource $Script:LastLogonStrategy
```

---

## VALIDATION

### Criteres d'Acceptation
- [ ] Colonne `LastLogonSource` presente dans le CSV
- [ ] Valeur = "SignInActivity" si licence P1 detectee
- [ ] Valeur = "GraphReports" si Graph Reports utilise
- [ ] Valeur = "EXO" si fallback EXO Statistics
- [ ] Valeur vide si `-IncludeLastLogon` non specifie
- [ ] Pas de regression sur exports existants

### Test Manuel
```powershell
.\Get-ExchangeDelegation.ps1 -IncludeLastLogon -CsvPath test.csv
Import-Csv test.csv | Select-Object -First 1 | Format-List *Source*
# Doit afficher : LastLogonSource : [SignInActivity|GraphReports|EXO]
```

## CHECKLIST
- [ ] Code AVANT = code reel
- [ ] Tests passent
- [ ] PSScriptAnalyzer clean

Labels : feat ~ lastlogon csv

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | # (apres gh issue create) |
| Statut | RESOLVED |
| Branche | feature/FEAT-014-lastlogon-source-column |
