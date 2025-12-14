# Symboles UI PowerShell

## Accessibilite et conventions

### Pourquoi les brackets

Les brackets `[+][-][!][i][>][?]` assurent la lisibilite **sans couleur** :
- Utilisateurs daltoniens
- Redirection vers fichiers logs
- Pipelines CI/CD
- Screen readers

La couleur est un **renfort visuel**, pas le porteur de sens.

### Convention NO_COLOR

Respecter la convention [no-color.org](https://no-color.org/) :

```powershell
# Detecter si couleurs desactivees
$script:UseColor = -not $env:NO_COLOR -and $Host.UI.SupportsVirtualTerminal

function Write-Status {
    param([string]$Type, [string]$Message)

    $bracket = switch ($Type) {
        'Success' { '[+]' }
        'Error'   { '[-]' }
        'Warning' { '[!]' }
        'Info'    { '[i]' }
        'Action'  { '[>]' }
        'WhatIf'  { '[?]' }
    }

    if ($script:UseColor) {
        $color = switch ($Type) {
            'Success' { 'Green' }
            'Error'   { 'Red' }
            'Warning' { 'Yellow' }
            'Info'    { 'Cyan' }
            'Action'  { 'White' }
            'WhatIf'  { 'DarkGray' }
        }
        Write-Host "$bracket " -NoNewline -ForegroundColor $color
        Write-Host $Message
    } else {
        Write-Host "$bracket $Message"
    }
}
```

---

## Interdictions (MUST)

### Symboles interdits - JAMAIS utiliser
```powershell
# [-] Emoji et symboles Unicode pour status
Write-Host "Succes"      # [>] Utiliser [+]
Write-Host "Erreur"      # [>] Utiliser [-]
Write-Host "Warning"     # [>] Utiliser [!]
Write-Host "Info"        # [>] Utiliser [i]
Write-Host "Item"        # [>] Utiliser [>]

# [-] Autres emoji interdits
# 🤖 🔧 📁 📝 ⚙️ 🚀 💡 ⬆️ ⬇️ ➡️
```

### Table de conversion obligatoire
| Interdit | Remplacement |
|----------|--------------|
| `✓` `✔` | `[+]` |
| `✗` `✘` `×` | `[-]` |
| `⚠` `⚠️` | `[!]` |
| `ℹ` `ℹ️` | `[i]` |
| `•` `▸` `▶` `►` | `[>]` |
| `❓` `?` (emoji) | `[?]` |
| Tout emoji | Bracket correspondant ou rien |

---

## Status Messages (Brackets ASCII)

| Bracket | Couleur | Usage | Exemple |
|---------|---------|-------|---------|
| `[+]` | Green | Succès, création, ajout | `[+] Fichier créé` |
| `[-]` | Red | Erreur, échec, suppression | `[-] Connexion échouée` |
| `[!]` | Yellow | Warning, attention | `[!] Certificat expire bientôt` |
| `[i]` | Cyan | Info, titre | `[i] Traitement en cours` |
| `[>]` | White | Action, section, étape | `[>] Étape 1: Validation` |
| `[?]` | DarkGray | WhatIf, preview, question | `[?] Supprimerait: fichier.txt` |

## Patterns d'affichage

```powershell
# Succès
Write-Host "[+] " -NoNewline -ForegroundColor Green
Write-Host "Opération terminée" -ForegroundColor Green

# Erreur
Write-Host "[-] " -NoNewline -ForegroundColor Red
Write-Host "Échec: $($_.Exception.Message)" -ForegroundColor Red

# Warning
Write-Host "[!] " -NoNewline -ForegroundColor Yellow
Write-Host "Attention: quota presque atteint" -ForegroundColor Yellow

# Info
Write-Host "[i] " -NoNewline -ForegroundColor Cyan
Write-Host "Traitement de 150 éléments" -ForegroundColor Cyan

# Action/Section
Write-Host "[>] " -NoNewline -ForegroundColor White
Write-Host "Connexion au serveur Exchange" -ForegroundColor White

# WhatIf/Preview
Write-Host "[?] " -NoNewline -ForegroundColor DarkGray
Write-Host "Supprimerait: $filePath" -ForegroundColor DarkGray
```

## Box Drawing (Unicode - Conserver)

### Caractères cadres
| Caractère | Nom | Usage |
|-----------|-----|-------|
| `┌` | Coin haut-gauche | Début cadre |
| `┐` | Coin haut-droit | Fin ligne haute |
| `└` | Coin bas-gauche | Début ligne basse |
| `┘` | Coin bas-droit | Fin cadre |
| `─` | Ligne horizontale | Bordure haut/bas |
| `│` | Ligne verticale | Bordure gauche/droite |

### Bannière standard
```powershell
$width = 60
Write-Host ("┌" + ("─" * $width) + "┐") -ForegroundColor DarkGray
Write-Host "│  " -NoNewline -ForegroundColor DarkGray
Write-Host "TITRE" -NoNewline -ForegroundColor Cyan
Write-Host (" " * ($width - 5)) -NoNewline
Write-Host "│" -ForegroundColor DarkGray
Write-Host ("└" + ("─" * $width) + "┘") -ForegroundColor DarkGray
```

### Bannière avec version
```powershell
function Write-Banner {
    param(
        [string]$Title,
        [string]$Version,
        [int]$Width = 60
    )

    $innerWidth = $Width - 2
    Write-Host ("┌" + ("─" * $innerWidth) + "┐") -ForegroundColor DarkGray

    # Ligne titre
    $titleLine = "  $Title"
    $padding = $innerWidth - $titleLine.Length
    Write-Host "│" -NoNewline -ForegroundColor DarkGray
    Write-Host $titleLine -NoNewline -ForegroundColor Cyan
    Write-Host (" " * $padding) -NoNewline
    Write-Host "│" -ForegroundColor DarkGray

    # Ligne version
    $versionLine = "  Version $Version"
    $padding = $innerWidth - $versionLine.Length
    Write-Host "│" -NoNewline -ForegroundColor DarkGray
    Write-Host $versionLine -NoNewline -ForegroundColor DarkGray
    Write-Host (" " * $padding) -NoNewline
    Write-Host "│" -ForegroundColor DarkGray

    Write-Host ("└" + ("─" * $innerWidth) + "┘") -ForegroundColor DarkGray
}
```

### Fallback ASCII (console legacy)

Windows Terminal supporte Unicode. Pour compatibilite avec consoles legacy (conhost.exe) :

```powershell
# Detection Windows Terminal
$script:IsWindowsTerminal = $null -ne $env:WT_SESSION

# Caracteres adaptatifs
$script:BoxChars = if ($script:IsWindowsTerminal) {
    @{
        TopLeft     = '┌'
        TopRight    = '┐'
        BottomLeft  = '└'
        BottomRight = '┘'
        Horizontal  = '─'
        Vertical    = '│'
    }
} else {
    @{
        TopLeft     = '+'
        TopRight    = '+'
        BottomLeft  = '+'
        BottomRight = '+'
        Horizontal  = '-'
        Vertical    = '|'
    }
}

# Usage
$top = $script:BoxChars.TopLeft + ($script:BoxChars.Horizontal * 58) + $script:BoxChars.TopRight
Write-Host $top -ForegroundColor DarkGray
```

**Resultat Windows Terminal :**
```
┌──────────────────────────────────────────────────────────┐
│  TITRE                                                   │
└──────────────────────────────────────────────────────────┘
```

**Resultat console legacy :**
```
+----------------------------------------------------------+
|  TITRE                                                   |
+----------------------------------------------------------+
```

## Couleurs sémantiques

| Couleur | Usage |
|---------|-------|
| `Green` | Succès, création, validation |
| `Red` | Erreur, échec, suppression |
| `Yellow` | Warning, attention, deprecated |
| `Cyan` | Info, titre, mise en avant |
| `White` | Texte principal, actions |
| `DarkGray` | Labels, secondaire, preview |

## Indentation standard

```powershell
# Niveau 0 - Bannière/Titre principal
Write-Host "[i] Démarrage du script" -ForegroundColor Cyan

# Niveau 1 - Sections (2 espaces)
Write-Host "  [>] Section 1: Validation" -ForegroundColor White

# Niveau 2 - Détails (4 espaces)
Write-Host "    [+] Fichier config trouvé" -ForegroundColor Green
Write-Host "    [+] Connexion établie" -ForegroundColor Green

# Niveau 3 - Sous-détails (6 espaces)
Write-Host "      [i] 150 éléments à traiter" -ForegroundColor Cyan
```

## Progress inline (grandes boucles)

```powershell
$total = $items.Count
$current = 0

foreach ($item in $items) {
    $current++
    
    # Afficher tous les 100 éléments
    if ($current % 100 -eq 0 -or $current -eq $total) {
        $percent = [math]::Round(($current / $total) * 100)
        Write-Host "`r  [>] Progression: $current/$total ($percent%)" -NoNewline -ForegroundColor White
    }
    
    # Traitement...
}
Write-Host ""  # Nouvelle ligne finale
```
