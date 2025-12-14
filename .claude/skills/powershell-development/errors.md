# Gestion des Erreurs PowerShell

## Terminating vs Non-Terminating (MUST)

PowerShell distingue deux types d'erreurs :

| Type | Comportement | Catch | Exemple |
|------|--------------|-------|---------|
| **Terminating** | Arrete l'execution | Oui | `throw`, division par zero, .NET exceptions |
| **Non-Terminating** | Continue l'execution | Non* | `Get-Item` fichier inexistant, `Get-ADUser` introuvable |

*Les erreurs non-terminantes ne sont **pas** interceptees par try-catch par defaut.

```powershell
# [-] try-catch INEFFICACE sur erreur non-terminante
try {
    Get-Item "C:\fichier-inexistant.txt"  # Erreur non-terminante
    Write-Host "Cette ligne s'execute quand meme!"
} catch {
    Write-Host "Ce catch n'est JAMAIS atteint"
}

# [+] Convertir en terminante avec -ErrorAction Stop
try {
    Get-Item "C:\fichier-inexistant.txt" -ErrorAction Stop
} catch {
    Write-Host "Maintenant le catch fonctionne"
}
```

## -ErrorAction Stop (MUST)

Utiliser `-ErrorAction Stop` sur les cmdlets dans un bloc try pour garantir l'interception.

```powershell
# [+] Pattern recommande
try {
    $user = Get-ADUser -Identity $userId -ErrorAction Stop
    $mailbox = Get-EXOMailbox -Identity $userId -ErrorAction Stop
    Set-ADUser -Identity $userId -Department $dept -ErrorAction Stop
} catch {
    Write-Error "Operation echouee: $($_.Exception.Message)"
}

# [+] Alternative : $ErrorActionPreference en debut de scope
$ErrorActionPreference = 'Stop'
try {
    Get-ADUser -Identity $userId
    Get-EXOMailbox -Identity $userId
} catch {
    # Toutes les erreurs sont maintenant interceptees
}
```

Quand utiliser :
- **-ErrorAction Stop** : Sur chaque cmdlet critique dans try-catch
- **$ErrorActionPreference = 'Stop'** : En debut de fonction pour tout intercepter

## Pattern Try-Catch-Finally
```powershell
function Invoke-SafeOperation {
    [CmdletBinding()]
    param([string]$ResourcePath)
    
    $stream = $null
    
    try {
        $stream = [System.IO.File]::OpenRead($ResourcePath)
        $result = Process-Data -Stream $stream
        return $result
        
    } catch [System.IO.FileNotFoundException] {
        Write-Error "File not found: $ResourcePath"
        throw
        
    } catch [System.UnauthorizedAccessException] {
        Write-Error "Access denied: $ResourcePath"
        throw
        
    } catch {
        Write-Error "Unexpected: $($_.Exception.Message)"
        Write-Verbose "Stack: $($_.ScriptStackTrace)"
        throw
        
    } finally {
        # TOUJOURS exécuté
        if ($stream) {
            $stream.Close()
            $stream.Dispose()
        }
    }
}
```

## Exceptions personnalisées
```powershell
class ValidationException : System.Exception {
    [string]$PropertyName
    [object]$InvalidValue
    
    ValidationException([string]$prop, [object]$val, [string]$msg) : base($msg) {
        $this.PropertyName = $prop
        $this.InvalidValue = $val
    }
}

class ResourceNotFoundException : System.Exception {
    [string]$ResourceId
    [string]$ResourceType
    
    ResourceNotFoundException([string]$type, [string]$id) : base("$type not found: $id") {
        $this.ResourceType = $type
        $this.ResourceId = $id
    }
}

# Utilisation
throw [ValidationException]::new('Email', $email, 'Invalid email format')
throw [ResourceNotFoundException]::new('Customer', $customerId)
```

## Catch exceptions custom
```powershell
try {
    $customer = Get-CustomerById -Id "ABC"
} catch [ValidationException] {
    Write-Error "Validation: $($_.Exception.PropertyName) - $($_.Exception.Message)"
} catch [ResourceNotFoundException] {
    Write-Error "Not found: $($_.Exception.ResourceType) $($_.Exception.ResourceId)"
} catch {
    Write-Error "Unexpected: $($_.Exception.Message)"
}
```

## Erreurs non-terminantes (continuer le traitement)
```powershell
function Process-Items {
    param([array]$Items)
    
    $errors = @()
    
    foreach ($item in $Items) {
        try {
            $ErrorActionPreference = 'Stop'
            Process-SingleItem -Item $item
        } catch {
            $errors += [PSCustomObject]@{
                Item = $item
                Error = $_.Exception.Message
            }
            Write-Warning "Failed: $($item.Id)"
            # Continue avec l'item suivant
        }
    }
    
    if ($errors.Count -gt 0) {
        Write-Warning "$($errors.Count) errors occurred"
    }
}
```

## Sauvegarde/Restauration préférences
```powershell
$savedPrefs = @{
    Error = $ErrorActionPreference
    Warning = $WarningPreference
}

try {
    $ErrorActionPreference = 'SilentlyContinue'
    # Opération silencieuse
} finally {
    $ErrorActionPreference = $savedPrefs.Error
    $WarningPreference = $savedPrefs.Warning
}
```

## Validation Syntaxe

Valider la syntaxe PowerShell avant commit :

```powershell
function Test-PowerShellSyntax {
    <#
    .SYNOPSIS
        Valide la syntaxe des fichiers PowerShell
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $files = Get-ChildItem -Path $Path -Filter *.ps1 -Recurse
    $hasErrors = $false

    foreach ($file in $files) {
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile(
            $file.FullName,
            [ref]$null,
            [ref]$errors
        )

        if ($errors) {
            $hasErrors = $true
            Write-Host "[-] $($file.Name):" -ForegroundColor Red
            $errors | ForEach-Object {
                Write-Host "    L$($_.Extent.StartLineNumber): $($_.Message)" -ForegroundColor Red
            }
        }
    }

    if (-not $hasErrors) {
        Write-Host "[+] Syntaxe valide" -ForegroundColor Green
    }

    return -not $hasErrors
}

# Usage
Test-PowerShellSyntax -Path "./Modules"
```

## Analyse Statique (PSScriptAnalyzer)

```powershell
# Installation
Install-Module -Name PSScriptAnalyzer -Force

# Analyse
Invoke-ScriptAnalyzer -Path ./Modules -Recurse

# Avec severite
Invoke-ScriptAnalyzer -Path ./Modules -Recurse -Severity Warning, Error
```
