function Get-ExplrIcon {
    <#
    .SYNOPSIS
        Resolves an icon for a FileSystemInfo via Terminal-Icons; ASCII fallback.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileSystemInfo]$Item
    )

    $ti = Get-Module -Name 'Terminal-Icons'
    if ($null -ne $ti) {
        try {
            $resolved = & $ti { param($x) Resolve-Icon $x } $Item
            if ($null -ne $resolved) {
                return @{
                    Icon   = $resolved.Icon
                    Color  = $resolved.Color
                    Target = $resolved.Target
                }
            }
        }
        catch {
            # Resolve-Icon is private API; if Terminal-Icons changes shape, fall through to ASCII
            # but tell the truth in the warning — the module IS loaded, the call just failed.
            if (-not $script:ExplrIconResolveWarned) {
                Write-Warning "Terminal-Icons Resolve-Icon failed; falling back to ASCII glyphs. ($_)"
                $script:ExplrIconResolveWarned = $true
            }
        }
    }
    else {
        if (-not $script:ExplrIconMissingWarned) {
            Write-Warning 'Terminal-Icons module not loaded; falling back to ASCII glyphs.'
            $script:ExplrIconMissingWarned = $true
        }
    }

    $glyph = if ($Item.PSIsContainer) { '[/]' } else { '[ ]' }
    return @{
        Icon   = $glyph
        Color  = $null
        Target = $null
    }
}
