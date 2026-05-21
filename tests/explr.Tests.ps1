BeforeAll {
    $script:ModuleRoot = Split-Path -Parent $PSScriptRoot
    $script:ManifestPath = Join-Path $script:ModuleRoot 'explr.psd1'
}

Describe 'explr module manifest' {
    It 'has a valid module manifest' {
        # Test-ModuleManifest will fail if RequiredModules cannot be resolved on this machine,
        # so we read & validate the data hash directly to keep the test environment-agnostic.
        $data = Import-PowerShellDataFile -Path $script:ManifestPath
        $data.ModuleVersion | Should -Be '0.1.0'
        $data.RootModule | Should -Be 'explr.psm1'
        $data.PowerShellVersion | Should -Be '7.0'
    }

    It 'exports exactly the three documented public functions' {
        $data = Import-PowerShellDataFile -Path $script:ManifestPath
        $expected = @('Invoke-Explr', 'Enable-ExplrAliases', 'Disable-ExplrAliases') | Sort-Object
        ($data.FunctionsToExport | Sort-Object) | Should -Be $expected
    }

    It 'exports the explr alias' {
        $data = Import-PowerShellDataFile -Path $script:ManifestPath
        $data.AliasesToExport | Should -Contain 'explr'
    }

    It 'declares Terminal-Icons as a required module' {
        $data = Import-PowerShellDataFile -Path $script:ManifestPath
        $req = @($data.RequiredModules)
        $req.Count | Should -BeGreaterThan 0
        $req[0].ModuleName | Should -Be 'Terminal-Icons'
        $req[0].ModuleVersion | Should -Be '0.11.0'
    }
}
