#Requires -Version 7.2
<#
.SYNOPSIS
    Récupération de toutes les délégations existantes sur une organisation Exchange Online
.DESCRIPTION
    Script principal du projet Demo Collect Delegation.
.NOTES
    Author: zornot
    Date: 2025-12-15
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# TODO: Implementer la logique principale
Write-Host "[i] " -NoNewline -ForegroundColor Cyan
Write-Host "Demo Collect Delegation - Script principal"
