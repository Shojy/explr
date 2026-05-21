function Select-ExplrMatches {
    <#
    .SYNOPSIS
        Filters Children by Fragment with prefix-priority ranking and dirs-first ordering.
        When -CurrentDir is supplied and the fragment is empty, prepends a synthetic self-row
        (a pscustomobject with IsSelfRow=$true and Item=<CurrentDir>) so the user can commit
        the current directory directly with Enter.
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.IList])]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [System.Collections.IEnumerable]$Children,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Fragment,

        [System.IO.DirectoryInfo]$CurrentDir
    )

    $items = @()
    if ($null -ne $Children) {
        foreach ($c in $Children) { if ($null -ne $c) { $items += $c } }
    }

    if ([string]::IsNullOrEmpty($Fragment)) {
        $sorted = @(
            $items |
                Sort-Object @{ Expression = { -not $_.PSIsContainer } }, @{ Expression = { $_.Name } }
        )
        if ($null -ne $CurrentDir) {
            $self = [pscustomobject]@{
                IsSelfRow   = $true
                Item        = $CurrentDir
                Name        = '.'
                FullName    = $CurrentDir.FullName
                PSIsContainer = $true
                Attributes  = $CurrentDir.Attributes
            }
            return @(@($self) + $sorted)
        }
        return $sorted
    }

    $f = $Fragment.ToLowerInvariant()
    $ranked = foreach ($item in $items) {
        $name = $item.Name
        $lower = $name.ToLowerInvariant()
        $rank = -1

        if ($lower.StartsWith($f)) {
            $rank = 0
        }
        else {
            # Word-start match after [._\-\s]
            $wordStart = $false
            for ($i = 1; $i -lt $lower.Length; $i++) {
                $prev = $lower[$i - 1]
                if ($prev -eq '.' -or $prev -eq '_' -or $prev -eq '-' -or [char]::IsWhiteSpace($prev)) {
                    if ($i + $f.Length -le $lower.Length -and $lower.Substring($i, $f.Length) -eq $f) {
                        $wordStart = $true
                        break
                    }
                }
            }
            if ($wordStart) {
                $rank = 1
            }
            elseif ($lower.Contains($f)) {
                $rank = 2
            }
        }

        if ($rank -ge 0) {
            [pscustomobject]@{
                Item     = $item
                Rank     = $rank
                DirFirst = if ($item.PSIsContainer) { 0 } else { 1 }
                Name     = $name
            }
        }
    }

    return @(
        $ranked |
            Sort-Object Rank, DirFirst, Name |
            ForEach-Object { $_.Item }
    )
}
