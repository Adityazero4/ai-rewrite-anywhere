import CoreGraphics
import Foundation

/// Synthetic keystrokes used for the copy/paste fallback path.
/// Posting these requires Accessibility trust, which callers verify first.
enum Keyboard {
    static let cKey: CGKeyCode = 8
    static let vKey: CGKeyCode = 9

    /// The user is still physically holding ⌘⇧ when a global hotkey fires. A synthetic ⌘C sent
    /// during that window arrives as ⌘⇧C in many apps, so give the modifiers a moment to lift.
    /// Proceeds anyway after `timeout` — our events carry explicit flags either way.
    static func waitForModifiersToClear(timeout: TimeInterval = 0.35) async {
        let watched: CGEventFlags = [.maskCommand, .maskShift, .maskControl, .maskAlternate]
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if CGEventSource.flagsState(.combinedSessionState).intersection(watched).isEmpty { return }
            try? await Task.sleep(nanoseconds: 15_000_000)
        }
    }

    /// Posts ⌘<key> down+up to the HID tap. Returns false if the events couldn't be created.
    @discardableResult
    static func postCommandKey(_ key: CGKeyCode) -> Bool {
        guard let source = CGEventSource(stateID: .combinedSessionState),
              let down = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false)
        else { return false }

        down.flags = .maskCommand
        up.flags = .maskCommand
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        return true
    }
}
