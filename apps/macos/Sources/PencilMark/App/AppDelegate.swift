import PencilMarkCore
import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    let settings = AppSettings()

    /// Mirrored from the coordinator so the menu-bar icon can show a busy state.
    @Published private(set) var isWorking = false

    private(set) var coordinator: RewriteCoordinator!
    private var hotKeys: HotKeyManager!
    private var settingsWindow: SettingsWindowController?
    private var cancellables = Set<AnyCancellable>()
    private let hud = ProgressHUD()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu-bar only: no Dock icon, no window required. (Also set via LSUIElement in Info.plist.)
        NSApp.setActivationPolicy(.accessory)

        let client = OpenAIClient(
            apiKey: { [settings] in settings.resolvedAPIKey() },
            model: { [settings] in settings.model }
        )

        coordinator = RewriteCoordinator(
            reader: TextSelectionService(),
            writer: TextReplacementService(),
            service: client,
            onError: { [weak self] error in self?.present(error) }
        )

        coordinator.$isWorking
            .receive(on: RunLoop.main)
            .sink { [weak self] working in
                self?.isWorking = working
                working ? self?.hud.show() : self?.hud.hide()
            }
            .store(in: &cancellables)

        hotKeys = HotKeyManager { [weak self] mode in
            self?.coordinator.trigger(mode)
        }
        hotKeys.register(settings.shortcuts)

        // Re-register whenever the user edits a shortcut in Settings.
        settings.$shortcuts
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] shortcuts in self?.hotKeys.register(shortcuts) }
            .store(in: &cancellables)

        if !TextSelectionService.hasAccessibilityPermission {
            TextSelectionService.requestAccessibilityPermission()
            openSettings()
        } else if !hotKeys.failedModes.isEmpty {
            let list = hotKeys.failedModes.map { settings.shortcut(for: $0).display }.joined(separator: ", ")
            presentAlert(title: "Some shortcuts are unavailable",
                         message: "Another app already owns \(list). The matching menu-bar items still work.")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeys?.unregisterAll()
    }

    // MARK: - Actions

    func trigger(_ mode: RewriteMode) {
        coordinator.trigger(mode)
    }

    func openSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindowController(settings: settings)
        }
        settingsWindow?.show()
    }

    // MARK: - Errors

    private func present(_ error: RewriteError) {
        let title: String
        switch error {
        case .accessibilityDenied: title = "Accessibility permission needed"
        case .missingAPIKey: title = "API key needed"
        case .noSelection, .emptySelection: title = "Nothing to rewrite"
        case .focusChanged: title = "Rewrite cancelled"
        default: title = "Rewrite failed"
        }

        presentAlert(title: title,
                     message: error.errorDescription ?? "Something went wrong.",
                     showsSettingsButton: error == .accessibilityDenied || error == .missingAPIKey)
    }

    private func presentAlert(title: String, message: String, showsSettingsButton: Bool = false) {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        if showsSettingsButton { alert.addButton(withTitle: "Open Settings…") }

        if alert.runModal() == .alertSecondButtonReturn, showsSettingsButton {
            openSettings()
        }
    }
}
