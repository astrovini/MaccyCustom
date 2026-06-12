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

- Local dev build: `xcodebuild -project Maccy.xcodeproj -scheme Maccy -configuration Release CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=YES build`
- Distribution (signed + notarized + zipped): `./scripts/release.sh`, then
  follow [RELEASING.md](RELEASING.md) (GitHub release + bump the cask in
  ~/Documents/Projects/homebrew-tap). Users install via
  `brew install --cask astrovini/tap/maccycustom`.

## Gotchas

- Do NOT reintroduce `SUFeedURL` in Maccy/Info.plist (e.g. during an
  upstream rebase): the upstream appcast would auto-update users back to
  official Maccy, silently removing the fork's features.
- Ad-hoc dev builds invalidate the macOS Accessibility grant on every
  rebuild (signature changes); paste then fails silently. Fix: remove and
  re-add Maccy in System Settings → Privacy & Security → Accessibility.
- The fork's core feature lives in `AppState.select()`
  (Maccy/Observables/AppState.swift) and `Maccy/Views/HistoryItemView.swift`
  (Shift+click). Upstream ships the same multi-select machinery behind a
  disabled `multiSelectionEnabled` flag — rebases may conflict there.
