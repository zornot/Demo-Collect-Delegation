# Conventions de Nommage PowerShell

## Fonctions : Verb-Noun (MUST)

### Verbes approuvés (Get-Verb)
```powershell
# Données
Get-     # Récupérer
Set-     # Modifier
New-     # Créer
Remove-  # Supprimer
Clear-   # Vider

# Actions
Start-   # Démarrer processus
Stop-    # Arrêter processus
Invoke-  # Exécuter action
Test-    # Tester (retourne bool)

# Transformation
ConvertTo-    # Convertir vers format
ConvertFrom-  # Convertir depuis format
Format-       # Formater affichage
Export-       # Exporter fichier
Import-       # Importer fichier

# Cycle de vie
Initialize-   # Initialiser
Enable-       # Activer
Disable-      # Désactiver
Register-     # Enregistrer
Unregister-   # Désenregistrer
```

### Nouns singuliers (MUST)

Le nom (Noun) est toujours au **singulier**, meme si la fonction retourne plusieurs elements.

```powershell
# [-] Pluriel interdit
function Get-Users { }
function Remove-Files { }
function Get-Processes { }

# [+] Singulier obligatoire
function Get-User { }       # Retourne 1 ou N users
function Remove-File { }    # Supprime 1 ou N fichiers
function Get-Process { }    # Convention Microsoft
```

Le verbe indique l'action, le nom indique le **type** d'objet (pas la quantite).

## Variables

### PascalCase - Variables importantes
```powershell
$CustomerData = @()
$TotalCount = 0
$IsCompleted = $false
$ConnectionString = "..."
```

### camelCase - Variables locales/temporaires
```powershell
$currentIndex = 0
$tempResult = $null
$loopCounter = 1
```

### MAJUSCULES - Constantes
```powershell
$MAX_RETRY_COUNT = 5
$DEFAULT_TIMEOUT = 300
$API_BASE_URL = "https://api.example.com"
```

### Préfixes de portée
```powershell
$script:GlobalConfig = @{}   # Scope script
$global:SharedData = @{}     # Scope global
$local:TempVar = "..."       # Scope local
$private:InternalVar = "..." # Privé au scope
```

## Noms Interdits (MUST)

### [-] Variables vagues
```powershell
# INTERDIT - Noms non explicites
$data = @()
$temp = $null
$obj = @{}
$result = $null
$item = $null
$value = $null
$x = 0
$s = ""
```

### [-] Index de boucle génériques
```powershell
# INTERDIT
for ($i = 0; $i -lt $count; $i++) { }
for ($j = 0; $j -lt $count; $j++) { }
foreach ($x in $items) { }

# [+] CORRECT - Index explicites
for ($userIndex = 0; $userIndex -lt $userCount; $userIndex++) { }
for ($appIndex = 0; $appIndex -lt $appCount; $appIndex++) { }
foreach ($user in $users) { }
foreach ($mailbox in $mailboxes) { }
```

### Liste complète des noms interdits
| Interdit | Remplacer par |
|----------|---------------|
| `$data` | `$userData`, `$reportData`, `$configData` |
| `$temp` | `$tempFilePath`, `$tempResult`, `$tempConfig` |
| `$obj` | `$userObject`, `$configObject` |
| `$result` | `$queryResult`, `$validationResult` |
| `$item` | `$currentUser`, `$mailboxItem` |
| `$value` | `$configValue`, `$returnValue` |
| `$x`, `$y`, `$z` | Noms descriptifs |
| `$i`, `$j`, `$k` | `$userIndex`, `$itemIndex` |
| `$s`, `$str` | `$userName`, `$filePath` |
| `$list` | `$userList`, `$mailboxList` |
| `$arr` | `$userArray`, `$resultArray` |

## Paramètres : PascalCase explicite (MUST)
```powershell
# [+] BON
param(
    [string]$CustomerId,
    [string]$ReportType,
    [int]$MaxResults,
    [switch]$IncludeArchived
)

# [-] MAUVAIS
param($id, $type, $max, [switch]$ia)
```

## Booléens : Préfixes sémantiques
```powershell
# [+] Préfixes clairs
$isEnabled = $true
$hasLicense = $false
$shouldProcess = $true
$canExecute = $false
$wasSuccessful = $true

# [-] Sans préfixe
$enabled = $true
$license = $false
```

## Classes et Enums : PascalCase
```powershell
class CustomerRecord {
    [string]$CustomerId
    [DateTime]$CreatedDate
}

enum OrderStatus {
    Pending
    Processing
    Completed
    Cancelled
}
```

## Commentaires : POURQUOI pas QUOI (SHOULD)

```powershell
# [+] BIEN : Explique le POURQUOI
# Retry nécessaire car API EXO throttle après 1000 requêtes/minute
Invoke-WithRetry -ScriptBlock { Get-EXOMailbox }

# Délai pour éviter rate limiting Azure AD
Start-Sleep -Seconds 2

# Hash pour comparaison rapide sans charger tout en mémoire
$existingHashes = [System.Collections.Generic.HashSet[string]]::new()

# [-] MAL : Explique le QUOI (évident du code)
# Obtient la mailbox
Get-EXOMailbox

# Attend 2 secondes
Start-Sleep -Seconds 2

# Crée un HashSet
$hashes = [System.Collections.Generic.HashSet[string]]::new()
```
