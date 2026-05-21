function Set-ExplrConsoleMode {
    <#
    .SYNOPSIS
        Enters takeover mode: hide cursor, capture Ctrl+C, anchor cursor.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$State
    )

    $script:ExplrPrevTreatCtrlC = [Console]::TreatControlCAsInput
    [Console]::TreatControlCAsInput = $true

    # Force UTF-8 output for the duration of takeover. We bypass the PowerShell formatter and write
    # raw to [Console]::Out, which uses [Console]::OutputEncoding — on Windows that defaults to the
    # OEM codepage and renders Nerd Font glyphs (and any non-ASCII char) as '?' / '??'.
    try {
        $script:ExplrPrevOutputEncoding = [Console]::OutputEncoding
        [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    }
    catch {
        $script:ExplrPrevOutputEncoding = $null
    }

    # Hide cursor.
    [Console]::Write("`e[?25l")

    # Make sure there is room below the prompt for the dropdown, then anchor.
    $size = Get-ExplrConsoleSize
    $State.ConsoleWidth = $size.Width
    $State.ConsoleHeight = $size.Height
    $State.VisibleRows = [Math]::Min(10, [Math]::Max(1, $size.Height - 2))

    # Reserve VisibleRows lines below for the dropdown by writing newlines, then moving back up.
    $reserve = $State.VisibleRows
    try {
        $top = [Console]::CursorTop
        $left = [Console]::CursorLeft
        # If near bottom, scroll buffer by writing newlines, then come back.
        $available = $size.Height - 1 - $top
        if ($available -lt $reserve) {
            $needed = $reserve - $available
            for ($i = 0; $i -lt $needed; $i++) { [Console]::Write("`n") }
            $top = [Console]::CursorTop - $needed
            [Console]::SetCursorPosition($left, $top)
        }
        $State.AnchorRow = [Console]::CursorTop
    }
    catch {
        # NOTE: SetCursorPosition can fail in rare host conditions; ignore and continue.
        $State.AnchorRow = 0
    }

    # Save cursor position with DECSC (ESC 7).
    [Console]::Write("`e7")
}
