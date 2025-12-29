---
name: knowledge-verification
description: "Temporal knowledge verification for fast-evolving technologies. Use when evaluating knowledge and detecting potential obsolescence due to cutoff date. Triggers @tech-researcher invocation when uncertainty detected."
---

# Knowledge Verification

Verification temporelle des connaissances pour technologies evoluant rapidement.

## Processus d'Evaluation Temporelle

### Etape 0 : Identification des technologies (AVANT evaluation)

Scanner le code pour identifier TOUTES les technologies a evaluer :

| Categorie | Quoi chercher | Exemple |
|-----------|---------------|---------|
| **Runtime/Langage** | Version, #Requires | PowerShell 7.2+, Python 3.11 |
| **Modules importes** | Import-Module, #Requires -Modules | Az.*, Microsoft.Graph, Pester |
| **APIs externes** | Invoke-RestMethod, Invoke-WebRequest | Microsoft Graph, Azure REST, AWS |
| **Patterns sensibles** | Auth, crypto, secrets | OAuth, JWT, DPAPI, AES |
| **Versions specifiques** | ModuleVersion, RequiredVersion | @{ModuleName='X'; ModuleVersion='2.0'} |

> **IMPORTANT** : Ne pas evaluer uniquement le langage. Les APIs et modules tiers
> sont souvent plus evolutifs que le langage lui-meme.

### Etape 1 : Auto-evaluation de la connaissance

Pour chaque technologie identifiee, appliquer ce processus de decision :

Evaluer honnetement : "Sur une echelle de 0-10, a quel point je maitrise cette techno ?"

- Si < 9/10 → invoquer `@tech-researcher` (lacune de connaissance)
- Si >= 9/10 → continuer a l'etape 2

### Etape 2 : Calcul de l'ecart temporel

```
Date du jour    : [obtenue dynamiquement]
Date de coupure : [connue intrinsequement]
Ecart           : [difference en mois]
```

### Etape 3 : Evaluation du risque d'obsolescence

Pour l'ecart calcule, se poser la question :
**"Cette techno a-t-elle probablement eu des changements significatifs pendant [ecart] mois ?"**

Indicateurs de risque eleve :
- APIs cloud/SaaS (Microsoft Graph, Azure, AWS) → changements frequents
- Domaine securite (CVE, auth, crypto) → nouvelles vulnerabilites
- Framework en developpement actif → breaking changes possibles
- Versions specifiques mentionnees dans le code → verifier deprecation

### Etape 4 : Decision

```
SI (connaissance < 9/10) OU (risque obsolescence eleve)
ALORS → @tech-researcher avec le concept a verifier
SINON → continuer sans recherche
```

## Qui Applique ce Processus ?

| Mecanisme | Applique le processus | Peut invoquer @tech-researcher |
|-----------|----------------------|-------------------------------|
| `/audit-code` | Oui (Phase 0) | Oui |
| `/review-code` | Oui (pre-verification) | Oui |
| `/create-script` | Oui (si APIs/modules externes) | Oui |
| `/analyze-bug` | Oui (investigation bugs) | Oui |
| Contexte principal | Oui (a la demande) | Oui |
| `@code-reviewer` | **Non** | Non (agent isole) |
| `@security-auditor` | **Non** | Non (agent isole) |

> **Pourquoi les agents ne peuvent pas ?** (CLAUDE-CODE-GUIDE.md Section 8)
> "Les subagents ne peuvent PAS appeler d'autres subagents." (regle anti-nesting)

---

## Application des Resultats (Post-Recherche)

Le processus ci-dessus garantit la **decouverte** des bonnes informations.
Cette section garantit leur **application** dans le code.

### Checklist Post-Recherche

Apres chaque invocation de `@tech-researcher`, verifier :

```
[ ] Les resultats ont-ils ete INTEGRES dans le code ?
    +-- Connexion : Get-*Context utilise (pas retour Connect-*)
    +-- Imports : Sous-modules explicitement importes
    +-- Proprietes : Noms actuels utilises (pas anciens)
    +-- Retours : Types geres correctement

[ ] Les choix sont-ils DOCUMENTES ?
    +-- Commentaire expliquant le choix
    +-- Reference a la source si pertinent
```

### Exemple d'application

```powershell
# Resultat tech-researcher : Connect-SomeApi retourne $null
# Application : Utiliser Get-SomeApiContext pour verification
Connect-SomeApi -Scopes $scopes -NoWelcome -ErrorAction SilentlyContinue
if (-not (Get-SomeApiContext)) {
    throw "Echec connexion API"
}

# Resultat tech-researcher : Get-SomeUser dans SomeApi.Users
# Application : Import explicite du sous-module
Import-Module SomeApi.Users -ErrorAction Stop
```

### Reference

Voir `.claude/skills/external-apis/SKILL.md` pour les meta-patterns a appliquer.
