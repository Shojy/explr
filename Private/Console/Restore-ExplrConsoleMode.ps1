function Restore-ExplrConsoleMode {
    <#
    .SYNOPSIS
        Exits takeover mode: clear dropdown, restore cursor, restore Ctrl+C handling.
    #>
    [CmdletBinding()]
    param()

    try {
        # Restore cursor with DECRC, clear from there to end of screen, show cursor.
        [Console]::Write("`e8`e[0J`e[?25h")
    }
    catch {
        # NOTE: ignore write failures during restore; we still need to restore Ctrl+C handling.
    }

    if ($null -ne $script:ExplrPrevTreatCtrlC) {
        try {
            [Console]::TreatControlCAsInput = [bool]$script:ExplrPrevTreatCtrlC
        }
        catch { }
        $script:ExplrPrevTreatCtrlC = $null
    }
    else {
        try { [Console]::TreatControlCAsInput = $false } catch { }
    }

    if ($null -ne $script:ExplrPrevOutputEncoding) {
        try { [Console]::OutputEncoding = $script:ExplrPrevOutputEncoding } catch { }
        $script:ExplrPrevOutputEncoding = $null
    }
}
