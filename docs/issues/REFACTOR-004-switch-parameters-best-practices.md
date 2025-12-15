# [~] REFACTOR-004 - Aligner parametres switch sur best practices PowerShell - Effort: 30min

## PROBLEME

Le parametre `[switch]$IncludeSharedMailbox = $true` viole les conventions PowerShell (PSAvoidDefaultValueSwitchParameter). Un switch ne doit pas avoir de valeur par defaut. De plus, le comportement actuel est incoherent avec Get-EXOMailbox natif qui retourne UserMailbox seulement par defaut.

**Impact** : Warning PSScriptAnalyzer, confusion utilisateur, incoherence avec ecosystem Exchange.

## LOCALISATION

- Fichier : Get-ExchangeDelegation.ps1:L79-80
- Parametres : `$IncludeSharedMailbox`, `$IncludeRoomMailbox`
- Documentation : README.md (exemples d'usage)

## OBJECTIF

Aligner sur les best practices Microsoft/PowerShell :
- Switches sans valeur par defaut (opt-in explicite)
- Comportement par defaut restrictif (UserMailbox seulement)
- Coherent avec Get-EXOMailbox natif

---

## ANALYSE

### Sources consultees

| Source | Recommandation |
|--------|----------------|
| [Azure PowerShell Guidelines](https://github.com/Azure/azure-powershell/blob/main/documentation/development-docs/design-guidelines/parameter-best-practices.md) | "Parameters of type bool are strongly discouraged" - utiliser switch |
| [PowerShell Team Blog](https://devblogs.microsoft.com/powershell/exclude-include-filter-parameters-how-to-make-sense-of-these/) | Include = opt-in additif, Exclude = opt-out soustractif |
| Get-EXOMailbox natif | UserMailbox seulement par defaut |

### Comportement actuel vs cible

| Parametre | Actuel | Cible |
|-----------|--------|-------|
| Sans flags | User + Shared | User seulement |
| `-IncludeSharedMailbox` | Redondant (deja actif) | Ajoute SharedMailbox |
| `-IncludeRoomMailbox` | Ajoute Room | Ajoute Room (inchange) |

### Breaking Change

**Comportemental** : Oui - le default passe de "User+Shared" a "User only"
**API** : Non - les parametres restent identiques

---

## IMPLEMENTATION

### Etape 1 : Supprimer valeur par defaut - 5min

Fichier : Get-ExchangeDelegation.ps1

AVANT :
```powershell
    [Parameter(Mandatory = $false)]
    [switch]$IncludeSharedMailbox = $true,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeRoomMailbox = $false,
```

APRES :
```powershell
    [Parameter(Mandatory = $false)]
    [switch]$IncludeSharedMailbox,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeRoomMailbox,
```

### Etape 2 : Mettre a jour documentation param - 5min

Fichier : Get-ExchangeDelegation.ps1 (section .PARAMETER)

AVANT :
```powershell
.PARAMETER IncludeSharedMailbox
    Inclut les boites partagees (SharedMailbox) dans la collecte.
    Active par defaut.
```

APRES :
```powershell
.PARAMETER IncludeSharedMailbox
    Inclut les boites partagees (SharedMailbox) dans la collecte.
    Par defaut, seules les UserMailbox sont collectees.
```

### Etape 3 : Mettre a jour README - 10min

Fichier : README.md

AVANT :
```powershell
# Exclure les boites partagees
.\Get-ExchangeDelegation.ps1 -IncludeSharedMailbox:$false
```

APRES :
```powershell
# Collecte standard (UserMailbox seulement)
.\Get-ExchangeDelegation.ps1

# Inclure les boites partagees
.\Get-ExchangeDelegation.ps1 -IncludeSharedMailbox

# Collecte complete (User + Shared + Room + Inactive)
.\Get-ExchangeDelegation.ps1 -IncludeSharedMailbox -IncludeRoomMailbox -IncludeInactive
```

### Etape 4 : Verifier logique interne - 5min

Fichier : Get-ExchangeDelegation.ps1 (ligne ~718)

La logique existante est deja correcte (opt-in) :
```powershell
$mailboxTypes = @('UserMailbox')
if ($IncludeSharedMailbox) { $mailboxTypes += 'SharedMailbox' }
if ($IncludeRoomMailbox) { $mailboxTypes += 'RoomMailbox' }
```

Aucune modification necessaire.

---

## VALIDATION

### Criteres d'Acceptation

- [ ] PSScriptAnalyzer : aucun warning PSAvoidDefaultValueSwitchParameter
- [ ] Sans flags : collecte UserMailbox seulement
- [ ] `-IncludeSharedMailbox` : collecte User + Shared
- [ ] `-IncludeSharedMailbox -IncludeRoomMailbox` : collecte User + Shared + Room
- [ ] README mis a jour avec nouveaux exemples
- [ ] Pas de regression fonctionnelle

### Tests manuels

```powershell
# Test 1 : Default (UserMailbox only)
.\Get-ExchangeDelegation.ps1 -OutputPath .\test1.csv
# Verifier : pas de SharedMailbox dans le CSV

# Test 2 : Avec SharedMailbox
.\Get-ExchangeDelegation.ps1 -IncludeSharedMailbox -OutputPath .\test2.csv
# Verifier : SharedMailbox presentes

# Test 3 : Complet
.\Get-ExchangeDelegation.ps1 -IncludeSharedMailbox -IncludeRoomMailbox -OutputPath .\test3.csv
# Verifier : tous types presents
```

## CHECKLIST

- [ ] Code AVANT = code reel
- [ ] PSScriptAnalyzer sans warning
- [ ] README a jour
- [ ] Tests manuels passes

Labels : refactor parameters powershell-best-practices breaking-change

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | # (apres gh issue create) |
| Statut | DRAFT |
| Branche | feature/REFACTOR-004-switch-parameters-best-practices |
