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

## Seuils Performance PowerShell

| Pattern | Complexite | Seuil Alerte | Action |
|---------|------------|--------------|--------|
| `@() +=` en boucle | O(n²) | N > 50 | `List<T>.Add()` |
| `foreach` imbrique | O(n×m) | N×M > 10000 | Evaluer refactoring |
| `Where-Object` pipeline | O(n) + overhead | N > 10000 | `.Where()` |
| Parallelisation | O(n/p) | N > 100, I/O | `ForEach -Parallel` |

> Analyse Big O complete et quantification : voir [code-audit/metrics-sqale.md](../../code-audit/metrics-sqale.md)

---

## References

- Metriques SQALE et Big O : [code-audit/metrics-sqale.md](../../code-audit/metrics-sqale.md)
- Methodologie audit : [code-audit/methodology.md](../../code-audit/methodology.md)
