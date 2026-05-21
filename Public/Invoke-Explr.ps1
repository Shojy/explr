function Invoke-Explr {
    <#
    .SYNOPSIS
        Interactive cd + ls replacement with live filtered dropdown.
    #>
    [CmdletBinding()]
    [OutputType([System.IO.FileSystemInfo])]
    param(
        [Parameter(Position = 0)]
        [string]$Path,

        [string]$StartPath,

        [switch]$ListOnly
    )

    if (-not (Test-ExplrConsoleSupported)) {
        $msg = 'explr requires an interactive PowerShell 7+ host with virtual-terminal support. ' +
               'It cannot run inside Windows PowerShell ISE, with redirected input, or when $env:NO_COLOR is set.'
        throw $msg
    }

    # Resolve start directory.
    $startDirPath = if ($PSBoundParameters.ContainsKey('StartPath') -and -not [string]::IsNullOrEmpty($StartPath)) {
        Resolve-ExplrPath -Path $StartPath
    }
    else {
        (Get-Location).ProviderPath
    }

    if (-not (Test-Path -LiteralPath $startDirPath -PathType Container)) {
        # If user passed a file path, use its parent.
        if (Test-Path -LiteralPath $startDirPath -PathType Leaf) {
            Write-Verbose "explr: -StartPath '$startDirPath' is a file; using its parent directory."
            $startDirPath = Split-Path -LiteralPath $startDirPath -Parent
        }
        else {
            throw "explr: start path not found: $startDirPath"
        }
    }

    $startDir = Get-Item -LiteralPath $startDirPath -Force

    # Initial fragment from -Path (if relative-ish) — for v1 we treat -Path as the typed input verbatim.
    $initialFragment = if ($PSBoundParameters.ContainsKey('Path')) { $Path } else { '' }

    $state = New-ExplrState -CurrentDir $startDir -Fragment $initialFragment -ListOnly:$ListOnly.IsPresent
    Update-ExplrChildCache -State $state

    try {
        Set-ExplrConsoleMode -State $state
        Invoke-ExplrLoop -State $state
    }
    finally {
        Restore-ExplrConsoleMode
    }

    Invoke-ExplrCommit -State $state
}
