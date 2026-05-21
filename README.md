# explr

Interactive `cd` + `ls` replacement for PowerShell 7+ with a live, scrollable, icon-coloured dropdown that updates as you type. Visually similar to PSReadLine's ListView history prediction, with the same colour and glyph scheme as the [`Terminal-Icons`](https://github.com/devblackops/Terminal-Icons) module.

## Install

One-liner (PowerShell 7+):

```powershell
irm https://raw.githubusercontent.com/Shojy/explr/main/install.ps1 | iex
```

The script downloads explr to `~\Documents\PowerShell\Modules\explr\<version>\`, installs the `Terminal-Icons` dependency from the PSGallery if needed, and prints next steps. To install from a non-default branch (e.g. a beta), set `$env:EXPLR_CHANNEL` first:

```powershell
$env:EXPLR_CHANNEL = 'beta'; irm https://raw.githubusercontent.com/Shojy/explr/main/install.ps1 | iex
```

Update an existing install (pulls the latest contents from the same channel):

```powershell
irm https://raw.githubusercontent.com/Shojy/explr/main/update.ps1 | iex
```

If explr isn't installed, the update script prints the install command and offers to run it.

Uninstall:

```powershell
irm https://raw.githubusercontent.com/Shojy/explr/main/uninstall.ps1 | iex
```

For local iteration during development:

```powershell
Import-Module .\explr.psd1 -Force
explr
```

## Key Bindings

| Key | Action |
|---|---|
| Up / Ctrl+P | Move highlight up. |
| Down / Ctrl+N | Move highlight down. |
| PgUp / PgDn | Move highlight by a full visible page (10 rows). |
| Home / Ctrl+A | Jump to first match. |
| End / Ctrl+E | Jump to last match. |
| Tab | Drill into the highlighted directory; commit if it is a file. |
| RightArrow | Drill into the highlighted directory. No-op on files. |
| LeftArrow (empty fragment) | Step up to the parent directory's full listing. |
| LeftArrow (with typed fragment) | Clear the fragment back to the current directory's full listing. |
| Backspace / Ctrl+H | Delete last character; if empty, step up. |
| Enter | Commit: `Set-Location` for a directory, or `Set-Location` to a file's containing directory and return the FileInfo. |
| Esc / Ctrl+C | Cancel; `$PWD` unchanged. |
| Ctrl+L | Force re-anchor and full redraw. |
| Ctrl+U | Clear fragment. |
| Type a drive letter + `:` | Jump to that drive root (e.g. `D:`). |
| Top "current folder" row | Selecting it and pressing Enter commits the current directory. |

## Opt-in `cd` Wrapper

`explr` does not shadow the built-in `cd` by default. To enable:

```powershell
Enable-ExplrAliases
```

This installs a wrapper function:

- `cd` (no args) opens explr.
- `cd <path>` falls through to `Set-Location <path>` so scripts and muscle-memory paths still work normally.

`ls` is intentionally not overridden — explr's own dropdown gives you the same icon-coloured listing for navigation, and leaves the standard `ls` alias untouched for scripts and pipelines.

Restore the original `cd` with:

```powershell
Disable-ExplrAliases
```

To make the wrapper persistent, add this to your `$PROFILE`:

```powershell
Import-Module explr
Enable-ExplrAliases
```

Caveat: function scoping. `Enable-ExplrAliases` defaults to `-Scope Global` so the wrapper survives function boundaries. Pass `-Scope` to override.

## Hosts

`explr` requires an interactive PowerShell 7+ console with virtual-terminal support. It will refuse to run inside:

- Windows PowerShell ISE.
- A session with `IsInputRedirected = $true` (e.g. piped stdin, CI).
- A host where `$Host.UI.SupportsVirtualTerminal` is `$false`, or `$env:NO_COLOR` is set.

## Screenshots

_(placeholder — add captures of the dropdown in Windows Terminal once the module ships.)_

## License

MIT.
