#Requires -Version 7.2
<#
.SYNOPSIS
    Hook PostToolUse pour analyser les fichiers PowerShell avec PSScriptAnalyzer
.DESCRIPTION
    Lance Invoke-ScriptAnalyzer sur les fichiers .ps1, .psm1, .psd1 apres Write/Edit.
    Affiche les warnings/errors pour correction immediate.
.NOTES
    Ignore silencieusement les fichiers non-PowerShell.
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

# Analyser le fichier PowerShell
try {
    $results = Invoke-ScriptAnalyzer -Path $filePath -Severity Warning, Error -ErrorAction Stop

    if ($results) {
        Write-Host ""
        Write-Host "[!] PSScriptAnalyzer - $($results.Count) finding(s):" -ForegroundColor Yellow
        foreach ($result in $results) {
            $color = if ($result.Severity -eq 'Error') { 'Red' } else { 'Yellow' }
            Write-Host "    [$($result.Severity)] L$($result.Line): $($result.RuleName)" -ForegroundColor $color
            Write-Host "    $($result.Message)" -ForegroundColor DarkGray
        }
        Write-Host ""
    }
}
catch {
    # Module PSScriptAnalyzer peut ne pas etre installe
    # Silencieux - ne pas bloquer le workflow
}

exit 0
