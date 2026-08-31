import PencilMarkCore
import AppKit
import SwiftUI

/// Click to record, then press a combination. Escape cancels, Delete restores the default.
///
/// While recording it installs a *local* monitor, so it only sees keys aimed at this window —
/// it never intercepts anything system-wide.
struct ShortcutRecorderView: View {
    let mode: RewriteMode
    @ObservedObject var settings: AppSettings

    @State private var isRecording = false
    @State private var monitor: Any?
    @State private var problem: String?

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 6) {
                Button(action: toggleRecording) {
                    Text(isRecording ? "Press keys…" : settings.shortcut(for: mode).display)
                        .font(.system(.body, design: .monospaced))
                        .frame(minWidth: 82)
                        .padding(.vertical, 3)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.bordered)
                .tint(isRecording ? .accentColor : nil)
                .help(isRecording ? "Press a combination, or Escape to cancel" : "Click to change")

                Button {
                    settings.resetShortcut(for: mode)
                    problem = nil
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .buttonStyle(.borderless)
                .disabled(settings.shortcut(for: mode) == mode.defaultShortcut)
                .help("Reset to \(mode.defaultShortcut.display)")
            }

            if let problem {
                Text(problem)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .onDisappear(perform: stopRecording)
    }

    // MARK: - Recording

    private func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    private func startRecording() {
        problem = nil
        isRecording = true

        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            handle(event)
            return nil  // swallow the key so it doesn't reach the rest of the UI
        }
    }

    private func stopRecording() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        isRecording = false
    }

    private func handle(_ event: NSEvent) {
        if event.keyCode == 53 {  // Escape
            stopRecording()
            return
        }

        if event.keyCode == 51 {  // Delete → back to the shipped default
            settings.resetShortcut(for: mode)
            stopRecording()
            return
        }

        let candidate = Shortcut(keyCode: UInt32(event.keyCode),
                                 modifiers: Shortcut.carbonModifiers(from: event.modifierFlags),
                                 key: Shortcut.displayKey(for: event))

        guard candidate.isValid else {
            problem = "Include ⌘, ⌃ or ⌥ — otherwise it would swallow normal typing."
            return
        }

        if let clash = settings.setShortcut(candidate, for: mode) {
            problem = "\(candidate.display) is already used by \(clash.title)."
            return
        }

        problem = nil
        stopRecording()
    }
}
