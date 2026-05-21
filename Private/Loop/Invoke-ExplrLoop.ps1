function Invoke-ExplrLoop {
    <#
    .SYNOPSIS
        Read-key/update/render switch loop.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$State
    )

    while ($true) {
        # 1. Resize check.
        $size = Get-ExplrConsoleSize
        if ($size.Width -ne $State.ConsoleWidth -or $size.Height -ne $State.ConsoleHeight) {
            $State.ConsoleWidth = $size.Width
            $State.ConsoleHeight = $size.Height
            $State.VisibleRows = [Math]::Min(10, [Math]::Max(1, $size.Height - 2))
            $State.NeedsResize = $true
            $State.Dirty = $true
        }

        # 2. Render if dirty.
        if ($State.Dirty) {
            if ($State.NeedsResize) {
                # Will be handled by Write-ExplrDropdown's anchor logic.
                $State.NeedsResize = $false
            }

            # Re-filter. CurrentDir is passed so an empty fragment yields a synthetic self-row at
            # the top, letting the user commit the current directory with Enter.
            $State.Matches = @(Select-ExplrMatches -Children $State.Children -Fragment $State.Fragment -CurrentDir $State.CurrentDir)

            # Clamp SelectedIndex.
            $matchCount = $State.Matches.Count
            if ($matchCount -eq 0) {
                $State.SelectedIndex = 0
                $State.ScrollOffset = 0
            }
            else {
                if ($State.SelectedIndex -lt 0) { $State.SelectedIndex = 0 }
                if ($State.SelectedIndex -ge $matchCount) { $State.SelectedIndex = $matchCount - 1 }

                # Adjust ScrollOffset so selection visible.
                $vr = $State.VisibleRows
                if ($State.SelectedIndex -lt $State.ScrollOffset) {
                    $State.ScrollOffset = $State.SelectedIndex
                }
                elseif ($State.SelectedIndex -ge $State.ScrollOffset + $vr) {
                    $State.ScrollOffset = $State.SelectedIndex - $vr + 1
                }
                if ($State.ScrollOffset -lt 0) { $State.ScrollOffset = 0 }
                if ($State.ScrollOffset -gt [Math]::Max(0, $matchCount - $vr)) {
                    $State.ScrollOffset = [Math]::Max(0, $matchCount - $vr)
                }
            }

            Write-ExplrDropdown -State $State
            $State.Dirty = $false
        }

        # 3. Read key.
        $key = Read-ExplrKey

        # 4. Dispatch.
        Invoke-ExplrKeyDispatch -State $State -Key $key

        # 5. Exit if commit/cancel.
        if ($State.ExitAction -ne 'None') {
            break
        }
    }
}

function Invoke-ExplrKeyDispatch {
    <#
    .SYNOPSIS
        Mutates State based on a single ConsoleKeyInfo.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$State,

        [Parameter(Mandatory)]
        [System.ConsoleKeyInfo]$Key
    )

    $ctrl = ($Key.Modifiers -band [System.ConsoleModifiers]::Control) -ne 0
    $matchCount = @($State.Matches).Count

    # Ctrl+C special-case (TreatControlCAsInput delivers it as 'C' with Control modifier
    # or as Key=Pause/etc on some hosts; check character).
    if ($ctrl -and ($Key.Key -eq [System.ConsoleKey]::C)) {
        $State.ExitAction = 'Cancel'
        $State.Dirty = $true
        return
    }

    switch ($Key.Key) {
        ([System.ConsoleKey]::Escape) {
            $State.ExitAction = 'Cancel'
            $State.Dirty = $true
            return
        }
        ([System.ConsoleKey]::UpArrow) {
            if ($matchCount -gt 0 -and $State.SelectedIndex -gt 0) { $State.SelectedIndex-- }
            $State.Dirty = $true
            return
        }
        ([System.ConsoleKey]::DownArrow) {
            if ($matchCount -gt 0 -and $State.SelectedIndex -lt $matchCount - 1) { $State.SelectedIndex++ }
            $State.Dirty = $true
            return
        }
        ([System.ConsoleKey]::PageUp) {
            $State.SelectedIndex -= $State.VisibleRows
            if ($State.SelectedIndex -lt 0) { $State.SelectedIndex = 0 }
            $State.Dirty = $true
            return
        }
        ([System.ConsoleKey]::PageDown) {
            $State.SelectedIndex += $State.VisibleRows
            if ($matchCount -gt 0 -and $State.SelectedIndex -ge $matchCount) {
                $State.SelectedIndex = $matchCount - 1
            }
            $State.Dirty = $true
            return
        }
        ([System.ConsoleKey]::Home) {
            $State.SelectedIndex = 0
            $State.Dirty = $true
            return
        }
        ([System.ConsoleKey]::End) {
            if ($matchCount -gt 0) { $State.SelectedIndex = $matchCount - 1 }
            $State.Dirty = $true
            return
        }
        ([System.ConsoleKey]::Tab) {
            if ($matchCount -gt 0) {
                $sel = $State.Matches[$State.SelectedIndex]
                # Self-row: Tab cannot drill in (it's already the current dir); ignore.
                if ($sel.PSObject.Properties['IsSelfRow'] -and $sel.IsSelfRow) {
                    return
                }
                if ($sel.PSIsContainer) {
                    Step-ExplrInto -State $State -Item $sel
                }
                else {
                    $State.ExitAction = if ($State.ListOnly) { 'CommitList' } else { 'CommitFile' }
                    $State.ExitTarget = $sel
                }
            }
            $State.Dirty = $true
            return
        }
        ([System.ConsoleKey]::RightArrow) {
            # RightArrow only drills into directories. On a file selection it is a no-op so the
            # user can keep navigating; only Tab/Enter commit on a file.
            if ($matchCount -gt 0) {
                $sel = $State.Matches[$State.SelectedIndex]
                # Self-row: nothing to drill into; ignore.
                if ($sel.PSObject.Properties['IsSelfRow'] -and $sel.IsSelfRow) {
                    return
                }
                if ($sel.PSIsContainer) {
                    Step-ExplrInto -State $State -Item $sel
                    $State.Dirty = $true
                }
            }
            return
        }
        ([System.ConsoleKey]::LeftArrow) {
            # Segment-aware jump: with a partial fragment typed, first Left clears the fragment
            # back to the current directory; subsequent Lefts walk up the path one directory at a
            # time. Backspace remains the per-character delete.
            if ([string]::IsNullOrEmpty($State.Fragment)) {
                Step-ExplrUp -State $State
            }
            else {
                $State.Fragment = ''
                $State.SelectedIndex = 0
                $State.ScrollOffset  = 0
            }
            $State.Dirty = $true
            return
        }
        ([System.ConsoleKey]::Enter) {
            if ($matchCount -gt 0) {
                $sel = $State.Matches[$State.SelectedIndex]
                # Self-row commits the current directory. Unwrap to the underlying DirectoryInfo so
                # downstream consumers (Set-Location, Format-TerminalIcons) get a real FileSystemInfo.
                if ($sel.PSObject.Properties['IsSelfRow'] -and $sel.IsSelfRow) {
                    $sel = $sel.Item
                }
                if ($State.ListOnly) {
                    if ($sel.PSIsContainer) {
                        $State.ExitAction = 'CommitList'
                        $State.ExitTarget = $sel
                    }
                    else {
                        $State.ExitAction = 'CommitFile'
                        $State.ExitTarget = $sel
                    }
                }
                elseif ($sel.PSIsContainer) {
                    $State.ExitAction = 'CommitDir'
                    $State.ExitTarget = $sel
                }
                else {
                    $State.ExitAction = 'CommitFile'
                    $State.ExitTarget = $sel
                }
            }
            else {
                # Commit current dir if no matches and ListOnly; otherwise stay.
                if ($State.ListOnly) {
                    $State.ExitAction = 'CommitList'
                    $State.ExitTarget = $State.CurrentDir
                }
            }
            $State.Dirty = $true
            return
        }
        ([System.ConsoleKey]::Backspace) {
            if ([string]::IsNullOrEmpty($State.Fragment)) {
                Step-ExplrUp -State $State
            }
            else {
                $State.Fragment = $State.Fragment.Substring(0, $State.Fragment.Length - 1)
                $State.SelectedIndex = 0
            }
            $State.Dirty = $true
            return
        }
        default {
            if ($ctrl) {
                switch ($Key.Key) {
                    ([System.ConsoleKey]::P) {
                        if ($matchCount -gt 0 -and $State.SelectedIndex -gt 0) { $State.SelectedIndex-- }
                        $State.Dirty = $true
                        return
                    }
                    ([System.ConsoleKey]::N) {
                        if ($matchCount -gt 0 -and $State.SelectedIndex -lt $matchCount - 1) { $State.SelectedIndex++ }
                        $State.Dirty = $true
                        return
                    }
                    ([System.ConsoleKey]::A) {
                        $State.SelectedIndex = 0
                        $State.Dirty = $true
                        return
                    }
                    ([System.ConsoleKey]::E) {
                        if ($matchCount -gt 0) { $State.SelectedIndex = $matchCount - 1 }
                        $State.Dirty = $true
                        return
                    }
                    ([System.ConsoleKey]::H) {
                        if ([string]::IsNullOrEmpty($State.Fragment)) {
                            Step-ExplrUp -State $State
                        }
                        else {
                            $State.Fragment = $State.Fragment.Substring(0, $State.Fragment.Length - 1)
                            $State.SelectedIndex = 0
                        }
                        $State.Dirty = $true
                        return
                    }
                    ([System.ConsoleKey]::L) {
                        # Force re-anchor + full redraw.
                        try {
                            $State.AnchorRow = [Console]::CursorTop
                            [Console]::Write("`e7")
                        }
                        catch { }
                        $State.NeedsResize = $true
                        $State.Dirty = $true
                        return
                    }
                    ([System.ConsoleKey]::U) {
                        $State.Fragment = ''
                        $State.SelectedIndex = 0
                        $State.Dirty = $true
                        return
                    }
                }
                # Unhandled Ctrl+chord — ignore.
                return
            }

            # Printable character.
            $ch = $Key.KeyChar
            if ($ch -and -not [char]::IsControl($ch)) {
                $State.Fragment += $ch
                $State.SelectedIndex = 0
                $State.Dirty = $true

                # Drive-change shortcut (per plan §"Edge Cases"): when the user types a bare
                # drive root like `D:`, switch CurrentDir to that drive and clear the fragment.
                if ($State.Fragment -match '^[A-Za-z]:$') {
                    $drive = "$($State.Fragment)\"
                    if (Test-Path -LiteralPath $drive -PathType Container) {
                        $State.CurrentDir = Get-Item -LiteralPath $drive -Force
                        $State.Fragment   = ''
                        $State.SelectedIndex = 0
                        $State.ScrollOffset  = 0
                        Update-ExplrChildCache -State $State
                    }
                }
            }
            return
        }
    }
}
