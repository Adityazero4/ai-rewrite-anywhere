import AIRewriteCore
import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    @State private var apiKeyField = ""
    @State private var status: String?
    @State private var hasAccessibility = TextSelectionService.hasAccessibilityPermission

    private let accessibilityURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )!

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                permissionSection
                Divider()
                apiKeySection
                Divider()
                modelSection
                Divider()
                shortcutSection
                Divider()
                privacySection
            }
            .padding(24)
        }
        .frame(width: 500, height: 660)
        .onReceive(Timer.publish(every: 2, on: .main, in: .common).autoconnect()) { _ in
            hasAccessibility = TextSelectionService.hasAccessibilityPermission
        }
    }

    // MARK: - Sections

    private var permissionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Accessibility Permission").font(.headline)

            HStack(spacing: 6) {
                Image(systemName: hasAccessibility ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(hasAccessibility ? .green : .orange)
                Text(hasAccessibility ? "Granted" : "Not granted")
                    .fontWeight(.medium)
            }

            Text("AIRewriteAnywhere needs Accessibility permission to read the text you have selected in other apps and to put the rewritten text back. Without it the shortcuts do nothing.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if !hasAccessibility {
                HStack {
                    Button("Open System Settings") { NSWorkspace.shared.open(accessibilityURL) }
                    Button("Request Permission") { TextSelectionService.requestAccessibilityPermission() }
                }
                Text("Enable AIRewriteAnywhere under Privacy & Security → Accessibility, then return here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider().padding(.vertical, 2)

                // macOS answers AXIsProcessTrusted() from a per-process cache, so an app that was
                // already running when you flipped the toggle keeps seeing "denied" until it restarts.
                Text("Already enabled it and still seeing this? macOS only tells an app about the change when it restarts.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Quit & Reopen") { relaunch() }
                    .keyboardShortcut(.defaultAction)
            }
        }
    }

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OpenAI API Key").font(.headline)

            SecureField("sk-…", text: $apiKeyField)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Save") {
                    let ok = settings.saveAPIKey(apiKeyField)
                    apiKeyField = ""
                    status = ok ? "Saved to Keychain." : "Could not write to the Keychain."
                }
                .disabled(apiKeyField.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button("Remove") {
                    settings.removeAPIKey()
                    apiKeyField = ""
                    status = "Removed from Keychain."
                }

                Spacer()

                Label(settings.hasAPIKey ? "Key set" : "No key",
                      systemImage: settings.hasAPIKey ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundStyle(settings.hasAPIKey ? .green : .secondary)
                    .font(.callout)
            }

            if settings.usingEnvironmentKey {
                Text("Currently using the OPENAI_API_KEY environment variable. A key saved here takes precedence.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let status {
                Text(status).font(.caption).foregroundStyle(.secondary)
            }

            Text("Stored in the macOS Keychain, never in a file and never in this app's source.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var modelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Model").font(.headline)

            TextField(AppSettings.defaultModel, text: $settings.model)
                .textFieldStyle(.roundedBorder)

            HStack {
                Text("Any model available on the OpenAI Responses API.")
                Spacer()
                Button("Reset to \(AppSettings.defaultModel)") { settings.model = AppSettings.defaultModel }
                    .buttonStyle(.link)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var shortcutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Keyboard Shortcuts").font(.headline)
                Spacer()
                Button("Reset All") { settings.resetAllShortcuts() }
                    .buttonStyle(.link)
                    .disabled(settings.shortcutsAreDefault)
            }

            ForEach(RewriteMode.allCases, id: \.self) { mode in
                HStack(alignment: .top) {
                    Label(mode.title, systemImage: mode.symbol)
                    Spacer()
                    ShortcutRecorderView(mode: mode, settings: settings)
                }
            }

            Text("Click a shortcut to change it, then press the new combination. Escape cancels, Delete restores the default. Changes take effect immediately — no restart.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("These work in any app. If an app already uses one of these combos, AIRewriteAnywhere wins while it is running.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Relaunches the app so it picks up a permission change macOS has cached as denied.
    private func relaunch() {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true

        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: configuration) { _, error in
            DispatchQueue.main.async {
                // If the new instance couldn't start, stay put rather than leaving the user with nothing.
                guard error == nil else { return }
                NSApp.terminate(nil)
            }
        }
    }

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Privacy").font(.headline)

            Text("""
                 When you press one of the shortcuts above, the text you have selected is sent to \
                 the OpenAI API so it can be rewritten. That is the only time anything leaves your \
                 Mac. Your selected text is never logged, never written to disk, and the request \
                 asks OpenAI not to store the response. Your clipboard is snapshotted and restored \
                 whenever it has to be used to move text around.
                 """)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
