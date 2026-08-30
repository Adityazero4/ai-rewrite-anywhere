import Carbon.HIToolbox
import Foundation

/// Registers the four global ⌘⇧ shortcuts.
///
/// Carbon's `RegisterEventHotKey` is used deliberately: it needs no Accessibility permission,
/// no event tap, no third-party dependency, and it fires even when the app has no window.
public final class HotKeyManager {
    private static let signature: OSType = 0x4152_5741  // 'ARWA'

    private var hotKeyRefs: [EventHotKeyRef?] = []
    private var eventHandler: EventHandlerRef?
    private var modesByID: [UInt32: RewriteMode] = [:]
    private let onTrigger: (RewriteMode) -> Void

    /// Modes that macOS refused to register, usually because another app already owns the combo.
    public private(set) var failedModes: [RewriteMode] = []

    public init(onTrigger: @escaping (RewriteMode) -> Void) {
        self.onTrigger = onTrigger
    }

    deinit { unregisterAll() }

    /// Registers the given shortcuts, replacing any previously registered set.
    /// Safe to call again whenever the user edits a shortcut.
    public func register(_ shortcuts: [RewriteMode: Shortcut]) {
        unregisterAll()
        installHandler()

        for (index, mode) in RewriteMode.allCases.enumerated() {
            let shortcut = shortcuts[mode] ?? mode.defaultShortcut
            let id = UInt32(index + 1)
            var ref: EventHotKeyRef?
            let status = RegisterEventHotKey(
                shortcut.keyCode,
                shortcut.modifiers,
                EventHotKeyID(signature: Self.signature, id: id),
                GetApplicationEventTarget(),
                0,
                &ref
            )

            if status == noErr, ref != nil {
                modesByID[id] = mode
                hotKeyRefs.append(ref)
            } else {
                failedModes.append(mode)
            }
        }
    }

    public func unregisterAll() {
        for ref in hotKeyRefs where ref != nil {
            UnregisterEventHotKey(ref!)
        }
        hotKeyRefs.removeAll()
        modesByID.removeAll()
        failedModes.removeAll()

        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    // MARK: - Carbon plumbing

    private func installHandler() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let context = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let event, let userData else { return OSStatus(eventNotHandledErr) }

            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            guard status == noErr else { return status }

            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.dispatch(id: hotKeyID.id)
            return noErr
        }, 1, &spec, context, &eventHandler)
    }

    private func dispatch(id: UInt32) {
        guard let mode = modesByID[id] else { return }
        let handler = onTrigger
        DispatchQueue.main.async { handler(mode) }
    }
}
