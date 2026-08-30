import AppKit
import SwiftUI

/// A small floating "Rewriting…" panel shown while a request is in flight.
///
/// It must never take focus: the app tracks which app was frontmost when the selection was
/// captured and refuses to paste if that changed, so a panel that activated the app would
/// cancel the user's own rewrite. Hence `.nonactivatingPanel` plus `orderFrontRegardless()`.
@MainActor
final class ProgressHUD {
    private var panel: NSPanel?

    func show(_ text: String = "Rewriting…") {
        guard panel == nil else { return }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 168, height: 52),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        panel.contentView = NSHostingView(rootView: HUDContent(text: text))

        position(panel)
        panel.alphaValue = 0
        panel.orderFrontRegardless()  // shows without activating the app

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            panel.animator().alphaValue = 1
        }

        self.panel = panel
    }

    func hide() {
        guard let panel else { return }
        self.panel = nil

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            panel.animator().alphaValue = 0
        } completionHandler: {
            panel.orderOut(nil)
        }
    }

    /// Centred near the bottom of whichever screen the pointer is on, out of the way of text.
    private func position(_ panel: NSPanel) {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        guard let frame = screen?.visibleFrame else { return }

        let size = panel.frame.size
        panel.setFrameOrigin(NSPoint(x: frame.midX - size.width / 2,
                                     y: frame.minY + frame.height * 0.14))
    }
}

private struct HUDContent: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text(text)
                .font(.system(size: 13, weight: .medium))
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.primary.opacity(0.12), lineWidth: 1)
        )
    }
}
