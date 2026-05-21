function Enable-ExplrAliases {
    <#
    .SYNOPSIS
        Replaces cd with an explr-driven wrapper in the requested scope. ls is left untouched.
    #>
    [CmdletBinding()]
    param(
        [string]$Scope = 'Global'
    )

    # Idempotency: if a snapshot already exists, the previous Enable hasn't been Disabled.
    # Re-snapshotting now would capture explr's own replacement as the "original", permanently
    # breaking restore. Silently no-op so a profile that re-runs Enable-ExplrAliases is safe.
    if ($null -ne $script:OriginalAliases) {
        return
    }

    $existing = @{}
    $a = Get-Alias -Name 'cd' -ErrorAction SilentlyContinue
    if ($a) {
        $existing['cd'] = @{ Kind = 'Alias'; Definition = $a.Definition; Options = $a.Options }
    }
    else {
        $existing['cd'] = $null
    }
    $script:OriginalAliases = $existing

    # cd wrapper: parameterless `cd` opens explr; `cd <path>` falls through to Set-Location so
    # scripts and muscle-memory paths still work normally. Defining as a function (rather than
    # Set-Alias cd Invoke-Explr) lets us inspect $args before deciding which path to take.
    $cdBody = [scriptblock]::Create(@'
if ($args.Count -eq 0) {
    Invoke-Explr
}
else {
    Set-Location @args
}
'@)

    # PowerShell command resolution checks aliases before functions, so a function alone can't
    # shadow the built-in `cd` alias — we must remove the alias first. The default `cd` alias is
    # AllScope + ReadOnly, hence -Force. Disable-ExplrAliases recreates it from the snapshot.
    Remove-Item -Path 'Alias:cd' -Force -ErrorAction SilentlyContinue

    # The wrapper must live in the caller's session state, not the module's. Set-Item with a
    # 'function:global:' qualifier resolves relative to the *module's* session state when invoked
    # from inside a module function, which is not what we want. New-Item -Path Function:Global:
    # via the FileSystemProvider drive walks the real global scope.
    if ($Scope -eq 'Global') {
        New-Item -Path 'Function:Global:cd' -Value $cdBody -Force | Out-Null
    }
    else {
        # NOTE: non-global scopes can only target the module's script scope from here; document this caveat.
        New-Item -Path 'Function:Script:cd' -Value $cdBody -Force | Out-Null
    }
}
