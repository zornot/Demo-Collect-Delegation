# [Nom du Projet]

> [Description courte du projet]

**Version** : 1.0.0
**Stack** : PowerShell 7.2+
**Auteur** : [Nom]

---

## Table des Matieres

1. [Description](#description)
2. [Prerequis](#prerequis)
3. [Installation](#installation)
4. [Utilisation](#utilisation)
5. [Configuration](#configuration)
6. [Tests](#tests)
7. [Structure](#structure)

---

## Description

[Description detaillee du projet, son objectif, ses fonctionnalites principales]

## Prerequis

- PowerShell 7.2+
- [Autres prerequis]

## Installation

```powershell
# Cloner le projet
git clone [url]
cd [projet]

# Copier la configuration
Copy-Item Config/Settings.example.json Config/Settings.json
# Modifier Config/Settings.json selon vos besoins
```

## Utilisation

```powershell
# Executer le script principal
./Script.ps1 [-Parametre valeur]
```

### Exemples

```powershell
# Exemple 1 : [Description]
./Script.ps1 -Mode Basic

# Exemple 2 : [Description]
./Script.ps1 -Mode Advanced -Output "./Output"
```

## Configuration

Copier `Config/Settings.example.json` vers `Config/Settings.json` et personnaliser :

```json
{
    "Setting1": "valeur",
    "Setting2": true
}
```

| Parametre | Type | Description | Defaut |
|-----------|------|-------------|--------|
| Setting1 | string | [Description] | "valeur" |
| Setting2 | bool | [Description] | true |

## Tests

```powershell
# Executer tous les tests
Invoke-Pester -Path ./Tests -Output Detailed

# Executer tests specifiques
Invoke-Pester -Path ./Tests/Unit -Tag "Unit"
```

## Structure

```
[Projet]/
├── Script.ps1           # Point d'entree principal
├── Config/              # Configuration
│   └── Settings.json
├── Modules/             # Modules PowerShell
├── Tests/               # Tests Pester
├── Logs/                # Fichiers de log
└── Output/              # Fichiers generes
```

---

## Commandes Claude Code

| Commande | Description |
|----------|-------------|
| `/create-function Verb-Noun` | Creer une fonction |
| `/create-test NomFonction` | Creer des tests |
| `/run-tests` | Executer les tests |
| `/review-code` | Review du code |

---

## License

[Type de license]

---

*Copier ce fichier vers README.md et personnaliser selon votre projet.*
