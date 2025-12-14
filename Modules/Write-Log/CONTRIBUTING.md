# Guide de Contribution Universel

> Template standardise pour tous les projets PowerShell.
> Version: 1.2.0 | Date: 2025-12-02

---

## Table des Matieres

1. [Workflow de Developpement](#workflow-de-developpement)
2. [Structure du Projet](#structure-du-projet)
3. [Conventions de Code](#conventions-de-code)
4. [Documentation](#documentation)
5. [Tests](#tests)
6. [Versioning](#versioning)
7. [Git et Sauvegarde](#git-et-sauvegarde)
8. [Fichiers de Configuration](#fichiers-de-configuration)
9. [Securite](#securite)
10. [Commandes Utiles](#commandes-utiles)

---

## Workflow de Developpement

### 0. Creation d'une Issue (OBLIGATOIRE)

> **Workflow Local-First**: Les issues sont d'abord creees localement dans `Docs/Issues/`, puis synchronisees sur GitHub au moment du commit/push.

#### Etape 1 : Creer l'issue localement

1. Copier le template `Docs/Issues/TEMPLATE.md` vers `Docs/Issues/ISSUE-XXX-titre-court.md`
2. Remplir le template avec le format complet ci-dessous
3. Mettre a jour l'index `Docs/Issues/ISSUES.md`

#### Etape 2 : Synchroniser sur GitHub (au commit/push)

```bash
# Au moment du commit, creer l'issue GitHub correspondante
gh issue create --title "[TYPE-XXX] Titre" --body-file Docs/Issues/ISSUE-XXX-titre-court.md

# Noter le numero GitHub dans l'issue locale (champ "GitHub: #XXX")
# Commiter avec reference: "Fixes #XXX"
```

#### Template d'issue complet :

```markdown
# [!!|!|~|-] [TYPE-ID] Titre Imperatif | Effort: Xh

## PROBLEME
[Description technique 2-3 phrases]

## LOCALISATION
- Fichier : path/to/file.ext:L[debut]-[fin]
- Fonction : nomFonction()
- Module : NomComposant

## OBJECTIF
[Etat cible apres correction]

---

## ANALYSE IMPACT

### Fichiers Impactes
| Fichier | Raison | Action Requise |
|---------|--------|----------------|
| [fichier] | [appelle fonction modifiee] | [verifier/adapter] |

### Code Mort a Supprimer
| Ligne | Code | Raison |
|-------|------|--------|
| [X] | `[extrait]` | [plus utilise apres correction] |

---

## IMPLEMENTATION

### Etape 1 : [Action] - [X]min
Fichier : path/to/file.ext
Lignes [X-Y] - [AJOUTER | MODIFIER | SUPPRIMER]

AVANT (code REEL) :
```[langage]
[code exact tel qu'il existe]
```

APRES :
```[langage]
[code corrige]
```

Justification : [explication technique]

---

## VALIDATION

### Execution Virtuelle
```
Entree : [donnees test]
L[X] : [variable] = [valeur]
Sortie : [resultat]
```
[>] VALIDE - Le code APRES couvre tous les cas

### Criteres d'Acceptation
- [ ] [Condition specifique et verifiable]
- [ ] [Comportement attendu mesurable]
- [ ] Pas de regression sur [fonctionnalite liee]

---

## DEPENDANCES
- Bloquee par : #[XXX] | Aucune
- Bloque : #[YYY]
- Liee a : #[ZZZ]

## POINTS ATTENTION
- [X] fichiers modifies
- [Y] lignes ajoutees/supprimees
- Risques : [liste avec mitigation]

## CHECKLIST
- [ ] Code AVANT = code reel verifie
- [ ] Execution virtuelle validee
- [ ] Tests unitaires passent
- [ ] Code review effectuee

---

Labels : [type] [priorite] [module] [effort]
Sprint : [0|1|2|3|Backlog]
```

**Niveaux de priorite:**
| Symbole | Niveau | Description |
|---------|--------|-------------|
| `!!` | Critique | Bloquant, hotfix immediat |
| `!` | Elevee | Sprint courant |
| `~` | Moyenne | Sprint suivant |
| `-` | Faible | Backlog |

**Types d'issue:**
| Type | Usage |
|------|-------|
| `BUG` | Correction de bug |
| `FEAT` | Nouvelle fonctionnalite |
| `REFACTOR` | Amelioration du code |
| `ARCH` | Architecture/SOLID |
| `DRY` | Elimination duplication |
| `MAIN` | Maintenabilite |

### 1. Preparation de la branche

```bash
git checkout main
git pull origin main
git checkout -b feature/issue-XX
```

### 2. Implementation du code (OBLIGATOIRE)

Appliquer les modifications decrites dans la section IMPLEMENTATION de l'issue :

1. **Lire l'issue** : Verifier le code AVANT correspond au code actuel
2. **Appliquer chaque etape** : Modifier le code selon les blocs APRES
3. **Valider la syntaxe** :
   ```powershell
   # Validation syntaxe PowerShell
   $errors = $null
   [System.Management.Automation.Language.Parser]::ParseFile("./MonScript.ps1", [ref]$null, [ref]$errors)
   if ($errors) { $errors | ForEach-Object { Write-Error $_.Message } }
   ```

### 3. Tests (TDD)

```bash
# Executer les tests APRES implementation
pwsh -Command "Invoke-Pester -Path ./Tests -Output Detailed"
```

### 4. Commit (Conventional Commits)

Commiter l'issue ET le code corrige ensemble :

```bash
# Ajouter les fichiers modifies
git add Issues/ISSUE-XXX-*.md    # Documentation de l'issue
git add Issues/ISSUES.md         # Index mis a jour
git add MonScript.ps1            # Code corrige

# Commit avec message structure
git commit -m "fix(scope): description imperative

Corps optionnel expliquant le POURQUOI.
Limite 72 caracteres par ligne.

Fixes #XX

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

**Types de commit:**
| Type | SemVer | Usage |
|------|--------|-------|
| `fix` | PATCH | Correction de bug |
| `feat` | MINOR | Nouvelle fonctionnalite |
| `refactor` | - | Refactoring sans changement fonctionnel |
| `perf` | PATCH | Amelioration performance |
| `test` | - | Ajout/modification de tests |
| `docs` | - | Documentation uniquement |
| `style` | - | Formatage, espaces, virgules |
| `chore` | - | Maintenance, dependances |
| `build` | - | Systeme de build, CI/CD |

**Regles:**
- Mode imperatif : "Add" pas "Added" ou "Adding"
- Sujet <= 50 caracteres
- Corps <= 72 caracteres/ligne
- `!` apres type = BREAKING CHANGE (ex: `feat!:`)

### 5. Push

```bash
git push -u origin feature/issue-XX
```

### 6. Merge et nettoyage

```bash
git checkout main
git merge feature/issue-XX
git push origin main
git branch -d feature/issue-XX
git push origin --delete feature/issue-XX
```

### Resume du Workflow Complet

```
┌─────────────────────────────────────────────────────────────┐
│  0. ISSUE        Documenter probleme + solution (AVANT/APRES)│
├─────────────────────────────────────────────────────────────┤
│  1. BRANCHE      git checkout -b feature/issue-XX           │
├─────────────────────────────────────────────────────────────┤
│  2. CODE         Appliquer les modifications de l'issue     │
├─────────────────────────────────────────────────────────────┤
│  3. TEST         Invoke-Pester / validation syntaxe         │
├─────────────────────────────────────────────────────────────┤
│  4. COMMIT       Issue + Code corrige ensemble              │
├─────────────────────────────────────────────────────────────┤
│  5. PUSH         git push -u origin feature/issue-XX        │
├─────────────────────────────────────────────────────────────┤
│  6. MERGE        Merger dans main + supprimer branche       │
└─────────────────────────────────────────────────────────────┘
```

---

## Structure du Projet

### Arborescence Standard

```
[NomProjet]/
|
|-- [ScriptPrincipal].ps1          # Point d'entree (orchestrateur)
|-- README.md                       # Documentation principale
|-- CONTRIBUTING.md                 # Ce fichier
|-- CHANGELOG.md                    # Historique des versions
|-- LICENSE                         # Licence (si applicable)
|-- .gitignore                      # Fichiers ignores
|
|-- src/                            # CODE SOURCE (si plusieurs scripts)
|   |-- [Module1].ps1
|   |-- [Module2].ps1
|   +-- ...
|
|-- Modules/                        # MODULES POWERSHELL REUTILISABLES
|   |-- [NomModule]/
|   |   |-- [NomModule].psd1        # Manifest
|   |   |-- [NomModule].psm1        # Module principal
|   |   |-- Public/                 # Fonctions exportees
|   |   |-- Private/                # Fonctions internes
|   |   +-- README.md
|   +-- ...
|
|-- Config/                         # CONFIGURATION
|   |-- Settings.json               # Configuration principale
|   |-- Settings.example.json       # Template (versionne)
|   +-- README.md
|
|-- Tests/                          # TESTS PESTER
|   |-- Unit/                       # Tests unitaires
|   |-- Integration/                # Tests integration
|   |-- Fixtures/                   # Donnees de test (mocks)
|   |-- Coverage/                   # Rapports couverture (gitignore)
|   +-- README.md
|
|-- Docs/                           # DOCUMENTATION
|   |-- Architecture.md             # Architecture technique
|   |-- Audit/                      # Analyses et audits AI (recherches, recommandations)
|   |-- Issues/                     # Issues locales (workflow local-first)
|   |   |-- ISSUES.md               # Index des issues
|   |   +-- TEMPLATE.md             # Template d'issue
|   |-- API/                        # Documentation API (optionnel)
|   +-- README.md
|
|-- Scripts/                        # SCRIPTS UTILITAIRES (dev)
|   |-- Build.ps1                   # Script de build
|   |-- Deploy.ps1                  # Script de deploiement
|   +-- README.md
|
|-- Logs/                           # LOGS RUNTIME (gitignore)
|   +-- README.md
|
|-- Output/                         # SORTIES GENEREES (gitignore)
|   +-- README.md
|
|-- Backups/                        # SAUVEGARDES LOCALES (gitignore)
|   +-- README.md
|
|-- .temp/                          # FICHIERS TEMPORAIRES (gitignore)
|   +-- README.md
|
+-- .github/                        # GITHUB SPECIFIQUE
    |-- ISSUE_TEMPLATE/
    |-- workflows/                  # GitHub Actions
    +-- PULL_REQUEST_TEMPLATE.md
```

### Regles par Dossier

| Dossier | Git | Contenu | README.md |
|---------|-----|---------|-----------|
| `src/`, `Modules/` | Versionne | Code source | Optionnel |
| `Config/` | `.example.json` uniquement | Configuration | Obligatoire |
| `Tests/` | Versionne (sauf Coverage/) | Tests Pester | Obligatoire |
| `Docs/` | Versionne | Documentation | Optionnel |
| `Scripts/` | Versionne | Scripts dev | Optionnel |
| `Logs/` | Ignore | Logs runtime | Obligatoire |
| `Output/` | Ignore | Fichiers generes | Obligatoire |
| `Backups/` | Ignore | Sauvegardes | Obligatoire |
| `.temp/` | Ignore | Temporaires AI | Optionnel |
| `Docs/Audit/` | Versionne | Analyses AI | Optionnel |
| `Docs/Issues/` | Versionne | Issues locales | Obligatoire |

### Fichiers a la Racine (Initialisation)

Lors de l'initialisation d'un projet, creer ces fichiers a la racine :

| Fichier | Source | Description |
|---------|--------|-------------|
| `README.md` | Creer | Documentation principale du projet |
| `CONTRIBUTING.md` | Copier ce template | Guide de contribution |
| `CHANGELOG.md` | Creer | Historique des versions |
| `LICENSE` | Creer | Licence (MIT, Apache, etc.) |
| `.gitignore` | Copier le template standard | Fichiers ignores par Git |

> **Note**: Chaque dossier important doit contenir un `README.md` expliquant son contenu, meme si le dossier est vide (pour conserver la structure dans Git via les regles `!dossier/README.md` du .gitignore).

### Scripts Utilitaires vs Scripts AI Temporaires

| Dossier | Usage | Exemples | Git |
|---------|-------|----------|-----|
| `Scripts/` | Scripts utilitaires reutilisables | Build.ps1, Deploy.ps1, helpers | Versionne |
| `.temp/` | Scripts AI jetables (debug, validation) | validate-syntax.ps1, test-*.ps1 | Ignore |

**Regles pour les scripts generes par AI :**

1. **Scripts temporaires** (validation syntaxe, exploration, tests rapides)
   - Placer dans `.temp/`
   - Supprimer apres usage
   - Non versionnes (gitignore)

2. **Scripts utilitaires** (helpers, build, deploy)
   - Placer dans `Scripts/`
   - Revus avant commit
   - Versionnes avec `Co-Authored-By: Claude`

> **Important** : Ne jamais laisser de scripts temporaires AI a la racine du projet.
> Utiliser systematiquement `.temp/` pour eviter les commits accidentels.

---

## Conventions de Code

### Nommage PowerShell

| Element | Convention | Exemple |
|---------|------------|---------|
| Fonctions | `Verb-Noun` (PascalCase) | `Get-UserMailbox`, `Set-Configuration` |
| Variables locales | `$camelCase` | `$userName`, `$mailboxList` |
| Variables script | `$script:PascalCase` | `$script:Config`, `$script:Colors` |
| Parametres | `$PascalCase` | `$UserName`, `$FilePath` |
| Constantes | `$UPPER_SNAKE_CASE` | `$MAX_RETRY_COUNT` |
| Index boucle | `$itemIndex` | `$appIndex`, `$userIndex` (pas `$i`) |
| Booleens | `$is...`, `$has...`, `$should...` | `$isEnabled`, `$hasLicense` |

### Verbes PowerShell Approuves

```powershell
# Obtenir la liste des verbes approuves
Get-Verb | Sort-Object Verb
```

| Categorie | Verbes Courants |
|-----------|-----------------|
| Common | `Add`, `Clear`, `Close`, `Copy`, `Get`, `New`, `Remove`, `Set` |
| Data | `Export`, `Import`, `Convert`, `ConvertFrom`, `ConvertTo` |
| Lifecycle | `Enable`, `Disable`, `Start`, `Stop`, `Restart` |
| Diagnostic | `Test`, `Measure`, `Trace`, `Debug` |
| Security | `Grant`, `Revoke`, `Protect`, `Unprotect` |

### Structure des Fonctions

```powershell
function Verb-Noun {
    <#
    .SYNOPSIS
        Description courte (1 ligne).

    .DESCRIPTION
        Description detaillee du comportement.
        Plusieurs lignes si necessaire.

    .PARAMETER Param1
        Description du parametre.

    .PARAMETER Param2
        Description du second parametre.

    .OUTPUTS
        [Type] Description de la sortie.

    .EXAMPLE
        Verb-Noun -Param1 "valeur"
        Description de l'exemple.

    .EXAMPLE
        Verb-Noun -Param1 "autre" -Param2 123
        Second exemple avec plus de parametres.

    .NOTES
        Auteur: [Nom]
        Version: 1.0.0
        Date: YYYY-MM-DD
    #>
    [CmdletBinding()]
    [OutputType([TypeRetour])]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$Param1,

        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$Param2 = 10
    )

    begin {
        # Initialisation (une seule fois)
    }

    process {
        # Traitement principal (pour chaque element du pipeline)
    }

    end {
        # Finalisation (une seule fois)
    }
}
```

### Validation des Entrees Utilisateur

```powershell
# TOUJOURS utiliser TryParse pour les conversions numeriques
$index = 0
if (-not [int]::TryParse($userInput, [ref]$index)) {
    Write-Error "Valeur numerique attendue"
    return
}

# JAMAIS caster directement (leve une exception)
# $index = [int]$userInput  # INTERDIT
```

### Gestion des Erreurs

```powershell
# Pattern standard
try {
    $result = Get-SomethingRisky -ErrorAction Stop
}
catch [System.SpecificException] {
    Write-Warning "Erreur specifique: $($_.Exception.Message)"
    # Gestion specifique
}
catch {
    Write-Error "Erreur inattendue: $($_.Exception.Message)"
    throw
}
finally {
    # Nettoyage (toujours execute)
}
```

### Commentaires

```powershell
# BIEN : Explique le POURQUOI
# Retry necessaire car API EXO throttle apres 1000 requetes/minute
Invoke-WithRetry -ScriptBlock { Get-EXOMailbox }

# MAL : Explique le QUOI (evident)
# Obtient la mailbox
Get-EXOMailbox
```

---

## Documentation

### README.md - Structure Standard

```markdown
# [Nom du Projet]

[Description courte 1-2 phrases]

**Version**: X.Y.Z
**Statut**: [Development | Production | Deprecated]
**Date**: YYYY-MM-DD

---

## Demarrage Rapide

### Prerequis

- PowerShell 5.1+ ou PowerShell 7.x
- [Autres dependances]

### Installation

```powershell
git clone [url]
cd [projet]
```

### Utilisation

```powershell
.\Script.ps1 -Param1 "valeur"
```

---

## Fonctionnalites

- [x] Fonctionnalite 1
- [x] Fonctionnalite 2
- [ ] Fonctionnalite future

---

## Structure du Projet

```
[Arborescence simplifiee]
```

---

## Configuration

[Instructions de configuration]

---

## Tests

```powershell
Invoke-Pester -Path ./Tests
```

---

## Documentation

- [Architecture](Docs/Architecture.md)
- [CHANGELOG](CHANGELOG.md)
- [CONTRIBUTING](CONTRIBUTING.md)

---

## Auteurs

- **[Nom]** - Developpement initial

## Licence

[Type de licence]
```

### CHANGELOG.md - Format Keep a Changelog

```markdown
# Changelog

Toutes les modifications notables sont documentees dans ce fichier.

Format base sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/).
Ce projet adhere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- [Nouvelles fonctionnalites en cours]

---

## [1.2.0] - 2025-01-15

### Added
- Nouvelle fonctionnalite X (#123)

### Changed
- Amelioration de Y pour meilleure performance

### Fixed
- Correction bug Z (#124)

### Deprecated
- Fonction `Old-Function` sera supprimee en v2.0.0

---

## [1.1.0] - 2025-01-01

### Added
- Fonctionnalite initiale

---

## [1.0.0] - 2024-12-15

### Added
- Version initiale
```

**Categories CHANGELOG:**
| Categorie | Usage |
|-----------|-------|
| `Added` | Nouvelles fonctionnalites |
| `Changed` | Changements fonctionnels existants |
| `Deprecated` | Fonctionnalites bientot supprimees |
| `Removed` | Fonctionnalites supprimees |
| `Fixed` | Corrections de bugs |
| `Security` | Correctifs de securite |

---

## Tests

### Organisation des Tests Pester

```
Tests/
|-- Unit/
|   |-- [Module1].Tests.ps1
|   |-- [Module2].Tests.ps1
|   +-- ...
|-- Integration/
|   |-- [Scenario1].Tests.ps1
|   +-- ...
|-- Fixtures/
|   |-- MockData.json
|   +-- ...
+-- Coverage/                       # (gitignore)
```

### Structure d'un Test Pester 5+

```powershell
BeforeAll {
    # Import du code a tester (une seule fois)
    . $PSScriptRoot/../src/Get-Something.ps1
}

Describe "Get-Something" {
    BeforeAll {
        # Setup pour tous les tests de ce Describe
        $script:testData = @{ Key = "Value" }
    }

    Context "Quand l'entree est valide" {
        BeforeEach {
            # Setup pour chaque test de ce Context
            $script:result = Get-Something -Input "valid"
        }

        It "Retourne un objet non null" {
            $result | Should -Not -BeNullOrEmpty
        }

        It "Contient la propriete attendue" {
            $result.Property | Should -Be "ExpectedValue"
        }
    }

    Context "Quand l'entree est invalide" {
        It "Leve une exception pour null" {
            { Get-Something -Input $null } | Should -Throw
        }

        It "Retourne erreur pour chaine vide" {
            { Get-Something -Input "" } | Should -Throw "*cannot be empty*"
        }
    }

    Context "Avec dependances mockees" {
        BeforeAll {
            # Mock actif pour tout ce Context
            Mock Get-ExternalData { return @{ Status = "OK" } }
        }

        It "Appelle le service externe une fois" {
            Get-Something -Input "test"
            Should -Invoke Get-ExternalData -Times 1 -Exactly
        }
    }
}
```

### Commandes de Test

```powershell
# Tous les tests
Invoke-Pester -Path ./Tests

# Tests avec details
Invoke-Pester -Path ./Tests -Output Detailed

# Tests par tag
Invoke-Pester -Path ./Tests -Tag "Unit"
Invoke-Pester -Path ./Tests -ExcludeTag "Integration"

# Avec couverture de code
Invoke-Pester -Path ./Tests -CodeCoverage ./src/*.ps1

# Export resultats CI/CD
Invoke-Pester -Path ./Tests -OutputFile TestResults.xml -OutputFormat NUnitXml
```

### Tags Recommandes

| Tag | Usage |
|-----|-------|
| `Unit` | Tests unitaires isoles |
| `Integration` | Tests avec dependances reelles |
| `Slow` | Tests lents (> 5s) |
| `RequiresAdmin` | Necessite elevation |
| `RequiresNetwork` | Necessite connexion |
| `BUG-XXX` | Test lie a une issue |

### Donnees de Test - Anonymisation Obligatoire

> **REGLE CRITIQUE** : Les tests ne doivent JAMAIS contenir de donnees de production reelles.

#### Pourquoi ?

- **Securite** : Eviter la fuite d'informations sensibles (emails, serveurs, GUIDs Azure)
- **Publication** : Permettre la publication du repository en open source
- **Conformite** : Respecter le RGPD et les politiques de confidentialite
- **Maintenance** : Faciliter les contributions externes sans risque

#### Donnees Interdites dans les Tests

| Type | Exemple Interdit | Risque |
|------|------------------|--------|
| Domaines client | `@client.com`, `@client.fr` | Identification |
| Serveurs reels | `VMPRODDC01`, `srv-exchange` | Infrastructure |
| GUIDs Azure | `79433f48-c36b-...` | Tenant/App ID |
| Emails personnels | `prenom.nom@client.com` | PII / RGPD |
| Chemins AD | `DC=ad,DC=client,DC=com` | Structure interne |
| Credentials | Thumbprints, secrets | Securite critique |

#### Donnees de Remplacement Standards

Utiliser les **domaines Microsoft de demonstration** (convention universelle) :

| Original | Remplacement | Usage |
|----------|--------------|-------|
| Domaine client principal | `contoso.com` | Microsoft standard |
| Domaine secondaire/partenaire | `fabrikam.com` | Microsoft standard |
| Tenant Azure | `contoso.onmicrosoft.com` | Convention |
| Serveurs | `SRV01`, `DC01`, `EXCH01` | Generique |
| GUIDs | `00000000-0000-0000-0000-000000000001` | Placeholder |
| Emails admin | `admin@contoso.com` | Generique |
| Chemins AD | `DC=ad,DC=contoso,DC=com` | Convention |

#### Exemple de Fichier MockUsers.json

```json
{
    "Users": [
        {
            "SamAccountName": "jdupont",
            "UserPrincipalName": "jean.dupont@contoso.com",
            "DisplayName": "Jean DUPONT",
            "DistinguishedName": "CN=Jean DUPONT,OU=Users,DC=ad,DC=contoso,DC=com",
            "extensionAttribute7": "F",
            "extensionAttribute15": "MAILBOX_TO_CREATE"
        }
    ],
    "ExchangeConfig": {
        "Organization": "contoso.onmicrosoft.com",
        "AppId": "00000000-0000-0000-0000-000000000001"
    }
}
```

#### Checklist Avant Commit de Tests

- [ ] Aucun domaine client reel (`@client.com`)
- [ ] Aucun nom de serveur de production
- [ ] Aucun GUID Azure reel
- [ ] Aucun email personnel identifiable
- [ ] Aucun chemin AD de production
- [ ] Utilisation de `contoso.com` / `fabrikam.com`

#### Script de Verification (Pre-commit)

```powershell
# Detecter donnees sensibles dans les fichiers de test
$patterns = @(
    '@(?!contoso|fabrikam)[a-z]+\.(com|fr|net)',  # Domaines non-standards
    'DC=(?!contoso|fabrikam)',                     # AD paths non-standards
    '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'  # GUIDs (verifier manuellement)
)

Get-ChildItem -Path ./Tests -Recurse -Include *.ps1,*.json |
    ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        foreach ($pattern in $patterns) {
            if ($content -match $pattern) {
                Write-Warning "Donnee potentiellement sensible dans $($_.Name): $($Matches[0])"
            }
        }
    }
```

> **Note** : Lors d'un audit de code existant, utiliser `grep -r` pour identifier toutes les occurrences de donnees sensibles, puis les remplacer systematiquement avant publication.

---

## Versioning

### Semantic Versioning (SemVer)

Format: `MAJOR.MINOR.PATCH` (ex: `2.1.3`)

| Composant | Increment quand... | Exemple |
|-----------|---------------------|---------|
| **MAJOR** | Changements incompatibles (breaking) | `1.x.x` -> `2.0.0` |
| **MINOR** | Nouvelles fonctionnalites compatibles | `2.1.x` -> `2.2.0` |
| **PATCH** | Corrections de bugs compatibles | `2.1.3` -> `2.1.4` |

**Regles:**
- `0.x.x` = Developpement initial (API instable)
- `1.0.0` = Premiere version stable (API publique)
- Une fois publie, le contenu d'une version ne DOIT PAS changer

### Versioning dans les Scripts

```powershell
# En-tete de script
<#
.SYNOPSIS
    Description du script.
.NOTES
    Version: 2.1.3
    Date: 2025-01-15
    Auteur: [Nom]
    Changelog:
        2.1.3 - Fix: Correction validation input
        2.1.2 - Fix: Gestion timeout API
        2.1.0 - Feat: Ajout export CSV
        2.0.0 - Breaking: Nouveau format config
#>

# Variable de version accessible
$script:Version = "2.1.3"
```

---

## Git et Sauvegarde

### .gitignore Standard PowerShell/Windows

```gitignore
# ========================================
# SORTIES GENEREES
# ========================================
Output/
Logs/
Reports/
*.log
*.csv
*.xlsx
*.html

# ========================================
# TESTS
# ========================================
Tests/Coverage/
TestResults/
*.trx
coverage.xml

# ========================================
# FICHIERS TEMPORAIRES
# ========================================
*.tmp
*.temp
~$*
.temp/
*.checkpoint.json

# ========================================
# IDE ET EDITEURS
# ========================================
.vscode/
.idea/
*.swp
*.swo
*~
*.suo
*.user

# ========================================
# OS WINDOWS
# ========================================
Thumbs.db
ehthumbs.db
Desktop.ini
$RECYCLE.BIN/
*.lnk

# ========================================
# OS MACOS
# ========================================
.DS_Store
.AppleDouble
.LSOverride
._*

# ========================================
# POWERSHELL DEBUG
# ========================================
*.pdb
*.TempPoint.ps1
*.RestorePoint.ps1

# ========================================
# SECRETS ET CREDENTIALS
# ========================================
*.credentials
*.secret
*.key
*.pfx
*.cer
appsettings.Development.json
Settings.json
!Settings.example.json
.env
.env.*
!.env.example

# ========================================
# SAUVEGARDES
# ========================================
*.bak
*.backup
*.old
Backups/

# ========================================
# DEPENDANCES
# ========================================
node_modules/
packages/

# ========================================
# CONSERVATION STRUCTURE (README.md)
# ========================================
# Garder les dossiers vides avec README.md
!Output/README.md
!Logs/README.md
!Backups/README.md
!.temp/README.md
!Tests/Coverage/.gitkeep
```

### Strategie de Branches

**Modele recommande: GitHub Flow (simplifie)**

```
master (production stable)
  |
  +-- feature/issue-XX (developpement)
  |     |
  |     +-- Commits atomiques
  |     |
  |     +-- Merge vers master
  |
  +-- hotfix/issue-YY (correction urgente)
        |
        +-- Merge direct vers master
```

**Regles:**
- `master` = toujours deployable
- 1 branche = 1 issue
- Merge frequent (quotidien si possible)
- Supprimer les branches mergees

### Strategie de Sauvegarde

#### Backup Avant Modification (Obligatoire)

Avant toute modification significative, sauvegarder les fichiers concernes :

```powershell
# Structure .backup/
.backup/
|-- 2025-11-30_BUG-001/
|   |-- Manager-WinGetApps.ps1.bak
|   +-- BACKUP_INFO.txt
+-- 2025-11-30_REFACTOR-002/
    |-- Module1.ps1.bak
    |-- Module2.ps1.bak
    +-- BACKUP_INFO.txt
```

**Script de backup pre-modification:**
```powershell
function Backup-BeforeModification {
    param(
        [Parameter(Mandatory)]
        [string]$IssueId,

        [Parameter(Mandatory)]
        [string[]]$FilesToBackup
    )

    $backupDir = ".backup/$(Get-Date -Format 'yyyy-MM-dd')_$IssueId"
    New-Item -Path $backupDir -ItemType Directory -Force | Out-Null

    foreach ($file in $FilesToBackup) {
        if (Test-Path $file) {
            Copy-Item -Path $file -Destination "$backupDir/$(Split-Path $file -Leaf).bak"
        }
    }

    # Info de backup
    @"
Issue: $IssueId
Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Fichiers:
$($FilesToBackup | ForEach-Object { "  - $_" } | Out-String)
"@ | Set-Content "$backupDir/BACKUP_INFO.txt"

    Write-Host "[+] Backup cree: $backupDir"
}

# Usage
Backup-BeforeModification -IssueId "BUG-001" -FilesToBackup @(
    "src/Manager-WinGetApps.ps1",
    "Modules/Core/Config.ps1"
)
```

#### Backup Batch d'Issues (Sprint/Audit)

Avant un batch de modifications (audit, sprint) :

```powershell
function Backup-ProjectSnapshot {
    param(
        [Parameter(Mandatory)]
        [string]$Reason,  # "AUDIT-2025-11", "SPRINT-3", etc.

        [Parameter()]
        [string]$ProjectRoot = $PWD
    )

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupName = "${Reason}_$timestamp"
    $backupPath = "$ProjectRoot/.backup/$backupName"

    # Copier uniquement le code source (pas logs, output, etc.)
    $include = @("*.ps1", "*.psm1", "*.psd1", "*.json", "*.md")
    $exclude = @("Logs", "Output", "Backups", ".backup", ".temp", "node_modules")

    New-Item -Path $backupPath -ItemType Directory -Force | Out-Null

    Get-ChildItem -Path $ProjectRoot -Recurse -Include $include |
        Where-Object { $exclude | ForEach-Object { $_.FullName -notlike "*\$_\*" } } |
        ForEach-Object {
            $relativePath = $_.FullName.Replace($ProjectRoot, "")
            $destPath = Join-Path $backupPath $relativePath
            $destDir = Split-Path $destPath -Parent
            if (-not (Test-Path $destDir)) {
                New-Item -Path $destDir -ItemType Directory -Force | Out-Null
            }
            Copy-Item -Path $_.FullName -Destination $destPath
        }

    # Manifest
    @"
Snapshot: $Reason
Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Git Commit: $(git rev-parse HEAD 2>$null)
Git Branch: $(git branch --show-current 2>$null)
"@ | Set-Content "$backupPath/SNAPSHOT_INFO.txt"

    Write-Host "[+] Snapshot cree: $backupPath"
    return $backupPath
}

# Usage avant audit
Backup-ProjectSnapshot -Reason "PRE-AUDIT-CODE"

# Usage avant sprint
Backup-ProjectSnapshot -Reason "PRE-SPRINT-3"
```

#### Restauration

```powershell
function Restore-FromBackup {
    param(
        [Parameter(Mandatory)]
        [string]$BackupPath,

        [Parameter()]
        [switch]$WhatIf
    )

    $files = Get-ChildItem -Path $BackupPath -Filter "*.bak" -Recurse

    foreach ($file in $files) {
        $originalName = $file.Name -replace '\.bak$', ''
        $originalPath = $file.FullName -replace [regex]::Escape($BackupPath), $PWD -replace '\.bak$', ''

        if ($WhatIf) {
            Write-Host "[?] Restaurerait: $originalPath"
        } else {
            Copy-Item -Path $file.FullName -Destination $originalPath -Force
            Write-Host "[+] Restaure: $originalPath"
        }
    }
}

# Previsualiser
Restore-FromBackup -BackupPath ".backup/2025-11-30_BUG-001" -WhatIf

# Executer
Restore-FromBackup -BackupPath ".backup/2025-11-30_BUG-001"
```

#### Nettoyage des Backups

```powershell
# Supprimer backups > 30 jours
Get-ChildItem -Path ".backup" -Directory |
    Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-30) } |
    Remove-Item -Recurse -Force
```

---

## Fichiers de Configuration

### Pattern Configuration

```
Config/
|-- Settings.example.json    # Template (versionne, valeurs fictives)
|-- Settings.json            # Production (gitignore, valeurs reelles)
+-- README.md                # Instructions
```

### Settings.example.json

```json
{
    "_comment": "Copier vers Settings.json et remplir les vraies valeurs",
    "_version": "1.0.0",

    "Application": {
        "Name": "MonProjet",
        "Environment": "DEV|PPD|PRD",
        "LogLevel": "Info|Debug|Warning|Error"
    },

    "Exchange": {
        "Organization": "contoso.onmicrosoft.com",
        "AppId": "00000000-0000-0000-0000-000000000000",
        "CertThumbprint": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    },

    "Email": {
        "SmtpServer": "smtp.contoso.com",
        "From": "noreply@contoso.com",
        "To": ["admin@contoso.com"],
        "Enabled": true
    },

    "Paths": {
        "Logs": "./Logs",
        "Output": "./Output",
        "Backup": "./Backups"
    },

    "Retention": {
        "LogDays": 90,
        "OutputDays": 30,
        "BackupCount": 10
    }
}
```

### Lecture de Configuration

```powershell
function Get-ProjectConfig {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [string]$ConfigPath = "$PSScriptRoot/Config/Settings.json"
    )

    if (-not (Test-Path $ConfigPath)) {
        throw "Configuration non trouvee: $ConfigPath. Copier Settings.example.json vers Settings.json"
    }

    try {
        $config = Get-Content -Path $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
        return $config
    }
    catch {
        throw "Erreur lecture configuration: $($_.Exception.Message)"
    }
}
```

### Variables d'Environnement (alternative)

```powershell
# Priorite: Variable env > Config file > Defaut
$organization = $env:EXO_ORGANIZATION ?? $config.Exchange.Organization ?? "default.onmicrosoft.com"
```

---

## Securite

### Regles Fondamentales

| Regle | Implementation |
|-------|----------------|
| Pas de secrets en dur | Utiliser Settings.json (gitignore) ou variables env |
| Pas de credentials dans les logs | Masquer: `Write-Log "Connexion user: ***"` |
| Valider toutes les entrees | `TryParse`, `ValidateScript`, `ValidatePattern` |
| Principe du moindre privilege | Demander uniquement les droits necessaires |
| Chiffrer les donnees sensibles | `ConvertTo-SecureString`, `Export-Clixml` |

### Patterns Securises

```powershell
# BIEN : Credential securise
$credential = Get-Credential
# ou
$securePassword = Read-Host "Password" -AsSecureString
$credential = New-Object PSCredential("user", $securePassword)

# MAL : Password en clair
$password = "MonMotDePasse"  # INTERDIT

# BIEN : Validation stricte des chemins
function Test-SafePath {
    param([string]$Path)

    $fullPath = [System.IO.Path]::GetFullPath($Path)

    # Bloquer chemins dangereux
    $blocked = @(
        "^\\\\",                           # UNC
        "^[A-Z]:\\Windows",                # System
        "^[A-Z]:\\Program Files",          # Programs
        "^[A-Z]:\\Users\\[^\\]+\\AppData"  # AppData
    )

    foreach ($pattern in $blocked) {
        if ($fullPath -match $pattern) {
            throw "Chemin non autorise: $fullPath"
        }
    }

    return $fullPath
}
```

### Audit de Securite

Checklist avant mise en production:
- [ ] Aucun secret dans le code source
- [ ] Settings.json dans .gitignore
- [ ] Validation de toutes les entrees utilisateur
- [ ] Gestion des erreurs sans exposition d'infos sensibles
- [ ] Logs sans donnees confidentielles
- [ ] Permissions minimales requises documentees

---

## Commandes Utiles

### Git

```bash
# Status et historique
git status
git log --oneline -10
git diff

# Branches
git branch -a
git checkout -b feature/issue-XX
git branch -d feature/issue-XX

# Commit
git add .
git commit -m "type(scope): description"
git push origin feature/issue-XX

# Merge
git checkout master
git merge feature/issue-XX
git push origin master

# Nettoyage
git remote prune origin
git branch --merged | grep -v master | xargs git branch -d
```

### GitHub CLI

```bash
# Issues
gh issue list
gh issue create --title "[TYPE] Description" --body "Details..."
gh issue view 42
gh issue close 42 --comment "Resolu dans commit abc123"

# Pull Requests
gh pr create --title "Fix #42" --body "Description"
gh pr list
gh pr merge 42
```

### PowerShell / Pester

```powershell
# Tests
Invoke-Pester -Path ./Tests
Invoke-Pester -Path ./Tests -Tag "Unit" -Output Detailed

# Validation syntaxe
Get-ChildItem -Path ./src -Filter *.ps1 | ForEach-Object {
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$errors)
    if ($errors) { Write-Warning "$($_.Name): $($errors.Count) erreurs" }
}

# Analyse statique
Invoke-ScriptAnalyzer -Path ./src -Recurse
```

---

## References

### Sources Officielles
- [PowerShell Practice and Style](https://poshcode.gitbook.io/powershell-practice-and-style/)
- [Microsoft PowerShell Documentation](https://learn.microsoft.com/en-us/powershell/)
- [Pester Documentation](https://pester.dev/docs/quick-start)

### Standards
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Conventional Commits](https://www.conventionalcommits.org/)

### Securite
- [OWASP Secrets Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)

---

**Version**: 1.2.0
**Date**: 2025-12-02
**Changelog**:
- 1.2.0 (2025-12-02): Workflow Local-First pour issues (local puis GitHub), ajout Docs/Audit/, section fichiers racine
- 1.1.0 (2025-12-02): Ajout section "Donnees de Test - Anonymisation Obligatoire"
- 1.0.0 (2025-11-30): Version initiale
**Auteur**: Genere avec Claude Code