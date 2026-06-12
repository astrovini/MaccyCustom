# MaccyCustom

Personal fork of [Maccy](https://github.com/p0deje/Maccy) (macOS clipboard
manager, Swift/SwiftUI) with multi-select paste. The app/product name is
still "Maccy"; only the repo is called MaccyCustom.

## Remotes and branches

- `origin` = upstream p0deje/Maccy (pull only — no write access)
- `fork` = astrovini/MaccyCustom (ours; `master` tracks `fork/master`)
- `master` = upstream master + a small stack of fork commits (multi-select
  paste, Option+V default shortcut, paste-automatically default, bundle ID
  `com.astrovini.maccy`, Sparkle feed removed, release tooling)

Upstream sync: `git fetch origin && git rebase origin/master && git push --force-with-lease`.

## Building and releasing

- Local dev build + run: `./scripts/dev.sh` (builds, signs with the
  Developer ID identity, launches from DerivedData). Do NOT launch the
  raw xcodebuild output: the embedded Sparkle framework's Team ID
  mismatch kills it at startup (dyld error), and ad-hoc re-signing makes
  paste fail (see Gotchas). Quit and `open /Applications/Maccy.app` to
  return to the brew-installed copy.
- Distribution (signed + notarized + zipped): `./scripts/release.sh`, then
  follow [RELEASING.md](RELEASING.md) (GitHub release + bump the cask in
  ~/Documents/Projects/homebrew-tap). Users install via
  `brew install --cask astrovini/tap/maccycustom`.

## Gotchas

- Do NOT reintroduce `SUFeedURL` in Maccy/Info.plist (e.g. during an
  upstream rebase): the upstream appcast would auto-update users back to
  official Maccy, silently removing the fork's features.
- macOS binds the Accessibility (paste) grant to bundle ID + code
  signature. The grant on this machine belongs to the Developer ID
  identity (team L228C8LS8X). Dev builds signed with the same identity
  (what scripts/dev.sh does) inherit it; ad-hoc builds do not — paste
  fails silently, and granting the ad-hoc build re-binds the entry and
  breaks the brew build instead. If TCC gets wedged:
  `tccutil reset Accessibility com.astrovini.maccy`, relaunch, re-grant.
- The fork's core feature lives in `AppState.select()`
  (Maccy/Observables/AppState.swift) and `Maccy/Views/HistoryItemView.swift`
  (Shift+click). Upstream ships the same multi-select machinery behind a
  disabled `multiSelectionEnabled` flag — rebases may conflict there.
