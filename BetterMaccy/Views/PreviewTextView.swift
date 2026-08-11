import AppKit
import SwiftUI

// The preview pane's text area.
//
// This used to be `ScrollView { Text(item.text).textSelection(.enabled) }`. A
// SwiftUI ScrollView proposes an unbounded height to its content, so Text had
// to line-break the entire string just to report an intrinsic height — and that
// measurement is quadratic in length. At the decorator's 10k-character cap it
// cost ~190ms, paid on *every* selection change, because SlideoutContentView
// rebuilds PreviewItemView whenever navigator.leadHistoryItem changes. Hovering,
// arrow-keying or clicking past a large item with the preview open stalled the
// whole popup for ~12 frames a step. (Closing the preview was already free —
// SlideoutView stops rendering the pane entirely when it's closed.)
//
// NSScrollView has no intrinsic content size, so it accepts the size it is
// offered and never asks the text how tall it really is, and TextKit 2 lays out
// only the visible viewport. Measured at the real pane geometry (370pt wide,
// 500pt viewport), swapping in a new item costs ~1.3ms at 10k characters and
// goes flat past ~2k, versus 193ms before.
struct PreviewTextView: NSViewRepresentable {
  let text: String
  // Identity of the previewed item. `HistoryItemDecorator.text` is computed once
  // at init and never mutates afterwards, so the id alone tells us whether the
  // content needs replacing — see updateNSView.
  let itemID: UUID

  private static let textAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.preferredFont(forTextStyle: .body),
    .foregroundColor: NSColor.labelColor
  ]

  final class Coordinator {
    var itemID: UUID?
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  func makeNSView(context: Context) -> NSScrollView {
    // NOTE: never read `textView.layoutManager` (directly or via a helper).
    // Touching TextKit 1's layout manager silently migrates the view off
    // TextKit 2, which loses viewport layout — the entire point of this view.
    let textView = PreviewNSTextView(frame: .zero)
    textView.isEditable = false
    textView.isSelectable = true
    textView.drawsBackground = false
    textView.textContainerInset = .zero
    textView.isVerticallyResizable = true
    textView.isHorizontallyResizable = false
    textView.autoresizingMask = [.width]
    textView.minSize = NSSize(width: 0, height: 0)
    textView.maxSize = NSSize(
      width: CGFloat.greatestFiniteMagnitude,
      height: CGFloat.greatestFiniteMagnitude
    )
    textView.textContainer?.lineFragmentPadding = 0
    textView.textContainer?.widthTracksTextView = true
    textView.textContainer?.containerSize = NSSize(
      width: 0,
      height: CGFloat.greatestFiniteMagnitude
    )

    let scrollView = NSScrollView()
    scrollView.documentView = textView
    scrollView.drawsBackground = false
    scrollView.hasVerticalScroller = true
    scrollView.autohidesScrollers = true

    return scrollView
  }

  func updateNSView(_ scrollView: NSScrollView, context: Context) {
    // updateNSView runs on any body re-evaluation, not just when the previewed
    // item changes. Replacing the text unconditionally would clear the user's
    // in-progress selection and scroll position out from under them.
    guard context.coordinator.itemID != itemID else { return }
    context.coordinator.itemID = itemID

    guard let textView = scrollView.documentView as? NSTextView else { return }
    textView.textStorage?.setAttributedString(
      NSAttributedString(string: text, attributes: Self.textAttributes)
    )
    // The old ScrollView got this for free by being rebuilt per item; a
    // persistent NSView would otherwise keep the previous item's scroll offset.
    scrollView.contentView.scroll(to: .zero)
    scrollView.reflectScrolledClipView(scrollView.contentView)
  }
}

private final class PreviewNSTextView: NSTextView {
  // The popup routes keys through SwiftUI's focus system (KeyHandlingView's
  // .onKeyPress). Clicking into this view to select text makes it the AppKit
  // first responder, which would otherwise swallow arrow keys and Return as
  // caret movement and kill history navigation. Keep the command-key events
  // that make a selection useful (⌘C, ⌘A) and bubble everything else back up
  // the responder chain to the hosting view.
  override func keyDown(with event: NSEvent) {
    if event.modifierFlags.contains(.command) {
      super.keyDown(with: event)
    } else {
      nextResponder?.keyDown(with: event)
    }
  }
}
