function Split-ExplrPathParts {
    <#
    .SYNOPSIS
        Splits an input path into (BaseDir, Fragment) for the dropdown.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Path
    )

    if ([string]::IsNullOrEmpty($Path)) {
        return @{ BaseDir = (Get-Location).ProviderPath; Fragment = '' }
    }

    $lastSlash = [Math]::Max($Path.LastIndexOf('\'), $Path.LastIndexOf('/'))
    if ($lastSlash -lt 0) {
        return @{ BaseDir = (Get-Location).ProviderPath; Fragment = $Path }
    }

    $base = $Path.Substring(0, $lastSlash + 1)
    $frag = $Path.Substring($lastSlash + 1)

    return @{ BaseDir = $base; Fragment = $frag }
}
