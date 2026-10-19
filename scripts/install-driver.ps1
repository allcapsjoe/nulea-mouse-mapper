#Requires -RunAsAdministrator
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$installer = Join-Path $projectRoot '.runtime\install-interception.exe'

if (-not (Test-Path -LiteralPath $installer)) {
    throw 'Runtime not found. Run scripts\setup.ps1 first.'
}

Write-Warning 'This installs the unsigned Interception input-filter driver.'
Write-Warning 'A driver problem can temporarily disable mouse or keyboard input until Windows is restarted.'
$answer = Read-Host 'Type INSTALL to continue'
if ($answer -cne 'INSTALL') {
    Write-Host 'Installation cancelled.'
    exit 1
}

& $installer /install
if ($LASTEXITCODE -ne 0) {
    throw "The installer exited with code $LASTEXITCODE."
}

Write-Host 'Driver installation command completed. Restart Windows before discovery.' -ForegroundColor Yellow
