function Enable-ExplrAliases {
    <#
    .SYNOPSIS
        Replaces cd/ls with explr-driven equivalents in the requested scope.
    #>
    [CmdletBinding()]
    param(
        [string]$Scope = 'Global'
    )

    # Idempotency: if a snapshot already exists, the previous Enable hasn't been Disabled.
    # Re-snapshotting now would capture explr's own replacements as the "original", permanently
    # breaking restore. Silently no-op so a profile that re-runs Enable-ExplrAliases is safe.
    if ($null -ne $script:OriginalAliases) {
        return
    }

    $existing = @{}
    foreach ($name in 'cd', 'ls') {
        $a = Get-Alias -Name $name -ErrorAction SilentlyContinue
        if ($a) {
            $existing[$name] = @{ Kind = 'Alias'; Definition = $a.Definition; Options = $a.Options }
        }
        else {
            $existing[$name] = $null
        }
    }
    $script:OriginalAliases = $existing

    # cd wrapper: parameterless `cd` opens explr; `cd <path>` falls through to Set-Location so
    # scripts and muscle-memory paths still work normally. Defining as a function (rather than
    # Set-Alias cd Invoke-Explr) lets us inspect $args before deciding which path to take.
    # Functions take precedence over aliases in command resolution, so this shadows the built-in
    # `cd` alias without removing it (the AllScope `cd` alias cannot be removed anyway).
    $cdBody = [scriptblock]::Create(@'
if ($args.Count -eq 0) {
    Invoke-Explr
}
else {
    Set-Location @args
}
'@)

    # ls wrapper: parameterless `ls` opens explr in -ListOnly mode; `ls <path>` falls through to
    # Get-ChildItem (the original ls alias target) so behaviour with arguments stays familiar.
    $lsBody = [scriptblock]::Create(@'
if ($args.Count -eq 0) {
    Invoke-Explr -ListOnly
}
else {
    Get-ChildItem @args
}
'@)

    # Wrappers must live in the caller's session state, not the module's. Set-Item with a
    # 'function:global:' qualifier resolves relative to the *module's* session state when invoked
    # from inside a module function, which is not what we want. New-Item -Path Function:Global:
    # via the FileSystemProvider drive walks the real global scope.
    if ($Scope -eq 'Global') {
        New-Item -Path 'Function:Global:cd' -Value $cdBody -Force | Out-Null
        New-Item -Path 'Function:Global:ls' -Value $lsBody -Force | Out-Null
    }
    else {
        # NOTE: non-global scopes can only target the module's script scope from here; document this caveat.
        New-Item -Path 'Function:Script:cd' -Value $cdBody -Force | Out-Null
        New-Item -Path 'Function:Script:ls' -Value $lsBody -Force | Out-Null
    }
}
