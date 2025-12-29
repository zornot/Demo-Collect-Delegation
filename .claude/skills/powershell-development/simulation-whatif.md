# Simulation et WhatIf

Guide des pieges et bonnes pratiques pour le mode WhatIf/Simulation en PowerShell.

## Concepts Fondamentaux

### $WhatIfPreference vs -WhatIf

| Mecanisme | Scope | Usage |
|-----------|-------|-------|
| `$WhatIfPreference = $true` | Session entiere | Active WhatIf sur TOUS les cmdlets compatibles |
| `-WhatIf` parametre | Commande unique | Active WhatIf sur UNE commande |
| `-WhatIf:$variable` | Commande unique | Controle dynamique (recommande) |

### Classification des Cmdlets

| Type | $WhatIfPreference fonctionne ? | Exemples |
|------|-------------------------------|----------|
| **Locaux** | OUI | `Set-Content`, `New-Item`, `Remove-Item` |
| **Modules locaux** | OUI | `Set-ADUser`, `Disable-ADAccount` |
| **Proxy (session distante)** | **NON** | Cmdlets Exchange, sessions PSRemoting |
| **Sans support WhatIf** | N/A | `Send-MailMessage`, `Write-EventLog` |

## Piege #1 : $WhatIfPreference AVANT Import-Module

**Probleme** : Definir `$WhatIfPreference = $true` AVANT le chargement des modules corrompt leur initialisation.

```powershell
# [-] ERREUR - Module Exchange corrompu
$WhatIfPreference = $true
Import-Module ExchangeOnlineManagement  # Operations internes en WhatIf!

# [+] CORRECT - Import AVANT WhatIfPreference
Import-Module ExchangeOnlineManagement
$WhatIfPreference = $true
```

**Pourquoi ?** Les modules utilisent des cmdlets avec support WhatIf pendant leur initialisation (`Set-Alias`, `Copy-Item`, etc.). Si `$WhatIfPreference = $true`, ces operations ne s'executent pas.

## Piege #2 : Proxy Cmdlets (Sessions Distantes)

**Probleme** : Les cmdlets importes via `Import-PSSession` ou modules cloud IGNORENT `$WhatIfPreference`.

```powershell
# [-] ERREUR - $WhatIfPreference IGNORE
$WhatIfPreference = $true
Enable-RemoteMailbox -Identity $user  # EXECUTE REELLEMENT!

# [+] CORRECT - -WhatIf explicite
Enable-RemoteMailbox -Identity $user -WhatIf:$IsSimulation
```

**Regle** : Pour les cmdlets proxy (Exchange, Azure, etc.), TOUJOURS passer `-WhatIf:$variable` explicitement.

## Piege #3 : Cmdlets Sans Support WhatIf

Certains cmdlets n'ont pas de parametre `-WhatIf` et s'executent toujours.

```powershell
# [-] ERREUR - Send-MailMessage n'a pas -WhatIf
$WhatIfPreference = $true
Send-MailMessage -To $user -Subject "Test"  # EMAIL ENVOYE!

# [+] CORRECT - Conditionner l'execution
if (-not $IsSimulation) {
    Send-MailMessage -To $user -Subject "Test"
} else {
    Write-Log "Email non envoye (mode simulation)" -Level INFO
}
```

## Piege #4 : Forcer ou Conditionner

| Cmdlet | Comportement | Solution |
|--------|--------------|----------|
| `Set-Content` | Respecte $WhatIfPreference | `-WhatIf:$false` pour forcer |
| `Send-MailMessage` | Ignore $WhatIfPreference | `if (-not $Simulation)` |

```powershell
# Forcer creation fichier meme en simulation (pour rapport)
$html | Set-Content $ReportFile -Encoding UTF8 -WhatIf:$false

# Conditionner envoi email
if (-not $Simulation) {
    Send-MailMessage @params
}
```

## Piege #5 : Erreurs Attendues en Simulation

En mode simulation, certaines erreurs sont ATTENDUES car les operations precedentes n'ont pas eu lieu.

```powershell
# En simulation :
# - Enable-RemoteMailbox -WhatIf -> mailbox NON creee
# - Enable-RemoteMailbox -Archive -WhatIf -> ERREUR "type User"

# [+] CORRECT - Gerer les erreurs attendues
try {
    Enable-RemoteMailbox -Identity $user -Archive -WhatIf:$IsSimulation
} catch {
    if ($IsSimulation -and ($_.Exception.Message -match "type User")) {
        Write-Log "Archive: simulation OK (comportement attendu)" -Level SUCCESS
    } else {
        throw
    }
}
```

## SupportsShouldProcess : Usage Correct

```powershell
# [-] ERREUR - doublon WhatIf
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$WhatIf  # INTERDIT - SupportsShouldProcess l'ajoute deja!
)

# [+] CORRECT - SupportsShouldProcess suffit
[CmdletBinding(SupportsShouldProcess)]
param()

# Utiliser $PSCmdlet.ShouldProcess() pour la logique
if ($PSCmdlet.ShouldProcess($target, "Supprimer")) {
    Remove-Item $target -Force
}
```

## Architecture Recommandee

```
1. param()              # Pas de [switch]$WhatIf avec SupportsShouldProcess
2. Import-Module ALL    # AVANT toute modification de preference
3. $WhatIfPreference    # APRES tous les imports (si necessaire)
4. Code principal       # Avec -WhatIf:$variable pour proxy cmdlets
```

## Checklist Audit WhatIf

- [ ] `$WhatIfPreference` defini APRES tous les `Import-Module`
- [ ] Cmdlets proxy ont `-WhatIf:$variable` explicite
- [ ] Cmdlets sans WhatIf sont conditionnes (`if (-not $Simulation)`)
- [ ] Erreurs attendues en simulation sont gerees
- [ ] Pas de `[switch]$WhatIf` avec `SupportsShouldProcess`

## References

- [about_Preference_Variables](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables)
- [about_Functions_CmdletBindingAttribute](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_cmdletbindingattribute)
