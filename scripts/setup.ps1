[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$cacheRoot = Join-Path $projectRoot '.cache'
$downloadsRoot = Join-Path $cacheRoot 'downloads'
$extractRoot = Join-Path $cacheRoot 'extracted'
$runtimeRoot = Join-Path $projectRoot '.runtime'

$packages = @(
    @{
        Name = 'AutoHotkey'
        Version = '2.0.30'
        Url = 'https://github.com/AutoHotkey/AutoHotkey/releases/download/v2.0.30/AutoHotkey_2.0.30.zip'
        File = 'AutoHotkey-v2.0.30.zip'
        Sha256 = '1E0ECE7ECB2D5646E55758150472677996A57F9DB5C83D2996D8B47B9E2F31A4'
        Folder = 'autohotkey'
    },
    @{
        Name = 'AutoHotInterception'
        Version = '0.9.2'
        Url = 'https://github.com/evilC/AutoHotInterception/releases/download/v0.9.2/AutoHotInterception.zip'
        File = 'AutoHotInterception-v0.9.2.zip'
        Sha256 = '5E0DD6C69A61FE0E6F040D9FD82D7099022A84A0E6BC3A338666EEB23CA4F0DA'
        Folder = 'ahi'
    },
    @{
        Name = 'Interception'
        Version = '1.0.1'
        Url = 'https://github.com/oblitum/Interception/releases/download/v1.0.1/Interception.zip'
        File = 'Interception-v1.0.1.zip'
        Sha256 = 'AD038963D6413055765128B0B931F6E765147C9916DBA79E65D872B261F9AF10'
        Folder = 'interception'
    }
)

New-Item -ItemType Directory -Force -Path $downloadsRoot, $extractRoot, $runtimeRoot, (Join-Path $runtimeRoot 'Lib\x64') | Out-Null

foreach ($package in $packages) {
    $archivePath = Join-Path $downloadsRoot $package.File
    $destination = Join-Path $extractRoot $package.Folder

    $needsDownload = $true
    if (Test-Path -LiteralPath $archivePath) {
        $existingHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $archivePath).Hash
        $needsDownload = $existingHash -ne $package.Sha256
    }

    if ($needsDownload) {
        Write-Host "Downloading $($package.Name) $($package.Version)..."
        Invoke-WebRequest -Uri $package.Url -OutFile $archivePath
    }

    $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $archivePath).Hash
    if ($actualHash -ne $package.Sha256) {
        throw "Checksum mismatch for $($package.Name). Expected $($package.Sha256), received $actualHash."
    }

    Unblock-File -LiteralPath $archivePath
    New-Item -ItemType Directory -Force -Path $destination | Out-Null
    Expand-Archive -LiteralPath $archivePath -DestinationPath $destination -Force
}

$ahkRoot = Join-Path $extractRoot 'autohotkey'
$ahiRoot = Join-Path $extractRoot 'ahi'
$interceptionRoot = Join-Path $extractRoot 'interception\Interception'

Copy-Item -Force -LiteralPath (Join-Path $ahkRoot 'AutoHotkey64.exe') -Destination (Join-Path $runtimeRoot 'AutoHotkey64.exe')
Copy-Item -Force -LiteralPath (Join-Path $ahiRoot 'AHK v2\Lib\AutoHotInterception.ahk') -Destination (Join-Path $runtimeRoot 'Lib\AutoHotInterception.ahk')
Copy-Item -Force -LiteralPath (Join-Path $ahiRoot 'AHK v2\Lib\CLR.ahk') -Destination (Join-Path $runtimeRoot 'Lib\CLR.ahk')
Copy-Item -Force -LiteralPath (Join-Path $ahiRoot 'Common\Lib\AutoHotInterception.dll') -Destination (Join-Path $runtimeRoot 'Lib\AutoHotInterception.dll')
Copy-Item -Force -LiteralPath (Join-Path $interceptionRoot 'library\x64\interception.dll') -Destination (Join-Path $runtimeRoot 'Lib\x64\interception.dll')
Copy-Item -Force -LiteralPath (Join-Path $interceptionRoot 'command line installer\install-interception.exe') -Destination (Join-Path $runtimeRoot 'install-interception.exe')
Copy-Item -Force -LiteralPath (Join-Path $projectRoot 'mapper\DiscoverNulea.ahk') -Destination (Join-Path $runtimeRoot 'DiscoverNulea.ahk')
Copy-Item -Force -LiteralPath (Join-Path $projectRoot 'mapper\NuleaMapper.ahk') -Destination (Join-Path $runtimeRoot 'NuleaMapper.ahk')

Get-ChildItem -LiteralPath $runtimeRoot -Recurse -File | Unblock-File

Write-Host ''
Write-Host 'Runtime prepared successfully.' -ForegroundColor Green
Write-Host "Location: $runtimeRoot"
Write-Host 'No driver was installed and no mapping was activated.'
