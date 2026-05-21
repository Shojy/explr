function New-ExplrState {
    <#
    .SYNOPSIS
        Factory for the explr state pscustomobject.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.IO.DirectoryInfo]$CurrentDir,

        [string]$Fragment = '',

        [bool]$ListOnly = $false
    )

    [pscustomobject]@{
        CurrentDir      = $CurrentDir
        Fragment        = $Fragment
        Children        = @()
        Matches         = @()
        SelectedIndex   = 0
        ScrollOffset    = 0
        VisibleRows     = 10
        ConsoleWidth    = 80
        ConsoleHeight   = 24
        AnchorRow       = 0
        ListOnly        = $ListOnly
        ExitAction      = 'None'
        ExitTarget      = $null
        Dirty           = $true
        NeedsResize     = $false
        VisitedSymlinks = [System.Collections.Generic.HashSet[string]]::new(
            # On Linux paths are case-sensitive; on Windows/macOS the default filesystem is insensitive.
            $(if ($IsWindows -or $IsMacOS) { [System.StringComparer]::OrdinalIgnoreCase } else { [System.StringComparer]::Ordinal }))
    }
}
