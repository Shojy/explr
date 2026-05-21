BeforeAll {
    $script:ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module (Join-Path $script:ModuleRoot 'explr.psd1') -Force
    . (Join-Path $script:ModuleRoot 'tests\_helpers\New-MockFs.ps1')
}

Describe 'Resolve-ExplrPath' {
    It 'expands ~ to the user profile' {
        InModuleScope explr {
            $r = Resolve-ExplrPath -Path '~'
            $r | Should -Be ([System.Environment]::GetFolderPath('UserProfile'))
        }
    }

    It 'preserves a trailing slash' {
        InModuleScope explr {
            $r = Resolve-ExplrPath -Path 'C:\Windows\'
            $r.EndsWith('\') -or $r.EndsWith('/') | Should -BeTrue
        }
    }

    It 'resolves .. against the base dir' {
        InModuleScope explr {
            $r = Resolve-ExplrPath -Path '..\foo' -BaseDir 'C:\Users\test'
            $r | Should -Be 'C:\Users\foo'
        }
    }

    It 'preserves UNC roots' {
        InModuleScope explr {
            # GetFullPath normalises slashes; we just need both UNC components preserved.
            $r = Resolve-ExplrPath -Path '\\server\share\folder'
            $r | Should -Match '^\\\\server\\share\\folder'
        }
    }
}

Describe 'Split-ExplrPathParts' {
    It 'splits on the last separator' {
        InModuleScope explr {
            $p = Split-ExplrPathParts -Path 'C:\Users\test\partial'
            $p.BaseDir | Should -Be 'C:\Users\test\'
            $p.Fragment | Should -Be 'partial'
        }
    }

    It 'returns empty fragment for trailing slash' {
        InModuleScope explr {
            $p = Split-ExplrPathParts -Path 'C:\Users\'
            $p.Fragment | Should -Be ''
        }
    }
}

Describe 'Step-ExplrUp / Step-ExplrInto' {
    BeforeAll {
        $script:Root = Join-Path ([System.IO.Path]::GetTempPath()) ("explr_path_" + [guid]::NewGuid())
        New-MockFs -Root $script:Root | Out-Null
    }
    AfterAll {
        if (Test-Path -LiteralPath $script:Root) {
            Remove-Item -LiteralPath $script:Root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'Step-ExplrUp lands in the parent with no fragment' {
        InModuleScope explr -Parameters @{ Root = $script:Root } {
            param($Root)
            $sub = Get-Item -LiteralPath (Join-Path $Root 'Documents')
            $state = New-ExplrState -CurrentDir $sub
            Update-ExplrChildCache -State $state
            Step-ExplrUp -State $state
            $state.CurrentDir.FullName.TrimEnd('\') | Should -Be $Root.TrimEnd('\')
            $state.Fragment | Should -Be ''
        }
    }

    It 'Step-ExplrUp at root is a no-op' {
        InModuleScope explr {
            $rootDir = Get-Item -LiteralPath ([System.IO.Path]::GetPathRoot([System.IO.Path]::GetTempPath()))
            $state = New-ExplrState -CurrentDir $rootDir
            Update-ExplrChildCache -State $state
            Step-ExplrUp -State $state
            $state.CurrentDir.FullName.TrimEnd('\') | Should -Be $rootDir.FullName.TrimEnd('\')
        }
    }

    It 'Step-ExplrInto drills into a subdirectory' {
        InModuleScope explr -Parameters @{ Root = $script:Root } {
            param($Root)
            $rootDir = Get-Item -LiteralPath $Root
            $state = New-ExplrState -CurrentDir $rootDir
            Update-ExplrChildCache -State $state
            $sub = Get-Item -LiteralPath (Join-Path $Root 'Documents')
            Step-ExplrInto -State $state -Item $sub
            $state.CurrentDir.FullName.TrimEnd('\') | Should -Be $sub.FullName.TrimEnd('\')
            $state.Fragment | Should -Be ''
        }
    }
}
