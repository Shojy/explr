function Test-ExplrConsoleSupported {
    <#
    .SYNOPSIS
        Returns $true if the host can drive the explr takeover loop.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    if ($Host.Name -eq 'Windows PowerShell ISE Host') {
        return $false
    }

    try {
        if ([Console]::IsInputRedirected) { return $false }
    }
    catch {
        # NOTE: IsInputRedirected may throw on certain non-standard hosts; treat as unsupported.
        return $false
    }

    if ($env:NO_COLOR) { return $false }

    if ($null -ne $Host.UI -and $null -ne $Host.UI.SupportsVirtualTerminal) {
        if (-not $Host.UI.SupportsVirtualTerminal) { return $false }
    }

    return $true
}
