function Read-ExplrKey {
    <#
    .SYNOPSIS
        Mockable wrapper over [Console]::ReadKey($true).
    #>
    [CmdletBinding()]
    [OutputType([System.ConsoleKeyInfo])]
    param()

    return [Console]::ReadKey($true)
}
