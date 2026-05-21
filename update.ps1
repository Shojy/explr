<#
.SYNOPSIS
    One-liner updater for the explr PowerShell module.

.DESCRIPTION
    Re-runs the install pipeline against the user's existing explr install, pulling the latest
    contents from the configured channel (default `main`; override with $env:EXPLR_CHANNEL).

    If no existing install is found, prints the install command and offers to run it now.

    Intended to be invoked as:

        irm https://raw.githubusercontent.com/Shojy/explr/main/update.ps1 | iex
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repo        = 'Shojy/explr'
$channel     = if ($env:EXPLR_CHANNEL) { $env:EXPLR_CHANNEL } else { 'main' }
$module      = 'explr'
$installUrl  = "https://raw.githubusercontent.com/$repo/main/install.ps1"

$modulesRoot = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules'
$moduleRoot  = Join-Path $modulesRoot $module

$existing = $null
if (Test-Path -LiteralPath $moduleRoot) {
    # Each version is a subfolder; the module is "installed" if at least one version exists.
    $existing = Get-ChildItem -LiteralPath $moduleRoot -Directory -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        Select-Object -First 1
}

if ($null -ne $existing) {
    Write-Host "Found existing install: $module $($existing.Name)" -ForegroundColor Cyan
    Write-Host "Updating from channel '$channel'..." -ForegroundColor Cyan
    Write-Host ""
    # Delegate to install.ps1 — it already replaces the version folder atomically and re-checks
    # the Terminal-Icons dependency, which is exactly what update needs to do.
    Invoke-Expression (Invoke-RestMethod -Uri $installUrl)
    return
}

# No install found.
Write-Host ""
Write-Host "$module is not installed." -ForegroundColor Yellow
Write-Host ""
Write-Host "Install command:" -ForegroundColor Cyan
Write-Host "  irm $installUrl | iex"
Write-Host ""

$reply = Read-Host 'Run the install script now? [Y/n]'
if ([string]::IsNullOrWhiteSpace($reply) -or $reply -match '^(y|yes)$') {
    Write-Host ""
    Invoke-Expression (Invoke-RestMethod -Uri $installUrl)
}
else {
    Write-Host 'Skipped.' -ForegroundColor DarkGray
}
