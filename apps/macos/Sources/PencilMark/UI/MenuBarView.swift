import PencilMarkCore
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var delegate: AppDelegate

    var body: some View {
        ForEach(RewriteMode.allCases, id: \.self) { mode in
            Button {
                delegate.trigger(mode)
            } label: {
                Label(mode == .rewrite ? "✨ \(mode.title)" : mode.title, systemImage: mode.symbol)
            }
            .help(delegate.settings.shortcut(for: mode).display)
        }

        Divider()

        if delegate.isWorking {
            Text("Rewriting…")
        }

        if !delegate.settings.hasAPIKey {
            Text("No API key set")
        }

        Button("Settings…") { delegate.openSettings() }
            .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit Pencil Mark") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q", modifiers: .command)
    }
}
