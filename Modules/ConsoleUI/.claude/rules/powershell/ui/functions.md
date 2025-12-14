# Fonctions UI PowerShell

> **Note** : Ces fonctions implementent les patterns definis dans `ui-symbols.md`.
> Pour le support NO_COLOR et fallback ASCII, voir `ui-symbols.md`.

## Module Recommande

Pour les projets necessitant une UI console avancee (bannieres, menus, boites de selection),
utiliser le module **Module-ConsoleUI** : https://github.com/zornot/Module-ConsoleUI

```powershell
# Installation
git clone https://github.com/zornot/Module-ConsoleUI.git Modules/ConsoleUI

# Usage
Import-Module "$PSScriptRoot\Modules\ConsoleUI\ConsoleUI.psm1"
Write-ConsoleBanner -Title "MON APPLICATION" -Version "1.0.0"
Write-SummaryBox -Total 100 -Success 95 -Errors 5 -Duration "00:02:30"
```

Les fonctions ci-dessous sont des patterns de base pour les cas simples.

---

## Write-Status (Fonction principale)

```powershell
function Write-Status {
    <#
    .SYNOPSIS
        Affiche un message de status avec bracket coloré
    .PARAMETER Type
        Type de message: Success, Error, Warning, Info, Action, WhatIf
    .PARAMETER Message
        Message à afficher
    .PARAMETER Indent
        Niveau d'indentation (0-3)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Success', 'Error', 'Warning', 'Info', 'Action', 'WhatIf')]
        [string]$Type,
        
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateRange(0, 3)]
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

# Usage
Write-Status -Type Success -Message "Fichier créé"
Write-Status -Type Error -Message "Connexion échouée" -Indent 1
Write-Status -Type Warning -Message "Quota presque atteint" -Indent 2
```

## Write-Banner

```powershell
function Write-Banner {
    <#
    .SYNOPSIS
        Affiche une bannière encadrée
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Title,
        
        [string]$Subtitle,
        
        [string]$Version,
        
        [int]$Width = 60
    )
    
    $innerWidth = $Width - 2
    
    Write-Host ("┌" + ("─" * $innerWidth) + "┐") -ForegroundColor DarkGray
    
    # Titre
    $titlePadding = $innerWidth - $Title.Length - 2
    Write-Host "│ " -NoNewline -ForegroundColor DarkGray
    Write-Host $Title -NoNewline -ForegroundColor Cyan
    Write-Host (" " * $titlePadding) -NoNewline
    Write-Host "│" -ForegroundColor DarkGray
    
    # Sous-titre (optionnel)
    if ($Subtitle) {
        $subPadding = $innerWidth - $Subtitle.Length - 2
        Write-Host "│ " -NoNewline -ForegroundColor DarkGray
        Write-Host $Subtitle -NoNewline -ForegroundColor White
        Write-Host (" " * $subPadding) -NoNewline
        Write-Host "│" -ForegroundColor DarkGray
    }
    
    # Version (optionnel)
    if ($Version) {
        $verText = "v$Version"
        $verPadding = $innerWidth - $verText.Length - 2
        Write-Host "│ " -NoNewline -ForegroundColor DarkGray
        Write-Host $verText -NoNewline -ForegroundColor DarkGray
        Write-Host (" " * $verPadding) -NoNewline
        Write-Host "│" -ForegroundColor DarkGray
    }
    
    Write-Host ("└" + ("─" * $innerWidth) + "┘") -ForegroundColor DarkGray
}

# Usage
Write-Banner -Title "MON SCRIPT" -Version "1.0.0"
Write-Banner -Title "AUDIT EXCHANGE" -Subtitle "Analyse des mailboxes" -Version "2.1.0"
```

## Write-Section

```powershell
function Write-Section {
    <#
    .SYNOPSIS
        Affiche un titre de section
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Title,
        
        [int]$Indent = 0
    )
    
    $spaces = "  " * $Indent
    Write-Host ""
    Write-Host "$spaces[>] " -NoNewline -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "$spaces$("─" * ($Title.Length + 4))" -ForegroundColor DarkGray
}

# Usage
Write-Section -Title "Configuration"
Write-Section -Title "Traitement des données" -Indent 1
```

## Write-Progress-Inline

```powershell
function Write-ProgressInline {
    <#
    .SYNOPSIS
        Affiche une progression inline (même ligne)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$Current,
        
        [Parameter(Mandatory)]
        [int]$Total,
        
        [string]$Activity = "Progression",
        
        [int]$UpdateEvery = 100
    )
    
    if ($Current % $UpdateEvery -eq 0 -or $Current -eq $Total) {
        $percent = [math]::Round(($Current / $Total) * 100)
        Write-Host "`r  [>] $Activity : $Current/$Total ($percent%)" -NoNewline -ForegroundColor White
        
        if ($Current -eq $Total) {
            Write-Host ""  # Nouvelle ligne à la fin
        }
    }
}

# Usage dans une boucle
$items = 1..1000
$itemIndex = 0
foreach ($item in $items) {
    $itemIndex++
    Write-ProgressInline -Current $itemIndex -Total $items.Count -Activity "Traitement"
    # ... traitement
}
```

## Write-ProgressBar

```powershell
function Write-ProgressBar {
    <#
    .SYNOPSIS
        Affiche une barre de progression visuelle
    .NOTES
        Utilise caracteres adaptatifs selon le terminal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$Percent,

        [int]$Width = 40,

        [string]$Label = ""
    )

    # Caracteres adaptatifs (Windows Terminal vs legacy)
    $isModernTerminal = $null -ne $env:WT_SESSION
    $charFilled = if ($isModernTerminal) { '█' } else { '#' }
    $charEmpty = if ($isModernTerminal) { '░' } else { '-' }

    $filled = [math]::Round($Width * $Percent / 100)
    $empty = $Width - $filled

    $bar = ($charFilled * $filled) + ($charEmpty * $empty)

    Write-Host "`r  [>] " -NoNewline -ForegroundColor White
    if ($Label) { Write-Host "$Label " -NoNewline -ForegroundColor DarkGray }
    Write-Host "[$bar] $Percent%" -NoNewline -ForegroundColor Cyan

    if ($Percent -eq 100) { Write-Host "" }
}

# Resultat Windows Terminal : [████████████░░░░░░░░] 60%
# Resultat legacy console  : [############--------] 60%

# Usage
for ($i = 0; $i -le 100; $i += 10) {
    Write-ProgressBar -Percent $i -Label "Telechargement"
    Start-Sleep -Milliseconds 200
}
```

## Write-Result (Résumé final)

```powershell
function Write-Result {
    <#
    .SYNOPSIS
        Affiche un résumé de résultats
    #>
    [CmdletBinding()]
    param(
        [int]$Success = 0,
        [int]$Errors = 0,
        [int]$Warnings = 0,
        [int]$Skipped = 0
    )
    
    Write-Host ""
    Write-Host "  ┌─────────────────────────────┐" -ForegroundColor DarkGray
    Write-Host "  │  RÉSUMÉ                     │" -ForegroundColor DarkGray
    Write-Host "  ├─────────────────────────────┤" -ForegroundColor DarkGray
    
    if ($Success -gt 0) {
        Write-Host "  │  [+] Succès   : " -NoNewline -ForegroundColor DarkGray
        Write-Host ("{0,-10}" -f $Success) -NoNewline -ForegroundColor Green
        Write-Host "│" -ForegroundColor DarkGray
    }
    if ($Errors -gt 0) {
        Write-Host "  │  [-] Erreurs  : " -NoNewline -ForegroundColor DarkGray
        Write-Host ("{0,-10}" -f $Errors) -NoNewline -ForegroundColor Red
        Write-Host "│" -ForegroundColor DarkGray
    }
    if ($Warnings -gt 0) {
        Write-Host "  │  [!] Warnings : " -NoNewline -ForegroundColor DarkGray
        Write-Host ("{0,-10}" -f $Warnings) -NoNewline -ForegroundColor Yellow
        Write-Host "│" -ForegroundColor DarkGray
    }
    if ($Skipped -gt 0) {
        Write-Host "  │  [?] Ignorés  : " -NoNewline -ForegroundColor DarkGray
        Write-Host ("{0,-10}" -f $Skipped) -NoNewline -ForegroundColor DarkGray
        Write-Host "│" -ForegroundColor DarkGray
    }
    
    Write-Host "  └─────────────────────────────┘" -ForegroundColor DarkGray
}

# Usage
Write-Result -Success 145 -Errors 3 -Warnings 12 -Skipped 5
```

## Détection Terminal

```powershell
function Test-WindowsTerminal {
    return $null -ne $env:WT_SESSION
}

function Get-ConsoleWidth {
    try {
        return $Host.UI.RawUI.WindowSize.Width
    } catch {
        return 80  # Défaut
    }
}

# Usage adaptatif
$width = Get-ConsoleWidth
Write-Banner -Title "MON SCRIPT" -Width ([math]::Min($width - 4, 80))
```

## PowerShell 7.2+ : $PSStyle.Progress

PowerShell 7.2+ offre un rendu natif de progression via `$PSStyle` :

```powershell
# Voir le style actuel
$PSStyle.Progress

# Modes disponibles
$PSStyle.Progress.View = 'Minimal'  # Une ligne (defaut PS 7.2+)
$PSStyle.Progress.View = 'Classic'  # Multi-lignes (ancien style)

# Personnaliser les couleurs
$PSStyle.Progress.Style = $PSStyle.Foreground.Cyan

# Usage avec Write-Progress natif
Write-Progress -Activity "Traitement" -Status "En cours" -PercentComplete 50
```

> **Recommandation** : Utiliser `Write-Progress` natif pour les scripts longs,
> les fonctions custom (`Write-ProgressInline`, `Write-ProgressBar`) pour l'UI stylisee.
