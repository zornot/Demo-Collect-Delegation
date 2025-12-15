---
name: knowledge-verification
description: "Temporal knowledge verification for fast-evolving technologies. Use when evaluating knowledge and detecting potential obsolescence due to cutoff date. Triggers @tech-researcher invocation when uncertainty detected."
---

# Knowledge Verification

Verification temporelle des connaissances pour technologies evoluant rapidement.

## Quand Appliquer

Pour tout concept evalue >= 8/10 concernant une technologie susceptible d'avoir evolue :
- Modules avec releases frequentes
- Securite / CVE / vulnerabilites
- APIs avec quotas, throttling, endpoints changeants
- Best practices vendors

## Action Obligatoire

1. Reconnaitre la limitation temporelle potentielle
2. Invoquer @tech-researcher avec le concept a verifier
3. Integrer les resultats ou documenter explicitement l'incertitude

> Le contexte principal decide de l'invocation, pas l'agent.

## Workflow

```
Contexte principal (audit/review/creation)
    |
    +-> Evalue connaissances sur un concept
    +-> Detecte incertitude temporelle (techno evolutive?)
    +-> Invoque @tech-researcher
    |
    +-> Agent recoit date du jour (dynamique)
        Compare avec sa date de coupure (intrinseque)
        Retourne les ecarts trouves
```

## Integration

### Mecanismes d'ANALYSE (lecture obligatoire)
- `code-reviewer` : Review code
- `security-auditor` : Audit securite
- `/audit-code` : Audit complet

### Mecanismes de CREATION (note optionnelle)
- `/create-script` : Si techno evolutive utilisee
- `/create-function` : Si API evolutive
