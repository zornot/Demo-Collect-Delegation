# ConsoleUI

Module PowerShell d'affichage console avec bannieres, menus et boites alignees dynamiquement.

**Version**: 1.0.0
**Statut**: Production
**Date**: 2025-12-07

---

## Fonctionnalites

- Bannieres avec calcul dynamique du padding
- Boites de resume avec statistiques colorees
- Menus de selection interactifs
- Box Drawing Unicode : `┌─┐│└─┘├┤`
- Icones brackets : `[+] [-] [!] [i] [>] [?]`
- Jamais d'emoji (compatibilite terminaux)

---

## Installation

```powershell
# Cloner le repository
git clone https://github.com/zornot/Module-ConsoleUI.git
```

---

## Integration dans un Projet

### Option 1 : Copie directe (recommande)

```powershell
# Depuis votre projet
Copy-Item -Path "chemin\vers\Module-ConsoleUI\Modules\ConsoleUI" -Destination ".\Modules\" -Recurse
```

Structure resultante :
```
VotreProjet/
├── Modules/
│   └── ConsoleUI/
│       └── ConsoleUI.psm1
├── VotreScript.ps1
└── ...
```

### Option 2 : Git submodule

```powershell
# Ajouter comme submodule
git submodule add https://github.com/zornot/Module-ConsoleUI.git Modules/ConsoleUI

# Apres clone du projet parent
git submodule update --init --recursive
```

### Option 3 : Reference externe

```powershell
# Dans votre script, pointer vers le module externe
$consoleUIPath = "D:\Libs\Module-ConsoleUI\Modules\ConsoleUI\ConsoleUI.psm1"
Import-Module $consoleUIPath -Force
```

---

## Usage dans un Script

```powershell
#Requires -Version 7.2

# Import du module (chemin relatif depuis le script)
Import-Module "$PSScriptRoot\Modules\ConsoleUI\ConsoleUI.psm1" -Force

# Banniere de demarrage
Write-ConsoleBanner -Title "MON SCRIPT" -Version "1.0.0"

# ... votre code ...

# Resume final
Write-SummaryBox -Total $total -Success $success -Errors $errors -Duration $duration
```

---

## Demarrage Rapide

```powershell
Import-Module ".\Modules\ConsoleUI\ConsoleUI.psd1"

# Banniere
Write-ConsoleBanner -Title "MON APPLICATION" -Version "1.0.0"

# Resume
Write-SummaryBox -Total 100 -Success 95 -Errors 5 -Duration "00:05:30"

# Menu
Write-MenuBox -Title "MENU PRINCIPAL" -Options @(
    @{Key='1'; Text='Option 1'}
    @{Key='2'; Text='Option 2'}
    @{Key='Q'; Text='Quitter'}
)
```

---

## Fonctions Disponibles

| Fonction | Description |
|----------|-------------|
| `Write-ConsoleBanner` | Affiche une banniere de titre avec version |
| `Write-SummaryBox` | Affiche un resume avec statistiques |
| `Write-SelectionBox` | Menu de selection d'applications |
| `Write-MenuBox` | Menu generique avec options |
| `Write-Box` | Boite generique avec contenu |
| `Write-EnterpriseAppsSelectionBox` | Menu Enterprise Apps |
| `Write-UnifiedSelectionBox` | Menu selection unifiee |
| `Write-CollectionModeBox` | Menu mode de collecte |
| `Write-CategorySelectionMenu` | Menu selection categories |
| `Update-CategorySelection` | Toggle selection categories |

---

## Write-ConsoleBanner

Affiche une banniere de titre avec alignement dynamique.

```powershell
Write-ConsoleBanner -Title "MON APPLICATION" -Version "2.0.0" -Width 65
```

### Parametres

| Parametre | Obligatoire | Description |
|-----------|-------------|-------------|
| Title | Oui | Titre principal |
| Version | Non | Version a afficher |
| Width | Non | Largeur (defaut: 65) |

### Resultat

```
  ┌─────────────────────────────────────────────────────────────────┐
  │                                                                 │
  │  MON APPLICATION  v2.0.0                                        │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘
```

---

## Write-SummaryBox

Affiche un resume avec icones colorees.

```powershell
Write-SummaryBox -Total 100 -Success 95 -Errors 5 -Duration "00:05:30"
```

### Parametres

| Parametre | Obligatoire | Description |
|-----------|-------------|-------------|
| Total | Non | Nombre total d'elements |
| Success | Non | Nombre de succes (vert) |
| Errors | Non | Nombre d'erreurs (rouge) |
| Duration | Non | Duree d'execution |

### Resultat

```
  ┌───────────────────────────────┐
  │  RESUME                       │
  ├───────────────────────────────┤
  │  [i] Total      : 100         │
  │  [+] Succes     : 95          │
  │  [-] Erreurs    : 5           │
  │  [>] Duree      : 00:05:30    │
  └───────────────────────────────┘
```

---

## Write-MenuBox

Affiche un menu generique avec options.

```powershell
Write-MenuBox -Title "ACTIONS" -Subtitle "Selectionnez une option" -Options @(
    @{Key='A'; Text='Ajouter'}
    @{Key='M'; Text='Modifier'}
    @{Key='S'; Text='Supprimer'}
    @{Key='Q'; Text='Quitter'}
)
```

---

## Conventions Icones

| Icone | Couleur | Usage |
|-------|---------|-------|
| `[+]` | Green | Succes, creation, ajout |
| `[-]` | Red | Erreur, echec, suppression |
| `[!]` | Yellow | Warning, attention |
| `[i]` | Cyan | Info, titre |
| `[>]` | White | Action, section, etape |
| `[?]` | DarkGray | WhatIf, preview, question |

---

## Structure du Projet

```
Module-ConsoleUI/
├── Modules/
│   └── ConsoleUI/
│       ├── ConsoleUI.psd1      # Manifest
│       └── ConsoleUI.psm1      # Module principal
├── Tests/
│   └── Unit/                   # Tests unitaires Pester
├── Logs/                       # Logs runtime (gitignore)
├── README.md
├── CHANGELOG.md
└── LICENSE
```

---

## Tests

```powershell
Invoke-Pester -Path .\Tests -Output Detailed
```

---

## Licence

MIT License
