# Documentation Standards

## CHANGELOG.md - Format Keep a Changelog

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
- Fonction sera supprimee en v2.0.0

---

## [1.0.0] - 2024-12-15

### Added
- Version initiale
```

## Categories CHANGELOG

| Categorie | Usage |
|-----------|-------|
| `Added` | Nouvelles fonctionnalites |
| `Changed` | Changements fonctionnels existants |
| `Deprecated` | Fonctionnalites bientot supprimees |
| `Removed` | Fonctionnalites supprimees |
| `Fixed` | Corrections de bugs |
| `Security` | Correctifs de securite |

## Semantic Versioning (SemVer)

Format: `MAJOR.MINOR.PATCH` (ex: `2.1.3`)

| Composant | Increment quand... | Exemple |
|-----------|---------------------|---------|
| **MAJOR** | Changements incompatibles (breaking) | `1.x.x` -> `2.0.0` |
| **MINOR** | Nouvelles fonctionnalites compatibles | `2.1.x` -> `2.2.0` |
| **PATCH** | Corrections de bugs compatibles | `2.1.3` -> `2.1.4` |

**Regles:**
- `0.x.x` = Developpement initial (API instable)
- `1.0.0` = Premiere version stable (API publique)
- Une fois publie, le contenu d'une version ne change pas

## Template README.md

```markdown
# [Nom du Projet]

[Description courte 1-2 phrases]

**Version**: X.Y.Z
**Statut**: [Development | Production | Deprecated]
**Date**: YYYY-MM-DD

---

## Demarrage Rapide

### Prerequis

- [Runtime/dependances]

### Installation

[Commandes d'installation]

### Utilisation

[Commande de base]

---

## Fonctionnalites

- [x] Fonctionnalite 1
- [x] Fonctionnalite 2
- [ ] Fonctionnalite future

---

## Structure du Projet

[Arborescence simplifiee]

---

## Configuration

[Instructions de configuration]

---

## Tests

[Commande pour executer les tests]

---

## Documentation

- [CHANGELOG](CHANGELOG.md)

---

## Auteurs

- **[Nom]** - Developpement initial

## Licence

[Type de licence]
```

## Commentaires Code

```
# [+] BIEN : Explique le POURQUOI
# Retry necessaire car API throttle apres 1000 requetes/minute

# Delai pour eviter rate limiting
# Hash pour comparaison rapide sans charger tout en memoire

# [-] MAL : Explique le QUOI (evident du code)
# Obtient l'item
# Attend 2 secondes
# Cree un HashSet
```

## Documentation Referentiel AI

Le dossier `.claude/rules/` remplace le traditionnel `CONTRIBUTING.md` :

| Ancien modele | Nouveau modele |
|---------------|----------------|
| `CONTRIBUTING.md` (pour humains) | `.claude/rules/RULES.md` (pour AI) |
| Guide verbeux, explicatif | Regles concises, declaratives |
| Difficile a maintenir | Modulaire (`.claude/rules/*.md`) |

Les regles dans `.claude/rules/` sont automatiquement chargees par Claude Code.
