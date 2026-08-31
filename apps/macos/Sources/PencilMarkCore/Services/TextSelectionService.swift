import AppKit
import ApplicationServices
import Foundation

/// What was selected, and where. Carried from capture to replacement so we can verify the user
/// hasn't switched apps in the meantime.
public struct Selection {
    public enum Method: String { case accessibility, clipboard }

    public let text: String
    public let pid: pid_t
    public let appName: String
    public let method: Method

    public init(text: String, pid: pid_t, appName: String, method: Method) {
        self.text = text
        self.pid = pid
        self.appName = appName
        self.method = method
    }
}

public protocol SelectionReading: AnyObject {
    func capture() async throws -> Selection
}

/// Reads the current selection from whatever app is frontmost.
///
/// Two strategies, in order:
/// 1. Accessibility — free, instant, and doesn't touch the clipboard. Works in native apps
///    (Notes, TextEdit, Mail, Xcode) and any app that exposes `AXSelectedText`.
/// 2. Clipboard copy — a synthetic ⌘C with full snapshot/restore around it. Needed for Chromium
///    and Electron apps (Chrome, Safari's web content, Slack, VS Code, Notion, Linear, Jira).
public final class TextSelectionService: SelectionReading {
    private let pasteboard: PasteboardType
    private let copyTimeout: TimeInterval
    private let postCopy: () -> Bool

    /// `postCopy` is injectable so the clipboard snapshot/restore contract can be unit tested
    /// without posting real keystrokes.
    public init(pasteboard: PasteboardType = SystemPasteboard(),
                copyTimeout: TimeInterval = 0.5,
                postCopy: (() -> Bool)? = nil) {
        self.pasteboard = pasteboard
        self.copyTimeout = copyTimeout
        self.postCopy = postCopy ?? { Keyboard.postCommandKey(Keyboard.cKey) }
    }

    public static var hasAccessibilityPermission: Bool { AXIsProcessTrusted() }

    /// Shows the system Accessibility prompt. Returns the current trust state.
    @discardableResult
    public static func requestAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    public func capture() async throws -> Selection {
        guard Self.hasAccessibilityPermission else { throw RewriteError.accessibilityDenied }
        guard let app = NSWorkspace.shared.frontmostApplication else { throw RewriteError.noSelection }

        let pid = app.processIdentifier
        let name = app.localizedName ?? "the frontmost app"

        if let text = Self.accessibilitySelectedText() {
            return try Self.validated(text, pid: pid, appName: name, method: .accessibility)
        }

        guard let copied = await copyViaClipboard() else { throw RewriteError.noSelection }
        return try Self.validated(copied, pid: pid, appName: name, method: .clipboard)
    }

    private static func validated(_ text: String, pid: pid_t, appName: String, method: Selection.Method) throws -> Selection {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RewriteError.emptySelection
        }
        return Selection(text: text, pid: pid, appName: appName, method: method)
    }

    // MARK: - Accessibility path

    /// The focused element's `AXSelectedText`, or nil if the app doesn't expose one.
    static func accessibilitySelectedText() -> String? {
        guard let focused = focusedElement() else { return nil }

        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(focused, kAXSelectedTextAttribute as CFString, &value) == .success,
              let text = value as? String,
              !text.isEmpty
        else { return nil }
        return text
    }

    static func focusedElement() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        var focused: CFTypeRef?
        guard AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focused) == .success
        else { return nil }
        guard CFGetTypeID(focused) == AXUIElementGetTypeID() else { return nil }
        return (focused as! AXUIElement)
    }

    // MARK: - Clipboard fallback

    /// Snapshot → ⌘C → read → restore. The user's clipboard is always put back, including on
    /// failure, so a rewrite never destroys what they had copied.
    func copyViaClipboard() async -> String? {
        let snapshot = pasteboard.snapshot()
        let before = pasteboard.changeCount
        defer { pasteboard.restore(snapshot) }

        await Keyboard.waitForModifiersToClear()
        guard postCopy() else { return nil }

        let deadline = Date().addingTimeInterval(copyTimeout)
        while Date() < deadline {
            try? await Task.sleep(nanoseconds: 20_000_000)
            if pasteboard.changeCount != before {
                return pasteboard.string()
            }
        }
        return nil  // nothing was selected, or the app ignored ⌘C
    }
}
