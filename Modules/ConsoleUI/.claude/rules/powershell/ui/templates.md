# Templates UI PowerShell

## Template Script avec UI Complète

```powershell
#Requires -Version 7.2

<#
.SYNOPSIS
    Description courte
.DESCRIPTION
    Description détaillée
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "$env:USERPROFILE\Desktop"
)

#region Configuration

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$script:Version = "1.0.0"

# Import module logging
Import-Module "$PSScriptRoot\Modules\Write-Log\Write-Log.psm1"
Initialize-Log -Path "$PSScriptRoot\Logs"

#endregion Configuration

#region UI Functions

function Write-Status {
    param(
        [ValidateSet('Success', 'Error', 'Warning', 'Info', 'Action', 'WhatIf')]
        [string]$Type,
        [string]$Message,
        [int]$Indent = 0
    )
    
    $config = switch ($Type) {
        'Success' { @{ Bracket = '[+]'; Color = 'Green' } }
        'Error'   { @{ Bracket = '[-]'; Color = 'Red' } }
        'Warning' { @{ Bracket = '[!]'; Color = 'Yellow' } }
        'Info'    { @{ Bracket = '[i]'; Color = 'Cyan' } }
        'Action'  { @{ Bracket = '[>]'; Color = 'White' } }
        'WhatIf'  { @{ Bracket = '[?]'; Color = 'DarkGray' } }
    }
    
    $spaces = "  " * $Indent
    Write-Host "$spaces$($config.Bracket) " -NoNewline -ForegroundColor $config.Color
    Write-Host $Message -ForegroundColor $config.Color
}

function Write-Banner {
    param([string]$Title, [string]$Version, [int]$Width = 60)
    
    $innerWidth = $Width - 2
    Write-Host ("┌" + ("─" * $innerWidth) + "┐") -ForegroundColor DarkGray
    
    $titlePadding = $innerWidth - $Title.Length - 2
    Write-Host "│ " -NoNewline -ForegroundColor DarkGray
    Write-Host $Title -NoNewline -ForegroundColor Cyan
    Write-Host (" " * $titlePadding) -NoNewline
    Write-Host "│" -ForegroundColor DarkGray
    
    $verText = "v$Version"
    $verPadding = $innerWidth - $verText.Length - 2
    Write-Host "│ " -NoNewline -ForegroundColor DarkGray
    Write-Host $verText -NoNewline -ForegroundColor DarkGray
    Write-Host (" " * $verPadding) -NoNewline
    Write-Host "│" -ForegroundColor DarkGray
    
    Write-Host ("└" + ("─" * $innerWidth) + "┘") -ForegroundColor DarkGray
}

# Write-Log fourni par le module Write-Log.psm1

#endregion UI Functions

#region Main

try {
    Write-Banner -Title "MON SCRIPT" -Version $script:Version
    Write-Log "Script démarré"
    
    Write-Status -Type Info -Message "Initialisation..."
    
    # === VOTRE CODE ICI ===
    
    Write-Status -Type Action -Message "Traitement en cours" -Indent 1
    
    # Exemple boucle avec progression
    $items = 1..100
    $itemIndex = 0
    foreach ($item in $items) {
        $itemIndex++
        if ($itemIndex % 10 -eq 0) {
            $percent = [math]::Round(($itemIndex / $items.Count) * 100)
            Write-Host "`r    [>] Progression: $itemIndex/$($items.Count) ($percent%)" -NoNewline
        }
        Start-Sleep -Milliseconds 10
    }
    Write-Host ""
    
    Write-Status -Type Success -Message "Traitement terminé" -Indent 1
    Write-Status -Type Success -Message "Script terminé avec succès"
    Write-Log "Script terminé" -Level SUCCESS
    
    exit 0
    
} catch {
    Write-Status -Type Error -Message "Erreur: $($_.Exception.Message)"
    Write-Log "Erreur: $($_.Exception.Message)" -Level ERROR
    throw
}

#endregion Main
```

## Template avec Résumé Final

```powershell
#region Counters
$script:Stats = @{
    Success  = 0
    Errors   = 0
    Warnings = 0
    Skipped  = 0
}
#endregion

#region Processing
foreach ($item in $items) {
    try {
        # Traitement
        $script:Stats.Success++
        Write-Status -Type Success -Message "Traité: $($item.Name)" -Indent 2
    }
    catch {
        $script:Stats.Errors++
        Write-Status -Type Error -Message "Échec: $($item.Name)" -Indent 2
    }
}
#endregion

#region Summary
Write-Host ""
Write-Host "  ┌─────────────────────────────┐" -ForegroundColor DarkGray
Write-Host "  │  RÉSUMÉ                     │" -ForegroundColor DarkGray
Write-Host "  ├─────────────────────────────┤" -ForegroundColor DarkGray
Write-Host "  │  [+] Succès   : " -NoNewline -ForegroundColor DarkGray
Write-Host ("{0,-10}" -f $script:Stats.Success) -NoNewline -ForegroundColor Green
Write-Host "│" -ForegroundColor DarkGray
Write-Host "  │  [-] Erreurs  : " -NoNewline -ForegroundColor DarkGray
Write-Host ("{0,-10}" -f $script:Stats.Errors) -NoNewline -ForegroundColor Red
Write-Host "│" -ForegroundColor DarkGray
Write-Host "  │  [!] Warnings : " -NoNewline -ForegroundColor DarkGray
Write-Host ("{0,-10}" -f $script:Stats.Warnings) -NoNewline -ForegroundColor Yellow
Write-Host "│" -ForegroundColor DarkGray
Write-Host "  └─────────────────────────────┘" -ForegroundColor DarkGray
#endregion
```

## Template WhatIf Support

```powershell
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$WhatIf
)

foreach ($file in $files) {
    if ($PSCmdlet.ShouldProcess($file.Name, "Supprimer")) {
        Remove-Item -Path $file.FullName -Force
        Write-Status -Type Success -Message "Supprimé: $($file.Name)" -Indent 1
    } else {
        Write-Status -Type WhatIf -Message "Supprimerait: $($file.Name)" -Indent 1
    }
}
```

## Template Try-Catch avec UI

```powershell
function Invoke-SafeOperation {
    param(
        [string]$OperationName,
        [scriptblock]$ScriptBlock
    )
    
    Write-Status -Type Action -Message $OperationName
    
    try {
        $result = & $ScriptBlock
        Write-Status -Type Success -Message "$OperationName - OK" -Indent 1
        return $result
    }
    catch [System.IO.FileNotFoundException] {
        Write-Status -Type Error -Message "Fichier non trouvé" -Indent 1
        Write-Log "FileNotFound: $($_.Exception.Message)" -Level ERROR
        throw
    }
    catch [System.UnauthorizedAccessException] {
        Write-Status -Type Error -Message "Accès refusé" -Indent 1
        Write-Log "AccessDenied: $($_.Exception.Message)" -Level ERROR
        throw
    }
    catch {
        Write-Status -Type Error -Message "Erreur inattendue: $($_.Exception.Message)" -Indent 1
        Write-Log "Error: $($_.Exception.Message)" -Level ERROR
        throw
    }
}

# Usage
$config = Invoke-SafeOperation -OperationName "Chargement configuration" -ScriptBlock {
    Get-Content ".\config.json" | ConvertFrom-Json
}
```

## Patterns Rapides

### Message simple
```powershell
Write-Host "[+] " -NoNewline -ForegroundColor Green; Write-Host "Terminé"
Write-Host "[-] " -NoNewline -ForegroundColor Red; Write-Host "Échec"
Write-Host "[!] " -NoNewline -ForegroundColor Yellow; Write-Host "Attention"
Write-Host "[i] " -NoNewline -ForegroundColor Cyan; Write-Host "Info"
Write-Host "[>] " -NoNewline -ForegroundColor White; Write-Host "En cours"
Write-Host "[?] " -NoNewline -ForegroundColor DarkGray; Write-Host "Preview"
```

### Avec indentation
```powershell
Write-Host "  [>] Section principale" -ForegroundColor White
Write-Host "    [+] Sous-tâche 1 OK" -ForegroundColor Green
Write-Host "    [+] Sous-tâche 2 OK" -ForegroundColor Green
Write-Host "    [-] Sous-tâche 3 ÉCHEC" -ForegroundColor Red
```

### Log + Console
```powershell
function Write-StatusLog {
    param($Type, $Message)
    Write-Status -Type $Type -Message $Message
    Write-Log -Message $Message -Level $Type.ToUpper()
}

Write-StatusLog -Type Success -Message "Opération terminée"
```
