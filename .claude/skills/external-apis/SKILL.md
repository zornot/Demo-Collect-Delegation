---
name: external-apis
description: "Meta-patterns for external APIs (cloud SDKs, third-party modules). Use when writing code that calls external APIs (Microsoft Graph, Exchange Online, Azure, AWS, etc.). Covers connection verification, modular imports, property evolution, return types. Do NOT load for internal PowerShell code."
---

# External APIs - Meta-Patterns

> Patterns generiques pour APIs evolutives. Applicable a tout SDK cloud ou module tiers.

## Pourquoi ce skill ?

Les APIs cloud evoluent constamment :
- Cmdlets renommees ou depreciees
- Proprietes qui changent entre versions
- Architectures qui evoluent (monolithique → modulaire)

Un skill avec des details specifiques serait obsolete en 6-12 mois.
Ce skill documente des **meta-patterns** stables applicables a toute API.

---

## Meta-Pattern 1 : Verification de Connexion

> Les cmdlets `Connect-*` ne retournent pas toujours un booleen ou un objet exploitable.

### Le piege

```powershell
# PROBLEME : Connect-* peut retourner $null meme en cas de succes
if (-not (Connect-SomeApi -Scopes $scopes)) {
    throw "Echec"  # Faux positif!
}
```

### La solution

```powershell
# CORRECT : Verifier l'etat avec Get-*Context apres connexion
Connect-SomeApi -Scopes $scopes -ErrorAction SilentlyContinue
if (-not (Get-SomeApiContext)) {
    throw "Echec connexion"
}
```

### Verification obligatoire

Avant d'utiliser une cmdlet `Connect-*` tierce :
1. Verifier le type de retour dans la documentation
2. Identifier la cmdlet `Get-*Context` correspondante
3. Si incertitude : invoquer `@tech-researcher`

---

## Meta-Pattern 2 : Imports Modulaires

> Les SDKs modernes sont souvent modulaires. Les cmdlets ne sont pas disponibles sans import explicite.

### Le piege

```powershell
# PROBLEME : Apres Connect-SomeApi, les cmdlets peuvent ne pas etre disponibles
Connect-SomeApi
Get-SomeResource  # "not recognized as a cmdlet"
```

### La solution

```powershell
# CORRECT : Importer explicitement les sous-modules requis
Import-Module SomeApi.Resources -ErrorAction Stop
Import-Module SomeApi.Users -ErrorAction Stop
Connect-SomeApi
Get-SomeResource  # OK
```

### Verification obligatoire

Avant d'utiliser un SDK modulaire :
1. Lister les sous-modules disponibles : `Get-Module SomeApi.* -ListAvailable`
2. Identifier les modules requis pour chaque cmdlet
3. Importer explicitement avec `-ErrorAction Stop`

---

## Meta-Pattern 3 : Evolution des Proprietes

> Les noms de proprietes changent entre versions d'API.

### Le piege

```powershell
# PROBLEME : Propriete qui existait dans v1, renommee dans v2
$lastLogin = $user.LastLogonTime  # Obsolete, surestimation 30%
```

### La solution

```powershell
# CORRECT : Utiliser la propriete actuelle apres verification
$lastLogin = $user.LastSuccessfulSignInDateTime  # Version actuelle
```

### Verification obligatoire

Pour toute propriete d'un objet API :
1. Ne pas se fier a la memoire ou aux connaissances anterieures
2. Consulter la documentation officielle actuelle
3. Si incertitude sur l'evolution : invoquer `@tech-researcher`

---

## Meta-Pattern 4 : Types de Retour

> Ne pas supposer le type de retour d'une cmdlet tierce.

### Le piege

```powershell
# PROBLEME : Supposer que la cmdlet retourne une collection
$items = Get-SomeItems
$items.Count  # Erreur si retour est $null ou objet unique
```

### La solution

```powershell
# CORRECT : Forcer le type ou gerer les cas
$items = @(Get-SomeItems)  # Force tableau
# OU
$items = Get-SomeItems
if ($null -eq $items) { $items = @() }
```

### Verification obligatoire

Avant d'utiliser le retour d'une cmdlet tierce :
1. Verifier le type documente (collection, objet, $null possible)
2. Gerer explicitement le cas $null
3. Utiliser `@()` pour forcer un tableau si necessaire

---

## Processus : Avant d'utiliser une API externe

```
1. IDENTIFIER l'API/SDK utilisee
   |
2. VERIFIER mes connaissances (seuil 9/10)
   |
   +---> < 9/10 ou incertitude --> Invoquer @tech-researcher
   |
3. APPLIQUER les meta-patterns ci-dessus
   |
4. DOCUMENTER les choix dans le code (commentaires)
```

---

## Integration avec knowledge-verification

Ce skill complete `knowledge-verification` :
- `knowledge-verification` : QUAND rechercher (evaluation temporelle)
- `external-apis` : QUOI verifier (meta-patterns specifiques)

Apres une recherche `@tech-researcher`, appliquer systematiquement les meta-patterns de ce skill.

---

## References

- Voir `.claude/skills/knowledge-verification/SKILL.md` pour le processus d'evaluation temporelle
- Voir `.claude/agents/tech-researcher.md` pour la recherche technique
- Voir `.claude/skills/powershell-development/patterns.md` pour Fallback/Throttle API
