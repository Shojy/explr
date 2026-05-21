BeforeAll {
    $script:ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module (Join-Path $script:ModuleRoot 'explr.psd1') -Force
}

Describe 'Enable-ExplrAliases / Disable-ExplrAliases' {
    AfterEach {
        # Best-effort cleanup so a failing test does not bleed state into the next.
        try { Disable-ExplrAliases -ErrorAction SilentlyContinue } catch { }
    }

    It 'creates a global cd wrapper that opens explr only when called bare' {
        Enable-ExplrAliases
        $cmd = Get-Command -Name cd -CommandType Function -ErrorAction SilentlyContinue
        $cmd | Should -Not -BeNullOrEmpty
        # Bare call → Invoke-Explr; with args → Set-Location (so existing scripts keep working).
        $cmd.Definition | Should -Match 'Invoke-Explr'
        $cmd.Definition | Should -Match 'Set-Location'
    }

    It 'does not touch ls' {
        # ls override was deliberately removed: explr's own -ListOnly view replaces the need for it.
        $before = Get-Command -Name ls -CommandType Function -ErrorAction SilentlyContinue
        Enable-ExplrAliases
        $after = Get-Command -Name ls -CommandType Function -ErrorAction SilentlyContinue
        # Whatever ls was before Enable should still be exactly that after Enable.
        if ($null -eq $before) { $after | Should -BeNullOrEmpty }
        else { $after.Definition | Should -Be $before.Definition }
    }

    It 'removes the cd wrapper function on Disable' {
        Enable-ExplrAliases
        Disable-ExplrAliases
        # The wrapper should be gone; the original AllScope cd alias re-surfaces in command resolution.
        $cdFn = Get-Command -Name cd -CommandType Function -ErrorAction SilentlyContinue
        $cdFn | Should -BeNullOrEmpty
    }

    It 'warns when Disable is called twice' {
        Enable-ExplrAliases
        Disable-ExplrAliases
        $warnings = @()
        Disable-ExplrAliases -WarningVariable warnings -WarningAction SilentlyContinue
        $warnings.Count | Should -BeGreaterThan 0
    }

    It 'is idempotent: a second Enable silently does not clobber the snapshot' {
        Enable-ExplrAliases
        $warnings = @()
        Enable-ExplrAliases -WarningVariable warnings -WarningAction SilentlyContinue
        # Second Enable must be silent so users can safely re-run it from their profile.
        $warnings.Count | Should -Be 0
        Disable-ExplrAliases
        # If the snapshot had been clobbered, cd would now point at Invoke-Explr instead of Set-Location.
        $a = Get-Alias -Name cd -Scope Global -ErrorAction SilentlyContinue
        if ($a) { $a.Definition | Should -Be 'Set-Location' }
    }
}
