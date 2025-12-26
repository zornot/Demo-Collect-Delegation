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
| [FEAT-012](FEAT-012-export-html-delegations.md) | Export HTML des delegations | ~ |

## Issues Terminees

| ID | Titre | Date | GitHub |
|----|-------|------|--------|
| REFACTOR-002 | Remplacer MgConnection par GraphConnection | 2025-12-26 | local |
| FEAT-013 | LastLogon via Graph Reports API | 2025-12-26 | local |
| BUG-007 | Checkpoint sauve index en cours au lieu du dernier complete | 2025-12-15 | local |
| BUG-006 | Statistiques incorrectes en reprise checkpoint | 2025-12-15 | local |
| FEAT-011 | Colonne MailboxType dans export CSV | 2025-12-15 | local |
| BUG-005 | Header CSV inverse + tri checkpoint | 2025-12-15 | local |
| BUG-004 | Variable locale vs etat module | 2025-12-15 | #16 |
| BUG-003 | Condition finally trop restrictive | 2025-12-15 | #15 |
| BUG-002 | CsvPath non restaure depuis checkpoint | 2025-12-15 | #14 |
| FEAT-008 | Parametre -IncludeInactive mailboxes | 2025-12-15 | local |
| REFACTOR-001 | Write-Status vers module ConsoleUI | 2025-12-15 | local |
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
| DOC-002 | Documenter limitation LastLogonTime | Remplacee par FEAT-013 (vraie solution) |
| PERF-001 | Parallelisation collecte | Isolation runspaces Exchange incompatible |
| FEAT-006 | TrusteeLastLogon via Graph API | Requiert Azure AD P1 (~150 USD/mois) |
| DRY-001 | Optimisation AddRange | AddRange incompatible List[PSCustomObject] |

---

*Derniere mise a jour : 2025-12-26*
*FEAT-013 remplace DOC-002 avec solution Graph Reports API*
