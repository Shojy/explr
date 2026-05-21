function Format-ExplrPromptLine {
    <#
    .SYNOPSIS
        Formats the input prompt line: prefix + CurrentDir + Fragment.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$State
    )

    $prefix = if ($State.ListOnly) { 'ls> ' } else { 'cd> ' }
    $sep = [System.IO.Path]::DirectorySeparatorChar
    $dir = $State.CurrentDir.FullName.TrimEnd($sep)
    return "$prefix$dir$sep$($State.Fragment)"
}
