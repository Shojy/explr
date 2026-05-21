@{
    ModuleVersion        = '0.1.0'
    RootModule           = 'explr.psm1'
    PowerShellVersion    = '7.0'
    GUID                 = '16c1ff2e-d9f6-4840-b89c-4de20483be16'
    Author               = 'JMOON'
    CompanyName          = 'Personal'
    Copyright            = '(c) 2026 JMOON. MIT.'
    Description          = 'Interactive cd + ls replacement with live dropdown, icons, and Terminal-Icons styling.'
    RequiredModules      = @(@{ ModuleName = 'Terminal-Icons'; ModuleVersion = '0.11.0' })
    FunctionsToExport    = @('Invoke-Explr', 'Enable-ExplrAliases', 'Disable-ExplrAliases')
    AliasesToExport      = @('explr')
    CmdletsToExport      = @()
    VariablesToExport    = @()
    PrivateData          = @{
        PSData = @{
            Tags       = @('cd', 'ls', 'navigation', 'filesystem', 'interactive', 'terminal-icons')
            LicenseUri = 'https://opensource.org/licenses/MIT'
            ProjectUri = ''
        }
    }
}
