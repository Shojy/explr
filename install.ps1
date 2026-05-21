<#
.SYNOPSIS
    One-liner installer for the explr PowerShell module.

.DESCRIPTION
    Downloads explr from GitHub and installs it into the current user's PowerShell module path.
    Defaults to the `main` branch; set $env:EXPLR_CHANNEL before running to install from a
    different branch (e.g. `pre-release`, `feature/foo`).

    Also installs the Terminal-Icons dependency from the PowerShell Gallery if it isn't already
    present.

    Intended to be invoked as:

        irm https://raw.githubusercontent.com/Shojy/explr/main/install.ps1 | iex

    Requirements: PowerShell 7+ (the module itself requires PowerShell 7+).
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# --- Configuration ----------------------------------------------------------------------------
$repo    = 'Shojy/explr'
$channel = if ($env:EXPLR_CHANNEL) { $env:EXPLR_CHANNEL } else { 'main' }
$module  = 'explr'

# --- Pre-flight -------------------------------------------------------------------------------
if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw "explr requires PowerShell 7+. Current version: $($PSVersionTable.PSVersion). Install from https://aka.ms/powershell."
}

Write-Host "Installing $module from $repo (channel: $channel)..." -ForegroundColor Cyan

# --- Resolve module version from the manifest in the chosen channel --------------------------
# We pull explr.psd1 from the branch tip, parse it, and use ModuleVersion as the install folder
# name. This lets us land at the conventional `Modules\explr\<version>\` layout that PowerShell's
# auto-loader expects.
$manifestUrl = "https://raw.githubusercontent.com/$repo/$channel/explr.psd1"
try {
    $manifestText = Invoke-RestMethod -Uri $manifestUrl -ErrorAction Stop
}
catch {
    throw "Failed to fetch manifest from $manifestUrl. Check that the repo is public and the channel '$channel' exists. ($_)"
}

$manifestData = Invoke-Expression $manifestText
$version = $manifestData.ModuleVersion
if ([string]::IsNullOrWhiteSpace($version)) {
    throw "Could not read ModuleVersion from manifest at $manifestUrl."
}

Write-Host "  Resolved version: $version" -ForegroundColor DarkGray

# --- Download the channel zip ----------------------------------------------------------------
$zipUrl = "https://codeload.github.com/$repo/zip/refs/heads/$channel"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("explr_install_" + [guid]::NewGuid())
$zipPath = Join-Path $tempRoot 'channel.zip'
$extractRoot = Join-Path $tempRoot 'extract'
New-Item -ItemType Directory -Path $tempRoot, $extractRoot -Force | Out-Null

try {
    Write-Host "  Downloading $zipUrl..." -ForegroundColor DarkGray
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing -ErrorAction Stop

    Write-Host "  Extracting..." -ForegroundColor DarkGray
    Expand-Archive -Path $zipPath -DestinationPath $extractRoot -Force

    # Codeload zips wrap content in `<repo>-<branch>` (slashes replaced with `-`).
    $sourceDir = Get-ChildItem -Path $extractRoot -Directory | Select-Object -First 1
    if ($null -eq $sourceDir) {
        throw "Extracted archive at $extractRoot was empty."
    }

    # --- Install into the user's module path ---------------------------------------------------
    $modulesRoot = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules'
    $destination = Join-Path $modulesRoot "$module\$version"

    if (Test-Path -LiteralPath $destination) {
        Write-Host "  Removing existing install at $destination..." -ForegroundColor DarkGray
        Remove-Item -LiteralPath $destination -Recurse -Force
    }
    New-Item -ItemType Directory -Path $destination -Force | Out-Null

    # Copy module payload, skipping repo-only files.
    $exclude = @('tests', '.git', '.github', '.gitignore', '.vscode', 'install.ps1', 'build.ps1', 'README.md', 'CHANGELOG.md')
    Get-ChildItem -Path $sourceDir.FullName -Force |
        Where-Object { $exclude -notcontains $_.Name } |
        Copy-Item -Destination $destination -Recurse -Force

    # Always include the LICENSE file.
    $license = Join-Path $sourceDir.FullName 'LICENSE'
    if (Test-Path -LiteralPath $license) {
        Copy-Item -LiteralPath $license -Destination $destination -Force
    }

    Write-Host "  Installed to $destination" -ForegroundColor DarkGray

    # --- Ensure Terminal-Icons is available ----------------------------------------------------
    if (-not (Get-Module -ListAvailable -Name 'Terminal-Icons')) {
        Write-Host "  Installing dependency: Terminal-Icons..." -ForegroundColor DarkGray
        Install-Module -Name 'Terminal-Icons' -Scope CurrentUser -Force -AllowClobber
    }
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "explr $version installed." -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  Import-Module $module"
Write-Host "  Enable-ExplrAliases    # opt-in: makes bare 'cd' / 'ls' open explr"
Write-Host ""
Write-Host "To make this persistent, add the two lines above to your `$PROFILE."
