function Resolve-ExplrPath {
    <#
    .SYNOPSIS
        Expands ~, env vars, and relative paths; preserves a trailing slash.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Path,

        [string]$BaseDir
    )

    if ([string]::IsNullOrEmpty($Path)) {
        return $Path
    }

    $hadTrailing = $Path.EndsWith('/') -or $Path.EndsWith('\')

    $expanded = [System.Environment]::ExpandEnvironmentVariables($Path)

    if ($expanded.StartsWith('~')) {
        $userHome = [System.Environment]::GetFolderPath('UserProfile')
        if ($expanded.Length -eq 1) {
            $expanded = $userHome
        }
        elseif ($expanded[1] -eq '/' -or $expanded[1] -eq '\') {
            $expanded = Join-Path $userHome $expanded.Substring(2)
        }
    }

    if (-not [System.IO.Path]::IsPathRooted($expanded)) {
        $base = if ($PSBoundParameters.ContainsKey('BaseDir') -and -not [string]::IsNullOrEmpty($BaseDir)) {
            $BaseDir
        }
        else {
            (Get-Location).ProviderPath
        }
        $expanded = Join-Path $base $expanded
    }

    try {
        $full = [System.IO.Path]::GetFullPath($expanded)
    }
    catch {
        # NOTE: invalid characters / malformed input — return unchanged so caller can decide.
        return $Path
    }

    if ($hadTrailing -and -not ($full.EndsWith('/') -or $full.EndsWith('\'))) {
        $full = $full + [System.IO.Path]::DirectorySeparatorChar
    }

    return $full
}
