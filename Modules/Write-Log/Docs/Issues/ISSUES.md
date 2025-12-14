# Index des Issues

> Issues locales synchronisees avec GitHub Issues

## En cours

| ID | Priorite | Type | Titre | Statut |
|----|----------|------|-------|--------|
| [FEAT-001](ISSUE-001-initialize-log.md) | ! | FEAT | Ajouter fonction Initialize-Log | Termine |
| [FEAT-002](ISSUE-002-invoke-logrotation.md) | ! | FEAT | Ajouter fonction Invoke-LogRotation | Termine |
| [FEAT-003](ISSUE-003-auto-scriptname.md) | - | FEAT | Ameliorer detection auto ScriptName | Termine |

## Terminees

| ID | Type | Titre | Date |
|----|------|-------|------|
| - | - | - | - |

---

## Workflow

1. Creer issue locale dans `Docs/Issues/ISSUE-XXX-titre.md`
2. Mettre a jour cet index
3. Commit avec `docs: add ISSUE-XXX`
4. Creer issue GitHub correspondante (`gh issue create`)
5. Lier le commit a l'issue GitHub (`Fixes #XXX`)

## Nomenclature

- Fichier: `ISSUE-{NUM}-{titre-court}.md`
- Priorite: `!!` Critique | `!` Elevee | `~` Moyenne | `-` Faible
- Type: `BUG` | `FEAT` | `REFACTOR` | `DOCS` | `TEST`
