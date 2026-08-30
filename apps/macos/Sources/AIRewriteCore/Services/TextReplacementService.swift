import AppKit
import ApplicationServices
import Foundation

public protocol SelectionWriting: AnyObject {
    func replace(_ text: String, for selection: Selection) async throws
}

/// Puts the rewritten text back where the selection was.
///
/// Order of preference:
/// 1. Set `AXSelectedText` directly — instant, and the clipboard is never touched at all.
/// 2. Clipboard paste — write, ⌘V, restore the user's original clipboard.
///
/// Refuses to do anything if the user switched apps while the request was in flight.
public final class TextReplacementService: SelectionWriting {
    private let pasteboard: PasteboardType
    private let pasteSettleDelay: TimeInterval
    private let postPaste: () -> Bool

    /// `postPaste` is injectable so the clipboard snapshot/restore contract can be unit tested
    /// without posting real keystrokes.
    public init(pasteboard: PasteboardType = SystemPasteboard(),
                pasteSettleDelay: TimeInterval = 0.3,
                postPaste: (() -> Bool)? = nil) {
        self.pasteboard = pasteboard
        self.pasteSettleDelay = pasteSettleDelay
        self.postPaste = postPaste ?? { Keyboard.postCommandKey(Keyboard.vKey) }
    }

    public func replace(_ text: String, for selection: Selection) async throws {
        guard TextSelectionService.hasAccessibilityPermission else { throw RewriteError.accessibilityDenied }
        guard NSWorkspace.shared.frontmostApplication?.processIdentifier == selection.pid else {
            throw RewriteError.focusChanged
        }

        // Re-fetch the focused element: the one captured before the API call may be stale.
        if selection.method == .accessibility, setViaAccessibility(text, expectedPID: selection.pid) {
            return
        }
        try await pasteViaClipboard(text)
    }

    // MARK: - Accessibility path

    private func setViaAccessibility(_ text: String, expectedPID: pid_t) -> Bool {
        guard let element = TextSelectionService.focusedElement() else { return false }

        var pid: pid_t = 0
        guard AXUIElementGetPid(element, &pid) == .success, pid == expectedPID else { return false }

        var settable = DarwinBoolean(false)
        guard AXUIElementIsAttributeSettable(element, kAXSelectedTextAttribute as CFString, &settable) == .success,
              settable.boolValue
        else { return false }

        return AXUIElementSetAttributeValue(element, kAXSelectedTextAttribute as CFString, text as CFTypeRef) == .success
    }

    // MARK: - Clipboard path

    func pasteViaClipboard(_ text: String) async throws {
        let snapshot = pasteboard.snapshot()
        pasteboard.write(text)

        await Keyboard.waitForModifiersToClear()
        let posted = postPaste()

        // Let the target app consume the paste before the clipboard changes under it.
        if posted {
            try? await Task.sleep(nanoseconds: UInt64(pasteSettleDelay * 1_000_000_000))
        }

        // Unconditional: the user gets their clipboard back even when the paste never went out.
        pasteboard.restore(snapshot)

        if !posted { throw RewriteError.pasteFailed }
    }
}
