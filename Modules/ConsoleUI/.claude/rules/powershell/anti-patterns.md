# Anti-Patterns PowerShell

## Nommage

```powershell
# [-] Noms vagues
$data = @()
$temp = $null
$i = 0
$obj = @{}
$result = $null

# [>] Noms explicites
$userData = @()
$tempFilePath = $null
$userIndex = 0
$configObject = @{}
$validationResult = $null
```

## Verbes non standard

```powershell
# [-] Verbes invalides
function Fetch-Data { }
function Retrieve-User { }
function Check-Status { }

# [>] Verbes approuves (Get-Verb)
function Get-Data { }
function Get-User { }
function Test-Status { }
```

## Validation parametres

```powershell
# [-] Sans validation
param($id, $name, $count)

# [>] Avec validation
param(
    [ValidateNotNullOrEmpty()]
    [string]$Id,

    [ValidateLength(1, 100)]
    [string]$Name,

    [ValidateRange(1, 1000)]
    [int]$Count
)
```

## Credentials

```powershell
# [-] Credentials hardcodes
$password = "P@ssw0rd"
$apiKey = "sk-1234567890"
$connectionString = "Server=srv;Password=secret"

# [>] Variables environnement ou SecureString
$password = $env:SERVICE_PASSWORD
$apiKey = $env:API_KEY
$cred = Get-Credential
```

## Collections

```powershell
# [-] Array += (O(n) a chaque ajout)
$arr = @()
foreach ($item in $source) {
    $arr += $item  # Realloue tout le tableau!
}

# [>] List<T> (O(1) amorti)
$list = [System.Collections.Generic.List[object]]::new()
foreach ($item in $source) {
    $list.Add($item)
}
```

## Input utilisateur

```powershell
# [-] Cast direct (exception si invalide)
$index = [int]$userInput
$date = [datetime]$userDate

# [>] TryParse (retourne bool)
$index = 0
if (-not [int]::TryParse($userInput, [ref]$index)) {
    Write-Error "Valeur numerique attendue"
    return
}

$date = [datetime]::MinValue
if (-not [datetime]::TryParse($userDate, [ref]$date)) {
    Write-Error "Date invalide"
    return
}
```

## Symboles UI

```powershell
# [-] Emoji et Unicode pour status
Write-Host "Succes"
Write-Host "Erreur"
Write-Host "Warning"
Write-Host "* Item"

# [>] Brackets ASCII
Write-Host "[+] " -NoNewline -ForegroundColor Green; Write-Host "Succes"
Write-Host "[-] " -NoNewline -ForegroundColor Red; Write-Host "Erreur"
Write-Host "[!] " -NoNewline -ForegroundColor Yellow; Write-Host "Warning"
Write-Host "[>] " -NoNewline -ForegroundColor White; Write-Host "Item"
```

## Donnees de test

```powershell
# [-] Donnees production dans tests
$email = "real.user@company.com"
$domain = "ad.entreprise.fr"
$guid = "79433f48-c36b-4a2e-9f1d-real-guid"

# [>] Donnees anonymisees
$email = "jean.dupont@contoso.com"
$domain = "ad.contoso.com"
$guid = "00000000-0000-0000-0000-000000000001"
```

## Chemins fichiers

```powershell
# [-] Chemins non valides
$path = $userInput  # Path traversal possible!
Remove-Item -Path "..\..\system\file"

# [>] Validation avec Test-SafePath
$safePath = Test-SafePath -Path $userInput -AllowedRoots @("D:\Data")
Remove-Item -Path $safePath
```

## Concatenation strings

```powershell
# [-] Concatenation en boucle
$output = ""
foreach ($line in $lines) {
    $output += "$line`n"  # Realloue a chaque iteration
}

# [>] StringBuilder ou -join
$sb = [System.Text.StringBuilder]::new()
foreach ($line in $lines) {
    [void]$sb.AppendLine($line)
}
$output = $sb.ToString()

# Ou plus simple
$output = $lines -join "`n"
```

## Pipeline vs Loop

```powershell
# [-] Pipeline lent pour gros volumes
$filtered = $bigData | Where-Object { $_.Status -eq 'Active' }

# [>] Method .Where() ou foreach
$filtered = $bigData.Where({ $_.Status -eq 'Active' })

# Ou
$filtered = foreach ($item in $bigData) {
    if ($item.Status -eq 'Active') { $item }
}
```

## Gestion erreurs

```powershell
# [-] Catch vide ou generique seul
try {
    Do-Something
} catch {
    # Rien ou juste throw
}

# [>] Catch specifique + logging
try {
    Do-Something
} catch [System.IO.FileNotFoundException] {
    Write-Log "Fichier non trouve: $($_.Exception.Message)" -Level ERROR
    throw
} catch [System.UnauthorizedAccessException] {
    Write-Log "Acces refuse: $($_.Exception.Message)" -Level ERROR
    throw
} catch {
    Write-Log "Erreur inattendue: $($_.Exception.Message)" -Level ERROR
    throw
}
```

## Output inutile

```powershell
# [-] Output non capture pollue le pipeline
New-Item -Path $dir -ItemType Directory
$list.Add($item)
$dict[$key] = $value

# [>] Supprimer output avec [void] ou $null
[void](New-Item -Path $dir -ItemType Directory)
[void]$list.Add($item)
$null = $dict[$key] = $value

# Ou redirection
New-Item -Path $dir -ItemType Directory | Out-Null
```
