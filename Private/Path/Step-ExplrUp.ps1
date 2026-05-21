function Step-ExplrUp {
    <#
    .SYNOPSIS
        Moves CurrentDir to parent; preserves leaf name as new fragment.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$State
    )

    $parent = $State.CurrentDir.Parent
    if ($null -eq $parent) {
        return
    }

    # Land in the parent's full listing — do not pre-fill the leaf as a fragment. Walking up the
    # tree should clear the filter so the user sees the parent's contents in full.
    $State.CurrentDir = $parent
    $State.Fragment = ''
    $State.SelectedIndex = 0
    $State.ScrollOffset = 0
    Update-ExplrChildCache -State $State
}
