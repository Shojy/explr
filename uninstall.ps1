<#
.SYNOPSIS
    Removes the explr PowerShell module from the current user's module path.

.DESCRIPTION
    Removes every installed version of explr from the user's PowerShell Modules folder. Does not
    uninstall Terminal-Icons (other modules may depend on it).

    Intended as a one-liner:

        irm https://raw.githubusercontent.com/Shojy/explr/main/uninstall.ps1 | iex
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$module = 'explr'
$modulesRoot = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules'
$moduleRoot = Join-Path $modulesRoot $module

if (-not (Test-Path -LiteralPath $moduleRoot)) {
    Write-Host "$module is not installed at $moduleRoot." -ForegroundColor Yellow
    return
}

# Drop any loaded copy from the current session before removing files.
Get-Module -Name $module -All | Remove-Module -Force -ErrorAction SilentlyContinue

Remove-Item -LiteralPath $moduleRoot -Recurse -Force
Write-Host "Removed $moduleRoot." -ForegroundColor Green
Write-Host "Note: Terminal-Icons was left in place. Uninstall it manually if desired:" -ForegroundColor DarkGray
Write-Host "  Uninstall-Module Terminal-Icons" -ForegroundColor DarkGray
