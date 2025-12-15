#Requires -Version 7.2

<#
.SYNOPSIS
    Module d'affichage console avec alignement dynamique des bordures
.DESCRIPTION
    Fournit des fonctions pour afficher des boites avec calcul dynamique
    du padding pour garantir l'alignement parfait des bordures droites.

    Respecte le guide CLAUDE.md :
    - Box drawing Unicode : ┌─┐│└─┘├┤
    - Icones : [+] Green | [-] Red | [!] Yellow | [i] Cyan | [>] White
    - Indentation 2 espaces
    - Jamais emoji
#>

# Initialisation encodage UTF-8 (une seule fois au chargement du module)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

#region Private Functions
#═══════════════════════════════════════════════════════════════════════════════
#  PRIVATE FUNCTIONS (Issue 035 - DRY padding pattern)
#═══════════════════════════════════════════════════════════════════════════════

function Write-PaddedLine {
    <#
    .SYNOPSIS
        Affiche une ligne avec padding dynamique dans une boite
    .DESCRIPTION
        Calcule le padding necessaire pour aligner la bordure droite
        et affiche le contenu avec les couleurs specifiees.
        Utilise [Math]::Max(0, $padding) pour eviter les valeurs negatives.
    .PARAMETER Content
        Texte a afficher
    .PARAMETER Width
        Largeur interieure de la boite
    .PARAMETER ContentColor
        Couleur du texte (defaut: White)
    .PARAMETER Indent
        Indentation du contenu dans la boite (defaut: 2)
    .PARAMETER PrefixBracket
        Bracket optionnel a afficher avant le contenu (ex: "[+]", "[-]")
    .PARAMETER PrefixColor
        Couleur du bracket (si different de ContentColor)
    .PARAMETER NoIndent
        Si present, pas d'indentation de 2 espaces pour la boite
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
        [int]$Indent = 2,

        [Parameter()]
        [string]$PrefixBracket,

        [Parameter()]
        [string]$PrefixColor,

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
        $bracketColor = if ($PrefixColor) { $PrefixColor } else { $ContentColor }
        Write-Host $PrefixBracket -NoNewline -ForegroundColor $bracketColor
        Write-Host ' ' -NoNewline
    }

    Write-Host $Content -NoNewline -ForegroundColor $ContentColor
    Write-Host (" " * $padding) -NoNewline
    Write-Host "│" -ForegroundColor DarkGray
}

function Write-BoxBorder {
    <#
    .SYNOPSIS
        Affiche une bordure horizontale de boite
    .PARAMETER Width
        Largeur interieure de la boite
    .PARAMETER Position
        Position de la bordure: Top, Middle, Bottom
    .PARAMETER NoIndent
        Si present, pas d'indentation de 2 espaces
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
        'Top' { @{ Left = '┌'; Right = '┐' } }
        'Middle' { @{ Left = '├'; Right = '┤' } }
        'Bottom' { @{ Left = '└'; Right = '┘' } }
    }

    $indent = if ($NoIndent) { '' } else { '  ' }
    Write-Host ($indent + $chars.Left + ("─" * $Width) + $chars.Right) -ForegroundColor DarkGray
}

function Write-EmptyLine {
    <#
    .SYNOPSIS
        Affiche une ligne vide dans une boite
    .PARAMETER Width
        Largeur interieure de la boite
    .PARAMETER NoIndent
        Si present, pas d'indentation de 2 espaces
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

#endregion Private Functions

#region Public Functions
#═══════════════════════════════════════════════════════════════════════════════
#  PUBLIC FUNCTIONS
#═══════════════════════════════════════════════════════════════════════════════

function Write-ConsoleBanner {
    <#
    .SYNOPSIS
        Affiche une banniere de titre avec alignement dynamique des bordures.

    .DESCRIPTION
        Cree une banniere encadree avec caracteres Unicode box-drawing.
        Calcule dynamiquement le padding pour garantir que la bordure
        droite est toujours alignee, quelle que soit la longueur du texte.
        Ajuste automatiquement la largeur si le contenu depasse.

    .PARAMETER Title
        Titre principal a afficher. Obligatoire, ne peut pas etre vide.
        Affiche en couleur Cyan.

    .PARAMETER Version
        Numero de version a afficher apres le titre.
        Format recommande: "X.Y.Z" (le prefixe "v" est ajoute automatiquement).
        Affiche en couleur DarkGray.

    .PARAMETER Width
        Largeur totale de la boite en caracteres.
        Defaut: 65. S'ajuste automatiquement si le contenu depasse.

    .OUTPUTS
        [void] - Affiche directement dans la console via Write-Host.

    .EXAMPLE
        Write-ConsoleBanner -Title "MON APPLICATION"

        Affiche une banniere simple avec le titre.

    .EXAMPLE
        Write-ConsoleBanner -Title "APP REGISTRATION COLLECTOR" -Version "1.0.0"

        Affiche:
        ┌───────────────────────────────────────────────────────────────┐
        │                                                               │
        │  APP REGISTRATION COLLECTOR  v1.0.0                           │
        │                                                               │
        └───────────────────────────────────────────────────────────────┘

    .EXAMPLE
        Write-ConsoleBanner -Title "TITRE" -Width 40

        Affiche une banniere plus etroite (40 caracteres).

    .NOTES
        Auteur: Zornot
        Module: ConsoleUI
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Title,

        [Parameter()]
        [string]$Version,

        [Parameter()]
        [int]$Width = 65
    )

    # Calcul du contenu : "  Title" ou "  Title  vX.X.X"
    $versionText = if ($Version) { "v$Version" } else { '' }
    $contentLen = if ($Version) { 2 + $Title.Length + 2 + $versionText.Length } else { 2 + $Title.Length }

    # Ajustement auto si contenu trop large
    if ($contentLen -gt ($Width - 2)) {
        $Width = $contentLen + 4
    }

    $padding = $Width - $contentLen

    # Affichage avec helpers DRY
    Write-Host ''
    Write-BoxBorder -Width $Width -Position Top
    Write-EmptyLine -Width $Width

    # Ligne titre (cas special: 2 couleurs)
    Write-Host "  │  " -NoNewline -ForegroundColor DarkGray
    Write-Host $Title -NoNewline -ForegroundColor Cyan
    if ($Version) {
        Write-Host "  " -NoNewline
        Write-Host $versionText -NoNewline -ForegroundColor DarkGray
    }
    Write-Host (" " * [Math]::Max(0, $padding)) -NoNewline
    Write-Host "│" -ForegroundColor DarkGray

    Write-EmptyLine -Width $Width
    Write-BoxBorder -Width $Width -Position Bottom
    Write-Host ''
}

function Write-SummaryBox {
    <#
    .SYNOPSIS
        Affiche une boite de resume avec statistiques colorees.

    .DESCRIPTION
        Cree une boite de resume formatee avec icones bracket et couleurs semantiques :
        - [i] Total (Cyan) : toujours affiche
        - [+] Succes (Green) : affiche si > 0
        - [-] Erreurs (Red) : affiche si > 0
        - [>] Duree (White) : affiche si fourni

        Ideal pour afficher le bilan d'une operation en fin de script.

    .PARAMETER Total
        Nombre total d'elements traites. Defaut: 0.
        Toujours affiche meme si 0.

    .PARAMETER Success
        Nombre d'operations reussies. Defaut: 0.
        Affiche uniquement si superieur a 0.

    .PARAMETER Errors
        Nombre d'erreurs rencontrees. Defaut: 0.
        Affiche uniquement si superieur a 0.

    .PARAMETER Duration
        Duree d'execution au format string (ex: "00:05:30", "2.5s").
        Affiche uniquement si fourni.

    .OUTPUTS
        [void] - Affiche directement dans la console via Write-Host.

    .EXAMPLE
        Write-SummaryBox -Total 100

        Affiche uniquement le total.

    .EXAMPLE
        Write-SummaryBox -Total 100 -Success 95 -Errors 5

        Affiche le total, les succes en vert et les erreurs en rouge.

    .EXAMPLE
        Write-SummaryBox -Total 50 -Success 50 -Duration "00:02:15"

        Affiche:
        ┌───────────────────────────────┐
        │  RESUME                       │
        ├───────────────────────────────┤
        │  [i] Total     : 50           │
        │  [+] Succes    : 50           │
        │  [>] Duree     : 00:02:15     │
        └───────────────────────────────┘

    .NOTES
        Auteur: Zornot
        Module: ConsoleUI
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter()]
        [int]$Total = 0,

        [Parameter()]
        [int]$Success = 0,

        [Parameter()]
        [int]$Errors = 0,

        [Parameter()]
        [string]$Duration
    )

    $labelWidth = 10
    $valueWidth = 10
    $boxWidth = 31

    Write-Host ''
    Write-BoxBorder -Width $boxWidth -Position Top
    Write-PaddedLine -Content 'RESUME' -Width $boxWidth -ContentColor White
    Write-BoxBorder -Width $boxWidth -Position Middle

    # Total (toujours affiche) - ligne multi-couleurs
    $statLineLen = 3 + 1 + $labelWidth + 2 + $valueWidth  # [i] + space + label + ": " + value
    $statPadding = [Math]::Max(0, $boxWidth - 2 - $statLineLen)

    Write-Host "  │  " -NoNewline -ForegroundColor DarkGray
    Write-Host "[i]" -NoNewline -ForegroundColor Cyan
    Write-Host " " -NoNewline
    Write-Host "Total".PadRight($labelWidth) -NoNewline -ForegroundColor DarkGray
    Write-Host ": " -NoNewline -ForegroundColor DarkGray
    Write-Host $Total.ToString().PadRight($valueWidth) -NoNewline -ForegroundColor Cyan
    Write-Host (" " * $statPadding) -NoNewline
    Write-Host "│" -ForegroundColor DarkGray

    # Succes (si > 0)
    if ($Success -gt 0) {
        Write-Host "  │  " -NoNewline -ForegroundColor DarkGray
        Write-Host "[+]" -NoNewline -ForegroundColor Green
        Write-Host " " -NoNewline
        Write-Host "Succes".PadRight($labelWidth) -NoNewline -ForegroundColor DarkGray
        Write-Host ": " -NoNewline -ForegroundColor DarkGray
        Write-Host $Success.ToString().PadRight($valueWidth) -NoNewline -ForegroundColor Green
        Write-Host (" " * $statPadding) -NoNewline
        Write-Host "│" -ForegroundColor DarkGray
    }

    # Erreurs (si > 0)
    if ($Errors -gt 0) {
        Write-Host "  │  " -NoNewline -ForegroundColor DarkGray
        Write-Host "[-]" -NoNewline -ForegroundColor Red
        Write-Host " " -NoNewline
        Write-Host "Erreurs".PadRight($labelWidth) -NoNewline -ForegroundColor DarkGray
        Write-Host ": " -NoNewline -ForegroundColor DarkGray
        Write-Host $Errors.ToString().PadRight($valueWidth) -NoNewline -ForegroundColor Red
        Write-Host (" " * $statPadding) -NoNewline
        Write-Host "│" -ForegroundColor DarkGray
    }

    # Duree (si fournie)
    if ($Duration) {
        Write-Host "  │  " -NoNewline -ForegroundColor DarkGray
        Write-Host "[>]" -NoNewline -ForegroundColor White
        Write-Host " " -NoNewline
        Write-Host "Duree".PadRight($labelWidth) -NoNewline -ForegroundColor DarkGray
        Write-Host ": " -NoNewline -ForegroundColor DarkGray
        Write-Host $Duration.PadRight($valueWidth) -NoNewline -ForegroundColor White
        Write-Host (" " * $statPadding) -NoNewline
        Write-Host "│" -ForegroundColor DarkGray
    }

    Write-BoxBorder -Width $boxWidth -Position Bottom
    Write-Host ''
}

function Write-SelectionBox {
    <#
    .SYNOPSIS
        Affiche la boite de selection des applications
    .DESCRIPTION
        Menu interactif pour le mode -Interactive avec options :
        [A] Toutes, [M] Microsoft, [S] Selection, [F] Filtre, [Q] Quitter
    .PARAMETER Count
        Nombre d'applications disponibles
    .PARAMETER MicrosoftCount
        Nombre d'applications Microsoft (optionnel)
    .PARAMETER MicrosoftExcluded
        Indique si les apps Microsoft sont exclues (defaut: $true)
    .PARAMETER Width
        Largeur de la boite (defaut: 65)
    .EXAMPLE
        Write-SelectionBox -Count 42
    .EXAMPLE
        Write-SelectionBox -Count 42 -MicrosoftCount 120 -MicrosoftExcluded $true
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [int]$Count,

        [Parameter()]
        [int]$MicrosoftCount = 0,

        [Parameter()]
        [bool]$MicrosoftExcluded = $true,

        [Parameter()]
        [int]$Width = 65
    )

    $title = "SELECTION DES APPLICATIONS"
    $subtitle = "$Count application(s) disponible(s)"
    $microsoftLine = "[!] $MicrosoftCount application(s) Microsoft detectee(s)"
    $microsoftOption = "[M] Hors Microsoft"

    # Calcul largeur necessaire
    $maxContentLen = [Math]::Max(2 + $title.Length, 2 + $subtitle.Length)
    $maxContentLen = [Math]::Max($maxContentLen, 2 + 27)  # "[A] Toutes les applications"
    $maxContentLen = [Math]::Max($maxContentLen, 2 + $microsoftLine.Length)
    $maxContentLen = [Math]::Max($maxContentLen, 2 + $microsoftOption.Length)

    if ($maxContentLen -gt ($Width - 2)) {
        $Width = $maxContentLen + 4
    }

    Write-Host ''
    Write-BoxBorder -Width $Width -Position Top
    Write-PaddedLine -Content $title -Width $Width -ContentColor White
    Write-BoxBorder -Width $Width -Position Middle
    Write-PaddedLine -Content $subtitle -Width $Width -ContentColor Cyan
    Write-PaddedLine -Content $microsoftLine -Width $Width -ContentColor Yellow
    Write-EmptyLine -Width $Width
    Write-PaddedLine -Content 'Options:' -Width $Width -ContentColor White

    # Options du menu
    $menuOptions = @(
        "[A] Toutes les applications"
        $microsoftOption
        "[S] Selectionner par numero"
        "[F] Filtrer par nom"
        "[Q] Quitter"
    )

    foreach ($opt in $menuOptions) {
        Write-PaddedLine -Content $opt -Width $Width -ContentColor DarkGray
    }

    Write-BoxBorder -Width $Width -Position Bottom
    Write-Host ''
}

function Write-MenuBox {
    <#
    .SYNOPSIS
        Affiche une boite de menu generique avec options clavier.

    .DESCRIPTION
        Cree un menu interactif encadre avec liste d'options formatees [X].
        Calcule automatiquement la largeur pour s'adapter au contenu.
        Chaque option est affichee avec sa touche entre crochets.

    .PARAMETER Title
        Titre du menu. Obligatoire, ne peut pas etre vide.
        Affiche en blanc sur la premiere ligne.

    .PARAMETER Subtitle
        Sous-titre descriptif optionnel.
        Affiche en Cyan sous le titre.

    .PARAMETER Options
        Tableau de hashtables definissant les options du menu.
        Chaque hashtable DOIT contenir les cles 'Key' et 'Text'.
        Format: @(@{Key='A'; Text='Premiere option'}, @{Key='Q'; Text='Quitter'})

    .OUTPUTS
        [void] - Affiche directement dans la console via Write-Host.

    .EXAMPLE
        Write-MenuBox -Title "MENU PRINCIPAL" -Options @(@{Key='A'; Text='Option A'}; @{Key='Q'; Text='Quitter'})

        Affiche un menu simple avec deux options.

    .EXAMPLE
        $options = @(
            @{Key='1'; Text='Nouvelle recherche'}
            @{Key='2'; Text='Exporter resultats'}
            @{Key='Q'; Text='Quitter'}
        )
        Write-MenuBox -Title "ACTIONS" -Subtitle "Choisissez une action" -Options $options

        Affiche:
        ┌─────────────────────────────┐
        │  ACTIONS                    │
        ├─────────────────────────────┤
        │  Choisissez une action      │
        │                             │
        │  Options:                   │
        │    [1] Nouvelle recherche   │
        │    [2] Exporter resultats   │
        │    [Q] Quitter              │
        └─────────────────────────────┘

    .NOTES
        Auteur: Zornot
        Module: ConsoleUI
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Title,

        [Parameter()]
        [string]$Subtitle,

        [Parameter(Mandatory)]
        [ValidateScript({
                foreach ($opt in $_) {
                    if (-not ($opt -is [hashtable] -and $opt.ContainsKey('Key') -and $opt.ContainsKey('Text'))) {
                        throw "Chaque option doit etre un hashtable avec les cles 'Key' et 'Text'. Recu: $($opt.GetType().Name)"
                    }
                }
                $true
            }, ErrorMessage = "Format attendu: @(@{Key='A'; Text='Option A'}, ...)")]
        [hashtable[]]$Options
    )

    # Calculer la largeur necessaire
    $maxLen = $Title.Length
    if ($Subtitle -and $Subtitle.Length -gt $maxLen) { $maxLen = $Subtitle.Length }

    foreach ($opt in $Options) {
        $optLen = 4 + 3 + $opt.Text.Length  # "  [X] Text"
        if ($optLen -gt $maxLen) { $maxLen = $optLen }
    }

    $boxWidth = $maxLen + 4

    Write-Host ''
    Write-BoxBorder -Width $boxWidth -Position Top
    Write-PaddedLine -Content $Title -Width $boxWidth -ContentColor White
    Write-BoxBorder -Width $boxWidth -Position Middle

    if ($Subtitle) {
        Write-PaddedLine -Content $Subtitle -Width $boxWidth -ContentColor Cyan
    }

    Write-EmptyLine -Width $boxWidth
    Write-PaddedLine -Content 'Options:' -Width $boxWidth -ContentColor White

    foreach ($opt in $Options) {
        $optText = "  [$($opt.Key)] $($opt.Text)"
        Write-PaddedLine -Content $optText -Width $boxWidth -ContentColor DarkGray
    }

    Write-BoxBorder -Width $boxWidth -Position Bottom
    Write-Host ''
}

function Write-Box {
    <#
    .SYNOPSIS
        Affiche une boite generique avec contenu flexible.

    .DESCRIPTION
        Cree une boite encadree pouvant afficher differents types de contenu :
        - Hashtable : affiche en format "Cle : Valeur" aligne
        - OrderedDictionary : idem, en preservant l'ordre
        - Tableau de strings : affiche chaque ligne
        - Tableau de hashtables : format mixte

        Calcule automatiquement la largeur minimale necessaire.
        N'utilise pas l'indentation externe (contrairement aux autres fonctions).

    .PARAMETER Title
        Titre optionnel de la boite.
        Si fourni, affiche sur la premiere ligne avec separateur.

    .PARAMETER Content
        Contenu a afficher. Accepte plusieurs formats :
        - [hashtable] : @{Cle1='Valeur1'; Cle2='Valeur2'}
        - [OrderedDictionary] : [ordered]@{...} pour controler l'ordre
        - [string[]] : @('Ligne 1', 'Ligne 2')
        - [hashtable[]] : mix de Label/Value et Text

    .OUTPUTS
        [void] - Affiche directement dans la console via Write-Host.

    .EXAMPLE
        Write-Box -Title "CONFIGURATION" -Content @{Serveur='SRV01'; Port=443}

        Affiche une boite avec titre et paires cle-valeur.

    .EXAMPLE
        Write-Box -Content @('Ligne 1', 'Ligne 2', 'Ligne 3')

        Affiche une boite sans titre avec du texte simple.

    .EXAMPLE
        $info = [ordered]@{
            Application = 'MonApp'
            Version     = '2.0.0'
            Statut      = 'Actif'
        }
        Write-Box -Title "INFO" -Content $info

        Affiche:
        ┌────────────────────────┐
        │ INFO                   │
        ├────────────────────────┤
        │ Application: MonApp    │
        │ Version    : 2.0.0     │
        │ Statut     : Actif     │
        └────────────────────────┘

    .NOTES
        Auteur: Zornot
        Module: ConsoleUI
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter()]
        [string]$Title,

        [Parameter()]
        [object]$Content
    )

    $lines = [System.Collections.Generic.List[hashtable]]::new()

    # Convertir le contenu
    if ($Content -is [hashtable] -or $Content -is [System.Collections.Specialized.OrderedDictionary]) {
        foreach ($key in $Content.Keys) {
            $lines.Add(@{ Label = $key.ToString(); Value = $Content[$key].ToString() })
        }
    }
    elseif ($Content -is [array]) {
        foreach ($item in $Content) {
            if ($item -is [hashtable]) {
                $lines.Add($item)
            }
            else {
                $lines.Add(@{ Text = $item.ToString() })
            }
        }
    }

    # Calculer largeurs
    $maxLabelLen = 0
    $maxValueLen = 0
    $maxTextLen = 0

    foreach ($line in $lines) {
        if ($line.ContainsKey('Label')) {
            if ($line.Label.Length -gt $maxLabelLen) { $maxLabelLen = $line.Label.Length }
            if ($line.Value.Length -gt $maxValueLen) { $maxValueLen = $line.Value.Length }
        }
        elseif ($line.ContainsKey('Text')) {
            if ($line.Text.Length -gt $maxTextLen) { $maxTextLen = $line.Text.Length }
        }
    }

    $contentWidth = if ($maxLabelLen -gt 0) { $maxLabelLen + 2 + $maxValueLen } else { $maxTextLen }
    if ($Title -and $Title.Length -gt $contentWidth) { $contentWidth = $Title.Length }
    $boxWidth = [Math]::Max($contentWidth + 4, 24)

    # Affichage (Write-Box utilise un format different: pas d'indentation externe)
    Write-BoxBorder -Width $boxWidth -Position Top -NoIndent

    if ($Title) {
        Write-PaddedLine -Content $Title -Width $boxWidth -ContentColor White -Indent 1 -NoIndent
        Write-BoxBorder -Width $boxWidth -Position Middle -NoIndent
    }

    # Lignes de contenu (multi-couleurs: Label=DarkGray, Value=White)
    foreach ($line in $lines) {
        Write-Host "│ " -NoNewline -ForegroundColor DarkGray

        if ($line.ContainsKey('Label')) {
            $labelPart = $line.Label.PadRight($maxLabelLen)
            $valuePart = $line.Value
            Write-Host $labelPart -NoNewline -ForegroundColor DarkGray
            Write-Host ": " -NoNewline -ForegroundColor DarkGray
            Write-Host $valuePart -NoNewline -ForegroundColor White
            $linePadding = $boxWidth - 2 - $maxLabelLen - 2 - $valuePart.Length
            Write-Host (" " * [Math]::Max(0, $linePadding)) -NoNewline
        }
        elseif ($line.ContainsKey('Text')) {
            $textPadding = $boxWidth - 2 - $line.Text.Length
            Write-Host $line.Text -NoNewline -ForegroundColor White
            Write-Host (" " * [Math]::Max(0, $textPadding)) -NoNewline
        }

        Write-Host " │" -ForegroundColor DarkGray
    }

    Write-BoxBorder -Width $boxWidth -Position Bottom -NoIndent
}

function Write-EnterpriseAppsSelectionBox {
    <#
    .SYNOPSIS
        Affiche une boite de selection pour les Enterprise Applications
    .PARAMETER TotalCount
        Nombre total d'applications
    .PARAMETER MicrosoftCount
        Nombre d'applications Microsoft
    .PARAMETER ThirdPartyCount
        Nombre d'applications tierces
    .PARAMETER CustomCount
        Nombre d'applications custom
    .PARAMETER Width
        Largeur de la boite (optionnel)
    .EXAMPLE
        Write-EnterpriseAppsSelectionBox -TotalCount 847 -MicrosoftCount 573 -ThirdPartyCount 264 -CustomCount 10
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [int]$TotalCount,

        [Parameter()]
        [int]$MicrosoftCount = 0,

        [Parameter()]
        [int]$ThirdPartyCount = 0,

        [Parameter()]
        [int]$CustomCount = 0,

        [Parameter()]
        [int]$Width = 65
    )

    $title = "ENTERPRISE APPLICATIONS"
    $subtitle = "$TotalCount application(s) dans le tenant"
    $statsLine = "[!] $MicrosoftCount Microsoft | $ThirdPartyCount Tierces | $CustomCount Custom"

    $menuOptions = @(
        "[A] Toutes les applications"
        "[M] Hors Microsoft ($($ThirdPartyCount + $CustomCount) apps)"
        "[T] Tierces uniquement ($ThirdPartyCount apps)"
        "[C] Custom uniquement ($CustomCount apps)"
        "[S] Selectionner par numero"
        "[F] Filtrer par nom"
        "[Q] Quitter"
    )

    # Calcul largeur necessaire
    $maxContentLen = [Math]::Max(2 + $title.Length, 2 + $subtitle.Length)
    $maxContentLen = [Math]::Max($maxContentLen, 2 + $statsLine.Length)
    foreach ($opt in $menuOptions) {
        $maxContentLen = [Math]::Max($maxContentLen, 2 + $opt.Length)
    }

    if ($maxContentLen -gt ($Width - 2)) {
        $Width = $maxContentLen + 4
    }

    Write-Host ''
    Write-BoxBorder -Width $Width -Position Top
    Write-PaddedLine -Content $title -Width $Width -ContentColor White
    Write-BoxBorder -Width $Width -Position Middle
    Write-PaddedLine -Content $subtitle -Width $Width -ContentColor Cyan
    Write-PaddedLine -Content $statsLine -Width $Width -ContentColor Yellow
    Write-EmptyLine -Width $Width
    Write-PaddedLine -Content 'Options:' -Width $Width -ContentColor White

    foreach ($opt in $menuOptions) {
        Write-PaddedLine -Content $opt -Width $Width -ContentColor DarkGray
    }

    Write-BoxBorder -Width $Width -Position Bottom
    Write-Host ''
}

function Write-UnifiedSelectionBox {
    <#
    .SYNOPSIS
        Affiche une boite de selection unifiee pour le mode "Tout"
    .DESCRIPTION
        Menu de selection unifie applique aux App Registrations ET Enterprise Apps.
        Une seule selection pour les deux modes.
    .PARAMETER AppRegistrationCount
        Nombre d'App Registrations disponibles
    .PARAMETER EnterpriseAppCount
        Nombre d'Enterprise Apps disponibles
    .PARAMETER MicrosoftAppRegCount
        Nombre d'App Registrations Microsoft
    .PARAMETER MicrosoftEnterpriseCount
        Nombre d'Enterprise Apps Microsoft
    .PARAMETER Width
        Largeur de la boite (optionnel)
    .EXAMPLE
        Write-UnifiedSelectionBox -AppRegistrationCount 42 -EnterpriseAppCount 847 -MicrosoftAppRegCount 5 -MicrosoftEnterpriseCount 573
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [int]$AppRegistrationCount,

        [Parameter(Mandatory)]
        [int]$EnterpriseAppCount,

        [Parameter()]
        [int]$MicrosoftAppRegCount = 0,

        [Parameter()]
        [int]$MicrosoftEnterpriseCount = 0,

        [Parameter()]
        [int]$Width = 65
    )

    $title = "SELECTION UNIFIEE"
    $subtitle = "App Registrations + Enterprise Apps"
    $countersLine = "$AppRegistrationCount App Reg. | $EnterpriseAppCount Enterprise Apps"
    $microsoftLine = "[!] Microsoft: $MicrosoftAppRegCount App Reg. | $MicrosoftEnterpriseCount Enterprise Apps"

    $menuOptions = @(
        "[A] Tout exporter"
        "    Exporte toutes les applications des deux modes"
        "[M] Hors Microsoft"
        "    Exclut les applications Microsoft first-party"
        "[C] Par categories"
        "    Selection par type: Custom, ThirdParty, Microsoft..."
        "[F] Filtrer par nom"
        "    Recherche dans les deux modes"
        "[Q] Quitter"
    )

    # Calcul largeur necessaire
    $maxContentLen = [Math]::Max(2 + $title.Length, 2 + $subtitle.Length)
    $maxContentLen = [Math]::Max($maxContentLen, 2 + $countersLine.Length)
    $maxContentLen = [Math]::Max($maxContentLen, 2 + $microsoftLine.Length)
    foreach ($opt in $menuOptions) {
        $maxContentLen = [Math]::Max($maxContentLen, 2 + $opt.Length)
    }

    if ($maxContentLen -gt ($Width - 2)) {
        $Width = $maxContentLen + 4
    }

    Write-Host ''
    Write-BoxBorder -Width $Width -Position Top
    Write-PaddedLine -Content $title -Width $Width -ContentColor White
    Write-PaddedLine -Content $subtitle -Width $Width -ContentColor DarkGray
    Write-BoxBorder -Width $Width -Position Middle
    Write-PaddedLine -Content $countersLine -Width $Width -ContentColor Cyan
    Write-PaddedLine -Content $microsoftLine -Width $Width -ContentColor Yellow
    Write-EmptyLine -Width $Width

    # Options (multi-couleurs: [X] Cyan, texte White/DarkGray)
    foreach ($opt in $menuOptions) {
        $optPadding = [Math]::Max(0, $Width - 2 - $opt.Length)
        Write-Host "  │  " -NoNewline -ForegroundColor DarkGray

        if ($opt.StartsWith('    ')) {
            Write-Host $opt -NoNewline -ForegroundColor DarkGray
        }
        elseif ($opt.StartsWith('[')) {
            $bracketEnd = $opt.IndexOf(']')
            $bracket = $opt.Substring(0, $bracketEnd + 1)
            $text = $opt.Substring($bracketEnd + 1)
            Write-Host $bracket -NoNewline -ForegroundColor Cyan
            Write-Host $text -NoNewline -ForegroundColor White
        }
        else {
            Write-Host $opt -NoNewline -ForegroundColor DarkGray
        }

        Write-Host (" " * $optPadding) -NoNewline
        Write-Host "│" -ForegroundColor DarkGray
    }

    Write-BoxBorder -Width $Width -Position Bottom
    Write-Host ''
}

function Write-CollectionModeBox {
    <#
    .SYNOPSIS
        Affiche une boite de selection du mode de collecte
    .DESCRIPTION
        Menu de selection entre App Registrations et Enterprise Apps
        avec descriptions claires de chaque mode.
    .PARAMETER Width
        Largeur de la boite (optionnel)
    .EXAMPLE
        Write-CollectionModeBox
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter()]
        [int]$Width = 65
    )

    $title = "MODE DE COLLECTE"

    $lines = @(
        @{ Type = 'option'; Key = 'R'; Text = 'App Registrations' }
        @{ Type = 'desc'; Text = 'Applications creees par votre organisation' }
        @{ Type = 'detail'; Text = 'Secrets, certificats, configuration complete' }
        @{ Type = 'empty' }
        @{ Type = 'option'; Key = 'E'; Text = 'Enterprise Apps' }
        @{ Type = 'desc'; Text = 'Applications installees (Microsoft, tierces, custom)' }
        @{ Type = 'detail'; Text = 'Permissions accordees, assignations utilisateurs' }
        @{ Type = 'empty' }
        @{ Type = 'option'; Key = 'T'; Text = 'Tout (les deux modes)' }
        @{ Type = 'desc'; Text = 'Exporte App Registrations ET Enterprise Apps' }
        @{ Type = 'detail'; Text = '2 fichiers de sortie distincts' }
        @{ Type = 'empty' }
        @{ Type = 'option'; Key = 'Q'; Text = 'Quitter' }
    )

    # Calcul largeur necessaire
    $maxContentLen = 2 + $title.Length
    foreach ($line in $lines) {
        $lineLen = switch ($line.Type) {
            'option' { 2 + 4 + $line.Text.Length }
            'desc' { 2 + 4 + $line.Text.Length }
            'detail' { 2 + 4 + 2 + $line.Text.Length }
            default { 0 }
        }
        $maxContentLen = [Math]::Max($maxContentLen, $lineLen)
    }

    if ($maxContentLen -gt ($Width - 2)) {
        $Width = $maxContentLen + 4
    }

    Write-Host ''
    Write-BoxBorder -Width $Width -Position Top
    Write-PaddedLine -Content $title -Width $Width -ContentColor White
    Write-BoxBorder -Width $Width -Position Middle
    Write-EmptyLine -Width $Width

    foreach ($line in $lines) {
        switch ($line.Type) {
            'option' {
                # Multi-couleurs: [X] Cyan, texte White
                $optText = "[$($line.Key)] $($line.Text)"
                $optPadding = [Math]::Max(0, $Width - 2 - $optText.Length)
                Write-Host "  │  " -NoNewline -ForegroundColor DarkGray
                Write-Host "[$($line.Key)]" -NoNewline -ForegroundColor Cyan
                Write-Host " $($line.Text)" -NoNewline -ForegroundColor White
                Write-Host (" " * $optPadding) -NoNewline
                Write-Host "│" -ForegroundColor DarkGray
            }
            'desc' {
                Write-PaddedLine -Content "    $($line.Text)" -Width $Width -ContentColor DarkGray
            }
            'detail' {
                Write-PaddedLine -Content "    > $($line.Text)" -Width $Width -ContentColor DarkYellow
            }
            'empty' {
                Write-EmptyLine -Width $Width
            }
        }
    }

    Write-BoxBorder -Width $Width -Position Bottom
    Write-Host ''
}

function Write-CategorySelectionMenu {
    <#
    .SYNOPSIS
        Affiche le menu de selection des categories avec toggle
    .DESCRIPTION
        Menu interactif pour selectionner les categories a exporter.
        Chaque categorie peut etre cochee/decochee avec un toggle.
    .PARAMETER CategoryCounts
        Hashtable avec les compteurs par categorie:
        @{ Custom = @{ AppReg = 228; EnterpriseApps = 227 }; ... }
    .PARAMETER SelectedCategories
        Liste des categories selectionnees (par defaut: Custom, ThirdParty)
    .PARAMETER Width
        Largeur de la boite (optionnel)
    .EXAMPLE
        Write-CategorySelectionMenu -CategoryCounts $counts -SelectedCategories @('Custom', 'ThirdParty')
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [hashtable]$CategoryCounts,

        [Parameter()]
        [string[]]$SelectedCategories = @('Custom', 'ThirdParty'),

        [Parameter()]
        [int]$Width = 65
    )

    $title = "PERIMETRE D'EXPORT"

    # Definir l'ordre et les labels des categories
    $categoryConfig = [ordered]@{
        'Custom'          = 'Applications Custom'
        'ThirdParty'      = 'Third-Party'
        'Microsoft'       = 'Microsoft First-Party'
        'ManagedIdentity' = 'Managed Identities'
        'StorageAccount'  = 'Storage Accounts'
    }

    # Calculer les totaux de la selection
    $totalAppReg = 0
    $totalEnterprise = 0
    foreach ($cat in $SelectedCategories) {
        if ($CategoryCounts.ContainsKey($cat)) {
            $totalAppReg += $CategoryCounts[$cat].AppReg
            $totalEnterprise += $CategoryCounts[$cat].EnterpriseApps
        }
    }

    # Preparer les lignes de categories
    $categoryLines = [System.Collections.Generic.List[string]]::new()
    $index = 1
    foreach ($cat in $categoryConfig.Keys) {
        $isSelected = $cat -in $SelectedCategories
        $checkbox = if ($isSelected) { '[x]' } else { '[ ]' }
        $label = $categoryConfig[$cat]
        $counts = $CategoryCounts[$cat]
        $appRegCount = if ($counts) { $counts.AppReg } else { 0 }
        $enterpriseCount = if ($counts) { $counts.EnterpriseApps } else { 0 }

        $line = "[$index] $checkbox $label".PadRight(35) + "$appRegCount".PadLeft(6) + "".PadLeft(6) + "$enterpriseCount".PadLeft(6)
        $categoryLines.Add($line)
        $index++
    }

    # Calculer la largeur necessaire
    $titleContentLen = 2 + $title.Length
    $headerLine = "INCLURE".PadRight(37) + "App Reg.  Enterprise Apps"
    $headerContentLen = 2 + $headerLine.Length
    $totalLine = "TOTAL SELECTION".PadRight(35) + "$totalAppReg".PadLeft(6) + "".PadLeft(6) + "$totalEnterprise".PadLeft(6)
    $totalContentLen = 2 + $totalLine.Length

    $maxContentLen = [Math]::Max($titleContentLen, $headerContentLen)
    $maxContentLen = [Math]::Max($maxContentLen, $totalContentLen)
    foreach ($line in $categoryLines) {
        $maxContentLen = [Math]::Max($maxContentLen, 2 + $line.Length)
    }

    if ($maxContentLen -gt ($Width - 2)) {
        $Width = $maxContentLen + 4
    }

    Write-Host ''
    Write-BoxBorder -Width $Width -Position Top
    Write-PaddedLine -Content $title -Width $Width -ContentColor White
    Write-BoxBorder -Width $Width -Position Middle

    # Header des colonnes
    Write-PaddedLine -Content $headerLine -Width $Width -ContentColor DarkGray
    Write-BoxBorder -Width $Width -Position Middle

    # Categories
    $catIndex = 0
    foreach ($line in $categoryLines) {
        $lineContentLen = 2 + $line.Length
        $linePadding = $Width - $lineContentLen
        Write-Host "  │  " -NoNewline -ForegroundColor DarkGray

        # Coloriser la ligne
        $cat = @($categoryConfig.Keys)[$catIndex]
        $isSelected = $cat -in $SelectedCategories

        # Numero
        $numEnd = $line.IndexOf(']') + 1
        Write-Host $line.Substring(0, $numEnd) -NoNewline -ForegroundColor Cyan

        # Checkbox
        $checkStart = $numEnd + 1
        $checkEnd = $line.IndexOf(']', $checkStart) + 1
        $checkColor = if ($isSelected) { 'Green' } else { 'DarkGray' }
        Write-Host $line.Substring($checkStart, $checkEnd - $checkStart) -NoNewline -ForegroundColor $checkColor

        # Reste de la ligne
        $textColor = if ($isSelected) { 'White' } else { 'DarkGray' }
        Write-Host $line.Substring($checkEnd) -NoNewline -ForegroundColor $textColor

        Write-Host (" " * [Math]::Max(0, $linePadding)) -NoNewline
        Write-Host "│" -ForegroundColor DarkGray
        $catIndex++
    }

    Write-BoxBorder -Width $Width -Position Middle
    Write-PaddedLine -Content $totalLine -Width $Width -ContentColor Cyan
    Write-BoxBorder -Width $Width -Position Bottom

    # Instructions
    Write-Host ''
    Write-Host "  [1-5] Basculer   [A] Tout   [N] Aucun   [V] Valider   [Q] Quitter" -ForegroundColor DarkGray
    Write-Host ''
}

function Update-CategorySelection {
    <#
    .SYNOPSIS
        Met a jour la selection des categories avec comportement toggle.

    .DESCRIPTION
        Fonction utilitaire pour gerer la selection/deselection de categories.
        Supporte trois modes d'operation :
        - Toggle : ajoute une categorie si absente, la retire si presente
        - SelectAll : selectionne toutes les categories disponibles
        - SelectNone : vide completement la selection

        Priorite des operations : SelectNone > SelectAll > Toggle

    .PARAMETER CurrentSelection
        Liste actuelle des categories selectionnees.
        Obligatoire, mais peut etre vide (@()).

    .PARAMETER Toggle
        Nom de la categorie a basculer.
        Si presente dans CurrentSelection : sera retiree.
        Si absente de CurrentSelection : sera ajoutee.

    .PARAMETER SelectAll
        Switch pour selectionner toutes les categories.
        Utilise AllCategories pour la liste complete.

    .PARAMETER SelectNone
        Switch pour vider la selection.
        A priorite sur SelectAll si les deux sont specifies.

    .PARAMETER AllCategories
        Liste de toutes les categories disponibles.
        Utilisee par SelectAll. Defaut: Custom, ThirdParty, Microsoft,
        ManagedIdentity, StorageAccount.

    .OUTPUTS
        [string[]] - Nouvelle liste de categories selectionnees.
        Peut etre vide si SelectNone ou si dernier element retire.

    .EXAMPLE
        $selection = @('Custom', 'ThirdParty')
        $selection = Update-CategorySelection -CurrentSelection $selection -Toggle 'Microsoft'
        # Resultat: @('Custom', 'ThirdParty', 'Microsoft')

    .EXAMPLE
        $selection = @('Custom', 'ThirdParty')
        $selection = Update-CategorySelection -CurrentSelection $selection -Toggle 'ThirdParty'
        # Resultat: @('Custom') - ThirdParty retire car deja present

    .EXAMPLE
        $selection = Update-CategorySelection -CurrentSelection @() -SelectAll
        # Resultat: @('Custom', 'ThirdParty', 'Microsoft', 'ManagedIdentity', 'StorageAccount')

    .EXAMPLE
        $selection = Update-CategorySelection -CurrentSelection @('Custom', 'ThirdParty') -SelectNone
        # Resultat: @() - Collection vide

    .NOTES
        Auteur: Zornot
        Module: ConsoleUI

        Note: PowerShell peut "unwrap" une collection vide en $null.
        Utiliser @(Update-CategorySelection ...) pour garantir un array.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]]$CurrentSelection,

        [Parameter()]
        [string]$Toggle,

        [Parameter()]
        [switch]$SelectAll,

        [Parameter()]
        [switch]$SelectNone,

        [Parameter()]
        [string[]]$AllCategories = @('Custom', 'ThirdParty', 'Microsoft', 'ManagedIdentity', 'StorageAccount')
    )

    if ($SelectNone) {
        return @()
    }

    if ($SelectAll) {
        return $AllCategories
    }

    if ($Toggle) {
        $result = [System.Collections.Generic.List[string]]::new($CurrentSelection)
        if ($Toggle -in $CurrentSelection) {
            $result.Remove($Toggle) | Out-Null
        }
        else {
            $result.Add($Toggle)
        }
        return $result.ToArray()
    }

    return $CurrentSelection
}

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
        'Error' { @{ Bracket = '[-]'; Color = 'Red' } }
        'Warning' { @{ Bracket = '[!]'; Color = 'Yellow' } }
        'Info' { @{ Bracket = '[i]'; Color = 'Cyan' } }
        'Action' { @{ Bracket = '[>]'; Color = 'White' } }
        'WhatIf' { @{ Bracket = '[?]'; Color = 'DarkGray' } }
    }

    $indentSpaces = "  " * $Indent
    $prefix = if ($CarriageReturn) { "`r" } else { "" }
    $output = "$prefix$indentSpaces$($statusConfig.Bracket) $Message"

    if ($NoNewline) {
        Write-Host $output -NoNewline -ForegroundColor $statusConfig.Color
    }
    else {
        Write-Host "$indentSpaces$($statusConfig.Bracket) " -NoNewline -ForegroundColor $statusConfig.Color
        Write-Host $Message -ForegroundColor $statusConfig.Color
    }
}

#endregion Public Functions

# Export des fonctions publiques
Export-ModuleMember -Function @(
    'Write-ConsoleBanner'
    'Write-SummaryBox'
    'Write-SelectionBox'
    'Write-MenuBox'
    'Write-Box'
    'Write-EnterpriseAppsSelectionBox'
    'Write-UnifiedSelectionBox'
    'Write-CollectionModeBox'
    'Write-CategorySelectionMenu'
    'Update-CategorySelection'
    'Write-Status'
)
