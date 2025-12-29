# Modules du Projet - Regle de Reutilisation

## Regle Fondamentale (OBLIGATOIRE)

**AVANT de coder une fonctionnalite (UI, logging, connexion, etc.) :**

1. Lister les modules existants dans `Modules/`
2. Lire le `CLAUDE.md` ou `README.md` de chaque module pertinent
3. Si besoin de details, lire le code du module
4. Importer le module existant
5. **NE JAMAIS recreer une fonction qui existe dans un module**

## Workflow de Decouverte

```powershell
# Etape 1 : Lister les modules disponibles
Get-ChildItem -Path ".\Modules" -Directory | Select-Object -ExpandProperty Name

# Etape 2 : Lire la documentation de chaque module
# → Modules/NomModule/CLAUDE.md (prioritaire)
# → Modules/NomModule/README.md (si pas de CLAUDE.md)

# Etape 3 : Si besoin de details, voir les fonctions exportees
Get-Command -Module NomModule
```

## POURQUOI cette regle ?

| Probleme | Consequence |
|----------|-------------|
| Duplication de code | 80+ lignes inutiles par script |
| Maintenance multiple | Bug corrige dans module, pas dans copie |
| Inconsistance UI | Chaque script a sa propre version |
| Violation DRY | Don't Repeat Yourself |

## Structure Attendue d'un Module

Chaque module dans `Modules/` devrait avoir :

```
Modules/
└── NomModule/
    ├── NomModule.psd1        # Manifeste
    ├── NomModule.psm1        # Code principal
    ├── CLAUDE.md             # Documentation AI (< 200 lignes)
    ├── README.md             # Documentation complete
    └── Settings.example.json # Configuration (si applicable)
```

> **Format standard** : Les modules sources utilisent le format `Module/` dans leur repo.
> Lors du bootstrap, les fichiers essentiels sont copies dans `Modules/<NomModule>/`.

Le fichier `CLAUDE.md` du module contient :
- Description du module
- Fonctions exportees avec exemples
- Configuration requise (si applicable)
- Cas d'usage

## Template Import Generique

```powershell
#region Modules
$modulePath = "$PSScriptRoot\Modules"

# Decouvrir les modules disponibles
$availableModules = Get-ChildItem -Path $modulePath -Directory -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Name

# Importer les modules necessaires (adapter selon le projet)
foreach ($moduleName in @('Write-Log', 'ConsoleUI')) {
    $moduleFile = Join-Path $modulePath "$moduleName\$moduleName.psm1"
    if (Test-Path $moduleFile) {
        Import-Module $moduleFile -Force -ErrorAction Stop
    }
}
#endregion
```

## Checklist Avant Creation Script

- [ ] `Get-ChildItem Modules/` execute
- [ ] `CLAUDE.md` ou `README.md` de chaque module lu
- [ ] Modules pertinents importes (pas de duplication)
- [ ] Pas de fonctions redefinies localement si elles existent dans un module

## Import de Modules Externes

Lors de l'import d'un module depuis un autre projet :

### Format Source Standard

Les modules sources utilisent le format `Module/` :
```
Module-NomModule/           # Repository GitHub
└── Module/                 # Dossier source
    ├── NomModule.psd1
    ├── NomModule.psm1
    ├── CLAUDE.md
    ├── README.md
    └── Settings.example.json
```

### Fichiers a copier (5 essentiels)

| Fichier | Role | Obligatoire |
|---------|------|-------------|
| `NomModule.psd1` | Manifest | OUI |
| `NomModule.psm1` | Code | OUI |
| `CLAUDE.md` | Ref AI (< 200 lignes) | Recommande |
| `README.md` | Doc complete | Recommande |
| `Settings.example.json` | Config module | Si applicable |

### Fichiers a EXCLURE

| Dossier/Fichier | Raison |
|-----------------|--------|
| `.claude/` | Config Claude Code du projet source |
| `audit/` | Rapports d'audit (historique) |
| `Config/` | Dossier config (Settings.example.json est a la racine) |
| `Examples/` | Exemples (deja documentes dans README) |
| `docs/` | Issues, SESSION-STATE, ROADMAP |
| `Tests/` | Tests unitaires (testes dans repo source) |

### Exemple copie (nouveau format)

```powershell
$source = "D:\Projets\Module-ConsoleUI\Module"  # Nouveau format
$dest = ".\Modules\ConsoleUI"

$files = @("ConsoleUI.psd1", "ConsoleUI.psm1", "CLAUDE.md", "README.md", "Settings.example.json")
New-Item -Path $dest -ItemType Directory -Force
foreach ($file in $files) {
    Copy-Item -Path "$source\$file" -Destination $dest -ErrorAction SilentlyContinue
}
```

## Reference Complete

Pour la documentation exhaustive (Progressive Disclosure, sections CLAUDE.md, etc.) :
Voir `docs/referentiel/CLAUDE-CODE-GUIDE.md` section 25.
