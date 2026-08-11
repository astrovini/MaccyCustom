
<img width="128px" src="docs/logo.png" alt="BetterMaccy" />

# [BetterMaccy](https://github.com/astrovini/BetterMaccy)

[![Downloads](https://img.shields.io/github/downloads/astrovini/BetterMaccy/total.svg)](https://github.com/astrovini/BetterMaccy/releases/latest)

**BetterMaccy is my improved fork of [Maccy](https://github.com/p0deje/Maccy)** — the
lightweight macOS clipboard manager — with the features I kept wishing it had. It
installs and runs **alongside** official Maccy, so you can try it without giving up your
current setup. Requires macOS Sonoma 14 or higher.

### What BetterMaccy adds over Maccy

- **Multi-select paste** — pick several history items (**Shift+click**, or **Shift+↑/↓**
  from the keyboard) and press **Enter** to paste them all at once as one block, joined
  by newlines.
- **Favorites** — mark the items you want to keep with **⌥⇧F**, and press **⌥F** to
  switch the list between Recents and Favorites. Favorites ignore the history size limit
  and survive **Clear**.
- **A preview pane you can select text in** — press **⌥Space** to open it, then
  highlight and copy just the part of an item you need (**⌘C**) instead of taking the
  whole entry. It can stay pinned open while you move around the popup.
- **`Option+V` default shortcut** with **"paste automatically" on by default** — hit
  Enter and it pastes straight into the app you were just in.
- **"Select item with" mode** (Settings → General) — choose **Hover** (hover highlights,
  one click pastes) or **Click** (one click highlights, double click pastes) when
  hover-to-select feels too twitchy.
- **No lag on huge items** — copying a massive log no longer stalls the popup, with the
  preview pane open or closed.
- **Coexists with official Maccy** — its own bundle id and clipboard history, a green app
  icon, and a downward-feather menu bar glyph, so the two never collide.

Install (signed & notarized):

```sh
brew install --cask astrovini/tap/bettermaccy
```

Or download from [Releases](https://github.com/astrovini/BetterMaccy/releases/latest). Building it yourself: see [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md). Shipping a release: see [RELEASING.md](RELEASING.md).

---

The rest of this README is Maccy's original documentation, adapted for BetterMaccy.

<!-- vim-markdown-toc GFM -->

* [Features](#features)
* [Install](#install)
* [Usage](#usage)
* [Advanced](#advanced)
  * [Ignore Copied Items](#ignore-copied-items)
  * [Ignore Custom Copy Types](#ignore-custom-copy-types)
  * [Speed up Clipboard Check Interval](#speed-up-clipboard-check-interval)
* [FAQ](#faq)
  * [Why doesn't it paste when I select an item in history?](#why-doesnt-it-paste-when-i-select-an-item-in-history)
  * [When assigning a hotkey to open BetterMaccy, it says that this hotkey is already used in some system setting.](#when-assigning-a-hotkey-to-open-bettermaccy-it-says-that-this-hotkey-is-already-used-in-some-system-setting)
  * [How to restore hidden footer?](#how-to-restore-hidden-footer)
  * [How to ignore copies from Universal Clipboard?](#how-to-ignore-copies-from-universal-clipboard)
  * [My keyboard shortcut stopped working in password fields. How do I fix this?](#my-keyboard-shortcut-stopped-working-in-password-fields-how-do-i-fix-this)
* [Translations](#translations)
* [Motivation](#motivation)
* [License](#license)

<!-- vim-markdown-toc -->

## Features

* Lightweight and fast
* Keyboard-first
* Secure and private
* Native UI
* Open source and free

## Install

Download the latest version from the [releases](https://github.com/astrovini/BetterMaccy/releases/latest) page, or use [Homebrew](https://brew.sh/):

```sh
brew install --cask astrovini/tap/bettermaccy
```

## Usage

1. <kbd>OPTION (⌥)</kbd> + <kbd>V</kbd> to popup BetterMaccy or click on its icon in the menu bar.
2. Type what you want to find.
3. To select the history item you wish to copy, press <kbd>ENTER</kbd>, or click the item, or use <kbd>COMMAND (⌘)</kbd> + `n` shortcut.
4. To choose the history item and paste, press <kbd>OPTION (⌥)</kbd> + <kbd>ENTER</kbd>, or <kbd>OPTION (⌥)</kbd> + <kbd>CLICK</kbd> the item, or use <kbd>OPTION (⌥)</kbd> + `n` shortcut.
5. To choose the history item and paste without formatting, press <kbd>OPTION (⌥)</kbd> + <kbd>SHIFT (⇧)</kbd> + <kbd>ENTER</kbd>, or <kbd>OPTION (⌥)</kbd> + <kbd>SHIFT (⇧)</kbd> + <kbd>CLICK</kbd> the item, or use <kbd>OPTION (⌥)</kbd> + <kbd>SHIFT (⇧)</kbd> + `n` shortcut.
6. To delete the history item, press <kbd>OPTION (⌥)</kbd> + <kbd>DELETE (⌫)</kbd>.
7. To see the full text of the history item, press <kbd>OPTION (⌥)</kbd> + <kbd>SPACE</kbd> to open the preview pane. You can select text in the preview and copy just that part with <kbd>COMMAND (⌘)</kbd> + <kbd>C</kbd>. (Hovering and waiting a couple of seconds for the tooltip still works too.)
8. To pin the history item so that it remains on top of the list, press <kbd>OPTION (⌥)</kbd> + <kbd>P</kbd>. The item will be moved to the top with a random but permanent keyboard shortcut. To unpin it, press <kbd>OPTION (⌥)</kbd> + <kbd>P</kbd> again.
9. To mark the history item as a favorite, press <kbd>OPTION (⌥)</kbd> + <kbd>SHIFT (⇧)</kbd> + <kbd>F</kbd>, or click its star. Press <kbd>OPTION (⌥)</kbd> + <kbd>F</kbd> to switch the list between Recents and Favorites. Favorites are kept regardless of the history size limit and survive _Clear_.
10. To clear all unpinned items, select _Clear_ in the menu, or press <kbd>OPTION (⌥)</kbd> + <kbd>COMMAND (⌘)</kbd> + <kbd>DELETE (⌫)</kbd>. To clear all items including pinned, select _Clear_ in the menu with  <kbd>OPTION (⌥)</kbd> pressed, or press <kbd>SHIFT (⇧)</kbd> + <kbd>OPTION (⌥)</kbd> + <kbd>COMMAND (⌘)</kbd> + <kbd>DELETE (⌫)</kbd>.
11. To disable BetterMaccy and ignore new copies, click on the menu icon with <kbd>OPTION (⌥)</kbd> pressed.
12. To ignore only the next copy, click on the menu icon with <kbd>OPTION (⌥)</kbd> + <kbd>SHIFT (⇧)</kbd> pressed.
13. To customize the behavior, check "Preferences…" window, or press <kbd>COMMAND (⌘)</kbd> + <kbd>,</kbd>.

## Advanced

### Ignore Copied Items

You can tell BetterMaccy to ignore all copied items:

```sh
defaults write com.astrovini.bettermaccy ignoreEvents true # default is false
```

This is useful if you have some workflow for copying sensitive data. You can set `ignoreEvents` to true, copy the data and set `ignoreEvents` back to false.

You can also click the menu icon with <kbd>OPTION (⌥)</kbd> pressed. To ignore only the next copy, click with <kbd>OPTION (⌥)</kbd> + <kbd>SHIFT (⇧)</kbd> pressed.

### Ignore Custom Copy Types

By default BetterMaccy will ignore certain copy types that are considered to be confidential
or temporary. The default list always include the following types:

* `org.nspasteboard.TransientType`
* `org.nspasteboard.ConcealedType`
* `org.nspasteboard.AutoGeneratedType`

Also, default configuration includes the following types but they can be removed
or overwritten:

* `com.agilebits.onepassword`
* `com.typeit4me.clipping`
* `de.petermaurer.TransientPasteboardType`
* `Pasteboard generator type`
* `net.antelle.keeweb`

You can add additional custom types using settings.
To find what custom types are used by an application, you can use
free application [Pasteboard-Viewer](https://github.com/sindresorhus/Pasteboard-Viewer).
Simply download the application, open it, copy something from the application you
want to ignore and look for any custom types in the left sidebar. [Here is an example
of using this approach to ignore Adobe InDesign](https://github.com/p0deje/Maccy/issues/125).

### Speed up Clipboard Check Interval

By default, BetterMaccy checks clipboard every 500 ms, which should be enough for most users. If you want
to speed it up, you can change it with `defaults`:

```sh
defaults write com.astrovini.bettermaccy clipboardCheckInterval 0.1 # 100 ms
```

## FAQ

### Why doesn't it paste when I select an item in history?

1. Make sure you have "Paste automatically" enabled in Preferences (enabled by default in this fork).
2. Make sure "BetterMaccy" is added to System Settings -> Privacy & Security -> Accessibility.

### When assigning a hotkey to open BetterMaccy, it says that this hotkey is already used in some system setting.

1. Open System settings -> Keyboard -> Keyboard Shortcuts.
2. Find where that hotkey is used. For example, "Convert text to simplified Chinese" is under Services -> Text.
3. Disable that hotkey or remove assigned combination ([screenshot](https://github.com/p0deje/Maccy/assets/576152/446719e6-c3e5-4eb0-95fb-5a811066487f)).
4. Restart BetterMaccy.
5. Assign hotkey in BetterMaccy settings.

### How to restore hidden footer?

1. Open BetterMaccy window.
2. Press <kbd>COMMAND (⌘)</kbd> + <kbd>,</kbd> to open preferences.
3. Enable footer in Appearance section.

If for some reason it doesn't work, run the following command in Terminal.app:

```sh
defaults write com.astrovini.bettermaccy showFooter 1
```

### How to ignore copies from [Universal Clipboard](https://support.apple.com/en-us/102430)?

1. Open Preferences -> Ignore -> Pasteboard Types.
2. Add `com.apple.is-remote-clipboard`.

### My keyboard shortcut stopped working in password fields. How do I fix this?

If your shortcut produces a character (like `Option+C` → "ç"), macOS security may block it in password fields. Use [Karabiner-Elements](https://karabiner-elements.pqrs.org/) to remap your shortcut to a different combination like `Cmd+Shift+C`. [See detailed solution](docs/keyboard-shortcut-password-fields.md).

## Translations

The translations are hosted in [Weblate](https://hosted.weblate.org/engage/maccy/).
You can use it to suggest changes in translations and localize the application to a new language.

[![Translation status](https://hosted.weblate.org/widget/maccy/multi-auto.svg)](https://hosted.weblate.org/engage/maccy/)

## Motivation

There are dozens of similar applications out there, so why build another?
Over the past years since I moved from Linux to macOS, I struggled to find
a clipboard manager that is as free and simple as [Parcellite](http://parcellite.sourceforge.net),
but I couldn't. So I've decided to build one.

Also, I wanted to learn Swift and get acquainted with macOS application development.


## License

[MIT](./LICENSE)
