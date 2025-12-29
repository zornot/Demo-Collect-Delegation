# PSScriptAnalyzer

Guide d'integration PSScriptAnalyzer dans le workflow de developpement.

## Analyse Obligatoire

Apres chaque modification de fichier .ps1/.psm1/.psd1 :
```powershell
Invoke-ScriptAnalyzer -Path $file -Severity Warning,Error
```

## Regles Critiques (TOUJOURS corriger)

| Regle | Severite | Solution |
|-------|----------|----------|
| PSAvoidUsingPlainTextForPassword | ERROR | Utiliser SecureString ou $env: |
| PSAvoidUsingConvertToSecureStringWithPlainText | ERROR | Utiliser Read-Host -AsSecureString |
| PSAvoidUsingInvokeExpression | WARNING | Utiliser & ou . pour executer |
| PSUseShouldProcessForStateChangingFunctions | WARNING | Ajouter [CmdletBinding(SupportsShouldProcess)] - voir [simulation-whatif.md](simulation-whatif.md) |

## Faux Positifs Connus

### Scope Pester (PSUseDeclaredVarsMoreThanAssignments)

PSScriptAnalyzer ne comprend pas le scope Pester ou les variables declarees
dans `BeforeEach` sont utilisees dans les blocs `It`.

**Solution - Niveau fichier** (recommande pour tests) :
```powershell
#Requires -Modules Pester

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

BeforeAll { ... }
```

**Solution - Niveau variable** (precision) :
```powershell
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'testCheckpointPath')]
param()
```

### Autres Faux Positifs Acceptables

| Regle | Contexte acceptable | Justification requise |
|-------|--------------------|-----------------------|
| PSReviewUnusedParameter | Parametre pour compatibilite API | Commentaire # UNUSED: reason |
| PSUseDeclaredVarsMoreThanAssignments | Variable pour scope externe | Commentaire # SCOPE: reason |

## Integration Workflow

### Apres Write/Edit de fichier PowerShell
1. Hook formate automatiquement (Invoke-Formatter)
2. Verifier manuellement : `Invoke-ScriptAnalyzer -Path $file`
3. Corriger les WARNING/ERROR
4. Si faux positif : ajouter SuppressMessageAttribute avec commentaire

### Commit Checklist
- [ ] Aucun ERROR PSScriptAnalyzer
- [ ] WARNING corriges ou justifies (SuppressMessage)
- [ ] Commentaire explicatif si suppression
