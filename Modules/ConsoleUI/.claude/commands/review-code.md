---
description: Review le code PowerShell selon les standards du projet
allowed-tools: Read, Grep, Glob
---

Effectuer une review de code complete en utilisant TOUS les standards du projet.

## Fichiers de Reference

Lire ces fichiers avant de reviewer :
- `.claude/rules/powershell/naming.md`
- `.claude/rules/powershell/errors.md`
- `.claude/rules/powershell/performance.md`
- `.claude/rules/powershell/security.md`
- `.claude/rules/powershell/anti-patterns.md`
- `.claude/rules/powershell/ui/symbols.md`

## Checklist de Review

### Nommage
- [ ] Verb-Noun avec verbes approuves
- [ ] Nouns SINGULIERS
- [ ] Pas de noms vagues : $data, $temp, $i, $obj, $result

### Gestion des Erreurs
- [ ] `-ErrorAction Stop` dans try-catch
- [ ] Catch specifique avant generique
- [ ] Nettoyage dans finally

### Performance
- [ ] `List<T>` et non `@() +=`
- [ ] `.Where()` et non `Where-Object` (grands volumes)
- [ ] `foreach` et non pipeline (performance)

### Securite
- [ ] Pas de credentials en dur
- [ ] `TryParse` pour input utilisateur
- [ ] Pas d'`Invoke-Expression` avec donnees utilisateur

### UI
- [ ] Brackets `[+][-][!][i][>]`
- [ ] PAS d'emoji

## Format de Sortie

```markdown
## Review de Code : [nom_fichier]

### CRITIQUE
- [fichier:ligne] Probleme
  Correction : Solution

### WARNING
- [fichier:ligne] Probleme

### Resume
- Critique : X | Warning : X | Info : X
- Global : [PASSE/ECHEC]
```
