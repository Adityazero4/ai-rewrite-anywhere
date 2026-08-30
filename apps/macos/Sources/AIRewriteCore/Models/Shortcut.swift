import AppKit
import Carbon.HIToolbox
import Foundation

/// A global keyboard shortcut: a Carbon virtual key code plus Carbon modifier flags.
///
/// `key` is the character to show in the UI. It is captured when the user records the shortcut
/// rather than derived from the key code, which avoids carrying a keyboard-layout table around.
public struct Shortcut: Codable, Equatable, Sendable {
    public var keyCode: UInt32
    public var modifiers: UInt32
    public var key: String

    public init(keyCode: UInt32, modifiers: UInt32, key: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.key = key
    }

    // MARK: - Display

    /// e.g. "⌘⇧R". Command first to match the documented defaults.
    public var display: String {
        var symbols = ""
        if modifiers & UInt32(cmdKey) != 0 { symbols += "⌘" }
        if modifiers & UInt32(shiftKey) != 0 { symbols += "⇧" }
        if modifiers & UInt32(optionKey) != 0 { symbols += "⌥" }
        if modifiers & UInt32(controlKey) != 0 { symbols += "⌃" }
        return symbols + key
    }

    // MARK: - Validation

    /// A shortcut needs ⌘, ⌃ or ⌥ — shift alone (or nothing) would swallow ordinary typing.
    public var isValid: Bool {
        let required = UInt32(cmdKey) | UInt32(controlKey) | UInt32(optionKey)
        return modifiers & required != 0 && !key.isEmpty
    }

    // MARK: - Bridging

    public static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.command) { result |= UInt32(cmdKey) }
        if flags.contains(.shift) { result |= UInt32(shiftKey) }
        if flags.contains(.option) { result |= UInt32(optionKey) }
        if flags.contains(.control) { result |= UInt32(controlKey) }
        return result
    }

    /// The label shown for a key that has no printable character of its own.
    public static func displayKey(for event: NSEvent) -> String {
        let named: [UInt16: String] = [
            UInt16(kVK_Space): "Space", UInt16(kVK_Return): "↩", UInt16(kVK_Tab): "⇥",
            UInt16(kVK_Delete): "⌫", UInt16(kVK_ForwardDelete): "⌦", UInt16(kVK_Escape): "⎋",
            UInt16(kVK_LeftArrow): "←", UInt16(kVK_RightArrow): "→",
            UInt16(kVK_UpArrow): "↑", UInt16(kVK_DownArrow): "↓",
            UInt16(kVK_Home): "↖", UInt16(kVK_End): "↘",
            UInt16(kVK_PageUp): "⇞", UInt16(kVK_PageDown): "⇟",
        ]
        if let name = named[event.keyCode] { return name }

        let characters = event.charactersIgnoringModifiers ?? ""
        return characters.isEmpty ? "Key \(event.keyCode)" : characters.uppercased()
    }
}

public extension RewriteMode {
    /// The shipped default. Users can override any of these in Settings.
    var defaultShortcut: Shortcut {
        Shortcut(keyCode: defaultKeyCode,
                 modifiers: UInt32(cmdKey) | UInt32(shiftKey),
                 key: String(shortcutKey).uppercased())
    }

    /// Carbon virtual key code (kVK_ANSI_*) of the default shortcut.
    var defaultKeyCode: UInt32 {
        switch self {
        case .rewrite: return UInt32(kVK_ANSI_R)
        case .grammar: return UInt32(kVK_ANSI_G)
        case .concise: return UInt32(kVK_ANSI_C)
        case .professional: return UInt32(kVK_ANSI_P)
        }
    }
}
