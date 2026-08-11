# BetterMaccy

Personal fork of [Maccy](https://github.com/p0deje/Maccy) (macOS clipboard
manager, Swift/SwiftUI) with multi-select paste. Both the app/product name
and the repo are "BetterMaccy". It installs and runs side-by-side with
official Maccy thanks to a distinct bundle ID and storage path.

## Remotes and branches

- `origin` = upstream p0deje/Maccy (pull only — no write access)
- `fork` = astrovini/BetterMaccy (ours; `master` tracks `fork/master`)
- `master` = upstream master + a small stack of fork commits (multi-select
  paste, Option+V default shortcut, paste-automatically default, bundle ID
  `com.astrovini.bettermaccy`, Sparkle feed removed, release tooling)

Upstream sync: `git fetch origin && git rebase origin/master && git push --force-with-lease`.

**Divergence from upstream is accepted and no longer a constraint.** The fork
has drifted far enough (full rebrand, reworked preview/navigation/selection)
that staying rebasable on p0deje/Maccy is not a goal. Do not shape changes to
minimize rebase conflicts, and do not preserve upstream implementations just
because they're upstream's — fix things the right way for this codebase. The
only upstream-related things still worth guarding are the coexistence values
listed under Gotchas (bundle ID, storage path, pasteboard marker, feed URL),
because reverting those breaks the side-by-side install.

## Building and releasing

- Local dev build + run: `./scripts/dev.sh` (builds, signs with the
  Developer ID identity, launches from DerivedData). Do NOT launch the
  raw xcodebuild output: the embedded Sparkle framework's Team ID
  mismatch kills it at startup (dyld error), and ad-hoc re-signing makes
  paste fail (see Gotchas). Quit and `open /Applications/BetterMaccy.app` to
  return to the brew-installed copy.
- Distribution (signed + notarized + zipped): `./scripts/release.sh`, then
  follow [RELEASING.md](RELEASING.md) (GitHub release + bump the cask in
  ~/Documents/Projects/homebrew-tap). Users install via
  `brew install --cask astrovini/tap/bettermaccy`.

## Testing

macOS has no simulator — the Mac is the runtime. For logic changes prefer
fast, headless unit tests over `scripts/dev.sh` (no signing dance, no
Accessibility grant, no launching the brew copy):

- Run one test: `xcodebuild test -scheme BetterMaccy -destination 'platform=macOS' -only-testing:BetterMaccyTests/<Class>/<method>` (drop `-only-testing` for the whole suite). Takes ~30-60s incl. build; the test itself is milliseconds.
- The BetterMaccyTests/UITests targets are HOSTED in BetterMaccy.app, so a run
  launches the app briefly. With the project's `DEVELOPMENT_TEAM` (L228C8LS8X)
  + the Apple Development cert it launches with no Gatekeeper prompt.
- The test plan passes the `enable-testing` launch arg, so Storage.swift uses
  an in-memory store — tests do NOT touch the real history DB.
- Do NOT pass `CODE_SIGN_IDENTITY="-"` or `CODE_SIGNING_ALLOWED=NO`: the hosted
  test bundle then fails to inject and the run silently executes 0 tests (a
  false green), or Gatekeeper blocks the ad-hoc host.
- `BetterMaccy.xctestplan` skips most of `HistoryTests` (inherited from
  upstream). New HistoryTests methods still run because only the class-level
  skip was removed; the originally-listed methods stay individually skipped.
- `ClipboardTests` fails on clean `master` (~6-10 failures, varying). Those
  tests poll the REAL system pasteboard, so a running clipboard manager or any
  copy activity on the machine breaks them. Verified against a clean checkout on
  2026-08-11 — do not go hunting for a regression, and do not stash the working
  tree to re-confirm it.

### Running tests and the app: ask first

Both `xcodebuild test` and `scripts/dev.sh` put a visible, long-lived
BetterMaccy on the user's screen. Neither is a background chore — get explicit
sign-off before running either, and say plainly when something is backgrounded.

- **Always scope test runs with `-only-testing`.** A bare `xcodebuild test`
  also runs `BetterMaccyUITests`, which is a multi-minute UI-driving phase that
  launches its own `BetterMaccy.app` copies from DerivedData. Killing the runner
  mid-phase orphans those instances (they reparent to launchd, PPID 1) and they
  keep running until killed by hand. This happened on 2026-08-11 and left three
  strays alongside the user's installed copy.
- **Never background the full suite.** If a run is needed, run it in the
  foreground so its lifetime is visible and it can't outlive the turn.
- **Check for strays afterwards** with
  `ps ax | grep MacOS/BetterMaccy`. Anything under `DerivedData/` with the
  `enable-testing` argument is a test host, not the user's app; the user's copy
  runs from `/Applications/BetterMaccy.app`.
- **Never `git stash` the user's working tree** — not to get a clean baseline,
  not for anything. Compare against `git show HEAD:<file>`, a scratchpad
  worktree, or just ask.

## Gotchas

- `SUFeedURL` in BetterMaccy/Info.plist and `appcast.xml` at the repo root must
  always point at the FORK (astrovini/BetterMaccy), never upstream. If an
  upstream rebase restores p0deje values, Sparkle would auto-update users
  back to official Maccy, silently removing the fork's features.
  release.sh regenerates appcast.xml each release; push it after the
  GitHub release exists.
- The whole project is renamed to BetterMaccy (Xcode project/target/scheme,
  source folder, Swift module, test targets) — a full divergence from
  upstream, so `git rebase origin/master` will conflict heavily on
  project.pbxproj and moved files. That cost was accepted for a clean rebrand.
- Coexistence with official Maccy relies on these staying distinct from the
  upstream values an unlucky rebase could restore: bundle ID
  `com.astrovini.bettermaccy`, the clipboard-history path
  `~/Library/Application Support/BetterMaccy` (hardcoded in Storage.swift),
  and the pasteboard "from me" marker `com.astrovini.bettermaccy`
  (BetterMaccy/Extensions/NSPasteboard.PasteboardType+Types.swift, was
  `org.p0deje.Maccy`). Revert any of these and the two apps step on each other.
- macOS binds the Accessibility (paste) grant to bundle ID + code
  signature. The grant on this machine belongs to the Developer ID
  identity (team L228C8LS8X). Dev builds signed with the same identity
  (what scripts/dev.sh does) inherit it; ad-hoc builds do not — paste
  fails silently, and granting the ad-hoc build re-binds the entry and
  breaks the brew build instead. If TCC gets wedged:
  `tccutil reset Accessibility com.astrovini.bettermaccy`, relaunch, re-grant.
- The fork's core feature lives in `AppState.select()`
  (BetterMaccy/Observables/AppState.swift) and `BetterMaccy/Views/HistoryItemView.swift`
  (Shift+click). Upstream ships the same multi-select machinery behind a
  disabled `multiSelectionEnabled` flag — rebases may conflict there.
