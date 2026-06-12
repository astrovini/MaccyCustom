# Releasing MaccyCustom

How to ship a new version to the Homebrew tap. End users install with:

```sh
brew install --cask astrovini/tap/maccycustom
```

## One-time prerequisites (already set up)

- **Developer ID Application certificate** in the login keychain
  (`Developer ID Application: José Miranda (L228C8LS8X)`). Created via
  Xcode → Settings → Accounts → Manage Certificates.
- **Notarization credentials** stored as keychain profile `maccy-notary`,
  backed by an App Store Connect API key (key ID `BH7PL4HXDX`, the
  `AuthKey_*.p8` file — keep it somewhere safe; it can't be re-downloaded).
  Recreate with:
  `xcrun notarytool store-credentials maccy-notary --key <path>.p8 --key-id <id> --issuer <issuer-uuid>`
- **`gh` CLI** authenticated as `astrovini`.
- The Homebrew tap repo: <https://github.com/astrovini/homebrew-tap>,
  local clone at `~/Documents/Projects/homebrew-tap`.

## Release steps

1. Bump `MARKETING_VERSION` in `Maccy.xcodeproj` (both Release and Debug
   entries in project.pbxproj, e.g. `2.6.1` → `2.6.2`). Commit and push.

2. Build, sign, notarize, staple, and package:

   ```sh
   ./scripts/release.sh
   ```

   Produces `dist/Maccy-<version>.zip` and prints its sha256.
   Notarization is automated (no human review) but can take 5–60 minutes.

3. Create the GitHub release:

   ```sh
   gh release create v<version> dist/Maccy-<version>.zip \
     --title "MaccyCustom <version>" --notes "<what changed>"
   ```

4. Update the cask in `~/Documents/Projects/homebrew-tap/Casks/maccycustom.rb`:
   set `version` and `sha256` to the new values, then commit and push.

5. Verify like a user would:

   ```sh
   brew upgrade maccycustom   # or: brew install --cask astrovini/tap/maccycustom
   spctl --assess --type exec -v /Applications/Maccy.app   # expect: Notarized Developer ID
   ```

## Pulling in upstream Maccy updates

`origin` points at upstream (p0deje/Maccy); `fork` is astrovini/MaccyCustom.
`master` tracks the fork and carries our commits on top of upstream:

```sh
git fetch origin
git rebase origin/master
git push --force-with-lease
```

Then release as above. Watch for upstream changes to `Maccy/Info.plist`
(we removed `SUFeedURL` — Sparkle updates must stay disabled, otherwise the
official appcast would replace this fork on users' machines) and to
`AppState.select()` / `HistoryItemView` (our multi-select paste changes).

## Fork changes vs upstream

- Multi-select paste: `multiSelectionEnabled = true`; Enter pastes the
  selection as one newline-joined block; Shift+click adds to selection
  (upstream gates this behind a disabled flag and uses Cmd+click with a
  sequential "paste stack" instead).
- Default popup shortcut Option+V; "paste automatically" on by default.
- Bundle ID `com.astrovini.maccy` (app name remains Maccy; clipboard
  history in `~/Library/Application Support/Maccy` is keyed by name and
  is shared/kept across upstream-vs-fork switches).
- Sparkle update feed removed; updates ship via `brew upgrade`.

## Troubleshooting

- **Notarization `Invalid`**: `xcrun notarytool log <submission-id>
  --keychain-profile maccy-notary` lists per-file errors. The script
  already handles the two we hit: Sparkle's nested binaries needing
  re-signing, and the `get-task-allow` entitlement from non-archive builds.
- **Paste not working after install**: grant Accessibility. For local
  ad-hoc dev builds (not brew installs), every rebuild changes the
  signature and silently invalidates the existing grant — remove and
  re-add Maccy in System Settings → Privacy & Security → Accessibility.
  Notarized brew builds keep a stable signature, so this only affects
  dev builds.
