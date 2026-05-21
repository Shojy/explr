BeforeAll {
    $script:ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module (Join-Path $script:ModuleRoot 'explr.psd1') -Force
    . (Join-Path $script:ModuleRoot 'tests\_helpers\New-MockFs.ps1')

    $script:FsRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("explr_filter_" + [guid]::NewGuid())
    New-MockFs -Root $script:FsRoot -IncludeHidden | Out-Null
    $script:Children = @(Get-ChildItem -LiteralPath $script:FsRoot -Force)
}

AfterAll {
    if ($script:FsRoot -and (Test-Path -LiteralPath $script:FsRoot)) {
        Remove-Item -LiteralPath $script:FsRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Select-ExplrMatches' {
    It 'returns directories first when fragment is empty' {
        InModuleScope explr -Parameters @{ Children = $script:Children } {
            param($Children)
            $r = @(Select-ExplrMatches -Children $Children -Fragment '')
            $r.Count | Should -BeGreaterThan 0
            # first item must be a directory.
            $r[0].PSIsContainer | Should -BeTrue
        }
    }

    It 'ranks startsWith above contains' {
        InModuleScope explr -Parameters @{ Children = $script:Children } {
            param($Children)
            $r = @(Select-ExplrMatches -Children $Children -Fragment 'doc')
            $r.Count | Should -BeGreaterThan 0
            $r[0].Name | Should -Be 'Documents'
        }
    }

    It 'is case-insensitive' {
        InModuleScope explr -Parameters @{ Children = $script:Children } {
            param($Children)
            $a = @(Select-ExplrMatches -Children $Children -Fragment 'DOC')
            $b = @(Select-ExplrMatches -Children $Children -Fragment 'doc')
            $a.Count | Should -Be $b.Count
        }
    }

    It 'includes hidden items' {
        InModuleScope explr -Parameters @{ Children = $script:Children } {
            param($Children)
            $r = @(Select-ExplrMatches -Children $Children -Fragment '')
            ($r | Where-Object { $_.Name -eq '.hidden' }).Count | Should -Be 1
        }
    }

    It 'returns word-start matches above plain contains' {
        InModuleScope explr -Parameters @{ Children = $script:Children } {
            param($Children)
            # 'list' should match 'todo-list.txt' as word-start (after '-').
            $r = @(Select-ExplrMatches -Children $Children -Fragment 'list')
            ($r | Where-Object { $_.Name -eq 'todo-list.txt' }).Count | Should -Be 1
        }
    }
}
