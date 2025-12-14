# Paramètres & Validation PowerShell

## Déclaration standard
```powershell
function Get-ProductInfo {
    [CmdletBinding(DefaultParameterSetName='ById')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(
            Mandatory=$true,
            Position=0,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            HelpMessage='ID du produit'
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('Id', 'ProductId')]
        [string]$ProductIdentifier,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Basic', 'Standard', 'Premium')]
        [string]$DetailLevel = 'Standard',
        
        [Parameter(Mandatory=$false)]
        [ValidateRange(1, 100)]
        [int]$MaxResults = 10,
        
        [Parameter(Mandatory=$false)]
        [switch]$IncludeDiscontinued
    )
    
    begin { }
    process { }
    end { }
}
```

## Validations disponibles

### ValidateSet - Liste de valeurs
```powershell
[ValidateSet('Dev', 'Test', 'Prod')]
[string]$Environment
```

### ValidateRange - Plage numérique
```powershell
[ValidateRange(0, 100)]
[int]$Percentage
```

### ValidateLength - Longueur string
```powershell
[ValidateLength(5, 50)]
[string]$Username
```

### ValidateCount - Nombre éléments array
```powershell
[ValidateCount(1, 10)]
[string[]]$Categories
```

### ValidatePattern - Regex
```powershell
[ValidatePattern('^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')]
[string]$Email

[ValidatePattern('^C\d{6}$')]
[string]$CustomerId
```

### ValidateScript - Logique custom
```powershell
[ValidateScript({
    if (-not (Test-Path $_)) {
        throw "Path does not exist: $_"
    }
    return $true
})]
[string]$FilePath
```

### ValidateScript avec ErrorMessage (SHOULD)

L'attribut `ErrorMessage` personnalise le message d'erreur pour l'utilisateur.

```powershell
# [+] Message explicite avec ErrorMessage
[ValidateScript(
    { Test-Path $_ -PathType Container },
    ErrorMessage = "Le dossier '{0}' n'existe pas ou n'est pas accessible"
)]
[string]$OutputFolder

[ValidateScript(
    { $_ -match '^[A-Z]{2}\d{4}$' },
    ErrorMessage = "Format attendu: 2 lettres + 4 chiffres (ex: AB1234), recu: '{0}'"
)]
[string]$ProductCode

# [-] Sans ErrorMessage - message technique peu clair
[ValidateScript({ Test-Path $_ -PathType Container })]
[string]$OutputFolder
# Erreur: "Cannot validate argument on parameter 'OutputFolder'..."
```

Cas d'usage :
- Validation de chemins avec message clair
- Formats specifiques (codes, references)
- Validations metier complexes

### ValidateNotNullOrEmpty
```powershell
[ValidateNotNullOrEmpty()]
[string]$RequiredValue
```

## Parameter Sets
```powershell
function Get-Customer {
    [CmdletBinding(DefaultParameterSetName='ById')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='ById')]
        [string]$CustomerId,
        
        [Parameter(Mandatory=$true, ParameterSetName='ByEmail')]
        [string]$Email,
        
        [Parameter(Mandatory=$true, ParameterSetName='ByName')]
        [string]$LastName,
        
        # Commun à tous les sets
        [Parameter(Mandatory=$false)]
        [switch]$IncludeOrders
    )
    
    switch ($PSCmdlet.ParameterSetName) {
        'ById'    { <# ... #> }
        'ByEmail' { <# ... #> }
        'ByName'  { <# ... #> }
    }
}
```

## Validation dynamique dans BEGIN
```powershell
begin {
    $validCategories = @('Sales', 'Marketing', 'Finance')

    if ($Categories) {
        $invalid = $Categories | Where-Object { $_ -notin $validCategories }
        if ($invalid) {
            throw "Invalid categories: $($invalid -join ', ')"
        }
    }
}
```

## Template Fonction Complete (begin/process/end)

```powershell
function Verb-Noun {
    <#
    .SYNOPSIS
        Description courte (1 ligne).

    .DESCRIPTION
        Description detaillee du comportement.
        Plusieurs lignes si necessaire.

    .PARAMETER Param1
        Description du parametre.

    .OUTPUTS
        [Type] Description de la sortie.

    .EXAMPLE
        Verb-Noun -Param1 "valeur"
        Description de l'exemple.

    .NOTES
        Version: 1.0.0
        Date: YYYY-MM-DD
    #>
    [CmdletBinding()]
    [OutputType([TypeRetour])]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$Param1,

        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$Param2 = 10
    )

    begin {
        # Initialisation (execute une seule fois)
        # - Validation globale
        # - Initialisation collections
        # - Connexions
        $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    }

    process {
        # Traitement principal (execute pour chaque element du pipeline)
        # - Logique metier
        # - Traitement item par item
        try {
            $processedItem = [PSCustomObject]@{
                Input  = $Param1
                Output = "Traite"
            }
            $results.Add($processedItem)
        }
        catch {
            Write-Error "Erreur traitement $Param1 : $($_.Exception.Message)"
            throw
        }
    }

    end {
        # Finalisation (execute une seule fois)
        # - Aggregation resultats
        # - Nettoyage ressources
        # - Deconnexions
        return $results
    }
}
```

### Quand utiliser begin/process/end

| Bloc | Usage |
|------|-------|
| `begin` | Initialisation, validation globale, connexions |
| `process` | Traitement de chaque element du pipeline |
| `end` | Aggregation, nettoyage, deconnexions |

Si la fonction ne supporte pas le pipeline, `process` seul suffit.
