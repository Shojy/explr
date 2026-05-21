function Invoke-ExplrCommit {
    <#
    .SYNOPSIS
        Dispatches on State.ExitAction after the loop ends.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$State
    )

    switch ($State.ExitAction) {
        'Cancel' {
            return
        }
        'CommitDir' {
            if ($null -ne $State.ExitTarget) {
                Set-Location -LiteralPath $State.ExitTarget.FullName
            }
            return
        }
        'CommitFile' {
            if ($null -ne $State.ExitTarget) {
                # Move the user to the file's containing directory so a file selection still
                # advances the working directory; emit the icon-coloured row + return the FileInfo.
                $parentPath = [System.IO.Path]::GetDirectoryName($State.ExitTarget.FullName)
                if (-not [string]::IsNullOrEmpty($parentPath)) {
                    Set-Location -LiteralPath $parentPath
                }
                Write-ExplrFileLine -Item $State.ExitTarget
                return $State.ExitTarget
            }
            return
        }
        'CommitList' {
            $target = if ($null -ne $State.ExitTarget) { $State.ExitTarget } else { $State.CurrentDir }
            if ($target -is [System.IO.FileInfo]) {
                Write-ExplrFileLine -Item $target
                return $target
            }
            $items = Get-ChildItem -LiteralPath $target.FullName -Force -ErrorAction SilentlyContinue
            if (Get-Module -Name 'Terminal-Icons') {
                $items | Format-TerminalIcons
            }
            else {
                $items
            }
            return
        }
        default {
            return
        }
    }
}
