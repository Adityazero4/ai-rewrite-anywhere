import PencilMarkCore
import AppKit
import SwiftUI

/// A plain NSWindow rather than SwiftUI's `Settings` scene: an `.accessory` app can't open that
/// reliably without version-specific selectors, and this is a dozen lines.
@MainActor
final class SettingsWindowController {
    private let window: NSWindow

    init(settings: AppSettings) {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 620),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Pencil Mark Settings"
        window.contentView = NSHostingView(rootView: SettingsView(settings: settings))
        window.isReleasedWhenClosed = false
        window.center()
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
