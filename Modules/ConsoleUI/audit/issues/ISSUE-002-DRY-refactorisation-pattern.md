# [!] [DRY-001] Refactoriser pattern d'affichage duplique x9 | Effort: 4h

## PROBLEME
Le meme pattern d'affichage (bordures, lignes avec padding, lignes vides) est
duplique dans 9 fonctions publiques, representant ~280 lignes (27% du code).
Des fonctions privees ont ete creees pour factoriser ce pattern mais ne sont
jamais utilisees (code mort).

## LOCALISATION
- Fichier : Modules/ConsoleUI/ConsoleUI.psm1
- Fonctions concernees : 9 fonctions publiques (L102-1132)
- Fonctions privees inutilisees : L22-93 (Write-PaddedLine, Write-BoxBorder, Write-EmptyLine)
- Module : ConsoleUI

## OBJECTIF
Utiliser les fonctions privees existantes pour eliminer la duplication,
reduire le code de ~200 lignes et ameliorer la maintenabilite.

---

## ANALYSE IMPACT

### Fichiers Impactes
| Fichier | Raison | Action Requise |
|---------|--------|----------------|
| ConsoleUI.psm1 | Toutes fonctions publiques | Refactoriser |

### Pattern Duplique a Factoriser

| Element | Occurrences | Fonction de remplacement |
|---------|-------------|--------------------------|
| `[Console]::OutputEncoding = UTF8` | 9 | Centraliser au chargement |
| Bordure haute `┌─┐` | 9 | Write-BoxBorder -Position Top |
| Bordure milieu `├─┤` | 7 | Write-BoxBorder -Position Middle |
| Bordure basse `└─┘` | 9 | Write-BoxBorder -Position Bottom |
| Ligne vide `│  │` | 8 | Write-EmptyLine |
| Ligne avec padding | ~50 | Write-PaddedLine |

---

## IMPLEMENTATION

### Etape 1 : Centraliser UTF-8 encoding - 15min
Fichier : Modules/ConsoleUI/ConsoleUI.psm1
Ligne ~L16 - AJOUTER (debut du module, hors fonctions)

AVANT :
```powershell
#region Private Functions
```

APRES :
```powershell
# Initialisation encodage UTF-8 (une seule fois au chargement)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

#region Private Functions
```

Puis SUPPRIMER les 9 lignes identiques dans chaque fonction :
- L131, L208, L321, L442, L520, L631, L758, L886, L1010

### Etape 2 : Adapter Write-BoxBorder - 15min
Fichier : Modules/ConsoleUI/ConsoleUI.psm1
Lignes L57-79 - MODIFIER

AVANT :
```powershell
function Write-BoxBorder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$Width,

        [Parameter()]
        [ValidateSet('Top', 'Middle', 'Bottom')]
        [string]$Position = 'Middle'
    )

    $chars = switch ($Position) {
        'Top'    { @{ Left = '┌'; Right = '┐' } }
        'Middle' { @{ Left = '├'; Right = '┤' } }
        'Bottom' { @{ Left = '└'; Right = '┘' } }
    }

    Write-Host ("  " + $chars.Left + ("─" * $Width) + $chars.Right) -ForegroundColor DarkGray
}
```

APRES :
```powershell
function Write-BoxBorder {
    <#
    .SYNOPSIS
        Affiche une bordure horizontale de boite
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [int]$Width,

        [Parameter()]
        [ValidateSet('Top', 'Middle', 'Bottom')]
        [string]$Position = 'Middle',

        [Parameter()]
        [switch]$NoIndent
    )

    $chars = switch ($Position) {
        'Top'    { @{ Left = '┌'; Right = '┐' } }
        'Middle' { @{ Left = '├'; Right = '┤' } }
        'Bottom' { @{ Left = '└'; Right = '┘' } }
    }

    $indent = if ($NoIndent) { '' } else { '  ' }
    Write-Host ($indent + $chars.Left + ("─" * $Width) + $chars.Right) -ForegroundColor DarkGray
}
```

### Etape 3 : Adapter Write-PaddedLine - 30min
Fichier : Modules/ConsoleUI/ConsoleUI.psm1
Lignes L22-55 - MODIFIER

APRES :
```powershell
function Write-PaddedLine {
    <#
    .SYNOPSIS
        Affiche une ligne avec padding dynamique dans une boite
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Content,

        [Parameter(Mandatory)]
        [int]$Width,

        [Parameter()]
        [string]$ContentColor = 'White',

        [Parameter()]
        [string]$PrefixBracket,

        [Parameter()]
        [string]$PrefixColor,

        [Parameter()]
        [int]$Indent = 2,

        [Parameter()]
        [switch]$NoIndent
    )

    $boxIndent = if ($NoIndent) { '' } else { '  ' }

    # Calcul longueur reelle (avec prefix bracket si present)
    $prefixLen = if ($PrefixBracket) { $PrefixBracket.Length + 1 } else { 0 }
    $contentLen = $Indent + $prefixLen + $Content.Length
    $padding = [Math]::Max(0, $Width - $contentLen)

    Write-Host "$boxIndent│" -NoNewline -ForegroundColor DarkGray
    Write-Host (" " * $Indent) -NoNewline

    if ($PrefixBracket) {
        $color = if ($PrefixColor) { $PrefixColor } else { $ContentColor }
        Write-Host $PrefixBracket -NoNewline -ForegroundColor $color
        Write-Host " " -NoNewline
    }

    Write-Host $Content -NoNewline -ForegroundColor $ContentColor
    Write-Host (" " * $padding) -NoNewline
    Write-Host "│" -ForegroundColor DarkGray
}
```

### Etape 4 : Adapter Write-EmptyLine - 10min
Fichier : Modules/ConsoleUI/ConsoleUI.psm1

APRES :
```powershell
function Write-EmptyLine {
    <#
    .SYNOPSIS
        Affiche une ligne vide dans une boite
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [int]$Width,

        [Parameter()]
        [switch]$NoIndent
    )

    $indent = if ($NoIndent) { '' } else { '  ' }
    Write-Host ($indent + "│" + (" " * $Width) + "│") -ForegroundColor DarkGray
}
```

### Etape 5 : Refactoriser Write-ConsoleBanner - 30min
Fichier : Modules/ConsoleUI/ConsoleUI.psm1

AVANT (extrait L155-171) :
```powershell
Write-Host ''
Write-Host ("  ┌" + ("─" * $Width) + "┐") -ForegroundColor DarkGray
Write-Host ("  │" + (" " * $Width) + "│") -ForegroundColor DarkGray

Write-Host "  │  " -NoNewline -ForegroundColor DarkGray
Write-Host $Title -NoNewline -ForegroundColor Cyan
# ... 10 lignes de plus
```

APRES :
```powershell
Write-Host ''
Write-BoxBorder -Width $Width -Position Top
Write-EmptyLine -Width $Width

# Ligne titre avec version optionnelle
$titleContent = if ($Version) { "$Title  v$Version" } else { $Title }
Write-PaddedLine -Content $titleContent -Width $Width -ContentColor Cyan

Write-EmptyLine -Width $Width
Write-BoxBorder -Width $Width -Position Bottom
Write-Host ''
```

### Etape 6-9 : Refactoriser les 8 autres fonctions - 2h30
Appliquer le meme pattern de refactorisation a :
- Write-SummaryBox
- Write-SelectionBox
- Write-MenuBox
- Write-Box
- Write-EnterpriseAppsSelectionBox
- Write-UnifiedSelectionBox
- Write-CollectionModeBox
- Write-CategorySelectionMenu

---

## VALIDATION

### Criteres d'Acceptation
- [ ] Toutes les fonctions produisent le meme affichage visuel
- [ ] Aucune regression visuelle
- [ ] Reduction de ~200 lignes de code
- [ ] Duplication < 10% (actuellement 27%)
- [ ] Tests visuels sur chaque fonction

---

## DEPENDANCES
- Bloquee par : Aucune
- Bloque : ISSUE-003 (code mort sera resolu par cette issue)

## POINTS ATTENTION
- 1 fichier modifie
- ~200 lignes supprimees
- ~50 lignes modifiees
- Risques : Regression visuelle - MITIGATION : tests visuels systematiques

## CHECKLIST
- [x] Code AVANT = code reel verifie
- [x] Tests unitaires passent
- [x] Tests visuels OK (10/10 fonctions testees)
- [x] Code review effectuee

Labels : refactoring dry maintenabilite effort-4h priorite-haute

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | # |
| Statut | RESOLVED |
| Commit Resolution | (a committer) |
