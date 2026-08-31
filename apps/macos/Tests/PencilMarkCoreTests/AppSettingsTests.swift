import Foundation
@testable import PencilMarkCore

func runAppSettingsTests() {
    t.suite("Settings persistence")

    let suiteName = "PencilMarkTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    func makeSettings(secrets: SecretStore = InMemorySecretStore(), env: [String: String] = [:]) -> AppSettings {
        AppSettings(defaults: defaults, secrets: secrets, environment: env)
    }

    // MARK: Model

    t.equal(makeSettings().model, AppSettings.defaultModel, "model defaults when nothing is stored")

    makeSettings().model = "gpt-5-mini"
    t.equal(makeSettings().model, "gpt-5-mini", "model persists across instances")

    makeSettings().model = "   "
    t.equal(makeSettings().model, AppSettings.defaultModel, "a blank model falls back to the default")

    makeSettings().model = "  gpt-4.1  "
    t.equal(makeSettings().model, "gpt-4.1", "the model is trimmed before persisting")

    // MARK: API key

    let settings = makeSettings()
    t.check(!settings.hasAPIKey, "starts with no API key")
    t.check(settings.saveAPIKey("sk-abc123"), "saving a key reports success")
    t.check(settings.hasAPIKey, "the key is reported as present")
    t.equal(settings.resolvedAPIKey(), "sk-abc123", "the key round-trips through the secret store")

    var leaked = false
    for (_, value) in defaults.dictionaryRepresentation() where "\(value)".contains("sk-abc123") { leaked = true }
    t.check(!leaked, "the API key is never written to UserDefaults")

    let trimming = makeSettings()
    trimming.saveAPIKey("  sk-padded  ")
    t.equal(trimming.resolvedAPIKey(), "sk-padded", "the API key is trimmed")

    let removing = makeSettings()
    removing.saveAPIKey("sk-abc")
    t.check(removing.removeAPIKey(), "removing the key reports success")
    t.check(removing.resolvedAPIKey() == nil && !removing.hasAPIKey, "removing the key clears it")

    let emptied = makeSettings()
    emptied.saveAPIKey("sk-abc")
    emptied.saveAPIKey("")
    t.check(emptied.resolvedAPIKey() == nil, "saving an empty key removes it")

    let failing = InMemorySecretStore()
    failing.failWrites = true
    t.check(!makeSettings(secrets: failing).saveAPIKey("sk-abc"), "a failed keychain write is reported")

    // MARK: Environment override

    let fromEnv = makeSettings(env: ["OPENAI_API_KEY": "sk-from-env"])
    t.equal(fromEnv.resolvedAPIKey(), "sk-from-env", "the environment key is used when the store is empty")
    t.check(fromEnv.hasAPIKey && fromEnv.usingEnvironmentKey, "the environment key is flagged as such")

    let both = makeSettings(env: ["OPENAI_API_KEY": "sk-from-env"])
    both.saveAPIKey("sk-from-keychain")
    t.equal(both.resolvedAPIKey(), "sk-from-keychain", "a stored key beats the environment")
    t.check(!both.usingEnvironmentKey, "the environment flag clears once a key is stored")
}

func runKeychainTests() {
    t.suite("Keychain")

    t.check(Keychain.get("definitely-not-stored-\(UUID().uuidString)") == nil,
            "reading a missing account returns nil")

    let account = "unit-test-\(UUID().uuidString)"
    guard Keychain.set("sk-keychain-test", account: account) else {
        print("  — skipped: this host has no keychain access (unsigned binary)")
        return
    }
    defer { Keychain.delete(account) }

    t.equal(Keychain.get(account), "sk-keychain-test", "a key round-trips through the real Keychain")
    t.check(Keychain.set("sk-updated", account: account), "an existing key can be updated")
    t.equal(Keychain.get(account), "sk-updated", "the update is readable")
    t.check(Keychain.delete(account), "the key can be deleted")
    t.check(Keychain.get(account) == nil, "the deleted key is gone")
}
