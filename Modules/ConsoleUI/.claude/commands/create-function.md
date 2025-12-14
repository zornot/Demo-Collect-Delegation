---
description: Cree une nouvelle fonction PowerShell avec CmdletBinding
argument-hint: Verb-Noun
allowed-tools: Read, Write, Bash
---

Creer une fonction PowerShell nommee `$ARGUMENTS` en suivant les standards du projet.

## Workflow TDD (OBLIGATOIRE)

Cette commande suit le cycle TDD. L'ordre d'execution est :

```
1. TESTS D'ABORD  → Verifier si tests existent, sinon proposer /project:create-test
2. IMPLEMENTATION → Creer la fonction (cette commande)
3. VALIDATION     → Executer les tests pour verifier
```

### Avant de creer la fonction

Verifier si le fichier de tests existe :
- `Tests/Unit/$ARGUMENTS.Tests.ps1`

**Si les tests n'existent PAS** :
> [!] Workflow TDD : Les tests doivent etre crees AVANT l'implementation.
> Veux-tu que je lance `/project:create-test $ARGUMENTS` d'abord ?

**Si les tests existent** : Continuer avec l'implementation.

### Apres creation de la fonction

Executer automatiquement les tests :
```powershell
Invoke-Pester -Path "./Tests/Unit/$ARGUMENTS.Tests.ps1" -Output Detailed
```

Afficher le resultat :
- `[+] Tests passent` → Implementation correcte
- `[-] Tests echouent` → Ajuster l'implementation

## References Requises

Lire ces fichiers avant de creer la fonction :

1. `.claude/rules/powershell/naming.md` - Nommage Verb-Noun, nouns SINGULIERS
2. `.claude/rules/powershell/parameters.md` - Validation des parametres

## Regles de Nommage

1. **Verbe** : Doit provenir de la liste approuvee `Get-Verb`
2. **Nom** : Doit etre SINGULIER (User et non Users)

Le nom indique le **type** d'objet, pas la quantite.
La fonction peut retourner plusieurs elements tout en ayant un nom singulier.

## Template de Fonction

```powershell
function $ARGUMENTS {
    <#
    .SYNOPSIS
        Description breve
    .PARAMETER NomParam
        Description
    .EXAMPLE
        $ARGUMENTS -NomParam "valeur"
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NomParam
    )

    begin {
        $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    }

    process {
        try {
            $processedItem = [PSCustomObject]@{
                Input  = $NomParam
                Output = "Traite"
            }
            $results.Add($processedItem)
        }
        catch {
            Write-Error $_.Exception.Message
            throw
        }
    }

    end {
        return $results
    }
}
```

## Checklist

- [ ] Verbe de la liste approuvee (Get-Verb)
- [ ] Nom SINGULIER
- [ ] Attribut [CmdletBinding()]
- [ ] Attribut [OutputType()]
- [ ] .SYNOPSIS et .EXAMPLE
- [ ] Parametres types et valides
- [ ] List<T> pour les collections
