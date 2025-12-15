# Get-ExchangeDelegation

Collecte toutes les delegations Exchange Online d'une organisation.

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
Import-Csv "ExchangeDelegations_*.csv" | Where-Object { $_.TrusteeEmail -match '^S-1-5-21' }
```

## Prerequis

- PowerShell 7.2+
- Module ExchangeOnlineManagement
- Droits : Exchange Administrator ou Global Reader

## Installation

```powershell
# Installer le module Exchange Online
Install-Module ExchangeOnlineManagement -Scope CurrentUser

# Cloner le projet
git clone <url-du-repo>
cd Demo-Collect-Delegation
```

## Utilisation

### Collecte Standard

```powershell
# Connexion et collecte (mailboxes utilisateurs + partagees)
.\Get-ExchangeDelegation.ps1
```

### Options

```powershell
# Specifier un dossier de sortie
.\Get-ExchangeDelegation.ps1 -OutputPath "C:\Reports"

# Inclure les salles de reunion
.\Get-ExchangeDelegation.ps1 -IncludeRoomMailbox

# Exclure les mailboxes partagees
.\Get-ExchangeDelegation.ps1 -IncludeSharedMailbox:$false
```

### Nettoyage des Orphelins

```powershell
# Simuler la suppression des delegations orphelines (sans supprimer)
.\Get-ExchangeDelegation.ps1 -CleanupOrphans -WhatIf

# Supprimer les delegations orphelines
.\Get-ExchangeDelegation.ps1 -CleanupOrphans
```

### Parametres

| Parametre | Type | Defaut | Description |
|-----------|------|--------|-------------|
| `-OutputPath` | string | ./Output | Dossier de sortie pour le CSV |
| `-IncludeSharedMailbox` | switch | $true | Inclure les mailboxes partagees |
| `-IncludeRoomMailbox` | switch | $false | Inclure les salles de reunion |
| `-CleanupOrphans` | switch | $false | Supprimer les delegations orphelines |
| `-WhatIf` | switch | - | Simuler sans supprimer (avec -CleanupOrphans) |

## Sortie

### Fichier CSV

Le script genere un fichier CSV dans le dossier Output :
```
ExchangeDelegations_2025-12-15_143022.csv
```

### Colonnes

| Colonne | Description |
|---------|-------------|
| MailboxEmail | Adresse email de la mailbox |
| MailboxDisplayName | Nom affiche de la mailbox |
| TrusteeEmail | Email ou SID du delegue |
| TrusteeDisplayName | Nom du delegue |
| DelegationType | Type de delegation |
| AccessRights | Droits accordes |
| FolderPath | Chemin du dossier (Calendar) |
| CollectedAt | Timestamp de collecte |

## Structure du Projet

```
Demo-Collect-Delegation/
├── Get-ExchangeDelegation.ps1   # Script principal
├── Modules/
│   ├── EXOConnection/           # Connexion Exchange Online
│   ├── Write-Log/               # Logging RFC 5424
│   └── ConsoleUI/               # Interface console
├── Tests/
│   └── Unit/                    # Tests Pester
├── Output/                      # Fichiers CSV generes
└── Logs/                        # Fichiers de log
```

## Tests

```powershell
# Executer les tests unitaires
Invoke-Pester -Path ./Tests -Output Detailed
```

## Securite

- Les permissions systeme (NT AUTHORITY, SELF, etc.) sont exclues du rapport
- Les delegations orphelines (S-1-5-21-*) sont incluses pour permettre l'audit
- Validation du chemin OutputPath contre le path traversal
- Aucun credential n'est stocke dans le code

## Licence

[A definir]

## Auteur

zornot - 2025
