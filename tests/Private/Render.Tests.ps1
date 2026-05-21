BeforeAll {
    $script:ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module (Join-Path $script:ModuleRoot 'explr.psd1') -Force
    . (Join-Path $script:ModuleRoot 'tests\_helpers\New-MockFs.ps1')

    $script:FsRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("explr_render_" + [guid]::NewGuid())
    New-MockFs -Root $script:FsRoot -IncludeHidden | Out-Null
}

AfterAll {
    if ($script:FsRoot -and (Test-Path -LiteralPath $script:FsRoot)) {
        Remove-Item -LiteralPath $script:FsRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Format-ExplrRow' {
    It 'truncates a long name with an ellipsis' {
        InModuleScope explr -Parameters @{ Root = $script:FsRoot } {
            param($Root)
            $longName = ('a' * 200) + '.txt'
            $longPath = Join-Path $Root $longName
            New-Item -ItemType File -Path $longPath -Force | Out-Null
            try {
                $item = Get-Item -LiteralPath $longPath
                Mock Get-ExplrIcon { @{ Icon = 'X'; Color = $null; Target = $null } }
                $row = Format-ExplrRow -Item $item -Width 30 -Selected:$false
                $row | Should -Match ([char]0x2026)
            }
            finally {
                Remove-Item -LiteralPath $longPath -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'wraps a selected row in a background highlight that extends to the right edge' {
        InModuleScope explr -Parameters @{ Root = $script:FsRoot } {
            param($Root)
            $item = Get-Item -LiteralPath (Join-Path $Root 'Documents')
            Mock Get-ExplrIcon { @{ Icon = 'X'; Color = $null; Target = $null } }
            $row = Format-ExplrRow -Item $item -Width 60 -Selected:$true
            # Explicit bg + CSI EL so the highlight paints to the edge regardless of fg state.
            $row | Should -Match "`e\[48;5;238m"
            $row | Should -Match "`e\[K"
            $row | Should -Match "`e\[49m"
        }
    }

    It 'does not emit Terminal-Icons full-reset (\e[0m) inside a selected row' {
        # Regression: Resolve-Icon returns '\e[0m' as Color for unthemed items. Emitting that
        # between our `\e[48;5;238m` (bg on) and `\e[K` (paint-to-edge) wipes the bg, making the
        # highlight invisible on generic folders/files.
        InModuleScope explr -Parameters @{ Root = $script:FsRoot } {
            param($Root)
            $item = Get-Item -LiteralPath (Join-Path $Root 'Documents')
            Mock Get-ExplrIcon { @{ Icon = 'X'; Color = "`e[0m"; Target = $null } }
            $row = Format-ExplrRow -Item $item -Width 60 -Selected:$true
            $row | Should -Not -Match "`e\[0m"
        }
    }

    It 'dims hidden items' {
        InModuleScope explr -Parameters @{ Root = $script:FsRoot } {
            param($Root)
            $item = Get-Item -LiteralPath (Join-Path $Root '.hidden') -Force
            Mock Get-ExplrIcon { @{ Icon = 'X'; Color = $null; Target = $null } }
            $row = Format-ExplrRow -Item $item -Width 60 -Selected:$false
            $row | Should -Match "`e\[2m"
            $row | Should -Match "`e\[22m"
        }
    }
}
