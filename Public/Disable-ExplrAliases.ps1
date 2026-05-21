function Disable-ExplrAliases {
    <#
    .SYNOPSIS
        Restores the cd alias captured by Enable-ExplrAliases.
    #>
    [CmdletBinding()]
    param(
        [string]$Scope = 'Global'
    )

    if ($null -eq $script:OriginalAliases -or $script:OriginalAliases.Count -eq 0) {
        Write-Warning 'Disable-ExplrAliases: no snapshot found (was Enable-ExplrAliases ever called?).'
        return
    }

    # Remove the wrapper function. Note: from inside a module, 'Function:Global:cd' does NOT
    # remove the actually-global function. Plain 'Function:cd' walks the same provider drive and
    # removes the function we created via New-Item -Path 'Function:Global:cd'.
    Remove-Item -Path 'Function:cd' -ErrorAction SilentlyContinue

    # Recreate the original cd alias. Enable-ExplrAliases removed it (since aliases beat
    # functions in command resolution), so it cannot re-surface on its own — we have to put it
    # back from the snapshot.
    $orig = $script:OriginalAliases['cd']
    if ($null -ne $orig -and $orig.Kind -eq 'Alias') {
        $opt = if ($null -ne $orig.Options) { $orig.Options } else { [System.Management.Automation.ScopedItemOptions]::AllScope }
        Set-Alias -Name 'cd' -Value $orig.Definition -Scope $Scope -Force -Option $opt
    }

    $script:OriginalAliases = $null
}
