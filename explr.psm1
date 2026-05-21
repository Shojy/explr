$ErrorActionPreference = 'Stop'

# Dot-source Private then Public, alphabetical within each, recursive.
foreach ($folder in 'Private', 'Public') {
    $root = Join-Path $PSScriptRoot $folder
    if (Test-Path $root) {
        Get-ChildItem -Path $root -Filter *.ps1 -Recurse |
            Sort-Object FullName |
            ForEach-Object { . $_.FullName }
    }
}

Set-Alias -Name explr -Value Invoke-Explr -Scope Script

Export-ModuleMember -Function 'Invoke-Explr', 'Enable-ExplrAliases', 'Disable-ExplrAliases' -Alias 'explr'
