function Update-ExplrChildCache {
    <#
    .SYNOPSIS
        Refreshes the Children cache on the state object from CurrentDir.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$State
    )

    try {
        $items = @(Get-ChildItem -LiteralPath $State.CurrentDir.FullName -Force -ErrorAction SilentlyContinue)
    }
    catch {
        # NOTE: defensive — Get-ChildItem with -ErrorAction SilentlyContinue should not throw, but UNC/permission edge cases can.
        $items = @()
    }

    $State.Children = $items
    $State.SelectedIndex = 0
    $State.ScrollOffset = 0
    $State.Dirty = $true
}
