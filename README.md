# Get-ExchangeDelegation

Collecte toutes les delegations Exchange Online d'une organisation avec tracabilite des sources de donnees.

## Description

Ce script recupere l'ensemble des delegations configurees sur les mailboxes Exchange Online :

| Type | Description |
|------|-------------|
| **FullAccess** | Acces complet a la mailbox |
| **SendAs** | Envoyer en tant que |
| **SendOnBehalf** | Envoyer de la part de |
| **Calendar** | Droits sur le calendrier |
| **Forwarding** | Regles de transfert SMTP |

### Detection des Delegations Orphelines

Les delegations vers des comptes supprimes (orphelins) sont **visibles** dans le rapport.
Elles apparaissent avec un SID au lieu d'une adresse email :

```
TrusteeEmail: S-1-5-21-583983544-471682574-2706792393-39628563
```

Pour filtrer les delegations orphelines :
```powershell
Import-Csv "ExchangeDelegations_*.csv" | Where-Object { $_.IsOrphan -eq 'True' }
```

### Strategie LastLogon

Le script detecte automatiquement la meilleure source disponible pour les dates de derniere connexion :

| Priorite | Source | Licence | Precision |
|----------|--------|---------|-----------|
| 1 | **SignInActivity** | Azure AD P1/P2 | Haute - connexion reelle |
| 2 | **GraphReports** | Standard | Moyenne - activite email |
| 3 | **EXO** | Aucune | Faible - inclut background |

La colonne `LastLogonSource` dans le CSV indique quelle methode a ete utilisee.

## Performance

Le script utilise plusieurs optimisations pour des performances optimales :

| Optimisation | Impact |
|--------------|--------|
| **Cache Recipients** | Pre-charge tous les recipients au demarrage (-80% appels API) |
| **Cmdlets EXO*** | Utilise les cmdlets REST (Get-EXOMailbox, etc.) 3x plus rapides |
| **HashSet Checkpoint** | Lookup O(1) pour reprise apres interruption |
| **Cache LastLogon** | Pre-charge les donnees Graph (evite N appels API) |

**Benchmark** (24 mailboxes, 80 recipients) : ~1 minute

## Prerequis

- PowerShell 7.2+
- Module ExchangeOnlineManagement v3 (cmdlets EXO*)
- Module Microsoft.Graph.Authentication (pour -IncludeLastLogon)
- Droits : Exchange Administrator ou Global Reader

## Installation

```powershell
# Installer les modules requis
Install-Module ExchangeOnlineManagement -Scope CurrentUser
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser

# Cloner le projet
git clone <url-du-repo>
cd Demo-Collect-Delegation
```

## Utilisation

### Collecte Standard

```powershell
# Connexion et collecte (mailboxes utilisateurs uniquement)
.\Get-ExchangeDelegation.ps1

# Collecte complete avec derniere connexion
.\Get-ExchangeDelegation.ps1 -IncludeSharedMailbox -IncludeLastLogon
```

### Options

```powershell
# Specifier un dossier de sortie
.\Get-ExchangeDelegation.ps1 -OutputPath "C:\Reports"

# Inclure les mailboxes partagees
.\Get-ExchangeDelegation.ps1 -IncludeSharedMailbox

# Inclure les salles de reunion
.\Get-ExchangeDelegation.ps1 -IncludeRoomMailbox

# Collecte complete (User + Shared + Room + Inactive + LastLogon)
.\Get-ExchangeDelegation.ps1 -IncludeSharedMailbox -IncludeRoomMailbox -IncludeInactive -IncludeLastLogon
```

### Nettoyage des Orphelins

```powershell
# Simuler la suppression des delegations orphelines (sans supprimer)
.\Get-ExchangeDelegation.ps1 -CleanupOrphans -WhatIf

# Supprimer les delegations orphelines
.\Get-ExchangeDelegation.ps1 -CleanupOrphans -Force
```

### Parametres

| Parametre | Type | Defaut | Description |
|-----------|------|--------|-------------|
| `-OutputPath` | string | ./Output | Dossier de sortie pour le CSV |
| `-IncludeSharedMailbox` | switch | - | Inclure les mailboxes partagees (SharedMailbox) |
| `-IncludeRoomMailbox` | switch | - | Inclure les salles de reunion (RoomMailbox) |
| `-IncludeInactive` | switch | - | Inclure les mailboxes inactives (soft-deleted) |
| `-IncludeLastLogon` | switch | - | Ajouter la date de derniere connexion |
| `-OrphansOnly` | switch | - | Exporter uniquement les delegations orphelines |
| `-CleanupOrphans` | switch | - | Supprimer les delegations orphelines |
| `-Force` | switch | - | Forcer la suppression (avec -CleanupOrphans) |
| `-NoResume` | switch | - | Ignorer le checkpoint existant |

## Sortie

### Fichier CSV

Le script genere un fichier CSV dans le dossier Output :
```
ExchangeDelegations_2025-12-15_143022.csv
```

### Colonnes

| Colonne | Description |
|---------|-------------|
| `MailboxEmail` | Adresse email de la mailbox |
| `MailboxDisplayName` | Nom affiche de la mailbox |
| `TrusteeEmail` | Email ou SID du delegue |
| `TrusteeDisplayName` | Nom du delegue |
| `DelegationType` | Type de delegation (FullAccess, SendAs, etc.) |
| `AccessRights` | Droits accordes |
| `FolderPath` | Chemin du dossier (Calendar uniquement) |
| `IsOrphan` | `True` si le delegue n'existe plus |
| `IsInactive` | `True` si la mailbox est inactive |
| `IsSoftDeleted` | `True` si la mailbox est en soft-delete |
| `MailboxType` | Type de mailbox (UserMailbox, SharedMailbox, RoomMailbox) |
| `MailboxLastLogon` | Date derniere connexion (si -IncludeLastLogon) |
| `LastLogonSource` | Source des donnees LastLogon (SignInActivity, GraphReports, EXO) |
| `CollectedAt` | Timestamp de collecte |

## Reprise apres Interruption

Le script supporte la reprise automatique en cas d'interruption (Ctrl+C, erreur reseau, etc.) :

1. Un fichier checkpoint est cree dans `Output/.checkpoint_<hash>.json`
2. A la reprise, le script detecte le checkpoint et propose de continuer
3. Les mailboxes deja traitees sont ignorees (lookup O(1))
4. Le CSV final contient toutes les donnees (mode append)

Pour forcer une nouvelle collecte :
```powershell
.\Get-ExchangeDelegation.ps1 -NoResume
```

## Structure du Projet

```
Exchange-Collect-Delegation/
├── Get-ExchangeDelegation.ps1    # Script principal
├── Config/
│   └── Settings.json             # Configuration globale
├── Modules/
│   ├── EXOConnection/            # Connexion Exchange Online (retry, validation)
│   ├── GraphConnection/          # Connexion Microsoft Graph
│   ├── Write-Log/                # Logging RFC 5424
│   ├── ConsoleUI/                # Interface console (banniere, status)
│   └── Checkpoint/               # Gestion checkpoint/reprise
├── Tests/
│   └── Unit/                     # Tests Pester
├── Output/                       # Fichiers CSV generes
├── Logs/                         # Fichiers de log
└── docs/
    ├── ARCHITECTURE.md           # Documentation technique
    └── issues/                   # Suivi des issues locales
```

## Tests

```powershell
# Executer tous les tests unitaires
Invoke-Pester -Path ./Tests -Output Detailed

# Executer les tests d'une fonction specifique
Invoke-Pester -Path ./Tests/Unit/New-DelegationRecord.Tests.ps1 -Output Detailed
```

## Securite

- Les permissions systeme (NT AUTHORITY, SELF, etc.) sont exclues du rapport
- Les delegations orphelines (S-1-5-21-*) sont incluses pour permettre l'audit
- Validation du chemin OutputPath contre le path traversal
- Aucun credential n'est stocke dans le code
- Les donnees sensibles ne sont jamais loggees

## Licence

MIT

## Auteur

zornot - 2025-2026
