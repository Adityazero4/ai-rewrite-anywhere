import PencilMarkCore
import SwiftUI

@main
struct PencilMarkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(delegate: delegate)
        } label: {
            // Doubles as the progress indicator: the icon changes while a rewrite is in flight.
            Image(systemName: delegate.isWorking ? "ellipsis.circle" : "sparkles")
        }
        .menuBarExtraStyle(.menu)
    }
}
