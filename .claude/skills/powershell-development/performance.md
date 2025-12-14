# Performance & Optimisation PowerShell

## Collections typées (CRITIQUE)

### [-] LENT : Array avec +=
```powershell
$slow = @()
for ($i = 0; $i -lt 10000; $i++) {
    $slow += $i  # Réallocation à chaque itération!
}
```

### [+] RAPIDE : List<T>
```powershell
$fast = [System.Collections.Generic.List[int]]::new()
for ($i = 0; $i -lt 10000; $i++) {
    $fast.Add($i)
}
```

### [+] Dictionary pour lookup O(1)
```powershell
$cache = [System.Collections.Generic.Dictionary[string,object]]::new()
$cache["user123"] = $userData
$exists = $cache.ContainsKey("user123")
```

### [+] HashSet pour valeurs uniques
```powershell
$unique = [System.Collections.Generic.HashSet[string]]::new()
$added = $unique.Add("value")  # false si déjà présent
```

### [+] Queue (FIFO) et Stack (LIFO)
```powershell
$queue = [System.Collections.Generic.Queue[object]]::new()
$queue.Enqueue("item")
$first = $queue.Dequeue()

$stack = [System.Collections.Generic.Stack[object]]::new()
$stack.Push("item")
$last = $stack.Pop()
```

## Pipeline vs Loop

### [-] LENT : Pipeline avec Where-Object
```powershell
$filtered = $data | Where-Object { $_.Status -eq 'Active' }
```

### [+] PLUS RAPIDE : Method .Where()
```powershell
$filtered = $data.Where({ $_.Status -eq 'Active' })
```

### [+] OPTIMAL : foreach loop
```powershell
$results = foreach ($item in $data) {
    if ($item.Status -eq 'Active') { $item }
}
```

## String Building

### [-] LENT : Concaténation
```powershell
$output = ""
for ($i = 0; $i -lt 1000; $i++) {
    $output += "Line $i`n"
}
```

### [+] RAPIDE : StringBuilder
```powershell
$sb = [System.Text.StringBuilder]::new()
for ($i = 0; $i -lt 1000; $i++) {
    [void]$sb.AppendLine("Line $i")
}
$output = $sb.ToString()
```

### [+] RAPIDE : Array join
```powershell
$lines = for ($i = 0; $i -lt 1000; $i++) { "Line $i" }
$output = $lines -join "`n"
```

## Garbage Collection manuel
```powershell
for ($i = 0; $i -lt $total; $i++) {
    # Traitement...
    
    if (($i % 1000) -eq 0 -and $i -gt 0) {
        $null = [System.GC]::GetTotalMemory($true)
        [System.GC]::WaitForPendingFinalizers()
    }
}
```

## StreamWriter pour gros fichiers
```powershell
$writer = [System.IO.StreamWriter]::new($path, $false, [System.Text.Encoding]::UTF8)
$writer.AutoFlush = $false

try {
    foreach ($item in $data) {
        $writer.WriteLine($item)
        if (($i % 100) -eq 0) { $writer.Flush() }
    }
} finally {
    $writer.Flush()
    $writer.Dispose()
}
```

## Parallélisation (PS 7+)
```powershell
$results = $items | ForEach-Object -ThrottleLimit 10 -Parallel {
    $config = $using:config  # Variables parent avec $using:
    Process-Item -Item $_ -Config $config
}
```

## Benchmark
```powershell
Measure-Command { <# code #> } | Select-Object TotalMilliseconds
```

---

## Analyse Complexite Big O (Audit)

### Table de Reference Rapide

| Notation | Nom | Verdict | Seuil N Max | Exemple PowerShell |
|----------|-----|---------|-------------|-------------------|
| O(1) | Constant | [+] Excellent | Infini | `$dict[$key]`, `$hashset.Contains()` |
| O(log n) | Logarithmique | [+] Excellent | Milliards | Recherche binaire |
| O(n) | Lineaire | [+] Bon | Millions | `foreach`, `.Where()`, `Where-Object` |
| O(n log n) | Log-lineaire | [~] Acceptable | 100 000 | `Sort-Object`, tri |
| O(n^2) | Quadratique | [!] Probleme | 1 000 | `foreach` imbrique, `@() +=` |
| O(n^3) | Cubique | [!!] Critique | 100 | Triple boucle |
| O(2^n) | Exponentiel | [!!] Inacceptable | 20 | Combinatoire brute |

### Patterns PowerShell et Complexite

| Pattern | Complexite | Note |
|---------|------------|------|
| `$dict[$key]` | O(1) | Lookup hashtable |
| `$list.Add($item)` | O(1) amorti | List generique |
| `$array += $item` | **O(n)** | Reallocation complete ! |
| `foreach ($x in $list)` | O(n) | Parcours lineaire |
| `$list.Where({})` | O(n) | Filtrage methode |
| `$list \| Where-Object` | O(n) | Pipeline (overhead) |
| `Sort-Object` | O(n log n) | Tri natif |
| `Group-Object` | O(n) | Groupement hashtable |
| `foreach` dans `foreach` | **O(n x m)** | Boucles imbriquees |
| `@() +=` dans boucle | **O(n^2)** | N reallocations |

### Calcul de Complexite

```
REGLES DE CALCUL :

Sequence    : O(f) + O(g) = O(max(f, g))
Boucle      : O(iterations) x O(corps)
Imbrication : O(n) x O(m) = O(n x m)
Recursion   : Analyser l'arbre d'appels
```

### Quantification Performance (Template Audit)

Pour chaque finding performance, fournir :

```
+---------------------------------------------------------------+
|              QUANTIFICATION PERFORMANCE                        |
+---------------------------------------------------------------+
|                                                                |
|  LOCALISATION : fichier.ps1:L42                               |
|  PATTERN      : [description du code]                         |
|                                                                |
|  COMPLEXITE ACTUELLE  : O([notation])                         |
|  COMPLEXITE OPTIMISEE : O([notation])                         |
|                                                                |
|  MESURES ESTIMEES :                                            |
|  | N elements | Actuel    | Optimise  | Gain   |              |
|  |------------|-----------|-----------|--------|              |
|  | 100        | [X] ms    | [Y] ms    | [Z]x   |              |
|  | 1 000      | [X] ms    | [Y] ms    | [Z]x   |              |
|  | 10 000     | [X] ms    | [Y] ms    | [Z]x   |              |
|                                                                |
|  EFFORT CORRECTION    : [X] heures                            |
|  FREQUENCE EXECUTION  : [X] fois/jour                         |
|  GAIN QUOTIDIEN       : [X] secondes                          |
|  ROI                  : Rentable apres [X] jours              |
|                                                                |
+---------------------------------------------------------------+
```

### Exemple Quantification

```
LOCALISATION : Export-Report.ps1:L87
PATTERN      : @() += dans boucle de 5000 users

COMPLEXITE ACTUELLE  : O(n^2) - 5000 reallocations
COMPLEXITE OPTIMISEE : O(n)   - List<T>.Add()

MESURES :
| N elements | Actuel | Optimise | Gain |
|------------|--------|----------|------|
| 1 000      | 2s     | 0.02s    | 100x |
| 5 000      | 50s    | 0.1s     | 500x |
| 10 000     | 200s   | 0.2s     | 1000x|

EFFORT : 30min
FREQUENCE : 10 fois/jour
GAIN QUOTIDIEN : 10 x 50s = 500s = 8.3min
ROI : Rentable apres 4 jours (30min / 8.3min)
```

### Opportunites Parallelisation (PS 7+)

```powershell
# Identifier les candidats a la parallelisation :
# - Boucles avec operations I/O (fichiers, reseau, API)
# - Boucles avec operations independantes
# - N > 100 elements

# AVANT : Sequentiel
foreach ($server in $servers) {
    Test-Connection -ComputerName $server -Count 1
}
# Temps : N x latence

# APRES : Parallele
$servers | ForEach-Object -ThrottleLimit 20 -Parallel {
    Test-Connection -ComputerName $_ -Count 1
}
# Temps : N x latence / min(N, ThrottleLimit)
```

### Seuils d'Alerte

| Situation | Seuil | Action |
|-----------|-------|--------|
| Boucle O(n^2) avec N > 1000 | [!] Alerte | Optimiser obligatoire |
| Boucle O(n^2) avec N > 100 | [~] Warning | Evaluer ROI |
| `@() +=` avec N > 50 | [!] Alerte | Remplacer par List<T> |
| Pipeline sur N > 10000 | [~] Warning | Considerer .Where() |

---

## References

- Metriques SQALE : `.claude/skills/code-audit/metrics-sqale.md`
- Methodologie audit : `.claude/skills/code-audit/methodology.md`
