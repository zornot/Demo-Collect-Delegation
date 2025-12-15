# Issues - Demo Collect Delegation

## Workflow

| Commande | Usage |
|----------|-------|
| `/create-issue TYPE-XXX-titre` | Creer une issue locale |
| `/implement-issue TYPE-XXX-titre` | Implementer une issue |

**Regle** : 1 issue = 1 branche = 1 commit atomique

---

## Issues En Cours

| ID | Titre | Priorite |
|----|-------|----------|
| - | Aucune issue en cours | - |

## Issues Terminees

| ID | Titre | Date | GitHub |
|----|-------|------|--------|
| FEAT-003 | Colonne IsOrphan pour delegations orphelines | 2025-12-15 | #6 |
| FEAT-004 | Option -OrphansOnly pour export filtre | 2025-12-15 | #7 |
| FEAT-005 | Option -IncludeLastLogon | 2025-12-15 | #8 |
| FEAT-007 | Implementation Settings.json | 2025-12-15 | local |
| BUG-001 | Retention days hardcode (fix) | 2025-12-15 | local |
| FIX-002 | Calendrier multilingue | 2025-12-15 | #4 |
| UI-001 | Amelioration affichage console | 2025-12-15 | local |

## Issues Abandonnees

| ID | Titre | Raison |
|----|-------|--------|
| PERF-001 | Parallelisation collecte | Isolation runspaces Exchange incompatible |
| FEAT-006 | TrusteeLastLogon via Graph API | Requiert Azure AD P1 (~150 USD/mois) |
| DRY-001 | Optimisation AddRange | AddRange incompatible List[PSCustomObject] |

---

*Derniere mise a jour : 2025-12-15*
