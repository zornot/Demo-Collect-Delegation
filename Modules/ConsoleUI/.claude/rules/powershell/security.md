# Sécurité PowerShell

## Credentials Management

### [-] JAMAIS : Hardcoded
```powershell
$password = "P@ssw0rd123"
```

### [+] Get-Credential interactif
```powershell
$cred = Get-Credential -Message "Enter credentials"
```

### [+] SecureString
```powershell
$secure = ConvertTo-SecureString "password" -AsPlainText -Force
$cred = [PSCredential]::new("username", $secure)
```

### [+] Export/Import sécurisé
```powershell
$cred | Export-Clixml -Path ".\cred.xml"
$cred = Import-Clixml -Path ".\cred.xml"
```

### [+] Variables d'environnement (CI/CD)
```powershell
$apiKey = $env:API_KEY
if ([string]::IsNullOrEmpty($apiKey)) {
    throw "API_KEY not set"
}
```

## Validation Entrées Utilisateur (MUST)

### TryParse pour conversions runtime
```powershell
# [+] TOUJOURS utiliser TryParse pour input utilisateur
$index = 0
if (-not [int]::TryParse($userInput, [ref]$index)) {
    Write-Error "Valeur numérique attendue"
    return
}

# [-] JAMAIS caster directement (lève exception)
$index = [int]$userInput  # INTERDIT
```

### Validation paramètres fonction
```powershell
# [+] Utiliser attributs [Validate*]
param(
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^[a-zA-Z0-9]+$')]
    [string]$UserId
)
```

## Protection Injection SQL

### [-] DANGEREUX : Concaténation
```powershell
$query = "SELECT * FROM Users WHERE Id = '$userId'"
```

### [+] Paramétrage
```powershell
$query = "SELECT * FROM Users WHERE Id = @Id"
$params = @{ Id = $userId }
Invoke-SqlCommand -Query $query -Parameters $params
```

## Protection Injection CSV/Excel

```powershell
function Protect-CsvValue {
    param([string]$Value)
    
    if ([string]::IsNullOrEmpty($Value)) { return $Value }
    
    $dangerChars = @('=', '+', '-', '@')
    if ($dangerChars -contains $Value[0]) {
        return "'" + $Value
    }
    return $Value
}

$data | ForEach-Object {
    [PSCustomObject]@{
        Name = Protect-CsvValue $_.Name
        Email = Protect-CsvValue $_.Email
    }
} | Export-Csv -Path "safe.csv"
```

## Validation Chemins (MUST)

```powershell
function Test-SafePath {
    <#
    .SYNOPSIS
        Valide qu'un chemin est sécurisé
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [string[]]$AllowedRoots = @()
    )
    
    # Résoudre le chemin complet
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    
    # [-] Pas UNC
    if ($fullPath -match '^\\\\') { 
        throw "Chemin UNC non autorisé: $fullPath" 
    }
    
    # [-] Pas traversal
    if ($Path -match '\.\.') { 
        throw "Path traversal détecté: $Path" 
    }
    
    # [-] Pas chemins système Windows
    $blocked = @(
        '^[A-Z]:\\Windows',
        '^[A-Z]:\\Program Files',
        '^[A-Z]:\\Program Files \(x86\)',
        '^[A-Z]:\\Users\\[^\\]+\\AppData',
        '^[A-Z]:\\ProgramData'
    )
    
    foreach ($pattern in $blocked) {
        if ($fullPath -match $pattern) {
            throw "Chemin système non autorisé: $fullPath"
        }
    }
    
    # Vérifier racines autorisées si spécifiées
    if ($AllowedRoots.Count -gt 0) {
        $allowed = $false
        foreach ($root in $AllowedRoots) {
            $resolvedRoot = [System.IO.Path]::GetFullPath($root)
            if ($fullPath.StartsWith($resolvedRoot, [StringComparison]::OrdinalIgnoreCase)) {
                $allowed = $true
                break
            }
        }
        if (-not $allowed) {
            throw "Chemin hors des racines autorisées: $fullPath"
        }
    }
    
    return $fullPath
}

# Usage
$safePath = Test-SafePath -Path $userInput -AllowedRoots @("D:\Data", "D:\Output")
```

## Exécution Sécurisée

### [-] DANGEREUX : Invoke-Expression
```powershell
Invoke-Expression $userInput
```

### [+] Commandes autorisées
```powershell
function Invoke-SafeCommand {
    param(
        [ValidateSet('Get-Process', 'Get-Service')]
        [string]$Command,
        [hashtable]$Parameters = @{}
    )
    & $Command @Parameters
}
```

## Logging Sécurisé (masquer données sensibles)

```powershell
function Write-SecureLog {
    param(
        [string]$Message,
        [string]$Level = 'INFO',
        [hashtable]$Sensitive = @{}
    )

    $masked = $Message
    foreach ($key in $Sensitive.Keys) {
        $pattern = [regex]::Escape($Sensitive[$key])
        $masked = $masked -replace $pattern, "***REDACTED***"
    }

    # Utilise le module Write-Log
    Write-Log -Message $masked -Level $Level
}

Write-SecureLog "User $user with password $pwd" -Sensitive @{
    Password = $pwd
}
# Output: 2025-12-02T14:30:45.123+01:00 | INFO | HOST | Script | PID:1234 | User john with password ***REDACTED***
```

## Audit Checklist Production (MUST)

Checklist avant mise en production :

- [ ] Aucun secret dans le code source
- [ ] Settings.json dans .gitignore
- [ ] Validation de toutes les entrées utilisateur
- [ ] Gestion des erreurs sans exposition d'infos sensibles
- [ ] Logs sans données confidentielles
- [ ] Permissions minimales requises documentées
- [ ] TryParse pour toute conversion d'input runtime
- [ ] Test-SafePath pour chemins utilisateur
- [ ] Pas d'Invoke-Expression avec input utilisateur

## Règles Fondamentales

| Règle | Implémentation |
|-------|----------------|
| Pas de secrets en dur | Settings.json (gitignore) ou variables env |
| Pas de credentials dans logs | Masquer: `***REDACTED***` |
| Valider toutes les entrées | TryParse, ValidateScript, ValidatePattern |
| Principe moindre privilège | Demander uniquement droits nécessaires |
| Chiffrer données sensibles | ConvertTo-SecureString, Export-Clixml |

---

## OWASP Top 10 - Checklist PowerShell

### 1. Injection (SQL, Command, LDAP)

```powershell
# [-] VULNERABLE : Concatenation
$query = "SELECT * FROM Users WHERE Name = '$userName'"
Invoke-Expression "Get-Process $userInput"
$filter = "(&(samAccountName=$userName))"

# [+] SECURISE : Parametrage
$query = "SELECT * FROM Users WHERE Name = @Name"
& 'Get-Process' -Name $userInput  # Commande fixe, param variable
$filter = "(&(samAccountName={0}))" -f [System.Web.HttpUtility]::HtmlEncode($userName)
```

**Checklist** :
- [ ] Pas de concatenation dans requetes SQL/LDAP
- [ ] Pas d'Invoke-Expression avec input utilisateur
- [ ] Requetes parametrees ou ORM
- [!] VERIFIER : Framework protege ? Validation amont ?

### 2. Broken Authentication

```powershell
# [-] Hash faibles
$hash = [System.Security.Cryptography.MD5]::Create()
$hash = [System.Security.Cryptography.SHA1]::Create()

# [+] Hash securises (passwords)
# Utiliser SecureString + DPAPI ou bibliotheques specialisees
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
```

**Checklist** :
- [ ] Pas de hash faible (MD5, SHA1 pour passwords)
- [ ] SecureString pour credentials en memoire
- [ ] Pas de tokens previsibles ou sequentiels
- [ ] Expiration des sessions/tokens

### 3. Sensitive Data Exposure

```powershell
# [-] Donnees sensibles exposees
Write-Log "User $user logged in with password $password"
$url = "https://api.example.com?apikey=$apiKey"

# [+] Masquage
Write-Log "User $user logged in" # Pas de password
$headers = @{ 'Authorization' = "Bearer $apiKey" }  # Dans header, pas URL
```

**Checklist** :
- [ ] Pas de donnees sensibles dans logs
- [ ] Pas de secrets dans URLs (query strings)
- [ ] Chiffrement at-rest si applicable
- [ ] HTTPS pour donnees en transit

### 4. Path Traversal (LFI/RFI)

```powershell
# [-] VULNERABLE
$content = Get-Content ".\data\$userInput.txt"
$path = Join-Path $baseDir $userInput

# [+] SECURISE : Utiliser Test-SafePath
$safePath = Test-SafePath -Path $userInput -AllowedRoots @("D:\Data")
$content = Get-Content $safePath
```

**Checklist** :
- [ ] Test-SafePath pour tout chemin utilisateur
- [ ] Pas de `..` non valide dans chemins
- [ ] Whitelist de repertoires autorises
- [ ] Resolution et validation du chemin complet

### 5. Security Misconfiguration

**Checklist** :
- [ ] Pas de credentials par defaut
- [ ] Messages d'erreur sans stack traces en production
- [ ] Permissions minimales sur fichiers/dossiers
- [ ] Pas de fonctionnalites de debug en production

### 6. Insecure Deserialization

```powershell
# [-] RISQUE : Deserialisation non validee
$data = [System.Management.Automation.PSSerializer]::Deserialize($xmlInput)
$obj = ConvertFrom-Json $untrustedJson

# [+] SECURISE : Validation schema
$obj = ConvertFrom-Json $jsonInput
if (-not (Test-JsonSchema -Data $obj -Schema $expectedSchema)) {
    throw "Invalid data format"
}
```

**Checklist** :
- [ ] Validation schema apres deserialisation
- [ ] Pas de Import-Clixml sur donnees non fiables
- [ ] Types attendus verifies

---

## Trust Boundaries

### Definition

Une Trust Boundary separe les zones de confiance differente. Les donnees traversant une boundary doivent etre validees.

### Sources de Donnees et Niveau de Confiance

| Source | Niveau | Validation Requise |
|--------|--------|-------------------|
| Parametres utilisateur | NON FIABLE | Validation complete |
| Fichiers utilisateur | NON FIABLE | Validation complete |
| API externes | NON FIABLE | Validation schema |
| Base de donnees interne | SEMI-FIABLE | Validation type |
| Variables d'environnement | SEMI-FIABLE | Validation format |
| Code interne | FIABLE | Minimale |

### Evaluation Severite selon Trust Boundary

| Condition d'exploitation | Severite Max | Justification |
|--------------------------|--------------|---------------|
| Necessite acces admin/filesystem | [~] MOYENNE | Attaquant deja privilegie |
| Utilisateur authentifie standard | [!] ELEVEE | Insider threat realiste |
| Sans authentification (public) | [!!] CRITIQUE | Exposition publique |
| Acces physique requis | [-] FAIBLE | Scenario peu probable |

### Flux Donnees Sensibles (Template Trace)

Pour chaque vulnerabilite potentielle, tracer le flux :

```
[Source] : D'ou vient la donnee ?
    |
    v
[Validation ?] <-- VERIFIER ICI
    |
    v
[Transformation] : Modifications appliquees ?
    |
    v
[Operation sensible] : SQL, fichier, commande, etc.
    |
    v
[VERDICT] : Vulnerable OUI/NON + Justification
```

### Exemple de Trace

```
[Source] : $userId depuis parametre HTTP (NON FIABLE)
    |
    v
[Validation ?] : ValidatePattern '^[a-zA-Z0-9]+$' sur param -> OUI
    |
    v
[Transformation] : Aucune
    |
    v
[Operation] : Get-ADUser -Identity $userId
    |
    v
[VERDICT] : NON VULNERABLE - Validation regex bloque injection LDAP
```

---

## References

- Protocole anti-FP : @.claude/rules/common/anti-false-positives.md
- Metriques : @.claude/rules/common/metrics-sqale.md
