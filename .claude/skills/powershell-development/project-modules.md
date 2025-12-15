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
    ├── CLAUDE.md        # Documentation pour Claude (prioritaire)
    ├── README.md        # Documentation humaine
    ├── NomModule.psm1   # Module principal
    └── NomModule.psd1   # Manifeste (optionnel)
```

Le fichier `CLAUDE.md` du module contient :
- Description du module
- Fonctions exportees avec exemples
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
        Import-Module $moduleFile -ErrorAction Stop
    }
}
#endregion
```

## Checklist Avant Creation Script

- [ ] `Get-ChildItem Modules/` execute
- [ ] `CLAUDE.md` ou `README.md` de chaque module lu
- [ ] Modules pertinents importes (pas de duplication)
- [ ] Pas de fonctions redefinies localement si elles existent dans un module
