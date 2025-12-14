<#
.SYNOPSIS
    Module de logging centralise au format ISO 8601.

.DESCRIPTION
    Fournit une fonction de logging standard compatible SIEM (Splunk, ELK, Azure Sentinel).
    Format : yyyy-MM-ddTHH:mm:ss.fffzzz | LEVEL | HOSTNAME | SCRIPT | PID:xxxxx | Message

    STANDARDS APPLIQUES :
    - RFC 5424 : Syslog Protocol (niveaux de severite)
    - ISO 8601 : Format timestamp avec timezone
    - RFC 3339 : Date-time Internet
    - UTF-8    : Encodage caracteres

    NIVEAUX DE LOG :
    - DEBUG   : Informations de debogage (gris)
    - INFO    : Informations generales (blanc)
    - SUCCESS : Operations reussies (vert)
    - WARNING : Avertissements (jaune)
    - ERROR   : Erreurs recuperables (rouge)
    - FATAL   : Erreurs critiques (magenta)

    COMPATIBILITE SIEM :
    - Splunk : props.conf avec TIME_FORMAT = %Y-%m-%dT%H:%M:%S.%3N%:z
    - ELK    : grok pattern TIMESTAMP_ISO8601
    - Azure Sentinel : parse KQL avec datetime
    - Graylog : REGEX extractor standard

    REGEX DE PARSING :
    ^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}[+-]\d{2}:\d{2})\s*\|\s*
    (DEBUG|INFO|SUCCESS|WARNING|ERROR|FATAL)\s*\|\s*([^\|]+)\s*\|\s*
    ([^\|]+)\s*\|\s*(PID:\d+)\s*\|\s*(.*)$

    PERFORMANCE :
    Appeler Initialize-Log au demarrage du script pour des performances optimales.
    Sans Initialize-Log, Get-PSCallStack est appele a chaque Write-Log (~30x plus lent).

    Exemple :
        Initialize-Log -Path ".\Logs"
        Write-Log "Message"  # Utilise les variables initialisees

.NOTES
    Module      : Write-Log.psm1
    Version     : 2.0
    Date        : 2025-12-02

    DOCUMENT DE REFERENCE :
    Voir Audit/STANDARD-LOGGING-RFC5424-ISO8601.md pour la specification complete.

    COPIE ISOLEE :
    Ce fichier est une copie de reference du module de production.
    Module actif : Common/Modules/Write-Log.psm1
#>

#region Private Functions

function Get-CallerScriptName {
    <#
    .SYNOPSIS
        Detecte automatiquement le nom du script appelant via la call stack.
    .DESCRIPTION
        Fonction privee utilisee par Write-Log et Initialize-Log pour determiner
        le nom du script qui appelle les fonctions de logging.
    .PARAMETER ExcludeCurrentScript
        Exclut le script courant (PSCommandPath) de la recherche.
        Utilise par Write-Log pour eviter de retourner le module lui-meme.
    .OUTPUTS
        [string] Nom du script sans extension, ou "PowerShell" si non detecte.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [switch]$ExcludeCurrentScript
    )

    $callStack = Get-PSCallStack

    $filter = if ($ExcludeCurrentScript) {
        { $_.ScriptName -and $_.ScriptName -ne $PSCommandPath }
    } else {
        { $_.ScriptName }
    }

    $caller = $callStack | Where-Object $filter | Select-Object -First 1

    if ($caller -and $caller.ScriptName) {
        return [System.IO.Path]::GetFileNameWithoutExtension($caller.ScriptName)
    }
    return "PowerShell"
}

#endregion Private Functions

#region Public Functions

function Write-Log {
    <#
    .SYNOPSIS
        Ecrit un message de log au format standard ISO 8601.

    .DESCRIPTION
        Format: yyyy-MM-ddTHH:mm:ss.fff+zz:zz | LEVEL   | HOSTNAME | SCRIPT | PID:xxxxx | Message
        Compatible SIEM (Splunk, ELK) et lisible par humain.

    .PARAMETER Message
        Le message a logger.

    .PARAMETER Level
        Niveau de severite : DEBUG, INFO, SUCCESS, WARNING, ERROR, FATAL

    .PARAMETER NoConsole
        Si specifie, n'affiche pas le message dans la console.

    .PARAMETER LogFile
        Chemin du fichier de log. Si non specifie, utilise $Script:LogFile.

    .PARAMETER ScriptName
        Nom du script appelant. Si non specifie, utilise $Script:ScriptName.

    .EXAMPLE
        Write-Log "Demarrage du script" -Level INFO

    .EXAMPLE
        Write-Log "Erreur critique" -Level FATAL -LogFile "C:\Logs\app.log"

    .NOTES
        PERFORMANCE : Appeler Initialize-Log au demarrage du script.
        Sans cela, Get-PSCallStack est appele a chaque Write-Log (~30x plus lent).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Message,

        [Parameter(Position = 1)]
        [ValidateSet("DEBUG", "INFO", "SUCCESS", "WARNING", "ERROR", "FATAL")]
        [string]$Level = "INFO",

        [switch]$NoConsole,

        [Parameter()]
        [string]$LogFile,

        [Parameter()]
        [string]$ScriptName
    )

    # Utiliser les variables du script appelant si non specifiees
    if ([string]::IsNullOrEmpty($LogFile)) {
        $LogFile = $Script:LogFile
        if ([string]::IsNullOrEmpty($LogFile)) {
            # Fallback: variable globale ou chemin par defaut
            $LogFile = if ($Global:LogFile) { $Global:LogFile } else { "$env:TEMP\PowerShell_$(Get-Date -Format 'yyyy-MM-dd').log" }
        }
    }

    if ([string]::IsNullOrEmpty($ScriptName)) {
        $ScriptName = $Script:ScriptName
        if ([string]::IsNullOrEmpty($ScriptName)) {
            $ScriptName = $Global:ScriptName
        }
        if ([string]::IsNullOrEmpty($ScriptName)) {
            # Detection automatique via call stack
            $ScriptName = Get-CallerScriptName -ExcludeCurrentScript
        }
    }

    # Timestamp ISO 8601 avec timezone (RFC 3339 compatible)
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffzzz"

    # Format standard : TIMESTAMP | LEVEL | HOST | SCRIPT | PID | MESSAGE
    # Padding niveau a 7 caracteres pour alignement
    $logEntry = "$timestamp | $($Level.PadRight(7)) | $($env:COMPUTERNAME) | $ScriptName | PID:$PID | $Message"

    # Couleur selon le niveau (correspondance RFC 5424)
    $color = switch ($Level) {
        "DEBUG"   { "Gray" }      # Severity 7
        "INFO"    { "White" }     # Severity 6
        "SUCCESS" { "Green" }     # Severity 5 (Notice)
        "WARNING" { "Yellow" }    # Severity 4
        "ERROR"   { "Red" }       # Severity 3
        "FATAL"   { "Magenta" }   # Severity 0-2
        default   { "White" }
    }

    # Affichage console
    if (-not $NoConsole) {
        Write-Host $logEntry -ForegroundColor $color
    }

    # Ecriture fichier avec gestion d'erreur
    if (-not [string]::IsNullOrEmpty($LogFile)) {
        try {
            # S'assurer que le dossier existe
            $logDir = Split-Path $LogFile -Parent
            if (-not [string]::IsNullOrEmpty($logDir) -and -not (Test-Path $logDir)) {
                New-Item -Path $logDir -ItemType Directory -Force | Out-Null
            }
            # UTF-8 encoding sans BOM pour compatibilite SIEM
            Add-Content -Path $LogFile -Value $logEntry -Encoding UTF8 -ErrorAction Stop
        } catch {
            Write-Host "[!] Impossible d'ecrire dans le log : $_" -ForegroundColor Red
        }
    }
}

function Initialize-Log {
    <#
    .SYNOPSIS
        Initialise le logging pour le script courant.
    .DESCRIPTION
        Configure $Script:LogFile et $Script:ScriptName automatiquement.
        Cree le dossier de logs si inexistant.
    .PARAMETER Path
        Chemin du dossier de logs. Defaut: .\Logs
    .PARAMETER ScriptName
        Nom du script. Si non specifie, detecte automatiquement.
    .EXAMPLE
        Initialize-Log -Path ".\Logs"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = ".\Logs",

        [Parameter()]
        [string]$ScriptName
    )

    # Detection auto du nom de script
    if ([string]::IsNullOrEmpty($ScriptName)) {
        $ScriptName = Get-CallerScriptName
    }

    # Construire le chemin du fichier log
    $logFileName = "{0}_{1}.log" -f $ScriptName, (Get-Date -Format 'yyyy-MM-dd')
    $logFilePath = Join-Path -Path $Path -ChildPath $logFileName

    # Creer le dossier si inexistant
    if (-not (Test-Path $Path)) {
        try {
            New-Item -Path $Path -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }
        catch {
            throw "Impossible de creer le dossier de logs '$Path': $($_.Exception.Message)"
        }
    }

    # Definir les variables dans le scope appelant
    Set-Variable -Name 'LogFile' -Value $logFilePath -Scope Script
    Set-Variable -Name 'ScriptName' -Value $ScriptName -Scope Script

    # Aussi dans le scope global pour compatibilite
    $Global:LogFile = $logFilePath
    $Global:ScriptName = $ScriptName

    Write-Verbose "Log initialise: $logFilePath"
}

function Invoke-LogRotation {
    <#
    .SYNOPSIS
        Supprime les fichiers de logs plus anciens que la retention specifiee.
    .DESCRIPTION
        Nettoie les fichiers .log dans le dossier specifie selon leur date de modification.
        Supporte -WhatIf pour previsualiser les suppressions.
    .PARAMETER Path
        Chemin du dossier de logs a nettoyer.
    .PARAMETER RetentionDays
        Nombre de jours de retention. Les fichiers plus anciens seront supprimes. Defaut: 30
    .PARAMETER Filter
        Filtre des fichiers a traiter. Defaut: *.log
    .EXAMPLE
        Invoke-LogRotation -Path ".\Logs" -RetentionDays 30
    .EXAMPLE
        Invoke-LogRotation -Path ".\Logs" -RetentionDays 7 -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$Path,

        [Parameter(Position = 1)]
        [ValidateRange(1, 365)]
        [int]$RetentionDays = 30,

        [Parameter()]
        [string]$Filter = "*.log"
    )

    $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
    $deletedCount = 0
    $deletedSize = 0

    $oldFiles = Get-ChildItem -Path $Path -Filter $Filter -File |
        Where-Object { $_.LastWriteTime -lt $cutoffDate }

    if (-not $oldFiles) {
        Write-Verbose "Aucun fichier a supprimer (retention: $RetentionDays jours)"
        return
    }

    foreach ($file in $oldFiles) {
        if ($PSCmdlet.ShouldProcess($file.FullName, "Supprimer (age: $([int]((Get-Date) - $file.LastWriteTime).TotalDays) jours)")) {
            try {
                $fileSize = $file.Length
                Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                $deletedCount++
                $deletedSize += $fileSize
            }
            catch {
                Write-Warning "Impossible de supprimer $($file.Name): $_"
            }
        }
    }

    if ($deletedCount -gt 0 -and -not $WhatIfPreference) {
        $sizeInMB = [math]::Round($deletedSize / 1MB, 2)
        Write-Verbose "$deletedCount fichier(s) supprime(s), $sizeInMB MB libere(s)"
    }
}

#endregion Public Functions

# Exporter les fonctions publiques (Get-CallerScriptName reste privee)
Export-ModuleMember -Function Write-Log, Initialize-Log, Invoke-LogRotation
