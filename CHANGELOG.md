# Changelog

Notable changes to BetterMaccy (a fork of [Maccy](https://github.com/p0deje/Maccy)).
Some fixes here patch pre-existing upstream behavior. The fork has diverged far
enough that staying rebasable on upstream is no longer a goal, so these are
written as the right fix for this codebase rather than as minimal patches.

## [2.8.4] — 2026-08-11

### Fixed

- **Severe lag when moving between large text items with the preview pane
  open.** The 2.8.0 fix removed this cost only while the preview was *closed*;
  with it open, hovering, arrow-keying or clicking past a large entry still
  stalled the popup for roughly a fifth of a second per step. The preview
  rendered its text as a SwiftUI `ScrollView { Text(…) }`, and a `ScrollView`
  proposes an unbounded height to its content — so the text had to be
  line-broken in full just to report how tall it was, a measurement that scales
  quadratically with length. At the 10,000-character preview cap that was
  ~193 ms, paid on every single selection change. The text pane is now backed by
  an `NSTextView`, which takes the size it is offered instead of measuring the
  whole string and lays out only the lines actually on screen: ~1.3 ms at the
  same 10,000 characters, and flat beyond ~2,000. Selecting and copying preview
  text works as before (`PreviewTextView.swift`, `PreviewItemView.swift`).

## [2.8.3] — 2026-06-24

### Added

- **New setting to turn off Option+V "tap again to move down the list."**
  By default, holding the popup shortcut's modifier and tapping its key again
  walks down the history list (and releasing the modifier pastes the
  highlighted item). The new **"Cycle through items with repeated shortcut
  presses"** toggle in Settings → General → Behavior lets you switch that off,
  so the shortcut simply opens and closes the popup instead — navigate with the
  arrow keys or mouse and confirm with Return. On by default, so existing
  behavior is unchanged (`Popup.swift`, `GeneralSettingsPane.swift`).

### Fixed

- **The preview pane now updates its image when you move between two image
  items in a row.** Selecting one image and then the adjacent image left the
  preview showing the first picture even though the metadata (app, copy times)
  switched to the second — the image load only ran once for the preview pane's
  lifetime and never re-ran when the selection changed. The preview now reloads
  its image whenever the selected item changes (`AsyncView.swift`,
  `PreviewItemView.swift`).

- **Arrow-key navigation no longer snags on the hidden "Clear all" footer
  item.** The footer's "Clear" and "Clear all" actions share a single slot;
  "Clear all" is drawn invisibly (opacity 0) and only appears while you hold the
  modifier that reveals it (Shift). On a fresh launch its `isVisible` flag was
  left `true` even though it was off-screen, so pressing Down on "Clear" moved
  the highlight onto the invisible "Clear all" — the selection appeared to
  vanish — and a second Down was needed to reach "Preferences"; the glitch
  recurred each time the cursor cycled back to "Clear". Pressing any modifier
  key (e.g. Control) silently reconciled it for the rest of the session, which
  is why it looked intermittent and only happened right after launching the app.
  "Clear all" now starts hidden, matching what's on screen, so arrow keys skip
  it until a modifier reveals it (`Footer.swift`).

## [2.8.2] — 2026-06-22

### Fixed

- **Likely fixed a whole-app freeze when the list scrolls during an Option+V
  cycle.** Holding Option and tapping V to move down a history list long enough
  to scroll — with the cursor resting over the list — could peg the CPU and
  lock up the entire popup, forcing a quit from Activity Monitor. The probable
  cause was hover selection mutating state inside SwiftUI's layout pass; it now
  updates outside that pass, so rows scrolling under a stationary cursor should
  no longer trigger a runaway layout loop. The freeze is intermittent and hard
  to reproduce, so this fix is unconfirmed (`HoverSelectionModifier.swift`).

- **Option+V cycling no longer falls into the footer.** Holding Option and
  tapping V to move down the history list used to descend past the last item
  into the footer and then loop there indefinitely (the cycle's wrap-to-top
  path was dead code), so releasing Option could fire a footer action —
  including destructive ones like Clear or Clear All. The held-hotkey cycle now
  wraps back to the top of the list and never enters the footer; arrow-key Down
  still reaches the footer as before (`NavigationManager.swift`).

## [2.8.1] — 2026-06-21

### Changed

- **Rebranded from MaccyCustom to BetterMaccy.** New app/product name, bundle
  id (`com.astrovini.bettermaccy`), repo (`astrovini/BetterMaccy`), and Homebrew
  cask (`bettermaccy`). The project was renamed internally as well (Xcode
  project/target/scheme, Swift module, source and test folders). BetterMaccy now
  **installs and runs alongside official Maccy**: distinct bundle id, its own
  clipboard history (separate sandbox container), and its own "from me"
  pasteboard marker (was `org.p0deje.Maccy`) so the two don't cross-trigger each
  other's self-ignore logic. Distinct branding too — a green app icon and a
  downward-feather menu bar glyph (the Maccy glyph flipped vertically). The
  cask's `conflicts_with maccy` was dropped to allow side-by-side installs.

## [2.8.0] — 2026-06-21

### Added

- **"Select item with" setting** (Settings → General; default "Hover").
  Chooses how the mouse selects items in the history list. **Hover** (the
  previous, unchanged behavior): hovering highlights an item and a single click
  pastes it. **Click**: hovering does nothing, a single click highlights an
  item, and a double click pastes it — handy if hover-to-select feels too
  twitchy. Keyboard navigation and Shift+click multi-select are identical in
  both modes. In Click mode, hovering a footer item (Clear, Quit, …) still
  highlights it but no longer clears the click-selected history item, so both
  stay highlighted. The single click reads the live click count (rather than
  pairing count:1/count:2 tap gestures) so highlighting stays instant instead of
  waiting out the double-click interval, and changing the setting applies
  immediately without restarting (`SelectionMode.swift`, `HistoryItemView.swift`,
  `HoverSelectionModifier.swift`, `ListItemView.swift`, `FooterItemView.swift`,
  `NavigationManager.swift`, `GeneralSettingsPane.swift`).

### Fixed

- **Severe hover/scroll lag with large clipboard items.** Hovering over a very
  large item (e.g. a copied log file with thousands of lines) caused the entire
  popup to stall. Three compounding issues all fired on every hover event: (1)
  `PreviewItemView` was always in the view hierarchy and re-rendered
  `item.text` (up to 10k chars via CoreText) even when the preview pane was
  completely closed; (2) `String.shortened(to:)` called `.count` first, which
  walked the entire string O(n) before truncating — for a 1 MB item that was
  ~1.25 M character walks per hover; (3) `HistoryItemDecorator.text` was a
  computed property repeating that work on every render. Fixed by: not rendering
  the slideout content when closed (`SlideoutView.swift`), fixing the
  `shortened(to:)` algorithm to O(maxLength) via `index(_:offsetBy:limitedBy:)`
  (`String+Shortened.swift`), and caching `text` on `HistoryItemDecorator` at
  init time.

## [2.7.1] — 2026-06-19

### Added

- **Popup width setting** — Settings → Appearance now has a "Popup width" field
  (alongside the existing "Popup height"), so the popup width can be set without
  dragging. The configured size applies the next time the popup opens.
- **Select & copy text in the preview** — text in the preview pane is now
  selectable, so you can highlight and copy part of an item (⌘C) instead of
  only copying the whole entry. The copied snippet is added as a new clipboard
  entry (`PreviewItemView.swift`).
- **"Keep preview open on footer hover" setting** (Settings → Appearance; active
  when auto-open is off, default on). Keeps a manually-opened preview pinned so you can
  drag-select and copy text in it: hovering the footer no longer closes or
  blanks the preview, and the hovered footer item still highlights and stays
  clickable. Turn it off to restore the previous behavior where moving to the
  footer dismisses the preview (`FooterItemView.swift`,
  `HoverSelectionModifier.swift`, `AppearanceSettingsPane.swift`).

### Changed

- **Minimum popup size is now 250 × 210** (previously ~200 wide with no real
  height floor), enforced both for dragging and for the Appearance size fields.
  The default size remains 450 × 500.
- **Preview shortcut now defaults to ⌥Space** (was ⌃Space, which collides with
  the macOS "select previous input source" system shortcut on most Macs). Only
  affects fresh installs; existing users keep their stored shortcut
  (`KeyboardShortcuts.Name+Shortcuts.swift`).
### Fixed

- **Clicking the preview text jumped the selection to the first entry.** The
  first click in the now-selectable preview pane pulled focus from the search
  field, which made SwiftUI write the search `Binding` back with its unchanged
  value. `searchQuery`'s `didSet` re-ran the filter on that no-op assignment,
  and an empty query re-selects the top item — so the selection (and preview)
  snapped to the first entry, but only on the first click after opening. Fixed
  by skipping the re-filter when the query hasn't actually changed
  (`History.swift`).
- **Couldn't shrink the popup again after widening it (pre-existing).** The list
  content is pinned to an exact width, which `NSHostingView` propagated as the
  window's minimum size — so every time the popup was widened the floor ratcheted
  up and it could never be made narrower again. Fixed by decoupling the window's
  minimum size from the SwiftUI content (`sizingOptions = []`) plus an explicit
  `contentMinSize`; the configured width now applies on open instead of being
  capped to the previous frame width (`FloatingPanel.swift`).
- **Right side of the popup ignored the mouse / appeared to freeze (with the
  preview closed).** The closed preview/slideout pane still laid out at its
  200pt minimum width and, on macOS 26, the clipped overflow kept receiving
  hit-testing — an invisible "ghost" pane sat over the right ~200pt of the list
  and swallowed mouse hover. Fixed by disabling hit-testing on the slideout
  while it's closed (`SlideoutView.swift`).
- **In-popup keyboard shortcuts were swallowed system-wide once recorded.** The
  KeyboardShortcuts library registers every shortcut as a global hotkey whenever
  its value is set (first-launch defaults and each time it's recorded in
  Settings). In-popup shortcuts (handled via `KeyChord`) have no global handler,
  so once claimed they were eaten everywhere and never reached the popup — which
  is why the Preview shortcut did nothing, and why Favorite / Favorites view
  would break the moment they were re-recorded. The app only un-claimed a
  hand-maintained `[.delete, .pin]` list. Inverted the model: only `.popup` is
  global; every other shortcut is auto-unregistered at launch and re-unregistered
  whenever it changes (`AppDelegate.swift`,
  `KeyboardShortcuts.Name+Shortcuts.swift`).

## [2.7.0] — 2026-06-18

### Added

- **Favorites view** — a separate list of items you mark as favorites, distinct
  from pins.
  - Toolbar star toggles between Recents and Favorites; the popup always reopens
    on Recents, and search filters within the current view.
  - Mark/unmark the selected item(s) with the per-row star or the keyboard.
  - Favorites are kept regardless of the history size limit and survive **Clear**
    (Clear All still removes them).
  - Shortcuts, rebindable in Settings → General: **⌥F** toggles the view,
    **⌥⇧F** marks/unmarks the selection.
