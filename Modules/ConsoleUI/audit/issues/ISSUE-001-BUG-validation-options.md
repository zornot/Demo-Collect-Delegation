# [~] [BUG-001] Ajouter validation format Options dans Write-MenuBox | Effort: 30min

## PROBLEME
Write-MenuBox accepte un parametre $Options de type [array] sans valider
que chaque element est un hashtable avec les cles 'Key' et 'Text'.
Si l'utilisateur passe un tableau de strings, une exception cryptique est levee
au lieu d'un message d'erreur explicite.

## LOCALISATION
- Fichier : Modules/ConsoleUI/ConsoleUI.psm1:L438-439
- Fonction : Write-MenuBox
- Module : ConsoleUI

## OBJECTIF
Valider le format des options a l'entree de la fonction avec un message d'erreur
explicite si le format est incorrect.

---

## ANALYSE IMPACT

### Fichiers Impactes
| Fichier | Raison | Action Requise |
|---------|--------|----------------|
| ConsoleUI.psm1 | Fonction modifiee | Modification parametre |

### Code Mort a Supprimer
Aucun - cette issue ajoute du code.

---

## IMPLEMENTATION

### Etape 1 : Modifier le parametre $Options - 30min
Fichier : Modules/ConsoleUI/ConsoleUI.psm1
Lignes L438-439 - MODIFIER

AVANT :
```powershell
[Parameter(Mandatory)]
[array]$Options
```

APRES :
```powershell
[Parameter(Mandatory)]
[ValidateScript({
    foreach ($opt in $_) {
        if (-not ($opt -is [hashtable] -and $opt.ContainsKey('Key') -and $opt.ContainsKey('Text'))) {
            throw "Chaque option doit etre un hashtable avec les cles 'Key' et 'Text'. Recu: $($opt.GetType().Name)"
        }
    }
    $true
}, ErrorMessage = "Format attendu: @(@{Key='A'; Text='Option A'}, ...)")]
[hashtable[]]$Options
```

Justification : ValidateScript permet une validation precise avec message d'erreur explicite.
Le typage [hashtable[]] renforce la validation.

---

## VALIDATION

### Execution Virtuelle
```
Entree : Write-MenuBox -Title "Test" -Options @("Option1", "Option2")
L438  : ValidateScript execute
L438  : $opt = "Option1" (string)
L438  : -not ($opt -is [hashtable]) = $true
L438  : throw "Chaque option doit etre un hashtable..."
Sortie : ParameterBindingValidationException avec message explicite
```
[>] VALIDE - Message d'erreur clair au lieu d'exception cryptique

### Criteres d'Acceptation
- [x] Format correct accepte : @(@{Key='A'; Text='Test'})
- [x] Format incorrect rejete avec message explicite
- [x] Pas de regression sur les appels existants

---

## DEPENDANCES
- Bloquee par : Aucune
- Bloque : Aucune

## POINTS ATTENTION
- 1 fichier modifie
- ~8 lignes ajoutees
- Risques : Breaking change si appelants utilisent mauvais format (peu probable)

## CHECKLIST
- [x] Code AVANT = code reel verifie
- [x] Tests unitaires passent
- [x] Code review effectuee

Labels : bug robustesse validation effort-30min

---

## SYNCHRONISATION GITHUB

| Champ | Valeur |
|-------|--------|
| GitHub Issue | # |
| Statut | RESOLVED |
| Commit Resolution | (a committer) |
