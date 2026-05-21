function Write-ExplrFileLine {
    <#
    .SYNOPSIS
        Prints a single Terminal-Icons-style row for a committed file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileSystemInfo]$Item
    )

    if (Get-Module -Name 'Terminal-Icons') {
        # NOTE: Format-TerminalIcons is a Format cmdlet — pipe a single item to print one row.
        $Item | Format-TerminalIcons | Out-Default
        return
    }

    $iconInfo = Get-ExplrIcon -Item $Item
    $line = "$($iconInfo.Icon) $($Item.Name)"
    [Console]::WriteLine($line)
}
