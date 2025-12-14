# Tests

Tests unitaires Pester pour le module MgConnection.

## Execution

```powershell
Invoke-Pester -Path .\Tests -Output Detailed
```

## Structure

```
Tests/
└── Unit/
    └── MgConnection.Tests.ps1
```

## Coverage

Le module a 44 tests couvrant :
- Get-MgConnectionConfig
- Initialize-MgConnection
- Connect-MgConnection (4 modes)
- Test-MgConnection
- Disconnect-MgConnection
- Gestion des erreurs
- BUGFIX (TenantId placeholder, fallback, null ref)
