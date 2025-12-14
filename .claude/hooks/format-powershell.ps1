#Requires -Version 7.2
<#
.SYNOPSIS
    Hook PostToolUse pour formater les fichiers PowerShell
.DESCRIPTION
    Applique PSScriptAnalyzer Invoke-Formatter sur les fichiers .ps1, .psm1, .psd1.
    Ignore silencieusement les autres types de fichiers.
.NOTES
    Optimisation: Verifie l'extension AVANT de lancer le formatage.
    Exit codes:
    - 0 : Succes (ou fichier non-PowerShell ignore)
#>

[CmdletBinding()]
param()

# Lire l'input JSON depuis stdin
$inputJson = [Console]::In.ReadToEnd()
$hookInput = $inputJson | ConvertFrom-Json -ErrorAction SilentlyContinue

if (-not $hookInput) {
    exit 0
}

# Extraire le chemin du fichier
$filePath = $hookInput.tool_input.file_path

if (-not $filePath) {
    exit 0
}

# Verifier l'extension - sortie immediate si pas PowerShell
if ($filePath -notmatch '\.(ps1|psm1|psd1)$') {
    exit 0
}

# Verifier que le fichier existe
if (-not (Test-Path -Path $filePath -PathType Leaf)) {
    exit 0
}

# Formater le fichier PowerShell
try {
    $content = Get-Content -Path $filePath -Raw -ErrorAction Stop

    # Ne pas formater si vide
    if ([string]::IsNullOrWhiteSpace($content)) {
        exit 0
    }

    $formatted = Invoke-Formatter -ScriptDefinition $content -ErrorAction Stop

    # Ne reecrire que si le contenu a change
    if ($formatted -ne $content) {
        Set-Content -Path $filePath -Value $formatted -NoNewline -ErrorAction Stop
    }
}
catch {
    # Silencieux en cas d'erreur (fichier peut etre syntaxiquement invalide)
    # Le formatage echouera mais ce n'est pas bloquant
}

exit 0
