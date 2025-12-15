# [-] REFACTOR-001-write-status-vers-module - Effort: 20min

## PROBLEME

`Write-Status` est definie directement dans le script au lieu d'etre dans le module ConsoleUI. Cette duplication viole le principe DRY et rend la maintenance difficile. Les autres fonctions UI (Write-Box, Write-ConsoleBanner) sont correctement dans le module.

## LOCALISATION

- Fichier source : Get-ExchangeDelegation.ps1:219-248
- Fichier cible : Modules/ConsoleUI/Modules/ConsoleUI/ConsoleUI.psm1
- Fonction : Write-Status()

## OBJECTIF

Centraliser Write-Status dans ConsoleUI.psm1 avec les parametres `-NoNewline` et `-CarriageReturn` pour la gestion de la progression.

---

## IMPLEMENTATION

### Etape 1 : Ajouter Write-Status au module ConsoleUI - 10min

Fichier : Modules/ConsoleUI/Modules/ConsoleUI/ConsoleUI.psm1

Ajouter avant `#endregion Public Functions` :

```powershell
function Write-Status {
    <#
    .SYNOPSIS
        Affiche un message de statut avec icone bracket coloree.
    .DESCRIPTION
        Affiche des messages console avec icones standardisees :
        [+] Green (Success), [-] Red (Error), [!] Yellow (Warning),
        [i] Cyan (Info), [>] White (Action), [?] DarkGray (WhatIf)
    .PARAMETER Type
        Type de statut : Success, Error, Warning, Info, Action, WhatIf
    .PARAMETER Message
        Message a afficher
    .PARAMETER Indent
        Niveau d'indentation (2 espaces par niveau)
    .PARAMETER NoNewline
        Ne pas ajouter de retour a la ligne
    .PARAMETER CarriageReturn
        Ajouter un retour chariot au debut (pour progression)
    .EXAMPLE
        Write-Status -Type Success -Message "Operation terminee"
    .EXAMPLE
        Write-Status -Type Action -Message "Progression 50%" -Indent 1 -NoNewline -CarriageReturn
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Success', 'Error', 'Warning', 'Info', 'Action', 'WhatIf')]
        [string]$Type,

        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [int]$Indent = 0,

        [Parameter()]
        [switch]$NoNewline,

        [Parameter()]
        [switch]$CarriageReturn
    )

    $statusConfig = switch ($Type) {
        'Success' { @{ Bracket = '[+]'; Color = 'Green' } }
        'Error'   { @{ Bracket = '[-]'; Color = 'Red' } }
        'Warning' { @{ Bracket = '[!]'; Color = 'Yellow' } }
        'Info'    { @{ Bracket = '[i]'; Color = 'Cyan' } }
        'Action'  { @{ Bracket = '[>]'; Color = 'White' } }
        'WhatIf'  { @{ Bracket = '[?]'; Color = 'DarkGray' } }
    }

    $indentSpaces = "  " * $Indent
    $prefix = if ($CarriageReturn) { "`r" } else { "" }
    $output = "$prefix$indentSpaces$($statusConfig.Bracket) $Message"

    if ($NoNewline) {
        Write-Host $output -NoNewline -ForegroundColor $statusConfig.Color
    } else {
        Write-Host "$indentSpaces$($statusConfig.Bracket) " -NoNewline -ForegroundColor $statusConfig.Color
        Write-Host $Message -ForegroundColor $statusConfig.Color
    }
}
```

### Etape 2 : Exporter Write-Status - 2min

Fichier : Modules/ConsoleUI/Modules/ConsoleUI/ConsoleUI.psm1

AVANT :
```powershell
Export-ModuleMember -Function @(
    'Write-ConsoleBanner'
    'Write-SummaryBox'
    ...
)
```

APRES :
```powershell
Export-ModuleMember -Function @(
    'Write-ConsoleBanner'
    'Write-SummaryBox'
    ...
    'Write-Status'
)
```

### Etape 3 : Supprimer Write-Status du script - 5min

Fichier : Get-ExchangeDelegation.ps1

Supprimer les lignes 219-248 (fonction Write-Status complete).

---

## VALIDATION

### Criteres d'Acceptation

- [ ] Write-Status dans ConsoleUI.psm1
- [ ] Write-Status exportee par le module
- [ ] Write-Status supprimee du script
- [ ] Script fonctionne sans erreur
- [ ] Progression affichee correctement

## CHECKLIST

- [ ] Module modifie
- [ ] Export ajoute
- [ ] Script nettoye
- [ ] Test manuel

Labels : refactor faible consoleui dry

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | # (apres gh issue create) |
| Statut | CLOSED |
| Branche | feature/REFACTOR-001-write-status-vers-module |
