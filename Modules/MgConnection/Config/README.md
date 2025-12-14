# Configuration

## Setup

1. Copier `Settings.example.json` vers `Settings.json`
2. Configurer selon votre environnement

```powershell
Copy-Item Settings.example.json Settings.json
```

## Modes

| Mode | Usage |
|------|-------|
| Interactive | Developpement, admin ponctuel |
| Certificate | Production (recommande) |
| ClientSecret | CI/CD, automation |
| ManagedIdentity | Azure VM/App Service |

## Securite

- `Settings.json` est ignore par Git
- Les secrets sont lus depuis les variables d'environnement
- Ne jamais commiter de credentials
