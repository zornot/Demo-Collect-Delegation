# Design Patterns PowerShell

Patterns organises en deux categories : Construction (code a copier) et Audit (violations a detecter).

---

## PARTIE A : Patterns de Construction (Prescriptifs)

Patterns a UTILISER lors de la creation de scripts.
Reference : `/create-script`

### Structured Result

Schema pour scripts de collecte avec typage explicite.

```powershell
$Script:Result = @{
    Metadata = @{
        StartTime    = Get-Date
        EndTime      = $null
        Author       = $env:USERNAME
        ComputerName = $env:COMPUTERNAME
    }
    Data = @{
        Items   = [System.Collections.Generic.List[PSCustomObject]]::new()
        Summary = @{}
    }
    Status = @{
        Success  = $true
        Errors   = [System.Collections.Generic.List[string]]::new()
        Warnings = [System.Collections.Generic.List[string]]::new()
    }
}

# Usage
$Script:Result.Data.Items.Add($item)
$Script:Result.Status.Errors.Add("Message")
$Script:Result.Metadata.EndTime = Get-Date
```

**Utiliser pour** : Collect-*, Audit-*, Export-*, scripts retournant donnees structurees.

### Fallback API

Tester disponibilite AVANT d'appeler, pas dans le catch.

```powershell
function Get-DataWithFallback {
    [CmdletBinding()]
    param()

    $hasAccess = Test-ApiAccess  # Tester AVANT

    if ($hasAccess) {
        return Get-FullData
    } else {
        Write-Warning "Mode degrade: donnees limitees"
        return Get-CachedData
    }
}

# Test avec cache (eviter appels repetes)
function Test-ApiAccess {
    return Get-Cached -Key 'ApiAccess' -Compute {
        try {
            $null = Invoke-ApiCall -Top 1 -ErrorAction Stop
            return $true
        } catch { return $false }
    } -MinutesTTL 5
}
```

**Utiliser pour** : APIs externes (Graph, EXO), ressources optionnelles.

### Throttle API

Delai entre appels pour respecter rate limits.

```powershell
function Invoke-ThrottledOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Items,
        [scriptblock]$Operation,
        [int]$DelayMs = 100
    )

    $results = [System.Collections.Generic.List[PSObject]]::new()

    foreach ($item in $Items) {
        $results.Add((& $Operation $item))
        Start-Sleep -Milliseconds $DelayMs
    }

    return $results
}

# Usage
$users = Invoke-ThrottledOperation -Items $userIds -DelayMs 50 -Operation {
    param($id)
    Get-MgUser -UserId $id
}
```

**Utiliser pour** : Boucles sur API Graph/EXO, operations en masse.

**Note** : EXO non parallelisable (cmdlets non thread-safe).

### Input Validation

Valider tot, echouer explicitement.

```powershell
# Numerique - TryParse (pas cast)
$days = 0
if (-not [int]::TryParse($InputDays, [ref]$days)) {
    throw "Valeur numerique attendue pour -Days"
}
if ($days -lt 1 -or $days -gt 365) {
    throw "Days doit etre entre 1 et 365"
}

# Path - Test-Path + Resolve
if (-not (Test-Path $InputPath -PathType Container)) {
    throw "Chemin invalide ou inexistant: $InputPath"
}
$safePath = Resolve-Path $InputPath

# Email - Regex simple
if ($Email -notmatch '^[\w.+-]+@[\w.-]+\.\w+$') {
    throw "Format email invalide"
}
```

**Utiliser pour** : Parametres utilisateur, input externe.

---

## PARTIE B : Patterns d'Audit (Detection)

Patterns a DETECTER lors des audits de code.
Reference : `/audit-code`

### Factory Pattern

```powershell
class ConnectionFactory {
    static [object] Create([string]$type, [string]$connString) {
        switch ($type) {
            'SqlServer'  { return [SqlConnection]::new($connString) }
            'MySQL'      { return [MySqlConnection]::new($connString) }
            'PostgreSQL' { return [NpgsqlConnection]::new($connString) }
            default      { throw "Unsupported: $type" }
        }
    }
}

$conn = [ConnectionFactory]::Create('SqlServer', $connString)
```

### Singleton Pattern

```powershell
class ConfigManager {
    static hidden [ConfigManager]$Instance = $null
    hidden [hashtable]$Config = @{}

    hidden ConfigManager() {
        $this.Config = Import-PowerShellDataFile ".\config.psd1"
    }

    static [ConfigManager] GetInstance() {
        if ($null -eq [ConfigManager]::Instance) {
            [ConfigManager]::Instance = [ConfigManager]::new()
        }
        return [ConfigManager]::Instance
    }

    [object] Get([string]$key) { return $this.Config[$key] }
}

$config = [ConfigManager]::GetInstance()
$apiUrl = $config.Get('ApiUrl')
```

### Builder Pattern (Fluent API)

```powershell
class EmailBuilder {
    hidden [string]$To
    hidden [string]$Subject
    hidden [string]$Body

    [EmailBuilder] SetTo([string]$to) { $this.To = $to; return $this }
    [EmailBuilder] SetSubject([string]$s) { $this.Subject = $s; return $this }
    [EmailBuilder] SetBody([string]$b) { $this.Body = $b; return $this }

    [object] Build() {
        if ([string]::IsNullOrEmpty($this.To)) { throw "To required" }
        return [PSCustomObject]@{
            To = $this.To
            Subject = $this.Subject
            Body = $this.Body
        }
    }
}

$email = [EmailBuilder]::new()
    .SetTo("user@example.com")
    .SetSubject("Report")
    .SetBody("Content")
    .Build()
```

### Strategy Pattern

```powershell
class GzipStrategy {
    [byte[]] Compress([byte[]]$data) {
        $ms = [System.IO.MemoryStream]::new()
        $gz = [System.IO.Compression.GZipStream]::new($ms, 'Compress')
        $gz.Write($data, 0, $data.Length)
        $gz.Close()
        return $ms.ToArray()
    }
}

class Compressor {
    hidden $Strategy

    Compressor($strategy) { $this.Strategy = $strategy }

    [void] CompressFile([string]$in, [string]$out) {
        $data = [System.IO.File]::ReadAllBytes($in)
        $compressed = $this.Strategy.Compress($data)
        [System.IO.File]::WriteAllBytes($out, $compressed)
    }
}
```

### Repository Pattern

```powershell
class CustomerRepository {
    hidden [string]$FilePath

    CustomerRepository([string]$path) { $this.FilePath = $path }

    [object] GetById([string]$id) {
        return $this.GetAll() | Where-Object Id -eq $id | Select-Object -First 1
    }

    [array] GetAll() {
        if (Test-Path $this.FilePath) {
            return Get-Content $this.FilePath -Raw | ConvertFrom-Json
        }
        return @()
    }

    [void] Add([object]$customer) {
        $all = $this.GetAll()
        $all += $customer
        $all | ConvertTo-Json -Depth 10 | Set-Content $this.FilePath
    }
}
```

### Caching Pattern

```powershell
$script:Cache = @{
    Data = [System.Collections.Generic.Dictionary[string,object]]::new()
    Expiry = [System.Collections.Generic.Dictionary[string,DateTime]]::new()
}

function Get-Cached {
    param([string]$Key, [scriptblock]$Compute, [int]$MinutesTTL = 60)

    $now = Get-Date
    if ($script:Cache.Data.ContainsKey($Key)) {
        if ($now -lt $script:Cache.Expiry[$Key]) {
            return $script:Cache.Data[$Key]  # HIT
        }
        $script:Cache.Data.Remove($Key)
    }

    # MISS - compute and store
    $value = & $Compute
    $script:Cache.Data[$Key] = $value
    $script:Cache.Expiry[$Key] = $now.AddMinutes($MinutesTTL)
    return $value
}
```

---

### Anti-Patterns Architecture

| Anti-Pattern | Criteres Detection | Severite | Impact |
|--------------|-------------------|----------|--------|
| **God Object** | >500 LOC, >15 methodes, >10 attributs | [!!] Critique | Maintenance impossible |
| **Spaghetti Code** | Graphe dependances chaotique, cycles | [!] Elevee | Comprehension difficile |
| **Big Ball of Mud** | Absence d'organisation, impacts imprevisibles | [!] Elevee | Evolution risquee |
| **Lava Flow** | Code mort abondant, TODO anciens (>6 mois) | [~] Moyenne | Dette technique |
| **Copy-Paste Programming** | Blocs >20 lignes dupliques | [~] Moyenne | Bugs propagation |
| **Golden Hammer** | Meme solution pour tous problemes | [~] Moyenne | Solutions inadaptees |

### Detection God Object

```powershell
# Indicateurs d'un God Object :

# 1. Trop de lignes
$loc = (Get-Content $file | Measure-Object -Line).Lines
if ($loc -gt 500) { "[!] God Object suspect : $loc lignes" }

# 2. Trop de fonctions/methodes
$functions = [regex]::Matches($content, 'function\s+\w+')
if ($functions.Count -gt 15) { "[!] God Object suspect : $($functions.Count) fonctions" }

# 3. Trop de responsabilites (heuristique : imports varies)
$imports = [regex]::Matches($content, 'Import-Module|using\s+namespace')
if ($imports.Count -gt 10) { "[~] Responsabilites multiples : $($imports.Count) imports" }
```

### Detection Spaghetti Code

Indicateurs :
- Fonctions appelant >10 autres fonctions
- Cycles de dependances (A -> B -> C -> A)
- Goto ou flow control non structure
- Variables globales modifiees partout

---

### Principes SOLID (Metriques Proxy)

#### Single Responsibility Principle (SRP)

| Metrique | Seuil Alerte | Detection |
|----------|--------------|-----------|
| LOC par fonction | > 100 | Fonction fait trop de choses |
| Parametres par fonction | > 5 | Responsabilites mixees |
| Imports par module | > 10 | Dependances excessives |

```powershell
# [-] Violation SRP
function Process-UserData {
    # Valide les donnees
    # Transforme les donnees
    # Sauvegarde en base
    # Envoie un email
    # Genere un rapport
}

# [+] SRP respecte
function Confirm-UserData { }
function ConvertTo-NormalizedUser { }
function Save-User { }
function Send-UserNotification { }
function New-UserReport { }
```

#### Open/Closed Principle (OCP)

| Indicateur | Probleme |
|------------|----------|
| Switch/If geant | Modification requise pour chaque nouveau cas |
| Hardcoded types | Pas d'extensibilite |

```powershell
# [-] Violation OCP
function Export-Data {
    param($Format)
    switch ($Format) {
        'CSV'  { <# ... #> }
        'JSON' { <# ... #> }
        'XML'  { <# ... #> }
        # Ajouter un format = modifier cette fonction
    }
}

# [+] OCP avec Strategy
$exporters = @{
    'CSV'  = { param($data) $data | Export-Csv }
    'JSON' = { param($data) $data | ConvertTo-Json }
}
function Export-Data {
    param($Format, $Data)
    & $exporters[$Format] $Data
}
# Ajouter un format = ajouter une entree, pas modifier
```

#### Dependency Inversion Principle (DIP)

| Indicateur | Probleme |
|------------|----------|
| `New-Object` dans fonctions | Couplage fort |
| Chemins en dur | Pas testable |

```powershell
# [-] Violation DIP
function Get-UserReport {
    $users = Get-ADUser -Filter *  # Dependance concrete
    # ...
}

# [+] DIP avec injection
function Get-UserReport {
    param(
        [scriptblock]$GetUsers = { Get-ADUser -Filter * }
    )
    $users = & $GetUsers
    # ...
}
# Testable : Get-UserReport -GetUsers { @([PSCustomObject]@{Name='Test'}) }
```

---

### Metriques Chidamber-Kemerer (CK)

| Metrique | Description | Seuil Alerte | Calcul |
|----------|-------------|--------------|--------|
| **WMC** | Weighted Methods per Class | > 20 | Somme complexite cyclomatique |
| **CBO** | Coupling Between Objects | > 14 | Nombre de classes/modules utilises |
| **RFC** | Response For Class | > 50 | Methodes + methodes appelees |
| **LCOM** | Lack of Cohesion Methods | > 0.8 | (M - sum(MF)/F) / (M-1) |
| **DIT** | Depth of Inheritance | > 5 | Profondeur heritage |
| **NOC** | Number of Children | > 10 | Classes derivees |

#### Adaptation PowerShell

| Metrique CK | Equivalent PowerShell |
|-------------|----------------------|
| WMC | Nombre fonctions x complexite moyenne |
| CBO | Nombre de modules importes + fonctions externes |
| RFC | Fonctions + cmdlets appeles |
| LCOM | Cohesion = variables partagees entre fonctions |

#### Exemple Calcul CBO

```powershell
# Fichier : MonModule.psm1

Import-Module ActiveDirectory      # +1 CBO
Import-Module ExchangeOnline       # +1 CBO

function Get-UserInfo {
    Get-ADUser                     # +1 CBO (si pas deja compte)
    Get-EXOMailbox                 # +1 CBO
    Send-MailMessage               # +1 CBO (module implicite)
}

# CBO = 5 (< 14 : OK)
```

---

## References

- Metriques SQALE et Complexite Cyclomatique : [code-audit/metrics-sqale.md](../../code-audit/metrics-sqale.md)
- Methodologie audit : [code-audit/methodology.md](../../code-audit/methodology.md)
- Anti-patterns code : [anti-patterns.md](anti-patterns.md)
