# Architecture - [Nom du Projet]

> Exemple de document d'architecture. Copier vers ARCHITECTURE.md et personnaliser.

---

## Vue d'Ensemble

```
┌─────────────────────────────────────────────────────────────────┐
│                         UTILISATEUR                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Script.ps1                               │
│  Point d'entree principal                                        │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
        ┌──────────┐   ┌──────────┐   ┌──────────┐
        │ Module A │   │ Module B │   │ Module C │
        └──────────┘   └──────────┘   └──────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      SORTIE / OUTPUT                             │
│  Fichiers, rapports, logs                                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## Composants Principaux

### Script.ps1

| Aspect | Description |
|--------|-------------|
| **Role** | Point d'entree, orchestration |
| **Entrees** | Parametres utilisateur, fichiers config |
| **Sorties** | Resultats vers Output/, logs vers Logs/ |

### Modules/

| Module | Role |
|--------|------|
| `ModuleA/` | [Description] |
| `ModuleB/` | [Description] |

---

## Flux de Donnees

```
1. Lecture configuration (Config/Settings.json)
2. Validation des entrees
3. Traitement principal
4. Generation des sorties
5. Logging des resultats
```

---

## Decisions d'Architecture

| Decision | Justification |
|----------|---------------|
| [Choix technique] | [Pourquoi ce choix] |

---

## Dependances

| Dependance | Version | Usage |
|------------|---------|-------|
| PowerShell | 7.2+ | Runtime |
| [Module] | X.Y | [Usage] |

---

*Copier ce fichier vers ARCHITECTURE.md et personnaliser selon votre projet.*
