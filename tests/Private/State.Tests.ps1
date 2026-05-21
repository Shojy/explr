BeforeAll {
    $script:ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module (Join-Path $script:ModuleRoot 'explr.psd1') -Force
    . (Join-Path $script:ModuleRoot 'tests\_helpers\New-MockFs.ps1')
}

Describe 'New-ExplrState' {
    It 'returns a state object with all required fields' {
        InModuleScope explr {
            $tempDir = [System.IO.Path]::GetTempPath()
            $state = New-ExplrState -CurrentDir (Get-Item -LiteralPath $tempDir)

            foreach ($field in 'CurrentDir', 'Fragment', 'Children', 'Matches', 'SelectedIndex',
                'ScrollOffset', 'VisibleRows', 'ConsoleWidth', 'ConsoleHeight', 'AnchorRow',
                'ListOnly', 'ExitAction', 'ExitTarget', 'Dirty', 'NeedsResize', 'VisitedSymlinks') {
                $state.PSObject.Properties.Name | Should -Contain $field
            }

            $state.Fragment | Should -Be ''
            $state.SelectedIndex | Should -Be 0
            $state.ExitAction | Should -Be 'None'
            $state.ListOnly | Should -BeFalse
            $state.VisitedSymlinks.GetType().Name | Should -Be 'HashSet`1'
        }
    }
}

Describe 'Update-ExplrChildCache' {
    BeforeAll {
        $script:FsRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("explr_state_" + [guid]::NewGuid())
        New-MockFs -Root $script:FsRoot | Out-Null
    }
    AfterAll {
        if (Test-Path -LiteralPath $script:FsRoot) {
            Remove-Item -LiteralPath $script:FsRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'populates Children for the current directory' {
        InModuleScope explr -Parameters @{ Root = $script:FsRoot } {
            param($Root)
            $state = New-ExplrState -CurrentDir (Get-Item -LiteralPath $Root)
            Update-ExplrChildCache -State $state
            $state.Children.Count | Should -BeGreaterThan 0
        }
    }

    It 'resets SelectedIndex and ScrollOffset to 0' {
        InModuleScope explr -Parameters @{ Root = $script:FsRoot } {
            param($Root)
            $state = New-ExplrState -CurrentDir (Get-Item -LiteralPath $Root)
            $state.SelectedIndex = 5
            $state.ScrollOffset = 5
            Update-ExplrChildCache -State $state
            $state.SelectedIndex | Should -Be 0
            $state.ScrollOffset | Should -Be 0
        }
    }
}
