<#
.SYNOPSIS
    Exemple d'utilisation du module GraphConnection.

.DESCRIPTION
    Demontre les fonctionnalites du module GraphConnection :
    - Connexion interactive a Microsoft Graph
    - Connexion par certificat
    - Verification de connexion
    - Deconnexion propre

.NOTES
    Auteur: Zornot
    Date: 2025-12-22
    Prerequis: Microsoft.Graph.Authentication >= 2.0.0
#>

#Requires -Version 7.2
#Requires -Modules @{ ModuleName='Microsoft.Graph.Authentication'; ModuleVersion='2.0.0' }

# Import du module
Import-Module "$PSScriptRoot\..\Module\GraphConnection.psd1" -ErrorAction Stop

# =============================================================================
# Exemple 1 : Initialisation avec fichier de configuration
# =============================================================================
Write-Host "[i] " -NoNewline -ForegroundColor Cyan
Write-Host "Initialisation depuis Config/Settings.json..."

Initialize-GraphConnection -ConfigPath "$PSScriptRoot\..\Config\Settings.json"

# =============================================================================
# Exemple 2 : Verification de connexion existante
# =============================================================================
Write-Host ""
Write-Host "[i] " -NoNewline -ForegroundColor Cyan
Write-Host "Verification de la connexion Microsoft Graph..."

if (Test-GraphConnection) {
    Write-Host "[+] " -NoNewline -ForegroundColor Green
    Write-Host "Session Microsoft Graph active"

    # Afficher les infos de connexion
    $info = Get-GraphConnectionInfo
    Write-Host "[i] " -NoNewline -ForegroundColor Cyan
    Write-Host "Tenant: $($info.TenantId)"
    Write-Host "[i] " -NoNewline -ForegroundColor Cyan
    Write-Host "Scopes: $($info.Scopes -join ', ')"
}
else {
    Write-Host "[!] " -NoNewline -ForegroundColor Yellow
    Write-Host "Aucune session active"
}

# =============================================================================
# Exemple 3 : Connexion interactive
# =============================================================================
Write-Host ""
Write-Host "[i] " -NoNewline -ForegroundColor Cyan
Write-Host "Tentative de connexion interactive..."

try {
    $connection = Connect-GraphConnection

    if ($connection) {
        Write-Host "[+] " -NoNewline -ForegroundColor Green
        Write-Host "Connexion etablie avec succes"

        # Exemple d'utilisation de l'API Graph
        Write-Host "[i] " -NoNewline -ForegroundColor Cyan
        Write-Host "Recuperation du profil utilisateur..."

        # $me = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/me"
        # Write-Host "[i] Utilisateur: $($me.displayName)"

        # Deconnexion via l'objet de connexion
        $connection.Disconnect()
        Write-Host "[+] " -NoNewline -ForegroundColor Green
        Write-Host "Deconnexion via objet de connexion"
    }
}
catch {
    Write-Host "[-] " -NoNewline -ForegroundColor Red
    Write-Host "Erreur de connexion: $($_.Exception.Message)"
}

# =============================================================================
# Exemple 4 : Connexion par certificat (App Registration)
# =============================================================================
Write-Host ""
Write-Host "[i] " -NoNewline -ForegroundColor Cyan
Write-Host "Exemple de connexion par certificat (commente)..."

<#
$certConnection = Connect-GraphConnection -UseCertificate `
    -ClientId "00000000-0000-0000-0000-000000000000" `
    -TenantId "00000000-0000-0000-0000-000000000000" `
    -CertificateThumbprint "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

if ($certConnection) {
    # Operations avec privileges application...
    Disconnect-GraphConnection
}
#>

Write-Host "[+] " -NoNewline -ForegroundColor Green
Write-Host "Demonstration terminee"
