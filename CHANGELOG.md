# Changelog

Toutes les modifications notables sont documentees dans ce fichier.

Format base sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/).
Ce projet adhere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Export HTML des delegations (FEAT-012)

---

## [1.3.0] - 2026-02-11

### Added
- **Colonne LastLogonSource** : Tracabilite de la source des donnees LastLogon (FEAT-014)
  - Valeurs : `SignInActivity` (P1/P2), `GraphReports`, `EXO`
  - Permet d'evaluer la fiabilite des dates de derniere connexion
- Tests unitaires Pester pour `New-DelegationRecord` (26 tests)

### Fixed
- Header CSV manquant pour la colonne LastLogonSource
- Suppression warnings PSScriptAnalyzer (variables non utilisees)

---

## [1.2.0] - 2025-12-29

### Added
- **LastLogon via Graph Reports API** : Alternative sans licence P1 (FEAT-013)
  - Detection automatique anonymisation (tenants < seuil utilisateurs)
  - Fallback vers EXO Statistics si anonymise
- **Detection licence P1/P2** : Test signInActivity au demarrage (BUG-012)

### Fixed
- LastLogon UPN mismatch : Normalisation en minuscules (BUG-011)
- LastLogon retourne DateTime.MinValue (01/01/1601) filtre (BUG-012)

### Changed
- Remplacement module MgConnection par GraphConnection (REFACTOR-002)
- Utilisation `LastInteractionTime` pour tous les types de mailbox

---

## [1.1.0] - 2025-12-15

### Added
- **Systeme Checkpoint** : Reprise apres interruption (FEAT-009, FEAT-010)
  - Sauvegarde automatique de l'etat dans fichier JSON
  - HashSet pour lookup O(1) des mailboxes traitees
  - Mode append CSV pour continuite des donnees
- **Colonne MailboxType** : UserMailbox, SharedMailbox, RoomMailbox (FEAT-011)
- **Colonne IsOrphan** : Identification delegations orphelines (FEAT-003)
- **Colonne IsSoftDeleted** : Mailboxes en soft-delete
- **Parametre -IncludeInactive** : Collecte mailboxes inactives (FEAT-008)
- **Parametre -OrphansOnly** : Export filtre orphelins uniquement (FEAT-004)
- **Parametre -IncludeLastLogon** : Date derniere connexion (FEAT-005)
- **Module ConsoleUI** : Interface console avec banniere et status (REFACTOR-001)
- **Fichier Settings.json** : Configuration externalisee (FEAT-007)

### Fixed
- Checkpoint sauve index en cours au lieu du dernier complete - 17% perte donnees (BUG-007)
- Statistiques incorrectes en reprise checkpoint (BUG-006)
- Header CSV inverse + tri checkpoint (BUG-005)
- Variable locale vs etat module dans finally block (BUG-004)
- Condition finally trop restrictive (BUG-003)
- CsvPath non restaure depuis checkpoint (BUG-002)
- Retention days hardcode (BUG-001)
- Calendrier multilingue (FIX-002)

### Changed
- Amelioration affichage console avec icones (UI-001)

---

## [1.0.0] - 2025-12-01

### Added
- Version initiale du script
- Collecte des 5 types de delegations : FullAccess, SendAs, SendOnBehalf, Calendar, Forwarding
- Module EXOConnection avec retry et validation
- Module Write-Log (RFC 5424)
- Cache Recipients pour performance
- Export CSV avec timestamp
- Parametre -CleanupOrphans pour suppression delegations orphelines
- Exclusion automatique des comptes systeme (NT AUTHORITY, SELF, etc.)
- Validation chemin OutputPath contre path traversal

---

## Types de Changements

- **Added** : Nouvelles fonctionnalites
- **Changed** : Modifications de fonctionnalites existantes
- **Deprecated** : Fonctionnalites qui seront supprimees
- **Removed** : Fonctionnalites supprimees
- **Fixed** : Corrections de bugs
- **Security** : Corrections de vulnerabilites
