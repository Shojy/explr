function New-MockKey {
    <#
    .SYNOPSIS
        Constructs a real System.ConsoleKeyInfo for use in mocked Read-ExplrKey.
    #>
    [CmdletBinding()]
    [OutputType([System.ConsoleKeyInfo])]
    param(
        [System.ConsoleKey]$Key = [System.ConsoleKey]::NoName,
        [char]$Char = [char]0,
        [switch]$Shift,
        [switch]$Alt,
        [switch]$Control
    )

    return [System.ConsoleKeyInfo]::new(
        $Char,
        $Key,
        [bool]$Shift,
        [bool]$Alt,
        [bool]$Control
    )
}

function New-MockChar {
    <#
    .SYNOPSIS
        Builds a printable ConsoleKeyInfo for a given char, picking a reasonable Key value.
    #>
    [CmdletBinding()]
    [OutputType([System.ConsoleKeyInfo])]
    param(
        [Parameter(Mandatory)]
        [char]$Char
    )

    $key = [System.ConsoleKey]::NoName
    $upper = [char]::ToUpperInvariant($Char)
    if ($upper -ge 'A' -and $upper -le 'Z') {
        $key = [System.ConsoleKey]([int][System.ConsoleKey]::A + ([int]$upper - [int][char]'A'))
    }
    elseif ($Char -ge '0' -and $Char -le '9') {
        $key = [System.ConsoleKey]([int][System.ConsoleKey]::D0 + ([int]$Char - [int][char]'0'))
    }
    return [System.ConsoleKeyInfo]::new($Char, $key, $false, $false, $false)
}
