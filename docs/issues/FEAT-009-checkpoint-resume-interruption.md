# [~] [FEAT-009] Gestion reprise apres interruption (module generique) - Effort: 4h

## PROBLEME
Sur un tenant avec beaucoup de mailboxes, une interruption (Ctrl+C, timeout, erreur reseau)
oblige a relancer la collecte depuis le debut. Aucun mecanisme de checkpoint/resume n'existe.
Le script actuel ne sauvegarde pas l'etat de progression.

## LOCALISATION
- Fichier : Get-ExchangeDelegation.ps1:744-809
- Fonction : Boucle foreach ($mailbox in $allMailboxes)
- Config : Config/Settings.json (a etendre)

## OBJECTIF
Creer un module Checkpoint **generique et reutilisable** permettant :
- Configuration via Settings.json (KeyProperty configurable)
- Sauvegarde periodique d'un checkpoint JSON
- Detection et reprise automatique au demarrage
- Skip des elements deja traites via HashSet O(1)
- Reutilisation dans d'autres scripts (Export-UserLicenses, etc.)

---

## DESIGN : MODULE GENERIQUE

### Principe de la cle configurable

Le module ne connait pas le type d'objet traite. La propriete cle est specifiee
dans la configuration, permettant la reutilisation :

| Script | KeyProperty | Exemple valeur |
|--------|-------------|----------------|
| Get-ExchangeDelegation | ExchangeGuid | "a1b2c3d4-..." |
| Export-UserLicenses | UserPrincipalName | "user@domain.com" |
| Collect-TeamsChannels | Id | "19:abc123..." |

---

## IMPLEMENTATION

### Etape 1 : Extension Settings.json - 15min

Fichier : Config/Settings.example.json

```json
{
    "_comment": "Copier vers Settings.json et adapter",
    "_version": "1.1.0",

    "Application": {
        "Name": "Get-ExchangeDelegation",
        "Environment": "PROD",
        "LogLevel": "Info"
    },

    "Paths": {
        "Logs": "./Logs",
        "Output": "./Output",
        "Checkpoints": "./Checkpoints"
    },

    "Retention": {
        "LogDays": 30,
        "OutputDays": 7,
        "CheckpointHours": 24
    },

    "Checkpoint": {
        "Enabled": true,
        "Interval": 50,
        "KeyProperty": "ExchangeGuid"
    }
}
```

### Etape 2 : Module Checkpoint generique - 2h

Fichier : Modules/Checkpoint/Checkpoint.psm1 (~200 lignes)

```powershell
<#
.SYNOPSIS
    Module de checkpoint generique pour reprise apres interruption.
.DESCRIPTION
    Permet la sauvegarde et restauration d'etat pour tout script de collecte.
    La cle d'identification est configurable via KeyProperty.
#>

#region State
$script:CheckpointState = $null
#endregion

function Initialize-Checkpoint {
    <#
    .SYNOPSIS
        Initialise ou restaure un checkpoint.
    .PARAMETER Config
        Configuration checkpoint depuis Settings.json
    .PARAMETER SessionId
        Identifiant unique de session (ex: nom du CSV)
    .PARAMETER TotalItems
        Nombre total d'elements a traiter
    .OUTPUTS
        [hashtable] Etat du checkpoint (nouveau ou restaure)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter(Mandatory)]
        [string]$SessionId,

        [Parameter(Mandatory)]
        [int]$TotalItems,

        [Parameter(Mandatory)]
        [string]$CheckpointPath,

        [Parameter()]
        [string]$CsvPath
    )

    $script:CheckpointState = @{
        SessionId       = $SessionId
        KeyProperty     = $Config.KeyProperty
        Interval        = $Config.Interval
        MaxAgeHours     = $Config.MaxAgeHours ?? 24
        CheckpointFile  = Join-Path $CheckpointPath "$SessionId.checkpoint.json"
        CsvPath         = $CsvPath
        TotalItems      = $TotalItems
        StartIndex      = 0
        ProcessedKeys   = [System.Collections.Generic.HashSet[string]]::new()
        LastSaveIndex   = 0
        IsResume        = $false
    }

    # Chercher checkpoint existant
    $existing = Get-ExistingCheckpoint
    if ($existing) {
        $script:CheckpointState.StartIndex = $existing.LastProcessedIndex
        $script:CheckpointState.ProcessedKeys = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]$existing.ProcessedKeys
        )
        $script:CheckpointState.IsResume = $true
    }

    return $script:CheckpointState
}

function Get-ExistingCheckpoint {
    <#
    .SYNOPSIS
        Recherche et valide un checkpoint existant.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $file = $script:CheckpointState.CheckpointFile
    if (-not (Test-Path $file)) { return $null }

    try {
        $data = Get-Content $file -Raw | ConvertFrom-Json -AsHashtable

        # Validation age
        $age = (Get-Date) - [datetime]$data.Timestamp
        if ($age.TotalHours -gt $script:CheckpointState.MaxAgeHours) {
            Write-Verbose "Checkpoint expire ($([int]$age.TotalHours)h > $($script:CheckpointState.MaxAgeHours)h)"
            Remove-Item $file -Force
            return $null
        }

        # Validation structure
        if (-not $data.ProcessedKeys -or -not $data.LastProcessedIndex) {
            Write-Verbose "Checkpoint invalide (structure)"
            Remove-Item $file -Force
            return $null
        }

        # Validation CSV associe
        if ($data.CsvPath -and -not (Test-Path $data.CsvPath)) {
            Write-Verbose "Checkpoint invalide (CSV manquant)"
            Remove-Item $file -Force
            return $null
        }

        return $data
    }
    catch {
        Write-Verbose "Checkpoint corrompu: $_"
        Remove-Item $file -Force -ErrorAction SilentlyContinue
        return $null
    }
}

function Test-AlreadyProcessed {
    <#
    .SYNOPSIS
        Verifie si un element a deja ete traite.
    .PARAMETER InputObject
        L'objet a verifier
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject
    )

    $keyProp = $script:CheckpointState.KeyProperty
    $keyValue = $InputObject.$keyProp

    if ([string]::IsNullOrEmpty($keyValue)) {
        Write-Warning "Propriete '$keyProp' vide ou absente sur l'objet"
        return $false
    }

    return $script:CheckpointState.ProcessedKeys.Contains($keyValue.ToString())
}

function Add-ProcessedItem {
    <#
    .SYNOPSIS
        Marque un element comme traite.
    .PARAMETER InputObject
        L'objet traite
    .PARAMETER Index
        Index courant dans la boucle
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [int]$Index
    )

    $keyProp = $script:CheckpointState.KeyProperty
    $keyValue = $InputObject.$keyProp.ToString()

    [void]$script:CheckpointState.ProcessedKeys.Add($keyValue)

    # Sauvegarde periodique
    if (($Index - $script:CheckpointState.LastSaveIndex) -ge $script:CheckpointState.Interval) {
        Save-CheckpointAtomic -LastProcessedIndex $Index
        $script:CheckpointState.LastSaveIndex = $Index
    }
}

function Save-CheckpointAtomic {
    <#
    .SYNOPSIS
        Sauvegarde atomique du checkpoint (temp -> validate -> move).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$LastProcessedIndex,

        [Parameter()]
        [switch]$Force
    )

    $state = $script:CheckpointState
    $tempFile = "$($state.CheckpointFile).tmp"

    $data = @{
        Version            = "1.0"
        SessionId          = $state.SessionId
        KeyProperty        = $state.KeyProperty
        LastProcessedIndex = $LastProcessedIndex
        TotalItems         = $state.TotalItems
        ProcessedKeys      = @($state.ProcessedKeys)
        ProcessedCount     = $state.ProcessedKeys.Count
        CsvPath            = $state.CsvPath
        Timestamp          = (Get-Date).ToString('o')
        ComputerName       = $env:COMPUTERNAME
    }

    try {
        # 1. Ecrire dans fichier temp
        $json = $data | ConvertTo-Json -Depth 5
        [System.IO.File]::WriteAllText($tempFile, $json)

        # 2. Valider JSON
        $null = Get-Content $tempFile -Raw | ConvertFrom-Json

        # 3. Move atomique
        Move-Item -Path $tempFile -Destination $state.CheckpointFile -Force

        Write-Verbose "Checkpoint sauvegarde: index $LastProcessedIndex, $($state.ProcessedKeys.Count) traites"
    }
    catch {
        Write-Warning "Echec sauvegarde checkpoint: $_"
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    }
}

function Complete-Checkpoint {
    <#
    .SYNOPSIS
        Finalise et supprime le checkpoint (collecte terminee).
    #>
    [CmdletBinding()]
    param()

    $file = $script:CheckpointState.CheckpointFile
    if (Test-Path $file) {
        Remove-Item $file -Force
        Write-Verbose "Checkpoint supprime (collecte terminee)"
    }

    $script:CheckpointState = $null
}

Export-ModuleMember -Function @(
    'Initialize-Checkpoint'
    'Test-AlreadyProcessed'
    'Add-ProcessedItem'
    'Save-CheckpointAtomic'
    'Complete-Checkpoint'
)
```

### Etape 3 : Integration script principal - 1h30

Fichier : Get-ExchangeDelegation.ps1

**Nouveaux parametres :**
```powershell
[CmdletBinding()]
param(
    # ... parametres existants ...

    [Parameter()]
    [switch]$NoResume  # Force nouvelle collecte (ignore checkpoint)
)
```

**Import module :**
```powershell
Import-Module "$PSScriptRoot\Modules\Checkpoint\Checkpoint.psm1" -Force
```

**Avant la boucle (L:730) :**
```powershell
# Initialiser checkpoint si active
$checkpointEnabled = $script:Config.Checkpoint.Enabled -and -not $NoResume
$checkpointState = $null

if ($checkpointEnabled) {
    $sessionId = "ExchangeDelegations_$(Get-Date -Format 'yyyy-MM-dd')"
    $checkpointPath = Join-Path $PSScriptRoot $script:Config.Paths.Checkpoints

    # Creer dossier si necessaire
    if (-not (Test-Path $checkpointPath)) {
        New-Item -Path $checkpointPath -ItemType Directory -Force | Out-Null
    }

    $checkpointState = Initialize-Checkpoint `
        -Config $script:Config.Checkpoint `
        -SessionId $sessionId `
        -TotalItems $allMailboxes.Count `
        -CheckpointPath $checkpointPath `
        -CsvPath $exportFilePath

    if ($checkpointState.IsResume) {
        Write-Status -Type Info -Message "Reprise checkpoint: $($checkpointState.ProcessedKeys.Count) deja traites" -Indent 1
    }
}
```

**Boucle modifiee (L:744) :**
```powershell
$startIndex = if ($checkpointState) { $checkpointState.StartIndex } else { 0 }

try {
    for ($i = $startIndex; $i -lt $allMailboxes.Count; $i++) {
        $mailbox = $allMailboxes[$i]

        # Skip si deja traite (checkpoint)
        if ($checkpointState -and (Test-AlreadyProcessed -InputObject $mailbox)) {
            continue
        }

        # Progression
        if ($i % 10 -eq 0 -or $i -eq ($allMailboxes.Count - 1)) {
            $percent = [math]::Round(($i / $allMailboxes.Count) * 100)
            Write-Status -Type Action -Message "Analyse mailboxes : $i/$($allMailboxes.Count) ($percent%)" -Indent 1
        }

        # ... traitement existant (FullAccess, SendAs, etc.) ...

        # Marquer comme traite + checkpoint periodique
        if ($checkpointState) {
            Add-ProcessedItem -InputObject $mailbox -Index $i
        }
    }

    # Collecte terminee avec succes - supprimer checkpoint
    if ($checkpointState) {
        Complete-Checkpoint
    }
}
finally {
    # Checkpoint de securite si interruption
    if ($checkpointState -and $i -lt $allMailboxes.Count) {
        Save-CheckpointAtomic -LastProcessedIndex $i -Force
        Write-Status -Type Warning -Message "Interruption - checkpoint sauvegarde (index $i)"
    }
}
```

### Etape 4 : Mise a jour Get-ScriptConfiguration - 15min

Ajouter valeurs par defaut pour Checkpoint :

```powershell
# Dans la fonction Get-ScriptConfiguration
$defaultConfig = @{
    # ... existant ...
    Paths = @{
        Logs = "./Logs"
        Output = "./Output"
        Checkpoints = "./Checkpoints"
    }
    Checkpoint = @{
        Enabled = $true
        Interval = 50
        KeyProperty = "ExchangeGuid"
        MaxAgeHours = 24
    }
}
```

---

## STRUCTURE CHECKPOINT JSON

```json
{
  "Version": "1.0",
  "SessionId": "ExchangeDelegations_2025-12-15",
  "KeyProperty": "ExchangeGuid",
  "LastProcessedIndex": 150,
  "TotalItems": 500,
  "ProcessedKeys": ["guid1", "guid2", "..."],
  "ProcessedCount": 150,
  "CsvPath": "D:\\Output\\ExchangeDelegations_2025-12-15_163000.csv",
  "Timestamp": "2025-12-15T16:45:00.000+01:00",
  "ComputerName": "YOURPC"
}
```

---

## REUTILISATION DANS AUTRES SCRIPTS

### Exemple : Export-UserLicenses.ps1

```json
// Config/Settings.json
{
    "Checkpoint": {
        "Enabled": true,
        "Interval": 100,
        "KeyProperty": "UserPrincipalName"
    }
}
```

```powershell
$checkpointState = Initialize-Checkpoint `
    -Config $Config.Checkpoint `
    -SessionId "UserLicenses_$(Get-Date -Format 'yyyy-MM-dd')" `
    -TotalItems $allUsers.Count `
    -CheckpointPath "./Checkpoints"

foreach ($user in $allUsers) {
    if (Test-AlreadyProcessed -InputObject $user) { continue }
    # ... traitement ...
    Add-ProcessedItem -InputObject $user -Index $i
}
```

---

## VALIDATION

### Criteres d'Acceptation
- [ ] Module generique fonctionne avec KeyProperty configurable
- [ ] Config Checkpoint dans Settings.json
- [ ] Checkpoint sauvegarde selon intervalle configure
- [ ] Reprise automatique si checkpoint valide < 24h
- [ ] CSV reutilise en mode append (pas de header duplique)
- [ ] -NoResume force nouvelle collecte
- [ ] Finally sauvegarde checkpoint sur Ctrl+C
- [ ] Complete-Checkpoint supprime fichier a la fin
- [ ] Pas de regression sur collecte normale

### Tests Manuels
```powershell
# Test 1: Interruption manuelle
.\Get-ExchangeDelegation.ps1  # Ctrl+C apres 30 mailboxes
.\Get-ExchangeDelegation.ps1  # Doit reprendre a index 30

# Test 2: Force nouvelle collecte
.\Get-ExchangeDelegation.ps1 -NoResume

# Test 3: Checkpoint expire
# Attendre 25h ou modifier Timestamp, doit recommencer

# Test 4: Checkpoint invalide
# Modifier JSON manuellement, doit ignorer et recommencer

# Test 5: Collecte complete
# Verifier que checkpoint est supprime a la fin
```

## CHECKLIST
- [x] Settings.example.json mis a jour
- [x] Module Checkpoint.psm1 cree
- [x] Get-ScriptConfiguration etendu (defaults)
- [x] Integration boucle principale
- [x] Finally block securite
- [x] Parametre -NoResume ajoute
- [x] Dossier Checkpoints dans .gitignore
- [ ] Tests manuels passes
- [ ] Code review

Labels : feature moyenne checkpoint resume generique

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | local |
| Statut | RESOLVED |
| Branche | feature/FEAT-009-checkpoint-resume |
| Commit | 5ead0a8 |

---

## REFERENCE

Architecture simplifiee inspiree de Exchange-Data-Collector :
- Modules/Checkpoint/Checkpoint.ps1:316-605 (Save-CheckpointAtomic)
- Modules/Processing/BatchProcessing.ps1:297-307 (boucle avec skip)
- Modules/Infrastructure/AdvancedHelpers.ps1:99-125 (Should-SkipMailbox)

Differences avec EDC :
- ~200 lignes vs ~1000 lignes (simplifie)
- KeyProperty configurable (generique)
- Pas de gestion Compliance (specifique EDC)
- API 5 fonctions vs 15+ fonctions
