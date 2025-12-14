# Changelog

Toutes les modifications notables sont documentees dans ce fichier.

Format base sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/).
Ce projet adhere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-07

### Added

- `Write-ConsoleBanner` : Banniere avec padding dynamique
- `Write-SummaryBox` : Resume avec statistiques colorees
- `Write-SelectionBox` : Menu selection applications
- `Write-MenuBox` : Menu generique
- `Write-Box` : Boite generique
- `Write-EnterpriseAppsSelectionBox` : Menu Enterprise Apps
- `Write-UnifiedSelectionBox` : Menu selection unifiee
- `Write-CollectionModeBox` : Menu mode de collecte
- `Write-CategorySelectionMenu` : Menu categories avec toggle
- `Update-CategorySelection` : Helper toggle categories
- Fonctions privees : `Write-PaddedLine`, `Write-BoxBorder`, `Write-EmptyLine`

### Features

- Box Drawing Unicode : `┌─┐│└─┘├┤`
- Icones brackets : `[+] [-] [!] [i] [>] [?]`
- Calcul dynamique du padding pour alignement parfait
- Compatible PowerShell 7.2+
- Pas d'emoji (compatibilite terminaux)
