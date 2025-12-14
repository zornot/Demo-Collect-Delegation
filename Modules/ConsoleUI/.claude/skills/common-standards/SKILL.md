---
name: common-standards
description: |
  Conventions communes a tous les langages. Charge automatiquement quand :
  - Travail sur Git (commits, branches, workflow)
  - Ecriture de tests (TDD)
  - Gestion d'issues
  - Documentation (CHANGELOG, README)
  - Anonymisation de donnees de test
globs:
  - "**/.gitignore"
  - "**/CHANGELOG.md"
  - "**/README.md"
  - "audit/issues/**"
---

# Common Development Standards

Standards transversaux applicables a tout langage de programmation.

## Git & Version Control

Regles pour commits atomiques, conventional commits, et GitHub Flow.

Reference: @.claude/rules/common/git.md

## TDD (Test-Driven Development)

Cycle obligatoire : RED -> GREEN -> REFACTOR

Reference: @.claude/rules/common/tdd.md

## Workflow Issues

Gestion locale des issues avant synchronisation GitHub.

Reference: @.claude/rules/common/workflow.md

## Testing Data Anonymization

Utiliser `contoso.com` et `fabrikam.com` pour les donnees de test.
Pas de donnees de production dans les tests.

Reference: @.claude/rules/common/testing-data.md

## Documentation

Format CHANGELOG (Keep a Changelog), SemVer, README standard.

Reference: @.claude/rules/common/documentation.md

---

## Quick Reference

### Conventional Commits
```
type(scope): description imperative

Types: fix | feat | refactor | perf | test | docs | style | chore | build
```

### TDD Cycle
```
1. RED    -> Tests AVANT le code (echouent)
2. GREEN  -> Minimum pour passer
3. REFACTOR -> Ameliorer sans casser
```

### Donnees Test
```
Domaine: contoso.com / fabrikam.com
GUID: 00000000-0000-0000-0000-000000000001
Email: jean.dupont@contoso.com
```

### Commit Authorship
- Auteur unique (pas de Co-Authored-By)
- Pas de mention AI/Claude
- Pas d'emoji dans les commits
