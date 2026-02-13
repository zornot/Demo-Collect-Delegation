# [~] BUG-013 - signInActivity echec silencieux masque la cause reelle - Effort: 30min

## PROBLEME

La fonction `Initialize-SignInActivityCache` intercepte les erreurs 403/Forbidden avec `Write-Verbose` uniquement (L482), rendant l'echec invisible dans la console ET les logs. Apres "Detection licence P1/P2..." aucun message n'apparait avant le fallback, creant un trou dans le flux console.

### Diagnostic confirme (2026-02-13)

Script `.temp/Test-SignInActivityScope.ps1` (GraphConnection Interactive) :

| Verification | Resultat |
|---|---|
| Scopes (3/3) | PRESENT (`AuditLog.Read.All`, `Reports.Read.All`, `User.Read.All`) |
| Endpoint `/v1.0/users?signInActivity` | **403 Forbidden** |
| Match pattern L481 | **True** → `Write-Verbose` (invisible) |
| Cause racine | Licence = Business Standard (pas P1) - comportement attendu |

## LOCALISATION

- Fichier : Get-ExchangeDelegation.ps1:L480-488
- Fonction : Initialize-SignInActivityCache
- Module : Script principal

## OBJECTIF

1. Afficher un message console propre apres "Detection licence P1/P2..."
2. Logger le vrai message d'erreur dans le fichier log pour diagnostic
3. Couvrir aussi les erreurs inattendues (hors 403)

---

## IMPLEMENTATION

### Etape 1 : Remplacer Write-Verbose par Write-Status + Write-Log - 30min

Fichier : Get-ExchangeDelegation.ps1:L480-488

AVANT :
```powershell
    catch {
        if ($_.Exception.Message -match '(403|Forbidden|license|Premium|Authorization_RequestDenied)') {
            Write-Verbose "[i] signInActivity non disponible (licence P1/P2 requise)"
        }
        else {
            Write-Log -Message "Erreur signInActivity: $($_.Exception.Message)" -Level Warning -NoConsole
        }
        return $false
    }
```

APRES :
```powershell
    catch {
        $errorMessage = $_.Exception.Message
        if ($errorMessage -match '(403|Forbidden|license|Premium|Authorization_RequestDenied)') {
            Write-Status -Type Info -Message "signInActivity non disponible (Entra ID P1/P2 requis)" -Indent 2
            Write-Log -Message "signInActivity: $errorMessage" -Level Warning -NoConsole
        }
        else {
            Write-Status -Type Warning -Message "signInActivity: erreur inattendue" -Indent 2
            Write-Log -Message "Erreur signInActivity: $errorMessage" -Level Warning
        }
        return $false
    }
```

### Rendu console

```
# Cas succes (P1 presente - inchange L446)
[>] Detection licence P1/P2...
  [+] Licence P1/P2 detectee - utilisation signInActivity

# Cas 403 (pas de P1 - nouveau)
[>] Detection licence P1/P2...
    [i] signInActivity non disponible (Entra ID P1/P2 requis)
[>] Chargement Graph Reports...

# Cas erreur inattendue (nouveau)
[>] Detection licence P1/P2...
    [!] signInActivity: erreur inattendue
[>] Chargement Graph Reports...
```

### Rendu log fichier

```
# Cas 403 : erreur reelle loggee pour diagnostic (NoConsole)
WARNING | signInActivity: Response status code does not indicate success: Forbidden (Forbidden).

# Cas inattendu : aussi visible en console
WARNING | Erreur signInActivity: [message complet]
```

---

## VALIDATION

### Criteres d'Acceptation

- [ ] Message visible en console apres "Detection licence P1/P2..."
- [ ] Erreur reelle dans le fichier log
- [ ] Pas de regression : cascade continue normalement
- [ ] Tests Pester passent

## CHECKLIST

- [x] Code AVANT = code reel verifie (L480-488)
- [ ] Tests passent
- [ ] Code review

Labels : bug ~ logging

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | local |
| Statut | RESOLVED |
| Branche | fix/BUG-013-signinactivity-silent-failure |
