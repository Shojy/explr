function Disable-ExplrAliases {
    <#
    .SYNOPSIS
        Restores the cd/ls aliases captured by Enable-ExplrAliases.
    #>
    [CmdletBinding()]
    param(
        [string]$Scope = 'Global'
    )

    if ($null -eq $script:OriginalAliases -or $script:OriginalAliases.Count -eq 0) {
        Write-Warning 'Disable-ExplrAliases: no snapshot found (was Enable-ExplrAliases ever called?).'
        return
    }

    # Remove the wrapper functions. Note: from inside a module, 'Function:Global:cd' does NOT
    # remove the actually-global function. Plain 'Function:<name>' walks the same provider drive
    # and removes the function we created via New-Item -Path 'Function:Global:<name>'. Removing
    # the wrapper lets the original AllScope cd/ls aliases re-surface in command resolution.
    foreach ($name in 'cd', 'ls') {
        Remove-Item -Path "Function:$name" -ErrorAction SilentlyContinue
    }

    # If the original cd/ls were ever something other than the default AllScope aliases (rare),
    # restore them explicitly. The common case (default aliases) needs no further action.
    foreach ($name in 'cd', 'ls') {
        $orig = $script:OriginalAliases[$name]
        if ($null -ne $orig -and $orig.Kind -eq 'Alias') {
            $current = Get-Alias -Name $name -ErrorAction SilentlyContinue
            if ($null -eq $current -or $current.Definition -ne $orig.Definition) {
                $opt = if ($null -ne $orig.Options) { $orig.Options } else { [System.Management.Automation.ScopedItemOptions]::AllScope }
                Set-Alias -Name $name -Value $orig.Definition -Scope $Scope -Force -Option $opt
            }
        }
    }

    $script:OriginalAliases = $null
}
