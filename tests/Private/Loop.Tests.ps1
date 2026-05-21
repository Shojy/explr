BeforeAll {
    $script:ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module (Join-Path $script:ModuleRoot 'explr.psd1') -Force
    . (Join-Path $script:ModuleRoot 'tests\_helpers\New-MockKey.ps1')
    . (Join-Path $script:ModuleRoot 'tests\_helpers\New-MockFs.ps1')

    $script:FsRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("explr_loop_" + [guid]::NewGuid())
    New-MockFs -Root $script:FsRoot | Out-Null
}

AfterAll {
    if ($script:FsRoot -and (Test-Path -LiteralPath $script:FsRoot)) {
        Remove-Item -LiteralPath $script:FsRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Invoke-ExplrLoop scenarios' {
    BeforeEach {
        $script:KeyQueue = [System.Collections.Queue]::new()
    }

    It "typing 'do' filters to Documents and Down moves selection" {
        InModuleScope explr -Parameters @{ Root = $script:FsRoot; Queue = $script:KeyQueue } {
            param($Root, $Queue)

            . (Join-Path (Split-Path -Parent (Get-Module explr).Path) 'tests\_helpers\New-MockKey.ps1')

            $Queue.Enqueue((New-MockChar 'd'))
            $Queue.Enqueue((New-MockChar 'o'))
            $Queue.Enqueue((New-MockKey -Key ([System.ConsoleKey]::DownArrow)))
            $Queue.Enqueue((New-MockKey -Key ([System.ConsoleKey]::Escape)))

            Mock Read-ExplrKey { $Queue.Dequeue() }
            Mock Write-ExplrDropdown { }
            Mock Get-ExplrConsoleSize { @{ Width = 80; Height = 24 } }

            $rootDir = Get-Item -LiteralPath $Root
            $state = New-ExplrState -CurrentDir $rootDir
            Update-ExplrChildCache -State $state

            Invoke-ExplrLoop -State $state

            $state.Fragment | Should -Be 'do'
            $state.ExitAction | Should -Be 'Cancel'
        }
    }

    It 'Tab on a directory updates CurrentDir and clears Fragment' {
        InModuleScope explr -Parameters @{ Root = $script:FsRoot; Queue = $script:KeyQueue } {
            param($Root, $Queue)

            . (Join-Path (Split-Path -Parent (Get-Module explr).Path) 'tests\_helpers\New-MockKey.ps1')

            # Empty fragment puts a synthetic self-row at index 0; press Down once to land on
            # 'Documents' (the first real entry, since dirs sort first), then Tab to drill in.
            $Queue.Enqueue((New-MockKey -Key ([System.ConsoleKey]::DownArrow)))
            $Queue.Enqueue((New-MockKey -Key ([System.ConsoleKey]::Tab)))
            $Queue.Enqueue((New-MockKey -Key ([System.ConsoleKey]::Escape)))

            Mock Read-ExplrKey { $Queue.Dequeue() }
            Mock Write-ExplrDropdown { }
            Mock Get-ExplrConsoleSize { @{ Width = 80; Height = 24 } }

            $rootDir = Get-Item -LiteralPath $Root
            $state = New-ExplrState -CurrentDir $rootDir
            Update-ExplrChildCache -State $state

            Invoke-ExplrLoop -State $state

            $state.CurrentDir.Name | Should -Be 'Documents'
            $state.Fragment | Should -Be ''
            $state.ExitAction | Should -Be 'Cancel'
        }
    }

    It 'Backspace at empty fragment goes up' {
        InModuleScope explr -Parameters @{ Root = $script:FsRoot; Queue = $script:KeyQueue } {
            param($Root, $Queue)

            . (Join-Path (Split-Path -Parent (Get-Module explr).Path) 'tests\_helpers\New-MockKey.ps1')

            $Queue.Enqueue((New-MockKey -Key ([System.ConsoleKey]::Backspace)))
            $Queue.Enqueue((New-MockKey -Key ([System.ConsoleKey]::Escape)))

            Mock Read-ExplrKey { $Queue.Dequeue() }
            Mock Write-ExplrDropdown { }
            Mock Get-ExplrConsoleSize { @{ Width = 80; Height = 24 } }

            $sub = Get-Item -LiteralPath (Join-Path $Root 'Documents')
            $state = New-ExplrState -CurrentDir $sub
            Update-ExplrChildCache -State $state

            Invoke-ExplrLoop -State $state

            $state.CurrentDir.FullName.TrimEnd('\') | Should -Be $Root.TrimEnd('\')
            $state.Fragment | Should -Be ''
        }
    }

    It 'Enter on the synthetic self-row commits the current directory' {
        InModuleScope explr -Parameters @{ Root = $script:FsRoot; Queue = $script:KeyQueue } {
            param($Root, $Queue)

            . (Join-Path (Split-Path -Parent (Get-Module explr).Path) 'tests\_helpers\New-MockKey.ps1')

            # Empty fragment → self-row is at index 0. Enter should commit CurrentDir.
            $Queue.Enqueue((New-MockKey -Key ([System.ConsoleKey]::Enter)))

            Mock Read-ExplrKey { $Queue.Dequeue() }
            Mock Write-ExplrDropdown { }
            Mock Get-ExplrConsoleSize { @{ Width = 80; Height = 24 } }

            $rootDir = Get-Item -LiteralPath $Root
            $state = New-ExplrState -CurrentDir $rootDir
            Update-ExplrChildCache -State $state

            Invoke-ExplrLoop -State $state

            $state.ExitAction | Should -Be 'CommitDir'
            $state.ExitTarget.FullName.TrimEnd('\') | Should -Be $rootDir.FullName.TrimEnd('\')
        }
    }

    It 'Tab on the synthetic self-row is a no-op' {
        InModuleScope explr -Parameters @{ Root = $script:FsRoot; Queue = $script:KeyQueue } {
            param($Root, $Queue)

            . (Join-Path (Split-Path -Parent (Get-Module explr).Path) 'tests\_helpers\New-MockKey.ps1')

            # Tab on the self-row should not change CurrentDir; Esc to exit.
            $Queue.Enqueue((New-MockKey -Key ([System.ConsoleKey]::Tab)))
            $Queue.Enqueue((New-MockKey -Key ([System.ConsoleKey]::Escape)))

            Mock Read-ExplrKey { $Queue.Dequeue() }
            Mock Write-ExplrDropdown { }
            Mock Get-ExplrConsoleSize { @{ Width = 80; Height = 24 } }

            $rootDir = Get-Item -LiteralPath $Root
            $state = New-ExplrState -CurrentDir $rootDir
            Update-ExplrChildCache -State $state

            Invoke-ExplrLoop -State $state

            $state.CurrentDir.FullName.TrimEnd('\') | Should -Be $rootDir.FullName.TrimEnd('\')
            $state.ExitAction | Should -Be 'Cancel'
        }
    }

    It 'Esc sets ExitAction to Cancel' {
        InModuleScope explr -Parameters @{ Root = $script:FsRoot; Queue = $script:KeyQueue } {
            param($Root, $Queue)

            . (Join-Path (Split-Path -Parent (Get-Module explr).Path) 'tests\_helpers\New-MockKey.ps1')

            $Queue.Enqueue((New-MockKey -Key ([System.ConsoleKey]::Escape)))

            Mock Read-ExplrKey { $Queue.Dequeue() }
            Mock Write-ExplrDropdown { }
            Mock Get-ExplrConsoleSize { @{ Width = 80; Height = 24 } }

            $rootDir = Get-Item -LiteralPath $Root
            $state = New-ExplrState -CurrentDir $rootDir
            Update-ExplrChildCache -State $state

            Invoke-ExplrLoop -State $state
            $state.ExitAction | Should -Be 'Cancel'
        }
    }

    It 'typing a bare drive root switches CurrentDir to that drive' {
        InModuleScope explr -Parameters @{ Root = $script:FsRoot; Queue = $script:KeyQueue } {
            param($Root, $Queue)

            . (Join-Path (Split-Path -Parent (Get-Module explr).Path) 'tests\_helpers\New-MockKey.ps1')

            # Derive the actual drive letter from the temp path so the test is portable.
            $driveRoot = [System.IO.Path]::GetPathRoot([System.IO.Path]::GetTempPath())  # e.g. 'C:\'
            $letter = $driveRoot[0]

            $Queue.Enqueue((New-MockChar $letter))
            $Queue.Enqueue((New-MockChar ':'))
            $Queue.Enqueue((New-MockKey -Key ([System.ConsoleKey]::Escape)))

            Mock Read-ExplrKey { $Queue.Dequeue() }
            Mock Write-ExplrDropdown { }
            Mock Get-ExplrConsoleSize { @{ Width = 80; Height = 24 } }

            $rootDir = Get-Item -LiteralPath $Root
            $state = New-ExplrState -CurrentDir $rootDir
            Update-ExplrChildCache -State $state

            Invoke-ExplrLoop -State $state

            $state.CurrentDir.FullName.TrimEnd('\') | Should -Be $driveRoot.TrimEnd('\')
            $state.Fragment | Should -Be ''
        }
    }

    It 'Enter on a file sets CommitFile with ExitTarget' {
        InModuleScope explr -Parameters @{ Root = $script:FsRoot; Queue = $script:KeyQueue } {
            param($Root, $Queue)

            . (Join-Path (Split-Path -Parent (Get-Module explr).Path) 'tests\_helpers\New-MockKey.ps1')

            # Type 'readme' to filter to readme.txt; Enter to commit.
            foreach ($c in 'readme'.ToCharArray()) { $Queue.Enqueue((New-MockChar $c)) }
            $Queue.Enqueue((New-MockKey -Key ([System.ConsoleKey]::Enter)))

            Mock Read-ExplrKey { $Queue.Dequeue() }
            Mock Write-ExplrDropdown { }
            Mock Get-ExplrConsoleSize { @{ Width = 80; Height = 24 } }

            $rootDir = Get-Item -LiteralPath $Root
            $state = New-ExplrState -CurrentDir $rootDir
            Update-ExplrChildCache -State $state

            Invoke-ExplrLoop -State $state

            $state.ExitAction | Should -Be 'CommitFile'
            $state.ExitTarget | Should -Not -BeNullOrEmpty
            $state.ExitTarget.Name | Should -Be 'readme.txt'
        }
    }
}
