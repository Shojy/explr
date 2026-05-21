function Get-ExplrConsoleSize {
    <#
    .SYNOPSIS
        Returns @{ Width; Height } of the current console.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    try {
        $w = [Console]::WindowWidth
        $h = [Console]::WindowHeight
    }
    catch {
        # NOTE: very rare — fall back to safe defaults rather than crashing the loop.
        $w = 80
        $h = 24
    }

    if ($w -le 0) { $w = 80 }
    if ($h -le 0) { $h = 24 }

    return @{ Width = $w; Height = $h }
}
