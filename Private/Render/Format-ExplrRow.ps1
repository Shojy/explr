function Format-ExplrRow {
    <#
    .SYNOPSIS
        Formats one dropdown row with icon, name, optional symlink target, and SGR.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileSystemInfo]$Item,

        [Parameter(Mandatory)]
        [int]$Width,

        [bool]$Selected = $false
    )

    $iconInfo = Get-ExplrIcon -Item $Item
    $iconColor = $iconInfo.Color
    # Terminal-Icons returns '\e[0m' (full reset) as the colour for items without an explicit
    # theme entry — emitting that mid-row wipes our selection background, leaving the highlight
    # invisible on generic folders/files. Strip the full-reset case so Format-ExplrRowApplySgr's
    # background can persist across the icon.
    if ($iconColor -eq "`e[0m") { $iconColor = '' }
    # Use SGR 39 (default foreground) to end the icon colour, not 0 (full reset), so any
    # surrounding background SGR survives across the icon.
    $iconReset = if ($iconColor) { "`e[39m" } else { '' }
    $iconSgr = if ($iconColor) { $iconColor } else { '' }

    $name = $Item.Name
    if ($Item.PSIsContainer) {
        $name = $name + '\'
    }

    $isLink = ($Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
    $linkTarget = $null
    if ($isLink) {
        try { $linkTarget = [System.IO.Directory]::ResolveLinkTarget($Item.FullName, $false) }
        catch { $linkTarget = $null }
    }

    # Worst-case visual width of the icon: assume 2 cells per char (Nerd Font folder glyphs are
    # often 2-cell even when the codepoint is one char). Surrogate pairs count once. We use this
    # only to budget truncation — padding is intentionally NOT emitted, so under/over-counting
    # never causes wrap; CSI EL paints the highlight to the right edge regardless.
    $iconVisual = 0
    foreach ($ch in $iconInfo.Icon.ToCharArray()) {
        if (-not [char]::IsLowSurrogate($ch)) { $iconVisual++ }
    }
    $iconBudget = ($iconVisual * 2) + 2   # *2 for ambiguous-width glyphs, +2 for spacing after the glyph.

    $plainTargetLen = if ($linkTarget) { (" -> $($linkTarget.FullName)").Length } else { 0 }

    # Truncation budget. Available width is the terminal width minus icon, target, and a 1-cell
    # safety margin so we never quite hit the edge (which can trigger wrap on some terminals).
    $available = [Math]::Max(0, $Width - 1)
    $maxName = $available - $iconBudget - $plainTargetLen

    if ($maxName -lt 1) {
        # Pathological narrow terminal — render only an ellipsis.
        $body = "$iconSgr$($iconInfo.Icon)$iconReset" + [char]0x2026
        return Format-ExplrRowApplySgr -Row $body -Item $Item -Selected:$Selected
    }

    if ($name.Length -gt $maxName) {
        $name = $name.Substring(0, $maxName - 1) + [char]0x2026
    }

    # Build the symlink target suffix using SGR 22;39 (cancel-dim + default-fg) instead of full
    # reset, so the surrounding reverse-video stays in effect.
    $targetSuffix = if ($linkTarget) { " `e[2;90m -> $($linkTarget.FullName)`e[22;39m" } else { '' }

    # No trailing padding — Format-ExplrRowApplySgr appends CSI EL when selected, which lets the
    # terminal paint the rest of the line in the active SGR (reverse-video).
    $body = "$iconSgr$($iconInfo.Icon)$iconReset  $name" + $targetSuffix

    return Format-ExplrRowApplySgr -Row $body -Item $Item -Selected:$Selected
}

function Format-ExplrRowApplySgr {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Row,

        [Parameter(Mandatory)]
        [System.IO.FileSystemInfo]$Item,

        [bool]$Selected
    )

    $isHidden = $Item.Name.StartsWith('.') -or (($Item.Attributes -band [System.IO.FileAttributes]::Hidden) -ne 0)

    $out = $Row
    if ($isHidden) {
        $out = "`e[2m$out`e[22m"
    }
    if ($Selected) {
        # Use an explicit 256-colour grey background (xterm 238) plus CSI EL to extend it to the
        # right edge. We deliberately avoid reverse-video (`\e[7m`): under reverse, terminals fill
        # `\e[K` with the swap of the current foreground, which is invisible on rows that don't
        # set an explicit fg (uncoloured folder glyphs in particular) — the highlight only
        # appeared on coloured rows. Explicit bg paints the same regardless of fg state.
        $out = "`e[48;5;238m$out`e[K`e[49m"
    }
    return $out
}
