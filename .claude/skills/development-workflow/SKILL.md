---
name: development-workflow
description: "Development workflow standards for Git, TDD, and issue management. Use when committing code, creating branches, writing tests, managing issues, or documenting changes. Covers conventional commits, atomic commits, TDD cycle (RED-GREEN-REFACTOR), local-first issue workflow, test data anonymization (contoso.com), and changelog format."
---

# Development Workflow Standards

Standards de workflow applicables a tout projet.

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

### Issue Workflow
```
1. ANALYSER    -> Identifier probleme
2. DOCUMENTER  -> /create-issue TYPE-XXX-titre
3. STOP        -> Attendre validation explicite
4. IMPLEMENTER -> /implement-issue TYPE-XXX-titre
                  (sync GitHub automatique a la fin)
```

Note : /sync-issue existe pour sync standalone (discussion avant implementation).

### Donnees Test Anonymisees
```
Domaine: contoso.com / fabrikam.com
GUID: 00000000-0000-0000-0000-000000000001
Email: jean.dupont@contoso.com
```

### Commit Authorship
- Auteur unique (pas de Co-Authored-By)
- Pas de mention AI/Claude
- Pas d'emoji dans commits

### Atomic Commits
Un commit = un changement logique. Chaque commit doit etre autonome et reversible.

```
# [+] Commits atomiques
git commit -m "fix(auth): correct token expiration check"
git commit -m "feat(export): add CSV export for reports"

# [-] Commit fourre-tout
git commit -m "fix auth + add export + refactor config"
```

## Detailed Standards

| Domaine | Fichier |
|---------|---------|
| Git complet | [git.md](git.md) |
| TDD cycle | [tdd.md](tdd.md) |
| Workflow issues | [workflow.md](workflow.md) |
| Donnees test | [testing-data.md](testing-data.md) |
| Documentation | [documentation.md](documentation.md) |
