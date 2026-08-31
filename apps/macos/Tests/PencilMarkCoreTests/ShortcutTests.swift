import Carbon.HIToolbox
import Foundation
@testable import PencilMarkCore

private let cmd = UInt32(cmdKey)
private let shift = UInt32(shiftKey)
private let opt = UInt32(optionKey)
private let ctrl = UInt32(controlKey)

func runShortcutTests() {
    t.suite("Shortcuts — display and validation")

    t.equal(Shortcut(keyCode: 15, modifiers: cmd | shift, key: "R").display, "⌘⇧R",
            "command+shift renders as ⌘⇧")
    t.equal(Shortcut(keyCode: 40, modifiers: ctrl | opt, key: "K").display, "⌥⌃K",
            "control+option renders both symbols")
    t.equal(Shortcut(keyCode: 49, modifiers: cmd | ctrl | opt | shift, key: "Space").display,
            "⌘⇧⌥⌃Space", "all four modifiers render, named keys keep their label")

    t.check(Shortcut(keyCode: 15, modifiers: cmd, key: "R").isValid, "⌘R is valid")
    t.check(Shortcut(keyCode: 15, modifiers: ctrl, key: "R").isValid, "⌃R is valid")
    t.check(Shortcut(keyCode: 15, modifiers: opt, key: "R").isValid, "⌥R is valid")
    t.check(!Shortcut(keyCode: 15, modifiers: shift, key: "R").isValid,
            "⇧R is rejected — it would swallow ordinary typing")
    t.check(!Shortcut(keyCode: 15, modifiers: 0, key: "R").isValid, "a bare key is rejected")
    t.check(!Shortcut(keyCode: 15, modifiers: cmd, key: "").isValid, "a shortcut with no key is rejected")

    t.suite("Shortcuts — persistence")

    let suiteName = "ShortcutTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    func makeSettings() -> AppSettings {
        AppSettings(defaults: defaults, secrets: InMemorySecretStore(), environment: [:])
    }

    let fresh = makeSettings()
    t.check(fresh.shortcutsAreDefault, "a fresh install uses the shipped defaults")
    t.equal(fresh.shortcut(for: .rewrite), RewriteMode.rewrite.defaultShortcut,
            "the default is returned per mode")

    let custom = Shortcut(keyCode: 40, modifiers: cmd | opt, key: "K")
    t.check(fresh.setShortcut(custom, for: .rewrite) == nil, "setting a free shortcut succeeds")
    t.equal(fresh.shortcut(for: .rewrite), custom, "the custom shortcut is returned")
    t.check(!fresh.shortcutsAreDefault, "the settings no longer report as default")

    t.equal(makeSettings().shortcut(for: .rewrite), custom, "custom shortcuts survive a relaunch")
    t.equal(makeSettings().shortcut(for: .grammar), RewriteMode.grammar.defaultShortcut,
            "untouched modes keep their default after a relaunch")

    t.suite("Shortcuts — collisions and reset")

    let settings = makeSettings()
    t.equal(settings.setShortcut(custom, for: .grammar), RewriteMode.rewrite,
            "assigning a shortcut another mode owns is refused, naming the clash")
    t.equal(settings.shortcut(for: .grammar), RewriteMode.grammar.defaultShortcut,
            "the refused assignment changed nothing")

    t.check(settings.setShortcut(custom, for: .rewrite) == nil,
            "re-assigning a mode its own shortcut is not a collision")

    settings.resetShortcut(for: .rewrite)
    t.equal(settings.shortcut(for: .rewrite), RewriteMode.rewrite.defaultShortcut,
            "a single shortcut can be reset")

    let all = makeSettings()
    all.setShortcut(custom, for: .concise)
    all.resetAllShortcuts()
    t.check(all.shortcutsAreDefault, "reset all restores every default")
    t.check(makeSettings().shortcutsAreDefault, "the reset is persisted")

    t.suite("Shortcuts — stored data is defensive")

    let hostile = UserDefaults(suiteName: "ShortcutTests-hostile-\(UUID().uuidString)")!
    defer { hostile.removePersistentDomain(forName: hostile.description) }

    hostile.set(Data("not json".utf8), forKey: AppSettings.shortcutsKey)
    t.check(AppSettings(defaults: hostile, secrets: InMemorySecretStore(), environment: [:]).shortcutsAreDefault,
            "a corrupt stored blob falls back to the defaults")

    let invalid = try! JSONEncoder().encode(["rewrite": Shortcut(keyCode: 15, modifiers: 0, key: "R"),
                                             "not-a-mode": Shortcut(keyCode: 1, modifiers: cmd, key: "S")])
    hostile.set(invalid, forKey: AppSettings.shortcutsKey)
    let loaded = AppSettings(defaults: hostile, secrets: InMemorySecretStore(), environment: [:])
    t.equal(loaded.shortcut(for: .rewrite), RewriteMode.rewrite.defaultShortcut,
            "a stored shortcut that fails validation is ignored")
    t.equal(loaded.shortcuts.count, RewriteMode.allCases.count,
            "unknown modes are dropped and the map stays complete")
}
