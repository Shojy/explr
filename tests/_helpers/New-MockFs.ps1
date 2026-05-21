function Test-Admin {
    <#
    .SYNOPSIS
        Returns $true if the current process has Administrator rights on Windows.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = [System.Security.Principal.WindowsPrincipal]::new($id)
        return $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function New-MockFs {
    <#
    .SYNOPSIS
        Builds a small mock filesystem under a directory and returns its root path.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Root,

        [switch]$IncludeHidden,

        [switch]$IncludeSymlink
    )

    if (-not (Test-Path -LiteralPath $Root)) {
        New-Item -ItemType Directory -Path $Root -Force | Out-Null
    }

    New-Item -ItemType Directory -Path (Join-Path $Root 'Documents') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $Root 'Downloads') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $Root 'Music') -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $Root 'readme.txt') -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $Root 'notes.md') -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $Root 'todo-list.txt') -Force | Out-Null

    if ($IncludeHidden) {
        $hidden = New-Item -ItemType File -Path (Join-Path $Root '.hidden') -Force
        try { $hidden.Attributes = $hidden.Attributes -bor [System.IO.FileAttributes]::Hidden } catch { }
    }

    if ($IncludeSymlink -and (Test-Admin)) {
        $linkPath = Join-Path $Root 'DocsLink'
        try {
            New-Item -ItemType SymbolicLink -Path $linkPath -Target (Join-Path $Root 'Documents') -Force | Out-Null
        }
        catch { }
    }

    return $Root
}
