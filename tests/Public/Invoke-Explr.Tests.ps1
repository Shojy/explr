BeforeAll {
    $script:ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module (Join-Path $script:ModuleRoot 'explr.psd1') -Force
    . (Join-Path $script:ModuleRoot 'tests\_helpers\New-MockKey.ps1')
    . (Join-Path $script:ModuleRoot 'tests\_helpers\New-MockFs.ps1')
}

Describe 'Invoke-Explr parameter binding' {
    It 'accepts -Path positionally' {
        (Get-Command Invoke-Explr).Parameters.ContainsKey('Path') | Should -BeTrue
    }

    It 'has -StartPath and -ListOnly' {
        $params = (Get-Command Invoke-Explr).Parameters
        $params.ContainsKey('StartPath') | Should -BeTrue
        $params.ContainsKey('ListOnly') | Should -BeTrue
    }
}

Describe 'Invoke-Explr host gating' {
    It 'throws a clean message when the host is unsupported' {
        InModuleScope explr {
            Mock Test-ExplrConsoleSupported { $false }
            { Invoke-Explr } | Should -Throw -ExpectedMessage '*virtual-terminal*'
        }
    }
}

Describe 'Invoke-Explr -StartPath honoured' {
    It 'starts the loop with CurrentDir = StartPath' {
        $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("explr_t_" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
        try {
            InModuleScope explr -Parameters @{ StartPath = $tempRoot } {
                param($StartPath)
                Mock Test-ExplrConsoleSupported { $true }
                Mock Set-ExplrConsoleMode { }
                Mock Restore-ExplrConsoleMode { }
                Mock Invoke-ExplrCommit { }
                $script:CapturedDir = $null
                Mock Invoke-ExplrLoop {
                    param($State)
                    $script:CapturedDir = $State.CurrentDir.FullName
                    $State.ExitAction = 'Cancel'
                }

                Invoke-Explr -StartPath $StartPath

                $script:CapturedDir.TrimEnd('\') | Should -Be $StartPath.TrimEnd('\')
            }
        }
        finally {
            Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Invoke-Explr commit dispatch' {
    It 'calls Set-Location on CommitDir' {
        $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("explr_c_" + [guid]::NewGuid())
        $sub = Join-Path $tempRoot 'sub'
        New-Item -ItemType Directory -Path $sub -Force | Out-Null
        try {
            InModuleScope explr -Parameters @{ Root = $tempRoot; Sub = $sub } {
                param($Root, $Sub)
                Mock Test-ExplrConsoleSupported { $true }
                Mock Set-ExplrConsoleMode { }
                Mock Restore-ExplrConsoleMode { }
                Mock Set-Location { } -Verifiable
                $script:SubItem = Get-Item -LiteralPath $Sub
                Mock Invoke-ExplrLoop {
                    param($State)
                    $State.ExitAction = 'CommitDir'
                    $State.ExitTarget = $script:SubItem
                }

                Invoke-Explr -StartPath $Root
                Should -Invoke Set-Location -Times 1
            }
        }
        finally {
            Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'returns FileInfo on CommitFile' {
        $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("explr_f_" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
        $f = Join-Path $tempRoot 'a.txt'
        New-Item -ItemType File -Path $f -Force | Out-Null
        try {
            $result = InModuleScope explr -Parameters @{ Root = $tempRoot; FilePath = $f } {
                param($Root, $FilePath)
                Mock Test-ExplrConsoleSupported { $true }
                Mock Set-ExplrConsoleMode { }
                Mock Restore-ExplrConsoleMode { }
                Mock Write-ExplrFileLine { }
                $script:FileItem = Get-Item -LiteralPath $FilePath
                Mock Invoke-ExplrLoop {
                    param($State)
                    $State.ExitAction = 'CommitFile'
                    $State.ExitTarget = $script:FileItem
                }

                Invoke-Explr -StartPath $Root
            }
            $result | Should -Not -BeNullOrEmpty
            $result.FullName | Should -Be (Get-Item -LiteralPath $f).FullName
        }
        finally {
            Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
