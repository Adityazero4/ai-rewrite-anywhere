import Combine
import Foundation

/// Where the API key is kept. Real app uses the Keychain; tests use an in-memory fake.
public protocol SecretStore: AnyObject {
    func secret(for account: String) -> String?
    func setSecret(_ value: String, for account: String) -> Bool
    func deleteSecret(for account: String) -> Bool
}

public final class KeychainSecretStore: SecretStore {
    public init() {}
    public func secret(for account: String) -> String? { Keychain.get(account) }
    public func setSecret(_ value: String, for account: String) -> Bool { Keychain.set(value, account: account) }
    public func deleteSecret(for account: String) -> Bool { Keychain.delete(account) }
}

public final class AppSettings: ObservableObject {
    public static let defaultModel = "gpt-4.1-mini"
    static let modelKey = "model"
    static let shortcutsKey = "shortcuts"
    static let apiKeyAccount = "openai-api-key"

    private let defaults: UserDefaults
    private let secrets: SecretStore

    /// Model name. Configurable, never hardcoded at the call site.
    @Published public var model: String {
        didSet {
            let trimmed = model.trimmingCharacters(in: .whitespacesAndNewlines)
            defaults.set(trimmed.isEmpty ? Self.defaultModel : trimmed, forKey: Self.modelKey)
        }
    }

    /// True when a key is available from the Keychain or the OPENAI_API_KEY environment override.
    @Published public private(set) var hasAPIKey: Bool = false

    /// One shortcut per mode. Always complete: any mode without a stored override uses its default.
    @Published public private(set) var shortcuts: [RewriteMode: Shortcut] = [:]

    public init(defaults: UserDefaults = .standard,
                secrets: SecretStore = KeychainSecretStore(),
                environment: [String: String] = ProcessInfo.processInfo.environment) {
        self.defaults = defaults
        self.secrets = secrets
        self.environmentKey = environment["OPENAI_API_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.model = defaults.string(forKey: Self.modelKey) ?? Self.defaultModel
        self.hasAPIKey = resolvedAPIKey() != nil
        self.shortcuts = Self.loadShortcuts(from: defaults)
    }

    // MARK: - Shortcuts

    public func shortcut(for mode: RewriteMode) -> Shortcut {
        shortcuts[mode] ?? mode.defaultShortcut
    }

    /// Rejects a shortcut that is already taken by another mode, so two actions can't collide.
    /// Returns the mode already using it, or nil on success.
    @discardableResult
    public func setShortcut(_ shortcut: Shortcut, for mode: RewriteMode) -> RewriteMode? {
        if let clash = shortcuts.first(where: { $0.key != mode && $0.value == shortcut })?.key {
            return clash
        }
        shortcuts[mode] = shortcut
        persistShortcuts()
        return nil
    }

    public func resetShortcut(for mode: RewriteMode) {
        shortcuts[mode] = mode.defaultShortcut
        persistShortcuts()
    }

    public func resetAllShortcuts() {
        shortcuts = Self.defaultShortcuts
        persistShortcuts()
    }

    public var shortcutsAreDefault: Bool { shortcuts == Self.defaultShortcuts }

    static var defaultShortcuts: [RewriteMode: Shortcut] {
        Dictionary(uniqueKeysWithValues: RewriteMode.allCases.map { ($0, $0.defaultShortcut) })
    }

    private func persistShortcuts() {
        let encodable = Dictionary(uniqueKeysWithValues: shortcuts.map { ($0.key.rawValue, $0.value) })
        guard let data = try? JSONEncoder().encode(encodable) else { return }
        defaults.set(data, forKey: Self.shortcutsKey)
    }

    private static func loadShortcuts(from defaults: UserDefaults) -> [RewriteMode: Shortcut] {
        var result = defaultShortcuts
        guard let data = defaults.data(forKey: Self.shortcutsKey),
              let stored = try? JSONDecoder().decode([String: Shortcut].self, from: data)
        else { return result }

        // Unknown keys are ignored, missing ones keep their default, so the map is always complete.
        for (raw, shortcut) in stored {
            if let mode = RewriteMode(rawValue: raw), shortcut.isValid { result[mode] = shortcut }
        }
        return result
    }

    private let environmentKey: String?

    /// Keychain first, then the dev-only environment override. Never logged, never persisted elsewhere.
    public func resolvedAPIKey() -> String? {
        if let stored = secrets.secret(for: Self.apiKeyAccount), !stored.isEmpty { return stored }
        if let env = environmentKey, !env.isEmpty { return env }
        return nil
    }

    /// True when the key in use comes from the environment rather than the Keychain.
    public var usingEnvironmentKey: Bool {
        secrets.secret(for: Self.apiKeyAccount) == nil && (environmentKey?.isEmpty == false)
    }

    @discardableResult
    public func saveAPIKey(_ key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let ok = trimmed.isEmpty
            ? secrets.deleteSecret(for: Self.apiKeyAccount)
            : secrets.setSecret(trimmed, for: Self.apiKeyAccount)
        hasAPIKey = resolvedAPIKey() != nil
        return ok
    }

    @discardableResult
    public func removeAPIKey() -> Bool {
        let ok = secrets.deleteSecret(for: Self.apiKeyAccount)
        hasAPIKey = resolvedAPIKey() != nil
        return ok
    }
}
