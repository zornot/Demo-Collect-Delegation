# [!] FIX-001 Corriger persistance cache authentification Interactive | Effort: 30min

## PROBLEME

Le mode Interactive utilise `useWAM` qui :
1. Ne controle pas vraiment WAM (bug SDK 2.26+ avec .NET 9)
2. Ne gere pas correctement la persistance du cache entre sessions PS

### Comportement actuel (bug)
- `useWAM: false` → Cache persiste quand meme (comportement par defaut SDK)
- `useWAM: true` → Erreur WAM : `Could not load type 'Microsoft.Identity.Client.AuthScheme.TokenType'`

### Comportement souhaite
| persistCache | Nouvelle session PS | Meme session PS |
|--------------|---------------------|-----------------|
| `false` | Popup navigateur | Reutilisation |
| `true` | Pas de popup (cache .mg) | Reutilisation |

## LOCALISATION
- Fichier : MgConnection.psm1 (section 'Interactive')
- Fichier : README.md ou Settings.example.json (documentation)

---

## ANALYSE CAUSE RACINE

### Bug WAM SDK 2.26+
`Set-MgGraphOption -EnableLoginByWAM $true` provoque l'erreur :
```
Could not load type 'Microsoft.Identity.Client.AuthScheme.TokenType'
from assembly 'Microsoft.Identity.Client, Version=4.67.2.0'
```

References :
- [Issue #3290](https://github.com/microsoftgraph/msgraph-sdk-powershell/issues/3290)
- [Issue #3332](https://github.com/microsoftgraph/msgraph-sdk-powershell/issues/3332)

### Solution : ContextScope

Le SDK Microsoft Graph utilise `-ContextScope` pour controler la persistance :
| ContextScope | Cache | Comportement |
|--------------|-------|--------------|
| `CurrentUser` | `.mg` disque | Persiste entre sessions PS |
| `Process` | Memoire | Limite a la session PS courante |

---

## CHANGEMENTS DE NOM

| Avant | Apres | Raison |
|-------|-------|--------|
| `useWAM` | `persistCache` | WAM non utilise (bug SDK), nom reflete le comportement reel |
| `$comment_useWAM` | `$comment_persistCache` | Coherence avec le parametre |

---

## IMPLEMENTATION

### Etape 1 : Modifier Settings.example.json

AVANT :
```json
"interactive": {
  "scopes": [
    "Application.Read.All",
    "Directory.Read.All"
  ],
  "useWAM": false,
  "$comment_useWAM": "useWAM=true active WAM (Token Broker/TPM) avec cache persistant entre sessions. useWAM=false force un nouveau login a chaque nouvelle session PS (cache MSAL vide au demarrage)."
}
```

APRES :
```json
"interactive": {
  "scopes": [
    "Application.Read.All",
    "Directory.Read.All"
  ],
  "persistCache": false,
  "$comment_persistCache": "true = cache persistant entre sessions PS (SSO via fichier .mg). false = popup a chaque nouvelle session PS."
}
```

### Etape 2 : Modifier Settings.json (production)

AVANT :
```json
"interactive": {
  "scopes": [
    "Application.Read.All",
    "Directory.Read.All"
  ],
  "useWAM": false,
  "$comment_useWAM": "useWAM=true active WAM (Token Broker/TPM) avec cache persistant entre sessions. useWAM=false force un nouveau login a chaque nouvelle session PS (cache MSAL vide au demarrage)."
}
```

APRES :
```json
"interactive": {
  "scopes": [
    "Application.Read.All",
    "Directory.Read.All"
  ],
  "persistCache": false,
  "$comment_persistCache": "true = cache persistant entre sessions PS (SSO via fichier .mg). false = popup a chaque nouvelle session PS."
}
```

| Ligne | Avant | Apres |
|-------|-------|-------|
| Parametre | `"useWAM": false,` | `"persistCache": false,` |
| Commentaire cle | `"$comment_useWAM":` | `"$comment_persistCache":` |
| Commentaire texte | `"useWAM=true active WAM..."` | `"true = cache persistant entre sessions PS (SSO via fichier .mg). false = popup a chaque nouvelle session PS."` |

### Etape 3 : Modifier le code MgConnection.psm1

AVANT :
```powershell
$useWAM = $interactiveConfig.useWAM
if ($useWAM -eq $true) {
    try {
        Set-MgGraphOption -EnableLoginByWAM $true -ErrorAction Stop
    }
    catch { }
}
```

APRES :
```powershell
# Desactiver WAM explicitement (bug SDK 2.26+ et force navigateur web)
try {
    Set-MgGraphOption -EnableLoginByWAM $false -ErrorAction SilentlyContinue
}
catch {
    # Ignorer si l'option n'existe pas
}

# Persistance du cache entre sessions PS
$persistCache = $interactiveConfig.persistCache
if ($persistCache -eq $true) {
    # Cache persistant via fichier .mg (ContextScope = CurrentUser)
    $connectionParams['ContextScope'] = 'CurrentUser'
    Write-Verbose "[i] Cache persistant active (ContextScope=CurrentUser)"
}
else {
    # Pas de cache entre sessions: ContextScope = Process
    $connectionParams['ContextScope'] = 'Process'
    Write-Verbose "[i] ContextScope=Process - cache limite a cette session PS"
}
```

### Tableau recapitulatif

| Config | ContextScope | Cache | Authentification |
|--------|--------------|-------|------------------|
| `persistCache: false` | `Process` | Memoire | Navigateur web (chaque session) |
| `persistCache: true` | `CurrentUser` | `.mg` | Navigateur web (1ere fois) + SSO |

---

## VALIDATION

### Criteres d'Acceptation
- [ ] persistCache=false + meme session PS : reutilisation sans popup
- [ ] persistCache=false + nouvelle session PS : popup navigateur obligatoire
- [ ] persistCache=true + meme session PS : reutilisation sans popup
- [ ] persistCache=true + nouvelle session PS : pas de popup (cache .mg)
- [ ] Navigateur web utilise (pas fenetre WAM)
- [ ] Mode Certificate : fonctionne sans changement

---

## REFERENCES

- [Microsoft Graph Authentication Commands](https://learn.microsoft.com/en-us/powershell/microsoftgraph/authentication-commands)
- [Connect-MgGraph -ContextScope](https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/connect-mggraph)
- [WAM Bug Issue #3290](https://github.com/microsoftgraph/msgraph-sdk-powershell/issues/3290)
- Code de reference : App-Registration-Data-Collector/Modules/MgConnection/MgConnection.psm1

---

## RESOLUTION
- Statut: CLOSED
- Commit: ef60119
- GitHub Issue: #1
- Date: 2025-12-08

Labels: fix authentication cache breaking-change
