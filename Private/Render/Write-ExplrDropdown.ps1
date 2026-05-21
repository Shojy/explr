function Write-ExplrDropdown {
    <#
    .SYNOPSIS
        Repaints the prompt line and dropdown rows from State.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$State
    )

    # Re-anchor if cursor scrolled off-screen.
    try {
        $top = [Console]::CursorTop
        if ($State.AnchorRow -ge $State.ConsoleHeight -or $State.AnchorRow -lt 0) {
            $State.AnchorRow = $top
            [Console]::Write("`e7")
        }
    }
    catch {
        # NOTE: cursor query may fail on exotic hosts; ignore.
    }

    # Restore to anchor and clear below.
    [Console]::Write("`e8`e[0J")

    # Prompt line.
    $promptLine = Format-ExplrPromptLine -State $State
    [Console]::Write($promptLine)
    [Console]::Write("`n")

    # Dropdown rows.
    $width = $State.ConsoleWidth
    $matchList = @($State.Matches)
    $count = $matchList.Count
    $visible = [Math]::Min($State.VisibleRows, [Math]::Max(1, $count))

    if ($count -eq 0) {
        # Empty state row.
        $msg = if ($State.Children.Count -eq 0 -and (-not (Test-Path -LiteralPath $State.CurrentDir.FullName))) {
            '(access denied)'
        }
        elseif ($State.Children.Count -eq 0) {
            '(empty)'
        }
        else {
            '(no matches)'
        }
        $color = if ($msg -eq '(access denied)') { "`e[2;31m" } else { "`e[2m" }
        [Console]::Write("$color$msg`e[0m")
        return
    }

    $offset = $State.ScrollOffset
    $end = [Math]::Min($offset + $visible - 1, $count - 1)

    for ($i = $offset; $i -le $end; $i++) {
        $isSel = ($i -eq $State.SelectedIndex)
        $entry = $matchList[$i]
        $row = if ($entry.PSObject.Properties['IsSelfRow'] -and $entry.IsSelfRow) {
            Format-ExplrSelfRow -Width $width -Selected:$isSel
        }
        else {
            Format-ExplrRow -Item $entry -Width $width -Selected:$isSel
        }
        [Console]::Write($row)
        if ($i -lt $end) { [Console]::Write("`n") }
    }
}

function Format-ExplrSelfRow {
    <#
    .SYNOPSIS
        Renders the synthetic 'commit current folder' row at the top of the dropdown.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [int]$Width,

        [bool]$Selected = $false
    )

    # Match Format-ExplrRow's icon spacing (two spaces after the glyph).
    $glyph = [char]0x00B7   # middle dot — visually distinct from a real entry's icon
    $body = "`e[2m$glyph  . (current folder)`e[22m"

    if ($Selected) {
        return "`e[48;5;238m$body`e[K`e[49m"
    }
    return $body
}
