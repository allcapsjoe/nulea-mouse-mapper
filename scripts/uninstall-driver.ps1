#Requires -RunAsAdministrator
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$installer = Join-Path $projectRoot '.runtime\install-interception.exe'

if (-not (Test-Path -LiteralPath $installer)) {
    throw 'Runtime not found. Run scripts\setup.ps1 first.'
}

$answer = Read-Host 'Type UNINSTALL to remove the Interception driver'
if ($answer -cne 'UNINSTALL') {
    Write-Host 'Uninstall cancelled.'
    exit 1
}

& $installer /uninstall
if ($LASTEXITCODE -ne 0) {
    throw "The uninstaller exited with code $LASTEXITCODE."
}

Write-Host 'Driver removal command completed. Restart Windows to finish.' -ForegroundColor Yellow
