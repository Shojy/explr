function Step-ExplrInto {
    <#
    .SYNOPSIS
        Drills into a directory selection; resolves symlink targets with loop guard.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$State,

        [Parameter(Mandatory)]
        [System.IO.FileSystemInfo]$Item
    )

    if (-not $Item.PSIsContainer) {
        return
    }

    $target = $Item.FullName

    # Symlink loop guard.
    $isLink = ($Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
    if ($isLink) {
        try {
            $resolved = [System.IO.Directory]::ResolveLinkTarget($Item.FullName, $true)
            if ($null -ne $resolved) {
                $target = $resolved.FullName
            }
        }
        catch {
            # NOTE: ResolveLinkTarget can throw on broken links; fall back to original path.
            $target = $Item.FullName
        }

        if ($State.VisitedSymlinks.Contains($target)) {
            return
        }
        [void]$State.VisitedSymlinks.Add($target)
    }

    try {
        $newDir = Get-Item -LiteralPath $target -Force -ErrorAction Stop
        if ($newDir -is [System.IO.DirectoryInfo]) {
            $State.CurrentDir = $newDir
            $State.Fragment = ''
            Update-ExplrChildCache -State $State
        }
    }
    catch {
        # NOTE: directory disappeared / access denied between render and drill; no-op.
    }
}
