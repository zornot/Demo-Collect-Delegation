# Module ConsoleUI

Module d'affichage console avec alignement dynamique des bordures.

## Installation

```powershell
Import-Module "$PSScriptRoot\Modules\ConsoleUI\ConsoleUI.psd1"
```

## Usage

```powershell
# Banniere
Write-ConsoleBanner -Title "MON APP" -Version "1.0.0"

# Resume
Write-SummaryBox -Total 100 -Success 95 -Errors 5

# Menu
Write-MenuBox -Title "MENU" -Options @(@{Key='A'; Text='Action'})
```

## Conventions

- Box drawing Unicode : `┌─┐│└─┘`
- Icones : `[+]` Green | `[-]` Red | `[!]` Yellow | `[i]` Cyan | `[>]` White
- Indentation 2 espaces
- Jamais emoji
