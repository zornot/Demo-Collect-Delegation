# [~] FEAT-012 - Export HTML des delegations - Effort: 2h

## PROBLEME

L'export actuel est uniquement au format CSV, utile pour l'analyse mais peu lisible pour un rapport final. Un export HTML avec mise en forme permettrait de partager un rapport visuel directement consultable dans un navigateur.

## LOCALISATION

- Fichier : Get-ExchangeDelegation.ps1
- Zone : Parametres (L86-130) + Fin de traitement (L1150+)
- Module : Script principal

## OBJECTIF

Ajouter un parametre `-HtmlReport` qui genere un fichier HTML stylise en complement du CSV, utilisable comme rapport final.

---

## DESIGN

### Objectif

Permettre la generation d'un rapport HTML autonome (CSS integre) des delegations collectees, consultable directement dans un navigateur sans dependance externe.

### Architecture

- **Module concerne** : Script principal (pas de nouveau module)
- **Dependances** : ConvertTo-Html (cmdlet native PowerShell)
- **Impact** : Get-ExchangeDelegation.ps1 uniquement
- **Pattern** : Generation post-traitement (apres boucle principale)

### Interface

```powershell
# Nouveau parametre
param(
    # ... parametres existants ...

    [Parameter(HelpMessage = "Genere un rapport HTML en plus du CSV")]
    [switch]$HtmlReport
)

# Exemple d'utilisation
.\Get-ExchangeDelegation.ps1 -OutputPath "C:\Reports" -HtmlReport
# Produit : Delegations_2025-12-23.csv + Delegations_2025-12-23.html
```

### Structure HTML

```html
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Rapport Delegations Exchange - {Date}</title>
    <style>
        /* CSS integre pour autonomie */
        body { font-family: Segoe UI, Arial, sans-serif; margin: 20px; }
        h1 { color: #0078D4; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th { background-color: #0078D4; color: white; padding: 10px; text-align: left; }
        td { border: 1px solid #ddd; padding: 8px; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        tr:hover { background-color: #e6f3ff; }
        .orphan { background-color: #fff3cd; }
        .summary { background-color: #f0f0f0; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>Rapport Delegations Exchange</h1>
    <div class="summary">
        <p><strong>Date :</strong> {Date}</p>
        <p><strong>Mailboxes traitees :</strong> {Count}</p>
        <p><strong>Delegations trouvees :</strong> {Total}</p>
    </div>
    <table>...</table>
</body>
</html>
```

### Tests Attendus

- [ ] Cas nominal : -HtmlReport genere fichier .html valide
- [ ] Cas sans delegations : HTML avec message "Aucune delegation trouvee"
- [ ] Cas orphelins : Lignes orphelines stylees differemment (.orphan)
- [ ] Validation : HTML valide (structure DOCTYPE, charset)

### Considerations

- **Performance** : Generation en fin de traitement uniquement (pas de streaming)
- **Taille** : Pour >10000 delegations, ajouter pagination ou warning
- **Compatibilite** : HTML5 standard, pas de JavaScript requis

---

## IMPLEMENTATION

### Etape 1 : Ajouter parametre -HtmlReport - 15min

Fichier : Get-ExchangeDelegation.ps1

AVANT (L130 environ, apres dernier parametre) :
```powershell
    [Parameter(HelpMessage = "Inclut les mailboxes inactives dans la collecte")]
    [switch]$IncludeInactive
)
```

APRES :
```powershell
    [Parameter(HelpMessage = "Inclut les mailboxes inactives dans la collecte")]
    [switch]$IncludeInactive,

    [Parameter(HelpMessage = "Genere un rapport HTML en plus du CSV")]
    [switch]$HtmlReport
)
```

### Etape 2 : Creer fonction New-HtmlReport - 45min

Fichier : Get-ExchangeDelegation.ps1

Ajouter fonction dans la region "Helper Functions" :

```powershell
function New-HtmlReport {
    <#
    .SYNOPSIS
        Genere un rapport HTML des delegations.
    .DESCRIPTION
        Cree un fichier HTML autonome avec CSS integre pour affichage des delegations.
    .PARAMETER CsvPath
        Chemin du fichier CSV source.
    .PARAMETER OutputPath
        Chemin du fichier HTML a generer.
    .PARAMETER Title
        Titre du rapport.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$CsvPath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath,

        [Parameter()]
        [string]$Title = "Rapport Delegations Exchange"
    )

    if (-not (Test-Path $CsvPath)) {
        Write-Log -Message "CSV introuvable pour generation HTML: $CsvPath" -Level Warning
        return $null
    }

    $delegations = Import-Csv -Path $CsvPath -Encoding UTF8
    $delegationCount = $delegations.Count

    $css = @"
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 20px; background: #fafafa; }
        h1 { color: #0078D4; border-bottom: 2px solid #0078D4; padding-bottom: 10px; }
        .summary { background: #fff; padding: 15px; border-radius: 5px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); margin-bottom: 20px; }
        .summary p { margin: 5px 0; }
        table { border-collapse: collapse; width: 100%; background: #fff; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
        th { background: #0078D4; color: #fff; padding: 12px 10px; text-align: left; font-weight: 600; }
        td { border-bottom: 1px solid #e0e0e0; padding: 10px; }
        tr:hover { background: #e6f3ff; }
        .orphan { background: #fff3cd; }
        .footer { margin-top: 20px; color: #666; font-size: 0.9em; }
"@

    $summaryHtml = @"
    <div class="summary">
        <p><strong>Date de generation :</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm')</p>
        <p><strong>Delegations exportees :</strong> $delegationCount</p>
    </div>
"@

    if ($delegationCount -eq 0) {
        $tableHtml = "<p>Aucune delegation trouvee.</p>"
    }
    else {
        $tableHtml = $delegations | ConvertTo-Html -Fragment |
            ForEach-Object {
                if ($_ -match 'True</td>$' -and $_ -match 'IsOrphan') {
                    $_ -replace '<tr>', '<tr class="orphan">'
                }
                else {
                    $_
                }
            } | Out-String
    }

    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$Title - $(Get-Date -Format 'yyyy-MM-dd')</title>
    <style>$css</style>
</head>
<body>
    <h1>$Title</h1>
    $summaryHtml
    $tableHtml
    <div class="footer">
        <p>Genere par Get-ExchangeDelegation.ps1</p>
    </div>
</body>
</html>
"@

    $html | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Log -Message "Rapport HTML genere: $OutputPath" -Level Info

    return $OutputPath
}
```

### Etape 3 : Appeler New-HtmlReport en fin de traitement - 15min

Fichier : Get-ExchangeDelegation.ps1

Localiser la section finale (apres la boucle principale, avant Write-Box final).

AVANT (zone ~L1180) :
```powershell
# Affichage du resume final
$summaryData = [ordered]@{
```

APRES :
```powershell
# Generation rapport HTML si demande
if ($HtmlReport) {
    $htmlPath = $exportFilePath -replace '\.csv$', '.html'
    $htmlResult = New-HtmlReport -CsvPath $exportFilePath -OutputPath $htmlPath
    if ($htmlResult) {
        Write-Status -Message "Rapport HTML genere" -Type Success -IndentLevel 1
    }
}

# Affichage du resume final
$summaryData = [ordered]@{
```

---

## VALIDATION

### Criteres d'Acceptation

- [ ] Parametre -HtmlReport disponible dans l'aide (Get-Help)
- [ ] Fichier .html genere au meme emplacement que le .csv
- [ ] HTML valide et lisible dans navigateur
- [ ] Lignes orphelines (IsOrphan=True) stylees en jaune
- [ ] CSS integre (pas de fichier externe)
- [ ] Pas de regression sur export CSV existant

### Tests Manuels

```powershell
# Test basique
.\Get-ExchangeDelegation.ps1 -OutputPath "C:\Test" -HtmlReport -Verbose

# Verifier les fichiers generes
Get-ChildItem "C:\Test\Delegations_*.html"

# Ouvrir dans navigateur
Start-Process "C:\Test\Delegations_2025-12-23.html"
```

## CHECKLIST

- [ ] Code AVANT = code reel
- [ ] Tests passent
- [ ] Code review

Labels : feat ~ export html

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | # (apres gh issue create) |
| Statut | DRAFT |
| Branche | feature/FEAT-012-export-html |
