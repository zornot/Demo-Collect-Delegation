# [-] FEAT-007-implementation-settings-json - Effort: 5min

## PROBLEME

Le fichier `Config/Settings.json` n'existe pas. Le script utilise les valeurs par defaut hardcodees dans `Get-ScriptConfiguration`. L'utilisateur doit pouvoir personnaliser la configuration sans modifier le code.

## LOCALISATION

- Fichier : Config/Settings.example.json (template existant)
- Fichier cible : Config/Settings.json (a creer)
- Fonction : Get-ScriptConfiguration() dans Get-ExchangeDelegation.ps1:102-143

## OBJECTIF

Creer `Config/Settings.json` a partir du template pour permettre la personnalisation de la configuration (chemins, retention, environnement).

---

## IMPLEMENTATION

### Etape 1 : Copier le template - 1min

```powershell
Copy-Item "Config/Settings.example.json" "Config/Settings.json"
```

### Etape 2 : Adapter les valeurs - 3min

Fichier : Config/Settings.json

AVANT :
```json
{
    "_comment": "Copier vers Settings.json et adapter les valeurs selon environnement",
    "_version": "1.0.0",
    ...
}
```

APRES :
```json
{
    "_version": "1.0.0",

    "Application": {
        "Name": "Get-ExchangeDelegation",
        "Environment": "PROD",
        "LogLevel": "Info"
    },

    "Paths": {
        "Logs": "./Logs",
        "Output": "./Output"
    },

    "Retention": {
        "LogDays": 30,
        "OutputDays": 7
    }
}
```

### Etape 3 : Verification gitignore - 1min

Verifier que `Config/Settings.json` est dans `.gitignore` (contient potentiellement des chemins sensibles).

---

## VALIDATION

### Criteres d'Acceptation

- [x] Settings.json existe dans Config/
- [x] Script log "Configuration chargee depuis Config/Settings.json"
- [x] Settings.json dans .gitignore
- [x] Pas de regression

## CHECKLIST

- [x] Template copie
- [x] Valeurs adaptees
- [x] gitignore verifie
- [x] Test execution script

Labels : feat faible config

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | # (apres gh issue create) |
| Statut | RESOLVED |
| Branche | feature/FEAT-007-implementation-settings-json |
