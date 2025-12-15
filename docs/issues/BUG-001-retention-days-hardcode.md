# [!] BUG-001-retention-days-hardcode - Effort: 5min

## PROBLEME

La rotation des logs utilise une valeur hardcodee `30` au lieu de `$script:Config.Retention.LogDays`. La configuration definie dans `Settings.json` est ignoree pour la retention des logs.

## LOCALISATION

- Fichier : Get-ExchangeDelegation.ps1:936
- Fonction : bloc `finally` (main)
- Variable config : `$script:Config.Retention.LogDays`

## OBJECTIF

Utiliser la valeur de configuration `$script:Config.Retention.LogDays` pour la rotation des logs, permettant la personnalisation sans modification du code.

---

## IMPLEMENTATION

### Etape 1 : Corriger l'appel Invoke-LogRotation - 2min

Fichier : Get-ExchangeDelegation.ps1:936

AVANT :
```powershell
    Invoke-LogRotation -Path "$PSScriptRoot\Logs" -RetentionDays 30 -ErrorAction SilentlyContinue
```

APRES :
```powershell
    Invoke-LogRotation -Path $logPath -RetentionDays $script:Config.Retention.LogDays -ErrorAction SilentlyContinue
```

Note : `$logPath` est deja defini ligne 170.

---

## VALIDATION

### Criteres d'Acceptation

- [x] Invoke-LogRotation utilise `$script:Config.Retention.LogDays`
- [x] Invoke-LogRotation utilise `$logPath` (variable existante)
- [x] Pas de regression

## CHECKLIST

- [x] Code AVANT = code reel
- [x] Tests passent
- [x] Code review

Labels : bug elevee config

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | # (apres gh issue create) |
| Statut | RESOLVED |
| Branche | fix/BUG-001-retention-days-hardcode |
