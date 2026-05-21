# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-05-21

### Added
- `Invoke-Explr` (alias `explr`): interactive `cd` + `ls` replacement with a live filtered dropdown of the current directory's contents.
- Hand-rolled ANSI takeover loop with PSReadLine ListView-style highlight band and fixed 10-row visible window.
- Substring + prefix-priority filtering (rank 0 startsWith, rank 1 word-start after `[._-\s]`, rank 2 contains).
- Tab / RightArrow drills into directories; LeftArrow with empty fragment steps up to the parent.
- Symlink follow with loop guard via `VisitedSymlinks` HashSet.
- Hidden items rendered dimmed (`\e[2m`); selected row in reverse video (`\e[7m`).
- Hard dependency on `Terminal-Icons` for icon glyph and colour resolution; ASCII fallback if the module is missing.
- `Enable-ExplrAliases` / `Disable-ExplrAliases`: opt-in `cd`/`ls` shadowing with snapshot/restore.
- Refuses to run inside Windows PowerShell ISE, with redirected input, or in terminals without virtual-terminal support.
- Pester v5 test suite covering filter, path, state, render, and loop subsystems.
