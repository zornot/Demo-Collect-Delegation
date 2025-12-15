#Requires -Version 7.2

<#
.SYNOPSIS
    Module de checkpoint generique pour reprise apres interruption.

.DESCRIPTION
    Permet la sauvegarde et restauration d'etat pour tout script de collecte.
    La cle d'identification est configurable via KeyProperty, permettant
    la reutilisation avec differents types d'objets.

    FONCTIONNALITES :
    - Sauvegarde atomique (temp -> validate -> move)
    - HashSet pour performance O(1) sur les lookups
    - Validation age et structure du checkpoint
    - Nettoyage automatique des checkpoints expires

    UTILISATION :
    1. Initialize-Checkpoint au demarrage
    2. Test-AlreadyProcessed dans la boucle (skip si deja traite)
    3. Add-ProcessedItem apres traitement (+ checkpoint periodique)
    4. Complete-Checkpoint a la fin (supprime le fichier)

.NOTES
    Module   : Checkpoint.psm1
    Version  : 1.0.0
    Date     : 2025-12-15
#>

#region Module State
#===============================================================================
#  MODULE STATE
#===============================================================================

$script:CheckpointState = $null

#endregion Module State

#region Private Functions
#===============================================================================
#  PRIVATE FUNCTIONS
#===============================================================================

function Get-ExistingCheckpoint {
    <#
    .SYNOPSIS
        Recherche et valide un checkpoint existant.
    .DESCRIPTION
        Verifie l'existence d'un fichier checkpoint, sa validite structurelle,
        son age et la presence du CSV associe.
    .OUTPUTS
        [hashtable] Donnees du checkpoint valide, ou $null si invalide/absent.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $file = $script:CheckpointState.CheckpointFile
    if (-not (Test-Path $file)) {
        return $null
    }

    try {
        $data = Get-Content $file -Raw -ErrorAction Stop | ConvertFrom-Json -AsHashtable -ErrorAction Stop

        # Validation age
        $timestamp = [datetime]$data.Timestamp
        $age = (Get-Date) - $timestamp
        $maxAge = $script:CheckpointState.MaxAgeHours

        if ($age.TotalHours -gt $maxAge) {
            Write-Verbose "Checkpoint expire ($([int]$age.TotalHours)h > ${maxAge}h)"
            Remove-Item $file -Force -ErrorAction SilentlyContinue
            return $null
        }

        # Validation structure
        if (-not $data.ContainsKey('ProcessedKeys') -or -not $data.ContainsKey('LastProcessedIndex')) {
            Write-Verbose "Checkpoint invalide (structure incomplete)"
            Remove-Item $file -Force -ErrorAction SilentlyContinue
            return $null
        }

        # Validation coherence
        if ($data.LastProcessedIndex -lt 0) {
            Write-Verbose "Checkpoint invalide (index negatif)"
            Remove-Item $file -Force -ErrorAction SilentlyContinue
            return $null
        }

        # Validation CSV associe (si specifie)
        if (-not [string]::IsNullOrEmpty($data.CsvPath) -and -not (Test-Path $data.CsvPath)) {
            Write-Verbose "Checkpoint invalide (CSV manquant: $($data.CsvPath))"
            Remove-Item $file -Force -ErrorAction SilentlyContinue
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

#endregion Private Functions

#region Public Functions
#===============================================================================
#  PUBLIC FUNCTIONS
#===============================================================================

function Initialize-Checkpoint {
    <#
    .SYNOPSIS
        Initialise ou restaure un checkpoint.

    .DESCRIPTION
        Configure l'etat du checkpoint pour la session courante.
        Si un checkpoint valide existe, restaure l'etat precedent.
        Sinon, initialise un nouvel etat vide.

    .PARAMETER Config
        Configuration checkpoint depuis Settings.json.
        Doit contenir: KeyProperty, Interval.
        Optionnel: MaxAgeHours (defaut: 24).

    .PARAMETER SessionId
        Identifiant unique de session (ex: "ExchangeDelegations_2025-12-15").
        Utilise pour nommer le fichier checkpoint.

    .PARAMETER TotalItems
        Nombre total d'elements a traiter.
        Utilise pour calculer la progression.

    .PARAMETER CheckpointPath
        Chemin du dossier contenant les checkpoints.
        Le dossier sera cree s'il n'existe pas.

    .PARAMETER CsvPath
        Chemin du fichier CSV de sortie (optionnel).
        Stocke dans le checkpoint pour validation a la reprise.

    .OUTPUTS
        [hashtable] Etat du checkpoint (nouveau ou restaure).

    .EXAMPLE
        $state = Initialize-Checkpoint -Config $Config.Checkpoint `
            -SessionId "Export_2025-12-15" -TotalItems 500 `
            -CheckpointPath "./Checkpoints"
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SessionId,

        [Parameter(Mandatory)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$TotalItems,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$CheckpointPath,

        [Parameter()]
        [string]$CsvPath
    )

    # Creer dossier si necessaire
    if (-not (Test-Path $CheckpointPath)) {
        New-Item -Path $CheckpointPath -ItemType Directory -Force | Out-Null
    }

    # Initialiser l'etat
    $script:CheckpointState = @{
        SessionId      = $SessionId
        KeyProperty    = $Config.KeyProperty
        Interval       = $Config.Interval
        MaxAgeHours    = if ($Config.ContainsKey('MaxAgeHours')) { $Config.MaxAgeHours } else { 24 }
        CheckpointFile = Join-Path $CheckpointPath "$SessionId.checkpoint.json"
        CsvPath        = $CsvPath
        TotalItems     = $TotalItems
        StartIndex     = 0
        ProcessedKeys  = [System.Collections.Generic.HashSet[string]]::new()
        LastSaveIndex  = 0
        IsResume       = $false
    }

    # Chercher checkpoint existant
    $existing = Get-ExistingCheckpoint
    if ($existing) {
        $script:CheckpointState.StartIndex = $existing.LastProcessedIndex + 1
        $script:CheckpointState.LastSaveIndex = $existing.LastProcessedIndex

        # Hydrater le HashSet
        foreach ($key in $existing.ProcessedKeys) {
            [void]$script:CheckpointState.ProcessedKeys.Add($key)
        }

        $script:CheckpointState.IsResume = $true
        Write-Verbose "Checkpoint restaure: index $($existing.LastProcessedIndex), $($script:CheckpointState.ProcessedKeys.Count) elements traites"
    }

    return $script:CheckpointState
}

function Test-AlreadyProcessed {
    <#
    .SYNOPSIS
        Verifie si un element a deja ete traite.

    .DESCRIPTION
        Extrait la valeur de KeyProperty de l'objet et verifie
        si elle existe dans le HashSet des elements traites.
        Performance O(1) grace au HashSet.

    .PARAMETER InputObject
        L'objet a verifier. Doit avoir la propriete KeyProperty.

    .OUTPUTS
        [bool] $true si deja traite, $false sinon.

    .EXAMPLE
        if (Test-AlreadyProcessed -InputObject $mailbox) { continue }
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject
    )

    if ($null -eq $script:CheckpointState) {
        return $false
    }

    $keyProp = $script:CheckpointState.KeyProperty
    $keyValue = $InputObject.$keyProp

    if ($null -eq $keyValue -or [string]::IsNullOrEmpty($keyValue.ToString())) {
        Write-Warning "Propriete '$keyProp' vide ou absente sur l'objet"
        return $false
    }

    return $script:CheckpointState.ProcessedKeys.Contains($keyValue.ToString())
}

function Add-ProcessedItem {
    <#
    .SYNOPSIS
        Marque un element comme traite.

    .DESCRIPTION
        Ajoute la cle de l'objet au HashSet et declenche
        une sauvegarde checkpoint si l'intervalle est atteint.

    .PARAMETER InputObject
        L'objet traite. Doit avoir la propriete KeyProperty.

    .PARAMETER Index
        Index courant dans la boucle (0-based).
        Utilise pour determiner si un checkpoint est necessaire.

    .EXAMPLE
        Add-ProcessedItem -InputObject $mailbox -Index $i
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Index
    )

    if ($null -eq $script:CheckpointState) {
        return
    }

    $keyProp = $script:CheckpointState.KeyProperty
    $keyValue = $InputObject.$keyProp

    if ($null -ne $keyValue) {
        [void]$script:CheckpointState.ProcessedKeys.Add($keyValue.ToString())
    }

    # Sauvegarde periodique
    $interval = $script:CheckpointState.Interval
    if ($interval -gt 0 -and ($Index - $script:CheckpointState.LastSaveIndex) -ge $interval) {
        Save-CheckpointAtomic -LastProcessedIndex $Index
        $script:CheckpointState.LastSaveIndex = $Index
    }
}

function Save-CheckpointAtomic {
    <#
    .SYNOPSIS
        Sauvegarde atomique du checkpoint.

    .DESCRIPTION
        Ecrit le checkpoint dans un fichier temporaire, valide le JSON,
        puis effectue un Move atomique vers le fichier final.
        Garantit qu'un checkpoint est toujours valide ou absent.

    .PARAMETER LastProcessedIndex
        Index du dernier element traite (0-based).

    .PARAMETER Force
        Force la sauvegarde meme si l'intervalle n'est pas atteint.
        Utiliser dans le bloc finally pour checkpoint de securite.

    .EXAMPLE
        Save-CheckpointAtomic -LastProcessedIndex 150

    .EXAMPLE
        # Dans finally block
        Save-CheckpointAtomic -LastProcessedIndex $i -Force
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$LastProcessedIndex,

        [Parameter()]
        [switch]$Force
    )

    if ($null -eq $script:CheckpointState) {
        return
    }

    $state = $script:CheckpointState
    $tempFile = "$($state.CheckpointFile).tmp.$([guid]::NewGuid().ToString('N').Substring(0,8))"

    $data = [ordered]@{
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
        UserName           = $env:USERNAME
    }

    try {
        # 1. Ecrire dans fichier temp
        $json = $data | ConvertTo-Json -Depth 5 -Compress:$false
        [System.IO.File]::WriteAllText($tempFile, $json, [System.Text.Encoding]::UTF8)

        # 2. Valider JSON ecrit
        $null = Get-Content $tempFile -Raw | ConvertFrom-Json -ErrorAction Stop

        # 3. Move atomique
        Move-Item -Path $tempFile -Destination $state.CheckpointFile -Force -ErrorAction Stop

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
        Finalise et supprime le checkpoint.

    .DESCRIPTION
        Appeler a la fin d'une collecte reussie pour supprimer
        le fichier checkpoint. Une nouvelle execution recommencera
        depuis le debut.

    .EXAMPLE
        # Apres la boucle principale
        Complete-Checkpoint
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()

    if ($null -eq $script:CheckpointState) {
        return
    }

    $file = $script:CheckpointState.CheckpointFile
    if (Test-Path $file) {
        Remove-Item $file -Force -ErrorAction SilentlyContinue
        Write-Verbose "Checkpoint supprime (collecte terminee)"
    }

    $script:CheckpointState = $null
}

function Get-CheckpointState {
    <#
    .SYNOPSIS
        Retourne l'etat actuel du checkpoint.

    .DESCRIPTION
        Fonction utilitaire pour acceder a l'etat du checkpoint
        depuis le script appelant.

    .OUTPUTS
        [hashtable] Etat actuel ou $null si non initialise.

    .EXAMPLE
        $state = Get-CheckpointState
        if ($state.IsResume) { Write-Host "Reprise en cours" }
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return $script:CheckpointState
}

#endregion Public Functions

# Export des fonctions publiques
Export-ModuleMember -Function @(
    'Initialize-Checkpoint'
    'Test-AlreadyProcessed'
    'Add-ProcessedItem'
    'Save-CheckpointAtomic'
    'Complete-Checkpoint'
    'Get-CheckpointState'
)
