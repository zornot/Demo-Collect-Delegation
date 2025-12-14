#Requires -Version 7.2
<#
.SYNOPSIS
    Hook PreToolUse pour securite: fichiers sensibles et commandes destructives
.DESCRIPTION
    Intercepte les appels Read/Edit/Write et Bash pour:
    - Bloquer l'acces aux fichiers sensibles (credentials, .env, etc.)
    - Bloquer les commandes destructives hors repertoires autorises
.NOTES
    Exit codes:
    - 0 : Autoriser l'operation
    - 2 : Bloquer l'operation
#>

[CmdletBinding()]
param()

# Lire l'input JSON depuis stdin
$inputJson = [Console]::In.ReadToEnd()
$hookInput = $inputJson | ConvertFrom-Json -ErrorAction SilentlyContinue

if (-not $hookInput) {
    exit 0  # Pas d'input, autoriser par defaut
}

$toolName = $hookInput.tool_name
$toolInput = $hookInput.tool_input

# ============================================
# VALIDATION FICHIERS SENSIBLES (Read/Edit/Write)
# ============================================

if ($toolName -in @('Read', 'Write', 'Edit')) {
    $filePath = $toolInput.file_path

    if ($filePath) {
        # Patterns de fichiers bloques (sensibles)
        $blockedPatterns = @(
            '*Config/Settings.json',
            '*Config\Settings.json',
            '*.key',
            '*.pem',
            '*.pfx',
            '*.env',
            '*.env.*',
            '*credentials*',
            '*secrets*',
            '*.credentials'
        )

        foreach ($pattern in $blockedPatterns) {
            if ($filePath -like $pattern) {
                @{
                    decision = 'block'
                    reason   = "Fichier sensible bloque: $pattern"
                } | ConvertTo-Json -Compress
                exit 2
            }
        }
    }
}

# ============================================
# VALIDATION COMMANDES BASH DESTRUCTIVES
# ============================================

if ($toolName -eq 'Bash') {
    $command = $toolInput.command

    if ($command) {
        # Patterns de commandes destructives
        $destructivePatterns = @(
            'Remove-Item.*-Recurse',
            'Remove-Item.*-Force',
            'rm\s+-[rf]',
            'del\s+/[sq]',
            'rmdir\s+/s',
            'rd\s+/s'
        )

        # Verifier si commande destructive
        $isDestructive = $false
        foreach ($pattern in $destructivePatterns) {
            if ($command -match $pattern) {
                $isDestructive = $true
                break
            }
        }

        if ($isDestructive) {
            # Extraire le chemin cible de la commande
            $targetPath = $null

            # Pattern pour Remove-Item -Path 'xxx' ou Remove-Item 'xxx'
            if ($command -match 'Remove-Item\s+(?:-Path\s+)?["'']?([^"''\s]+)') {
                $targetPath = $Matches[1]
            }
            # Pattern pour rm/del/rmdir avec chemin
            elseif ($command -match '(?:rm|del|rmdir|rd)\s+[^|;]*?([A-Za-z]:[^\s"''|;]+|\.?\.?[/\\][^\s"''|;]+)') {
                $targetPath = $Matches[1]
            }

            if ($targetPath) {
                # Repertoire de travail du projet
                $projectRoot = $hookInput.cwd

                # Resoudre le chemin complet
                $fullPath = try {
                    if ([System.IO.Path]::IsPathRooted($targetPath)) {
                        [System.IO.Path]::GetFullPath($targetPath)
                    }
                    else {
                        [System.IO.Path]::GetFullPath((Join-Path $projectRoot $targetPath))
                    }
                }
                catch {
                    $targetPath
                }

                # Repertoires autorises pour suppression (relatifs au projet)
                $safeDirectories = @(
                    '.temp',
                    'Logs',
                    'Output',
                    'Tests/Coverage',
                    'Tests\Coverage'
                )

                # Verifier si dans repertoire safe
                $isSafe = $false
                foreach ($safeDir in $safeDirectories) {
                    $safePath = Join-Path $projectRoot $safeDir
                    if ($fullPath.StartsWith($safePath, [StringComparison]::OrdinalIgnoreCase)) {
                        $isSafe = $true
                        break
                    }
                }

                if (-not $isSafe) {
                    # Verifier si hors du projet
                    $isOutsideProject = -not $fullPath.StartsWith($projectRoot, [StringComparison]::OrdinalIgnoreCase)

                    # Verifier si racine de lecteur (C:\, D:\, etc.)
                    $isRootPath = $fullPath -match '^[A-Za-z]:\\?$'

                    # Verifier si repertoire systeme Windows
                    $systemPaths = @(
                        $env:SystemRoot,
                        $env:ProgramFiles,
                        ${env:ProgramFiles(x86)},
                        $env:ProgramData
                    ) | Where-Object { $_ }

                    $isSystemPath = $false
                    foreach ($sysPath in $systemPaths) {
                        if ($fullPath.StartsWith($sysPath, [StringComparison]::OrdinalIgnoreCase)) {
                            $isSystemPath = $true
                            break
                        }
                    }

                    # Bloquer si dangereux
                    if ($isOutsideProject -or $isRootPath -or $isSystemPath) {
                        $reason = if ($isRootPath) {
                            "Suppression racine de lecteur bloquee"
                        }
                        elseif ($isSystemPath) {
                            "Suppression repertoire systeme bloquee"
                        }
                        else {
                            "Suppression hors du projet bloquee"
                        }

                        @{
                            decision = 'block'
                            reason   = "$reason`: $fullPath"
                        } | ConvertTo-Json -Compress
                        exit 2
                    }
                }
            }
        }
    }
}

# Autoriser par defaut
exit 0
