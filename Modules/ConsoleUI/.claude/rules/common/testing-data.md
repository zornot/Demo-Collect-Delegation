# Donnees de Test - Anonymisation

## Regle Critique

> **Les tests ne doivent JAMAIS contenir de donnees de production reelles.**

### Pourquoi ?
- **Securite** : Eviter la fuite d'informations sensibles
- **Publication** : Permettre la publication en open source
- **Conformite** : Respecter le RGPD et politiques de confidentialite
- **Maintenance** : Faciliter les contributions externes

## Donnees Interdites

| Type | Exemple Interdit | Risque |
|------|------------------|--------|
| Domaines client | `@client.com`, `@client.fr` | Identification |
| Serveurs reels | `VMPRODDC01`, `srv-exchange` | Infrastructure |
| GUIDs Azure | `79433f48-c36b-...` | Tenant/App ID |
| Emails personnels | `prenom.nom@client.com` | PII / RGPD |
| Chemins AD | `DC=ad,DC=client,DC=com` | Structure interne |
| Credentials | Thumbprints, secrets | Securite critique |

## Donnees de Remplacement Standards

Utiliser les **domaines Microsoft de demonstration** :

| Original | Remplacement | Usage |
|----------|--------------|-------|
| Domaine client principal | `contoso.com` | Microsoft standard |
| Domaine secondaire | `fabrikam.com` | Microsoft standard |
| Tenant Azure | `contoso.onmicrosoft.com` | Convention |
| Serveurs | `SRV01`, `DC01`, `EXCH01` | Generique |
| GUIDs | `00000000-0000-0000-0000-000000000001` | Placeholder |
| Emails admin | `admin@contoso.com` | Generique |
| Chemins AD | `DC=ad,DC=contoso,DC=com` | Convention |

## Exemple MockUsers.json

```json
{
    "Users": [
        {
            "SamAccountName": "jdupont",
            "UserPrincipalName": "jean.dupont@contoso.com",
            "DisplayName": "Jean DUPONT",
            "DistinguishedName": "CN=Jean DUPONT,OU=Users,DC=ad,DC=contoso,DC=com"
        }
    ],
    "Config": {
        "Organization": "contoso.onmicrosoft.com",
        "AppId": "00000000-0000-0000-0000-000000000001"
    }
}
```

## Checklist Avant Commit Tests

- [ ] Aucun domaine client reel (`@client.com`)
- [ ] Aucun nom de serveur de production
- [ ] Aucun GUID Azure reel
- [ ] Aucun email personnel identifiable
- [ ] Aucun chemin AD de production
- [ ] Utilisation de `contoso.com` / `fabrikam.com`

## Anti-Patterns

```
# [-] Donnees production dans tests
$email = "real.user@company.com"
$domain = "ad.entreprise.fr"
$guid = "79433f48-c36b-4a2e-9f1d-real-guid"

# [+] Donnees anonymisees
$email = "jean.dupont@contoso.com"
$domain = "ad.contoso.com"
$guid = "00000000-0000-0000-0000-000000000001"
```

## Script de Verification Pre-commit

Detecter automatiquement les donnees sensibles avant commit :

```powershell
function Test-SensitiveData {
    <#
    .SYNOPSIS
        Detecte les donnees sensibles dans les fichiers de test
    #>
    [CmdletBinding()]
    param(
        [string]$Path = "./Tests"
    )

    $patterns = @(
        '@(?!contoso|fabrikam)[a-z]+\.(com|fr|net)',  # Domaines non-standards
        'DC=(?!contoso|fabrikam|ad)',                  # AD paths non-standards
        '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'  # GUIDs reels
    )

    $issues = [System.Collections.Generic.List[PSCustomObject]]::new()

    Get-ChildItem -Path $Path -Recurse -Include *.ps1, *.json |
        ForEach-Object {
            $file = $_
            $content = Get-Content $file.FullName -Raw

            foreach ($pattern in $patterns) {
                if ($content -match $pattern) {
                    $issues.Add([PSCustomObject]@{
                        File    = $file.Name
                        Pattern = $pattern
                        Match   = $Matches[0]
                    })
                }
            }
        }

    if ($issues.Count -gt 0) {
        Write-Host "[-] Donnees sensibles detectees:" -ForegroundColor Red
        $issues | Format-Table -AutoSize
        return $false
    }

    Write-Host "[+] Aucune donnee sensible detectee" -ForegroundColor Green
    return $true
}

# Usage
Test-SensitiveData -Path "./Tests"
```

### Patterns a Verifier

| Pattern | Detecte | Action |
|---------|---------|--------|
| `@(?!contoso\|fabrikam)` | Domaines reels | Remplacer par contoso.com |
| `DC=(?!contoso)` | Chemins AD reels | Remplacer par DC=ad,DC=contoso,DC=com |
| GUID format complet | GUIDs Azure reels | Verifier manuellement, remplacer si reel |
