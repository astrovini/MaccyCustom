# Developing BetterMaccy

How to build, run and test the app locally. For shipping a release, see
[RELEASING.md](../RELEASING.md).

Requires macOS Sonoma 14 or higher and Xcode.

## Repository layout

BetterMaccy is a fork of [Maccy](https://github.com/p0deje/Maccy) (macOS
clipboard manager, Swift/SwiftUI). Both the app/product name and the repo are
"BetterMaccy". It installs and runs side-by-side with official Maccy thanks to a
distinct bundle ID and storage path.

- `origin` = upstream p0deje/Maccy (pull only — no write access)
- `fork` = astrovini/BetterMaccy (ours; `master` tracks `fork/master`)
- `master` = upstream master plus this fork's commits

Upstream sync: `git fetch origin && git rebase origin/master && git push --force-with-lease`.

### Divergence from upstream is accepted

The fork has drifted far enough from upstream — full rebrand, reworked
preview/navigation/selection — that staying rebasable on p0deje/Maccy is not a
goal. Don't shape changes to minimize rebase conflicts, and don't preserve an
upstream implementation just because it's upstream's; fix things the right way
for this codebase.

The project is renamed throughout (Xcode project/target/scheme, source folder,
Swift module, test targets), so `git rebase origin/master` conflicts heavily on
`project.pbxproj` and moved files. That cost was accepted for a clean rebrand.

The only upstream-related values still worth guarding on a rebase are the ones
under [Coexistence with official Maccy](#coexistence-with-official-maccy).

## Building and running locally

```sh
./scripts/dev.sh
```

This builds, signs with the Developer ID identity, and launches from
DerivedData. It `pkill`s any running BetterMaccy first, so the installed copy
quits and the dev build takes over. The dev build uses the clipboard menu bar
icon (`DEV_BUILD`) so you can tell it apart from the release build.

Return to the brew-installed copy with:

```sh
pkill -x BetterMaccy && open /Applications/BetterMaccy.app
```

**Do not launch the raw `xcodebuild` output.** The embedded Sparkle framework
keeps its original Team ID, which library validation rejects — the app dies at
startup with a dyld error. Ad-hoc re-signing gets it launching but silently
breaks paste (see [Accessibility](#accessibility-and-the-paste-grant)).
`dev.sh` exists to handle both.

## Testing

macOS has no simulator — the Mac is the runtime. For logic changes prefer fast,
headless unit tests over `scripts/dev.sh`: no signing dance, no Accessibility
grant, and it doesn't take over your running copy.

Run a single test (~30–60s including build; the test itself is milliseconds):

```sh
xcodebuild test -scheme BetterMaccy -destination 'platform=macOS' \
  -only-testing:BetterMaccyTests/<Class>/<method>
```

Scope the run with `-only-testing` whenever you can. Dropping it also runs
`BetterMaccyUITests`, a multi-minute UI-driving phase that launches its own
`BetterMaccy.app` copies from DerivedData; interrupting it orphans those
instances to launchd, where they keep running until killed by hand. Check for
strays with `ps ax | grep MacOS/BetterMaccy` — anything under `DerivedData/`
with the `enable-testing` argument is a leftover test host.

Things that will bite you:

- **The test targets are hosted in BetterMaccy.app**, so a run launches the app
  briefly. With the project's `DEVELOPMENT_TEAM` (L228C8LS8X) and the Apple
  Development cert, it launches with no Gatekeeper prompt.
- **Tests don't touch the real history DB.** The test plan passes the
  `enable-testing` launch argument, so `Storage.swift` uses an in-memory store.
- **Never pass `CODE_SIGN_IDENTITY="-"` or `CODE_SIGNING_ALLOWED=NO`.** The
  hosted test bundle then fails to inject and the run silently executes 0 tests
  — a false green — or Gatekeeper blocks the ad-hoc host.
- **`ClipboardTests` fails on clean `master`** (~6–10 failures, varying). Those
  tests poll the *real* system pasteboard, so a running clipboard manager or any
  copy activity on the machine breaks them. Verified against a clean checkout on
  2026-08-11; it is not a regression.
- **`BetterMaccy.xctestplan` skips most of `HistoryTests`** (inherited from
  upstream). New `HistoryTests` methods still run, because only the class-level
  skip was removed; the originally-listed methods stay individually skipped.
  Note that `-only-testing` does **not** override a test-plan skip.

## Gotchas

### Coexistence with official Maccy

Running side-by-side with official Maccy depends on these staying distinct from
the upstream values a careless rebase could restore. Revert any of them and the
two apps step on each other:

| What | Value | Where |
| --- | --- | --- |
| Bundle ID | `com.astrovini.bettermaccy` | `BetterMaccy/Info.plist` |
| Clipboard history path | `~/Library/Application Support/BetterMaccy` | hardcoded in `Storage.swift` |
| Pasteboard "from me" marker | `com.astrovini.bettermaccy` (was `org.p0deje.Maccy`) | `BetterMaccy/Extensions/NSPasteboard.PasteboardType+Types.swift` |
| Sparkle feed | the fork's own appcast | `SUFeedURL` in `BetterMaccy/Info.plist`, plus `appcast.xml` at the repo root |

`SUFeedURL` and `appcast.xml` matter most: if a rebase restores upstream's
values, Sparkle auto-updates users back to official Maccy, silently removing
this fork's features. `release.sh` regenerates `appcast.xml` each release — push
it only after the GitHub release exists, or in-app updates 404.

### Accessibility and the paste grant

macOS binds the Accessibility (paste) grant to bundle ID **plus code
signature**. The grant on the maintainer's machine belongs to the Developer ID
identity (team L228C8LS8X). Dev builds signed with that same identity — which is
what `scripts/dev.sh` does — inherit it. Ad-hoc builds do not: paste fails
silently, and granting an ad-hoc build re-binds the entry and breaks the brew
build instead.

If TCC gets wedged:

```sh
tccutil reset Accessibility com.astrovini.bettermaccy
```

then relaunch and re-grant.

### Where the fork's core feature lives

Multi-select paste is implemented in `AppState.select()`
(`BetterMaccy/Observables/AppState.swift`) and `BetterMaccy/Views/HistoryItemView.swift`
(Shift+click). Upstream ships the same multi-select machinery behind a disabled
`multiSelectionEnabled` flag, so rebases may conflict there.
