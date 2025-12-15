# [-] FEAT-004 Option pour exporter uniquement les orphelins | Effort: 30min

## PROBLEME

Actuellement le script exporte toutes les delegations dans le CSV. Pour analyser ou nettoyer les orphelins, l'utilisateur doit filtrer manuellement le CSV sur la colonne `IsOrphan`. Une option `-OrphansOnly` permettrait d'exporter uniquement les delegations orphelines.

## LOCALISATION

- Fichier : Get-ExchangeDelegation.ps1:L56-72
- Section : Parametres du script
- Section : Export CSV (~L700)

## OBJECTIF

Ajouter un parametre `-OrphansOnly` qui filtre l'export CSV pour ne contenir que les delegations avec `IsOrphan = $true`.

---

## IMPLEMENTATION

### Etape 1 : Ajouter le parametre OrphansOnly - 5min
Fichier : Get-ExchangeDelegation.ps1:L56-72

AVANT :
```powershell
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeSharedMailbox = $true,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeRoomMailbox = $false,

    [Parameter(Mandatory = $false)]
    [switch]$CleanupOrphans,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)
```

APRES :
```powershell
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeSharedMailbox = $true,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeRoomMailbox = $false,

    [Parameter(Mandatory = $false)]
    [switch]$CleanupOrphans,

    [Parameter(Mandatory = $false)]
    [switch]$OrphansOnly,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)
```

### Etape 2 : Filtrer avant export CSV - 10min
Fichier : Get-ExchangeDelegation.ps1 (section export ~L700)

Avant l'export CSV, appliquer le filtre si `-OrphansOnly` :

```powershell
# Filtrer si OrphansOnly
$exportData = if ($OrphansOnly) {
    $allDelegations | Where-Object { $_.IsOrphan -eq $true }
} else {
    $allDelegations
}

# Export CSV
$exportData | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
```

### Etape 3 : Mettre a jour l'aide du script - 5min
Fichier : Get-ExchangeDelegation.ps1 (section .PARAMETER)

Ajouter :
```powershell
.PARAMETER OrphansOnly
    Exporter uniquement les delegations orphelines (IsOrphan = True).
    Utile pour analyser ou nettoyer les permissions obsoletes.
```

Et un exemple :
```powershell
.EXAMPLE
    .\Get-ExchangeDelegation.ps1 -OrphansOnly
    Exporte uniquement les delegations orphelines dans le CSV.
```

---

## VALIDATION

### Criteres d'Acceptation

- [x] Parametre `-OrphansOnly` disponible
- [x] Avec `-OrphansOnly`, le CSV ne contient que les lignes IsOrphan=True
- [x] Sans `-OrphansOnly`, comportement inchange (toutes les delegations)
- [x] Log indique le nombre de delegations exportees (avec note "orphelins uniquement")
- [x] Aide du script mise a jour

---

## DEPENDANCES

- Bloquee par : FEAT-003 (colonne IsOrphan) - CLOSED
- Bloque : Aucune

## POINTS ATTENTION

- 1 fichier modifie
- ~15 lignes ajoutees
- Risques : Aucun - ajout non breaking

## CHECKLIST

- [x] Code AVANT = code reel verifie
- [x] Tests passent
- [x] Code review

Labels : feat faible export filter

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | # |
| Statut | CLOSED |
| Branche | feature/FEAT-004-export-orphelins-uniquement |
