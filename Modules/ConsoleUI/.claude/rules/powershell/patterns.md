# Design Patterns PowerShell

## Factory Pattern
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

## Singleton Pattern
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

## Builder Pattern (Fluent API)
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

## Strategy Pattern
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

## Repository Pattern
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

## Caching Pattern
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

## Anti-Patterns Architecture (Audit)

### Patterns a Detecter

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

## Principes SOLID (Metriques Proxy)

### Single Responsibility Principle (SRP)

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

### Open/Closed Principle (OCP)

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

### Dependency Inversion Principle (DIP)

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

## Metriques Chidamber-Kemerer (CK)

### Metriques pour Classes/Modules PowerShell

| Metrique | Description | Seuil Alerte | Calcul |
|----------|-------------|--------------|--------|
| **WMC** | Weighted Methods per Class | > 20 | Somme complexite cyclomatique |
| **CBO** | Coupling Between Objects | > 14 | Nombre de classes/modules utilises |
| **RFC** | Response For Class | > 50 | Methodes + methodes appelees |
| **LCOM** | Lack of Cohesion Methods | > 0.8 | (M - sum(MF)/F) / (M-1) |
| **DIT** | Depth of Inheritance | > 5 | Profondeur heritage |
| **NOC** | Number of Children | > 10 | Classes derivees |

### Adaptation PowerShell

PowerShell n'etant pas purement OO, adapter les metriques :

| Metrique CK | Equivalent PowerShell |
|-------------|----------------------|
| WMC | Nombre fonctions x complexite moyenne |
| CBO | Nombre de modules importes + fonctions externes |
| RFC | Fonctions + cmdlets appeles |
| LCOM | Cohesion = variables partagees entre fonctions |

### Exemple Calcul CBO

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

## Complexite Cyclomatique

### Definition

```
CC = 1 + nombre de (if, elseif, switch case, while, for, foreach, -and, -or, catch)
```

### Seuils

| CC | Risque | Testabilite | Action |
|----|--------|-------------|--------|
| 1-10 | Faible | Facile | OK |
| 11-20 | Modere | Moderee | Surveiller |
| 21-50 | Eleve | Difficile | Refactoring |
| > 50 | Tres eleve | Quasi impossible | Urgent |

### Exemple

```powershell
function Process-Order {      # CC = 1 (base)
    param($Order)

    if ($Order.Status -eq 'New') {           # +1 = 2
        if ($Order.Amount -gt 1000) {        # +1 = 3
            if ($Order.Customer.VIP) {       # +1 = 4
                # ...
            } elseif ($Order.Customer.Gold) { # +1 = 5
                # ...
            }
        }
    } elseif ($Order.Status -eq 'Pending') {  # +1 = 6
        foreach ($item in $Order.Items) {     # +1 = 7
            if ($item.Stock -lt 0) {          # +1 = 8
                # ...
            }
        }
    }
}
# CC = 8 : Acceptable mais surveiller
```

---

## References

- Metriques SQALE : @.claude/rules/common/metrics-sqale.md
- Methodologie audit : @.claude/rules/common/audit-methodology.md
- Anti-patterns code : @.claude/rules/powershell/anti-patterns.md
