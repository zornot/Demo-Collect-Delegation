# Architecture - Exchange Collect Delegation

Document d'Architecture Technique (DAT) v1.3.0

## Vue d'Ensemble

```
┌─────────────────────────────────────────────────────────────────┐
│                    Get-ExchangeDelegation.ps1                    │
│                         (Orchestrateur)                          │
└─────────────────────────────────────────────────────────────────┘
         │              │              │              │
         ▼              ▼              ▼              ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│ EXOConnection│ │GraphConnection│ │  ConsoleUI  │ │  Write-Log  │
│   Module    │ │    Module    │ │   Module    │ │   Module    │
└─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘
         │              │
         ▼              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    APIs Microsoft 365                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │Exchange Online│  │ Graph Reports│  │signInActivity│          │
│  │  (EXO REST)  │  │   (v1.0)     │  │  (P1/P2)     │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

## Composants

### Script Principal

| Fichier | Lignes | Responsabilite |
|---------|--------|----------------|
| `Get-ExchangeDelegation.ps1` | ~1500 | Orchestration, collecte, export CSV |

**Fonctions principales :**

| Fonction | Description |
|----------|-------------|
| `Initialize-RecipientCache` | Pre-charge tous les recipients en memoire |
| `Initialize-SignInActivityCache` | Cache signInActivity (P1/P2) |
| `Initialize-EmailActivityCache` | Cache Graph Reports (fallback) |
| `Get-MailboxLastLogon` | Cascade des 3 sources LastLogon |
| `New-DelegationRecord` | Fabrique d'objets delegation standardises |
| `Get-MailboxFullAccessDelegation` | Collecte FullAccess |
| `Get-MailboxSendAsDelegation` | Collecte SendAs |
| `Get-MailboxSendOnBehalfDelegation` | Collecte SendOnBehalf |
| `Get-MailboxCalendarDelegation` | Collecte Calendar (multilingue) |
| `Get-MailboxForwardingDelegation` | Collecte Forwarding SMTP |

### Modules

#### EXOConnection

```
Modules/EXOConnection/
├── Modules/EXOConnection/
│   ├── EXOConnection.psm1    # Logique connexion
│   └── EXOConnection.psd1    # Manifest
└── README.md
```

| Fonction | Description |
|----------|-------------|
| `Connect-EXOSession` | Connexion avec retry (3 tentatives, backoff exponentiel) |
| `Test-EXOConnection` | Validation connexion active |

#### GraphConnection

```
Modules/GraphConnection/
├── Modules/GraphConnection/
│   ├── GraphConnection.psm1  # Logique connexion Graph
│   └── GraphConnection.psd1  # Manifest
└── README.md
```

| Fonction | Description |
|----------|-------------|
| `Connect-GraphConnection` | Connexion Microsoft Graph avec scopes |

**Scopes requis :**
- `User.Read.All` - Lecture utilisateurs
- `AuditLog.Read.All` - signInActivity (P1/P2)
- `Reports.Read.All` - Graph Reports

#### ConsoleUI

```
Modules/ConsoleUI/
├── Modules/ConsoleUI/
│   ├── ConsoleUI.psm1        # Fonctions UI
│   └── ConsoleUI.psd1        # Manifest
└── README.md
```

| Fonction | Description |
|----------|-------------|
| `Write-ConsoleBanner` | Banniere ASCII au demarrage |
| `Write-Status` | Messages status avec icones [+] [-] [>] [i] [!] |
| `Write-ProgressBar` | Barre de progression |

#### Write-Log

```
Modules/Write-Log/
├── Modules/Write-Log/
│   ├── Write-Log.psm1        # Logging RFC 5424
│   └── Write-Log.psd1        # Manifest
└── README.md
```

| Fonction | Description |
|----------|-------------|
| `Write-Log` | Log structure avec niveaux (DEBUG, INFO, WARNING, ERROR) |

#### Checkpoint (integre)

Module interne au script principal pour la gestion des reprises.

| Fonction | Description |
|----------|-------------|
| `Initialize-Checkpoint` | Initialise ou restaure checkpoint |
| `Get-ExistingCheckpoint` | Detecte checkpoint existant |
| `Add-ProcessedItem` | Marque mailbox comme traitee |
| `Test-AlreadyProcessed` | Verifie si mailbox deja traitee (O(1)) |
| `Save-Checkpoint` | Sauvegarde etat courant |
| `Complete-Checkpoint` | Finalise et supprime checkpoint |
| `Get-CheckpointState` | Retourne etat actuel |

## Flux de Donnees

### Collecte Standard

```
1. Connexion
   ├── Connect-EXOSession (Exchange Online)
   └── Connect-GraphConnection (Microsoft Graph)

2. Initialisation Caches
   ├── Initialize-RecipientCache (tous recipients)
   └── Initialize-SignInActivityCache (si P1) OU Initialize-EmailActivityCache

3. Recuperation Mailboxes
   └── Get-EXOMailbox -ResultSize Unlimited

4. Boucle Collecte (par mailbox)
   ├── Test-AlreadyProcessed (checkpoint)
   ├── Get-MailboxFullAccessDelegation
   ├── Get-MailboxSendAsDelegation
   ├── Get-MailboxSendOnBehalfDelegation
   ├── Get-MailboxCalendarDelegation
   ├── Get-MailboxForwardingDelegation
   ├── Enrichissement (LastLogon, MailboxType, etc.)
   ├── Export-Csv -Append
   └── Add-ProcessedItem (checkpoint)

5. Finalisation
   ├── Complete-Checkpoint
   └── Affichage statistiques
```

### Strategie LastLogon

```
Get-MailboxLastLogon($UPN)
    │
    ├─ $Script:LastLogonStrategy == 'SignInActivity' ?
    │   └── Retourne $Script:SignInActivityCache[$UPN]
    │
    ├─ $Script:LastLogonStrategy == 'GraphReports' ?
    │   └── Retourne $Script:EmailActivityCache[$UPN]
    │
    └─ Fallback EXO
        └── Get-EXOMailboxStatistics -Properties LastInteractionTime
```

## Modele de Donnees

### DelegationRecord

```powershell
[PSCustomObject]@{
    MailboxEmail       = [string]   # PrimarySmtpAddress
    MailboxDisplayName = [string]   # DisplayName
    TrusteeEmail       = [string]   # Email ou SID (S-1-5-21-*)
    TrusteeDisplayName = [string]   # Nom ou SID
    DelegationType     = [string]   # FullAccess|SendAs|SendOnBehalf|Calendar|Forwarding
    AccessRights       = [string]   # Droits specifiques
    FolderPath         = [string]   # Chemin calendrier (si applicable)
    IsOrphan           = [bool]     # True si trustee supprime
    IsInactive         = [bool]     # True si mailbox inactive
    IsSoftDeleted      = [bool]     # True si mailbox soft-deleted
    MailboxType        = [string]   # UserMailbox|SharedMailbox|RoomMailbox
    MailboxLastLogon   = [string]   # dd/MM/yyyy ou vide
    LastLogonSource    = [string]   # SignInActivity|GraphReports|EXO|vide
    CollectedAt        = [string]   # Timestamp collecte
}
```

### Checkpoint

```json
{
    "StartTime": "2025-12-15T14:30:00",
    "Parameters": {
        "IncludeSharedMailbox": true,
        "IncludeLastLogon": true
    },
    "CsvPath": "Output/ExchangeDelegations_2025-12-15_143022.csv",
    "ProcessedItems": ["user1@contoso.com", "user2@contoso.com"],
    "LastCompletedIndex": 42
}
```

## Gestion des Erreurs

### Strategie Generale

| Niveau | Action |
|--------|--------|
| Connexion | Retry 3x avec backoff exponentiel |
| Mailbox | Continue, log warning |
| Delegation | Continue, log debug |
| Fatal | Exit avec code erreur |

### Codes de Sortie

| Code | Signification |
|------|---------------|
| 0 | Succes |
| 1 | Erreur connexion Exchange |
| 2 | Erreur connexion Graph |
| 3 | Erreur parametre invalide |

## Performance

### Optimisations

| Technique | Impact | Complexite |
|-----------|--------|------------|
| Cache Recipients | -80% appels API | O(1) lookup |
| Cmdlets EXO* | 3x plus rapide | REST natif |
| HashSet Checkpoint | O(1) vs O(n) | Reprise instantanee |
| Cache LastLogon | -N appels API | Pre-charge Graph |
| List<T> | Pas de reallocation | Add O(1) amorti |

### Benchmarks

| Scenario | Mailboxes | Recipients | Temps |
|----------|-----------|------------|-------|
| PME | 24 | 80 | ~1 min |
| ETI | 500 | 2000 | ~15 min |
| Grande entreprise | 5000 | 20000 | ~2h |

## Securite

### Principes

1. **Pas de credentials hardcodes** - Authentification interactive ou managed identity
2. **Validation inputs** - Tous les chemins valides contre path traversal
3. **Filtrage systeme** - Exclusion NT AUTHORITY, SELF, etc.
4. **Logs securises** - Pas de donnees sensibles dans les logs
5. **Permissions minimales** - Global Reader suffit pour collecte

### Exclusions Systeme

```powershell
$systemPatterns = @(
    'NT AUTHORITY*', 'S-1-5-10', 'SELF',
    'Default', 'Anonymous', '*DiscoverySearchMailbox*'
)
```

## Tests

### Structure

```
Tests/
└── Unit/
    └── New-DelegationRecord.Tests.ps1  # 26 tests
```

### Couverture

| Fonction | Tests | Statut |
|----------|-------|--------|
| New-DelegationRecord | 26 | OK |

### Execution

```powershell
Invoke-Pester -Path ./Tests -Output Detailed
```

## Evolutions Futures

| ID | Feature | Priorite |
|----|---------|----------|
| FEAT-012 | Export HTML des delegations | Moyenne |

---

*Derniere mise a jour : 2026-02-11*
*Version : 1.3.0*
