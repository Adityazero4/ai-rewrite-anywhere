import Foundation
@testable import PencilMarkCore

func runRewriteModeTests() {
    t.suite("Rewrite modes and prompt generation")

    t.equal(RewriteMode.allCases, [.rewrite, .grammar, .concise, .professional],
            "all four modes exist, in menu order")

    t.equal(Set(RewriteMode.allCases.map(\.instruction)).count, 4,
            "every mode has a distinct prompt")

    for mode in RewriteMode.allCases {
        t.check(!mode.instruction.isEmpty && mode.instruction.contains("Return only"),
                "\(mode.rawValue): prompt tells the model to return only the text")
        t.check(!mode.title.isEmpty && !mode.symbol.isEmpty,
                "\(mode.rawValue): has a menu title and an icon")
    }

    // Each mode's task is asserted exactly; the shared style context is asserted once.
    t.equal(RewriteMode.rewrite.task,
            "Rewrite the text so it reads well: fix grammar and awkward phrasing, and improve clarity and flow. Do not change what it says.",
            "rewrite task")

    t.equal(RewriteMode.grammar.task,
            "Fix only grammar, spelling, punctuation and awkward phrasing. Keep the original wording wherever it is already correct — this is a proofread, not a rewrite.",
            "grammar task is a proofread, not a rewrite")

    t.equal(RewriteMode.concise.task,
            "Make the text shorter and clearer while keeping its meaning and tone. Cut redundancy and filler, not substance.",
            "concise task")

    t.equal(RewriteMode.professional.task,
            "Make the text read as polished and credible to colleagues, while staying natural and conversational. Do not make it formal or corporate.",
            "professional task stays conversational")

    let context = RewriteMode.styleContext
    let expectedInContext = [
        ("workplace and technical communication", "names the domain"),
        ("Slack messages", "names Slack"),
        ("bug reports", "names bug reports"),
        ("pull request summaries", "names pull requests"),
        ("product feedback", "names product feedback"),
        ("interview notes", "names interview notes"),
        ("social posts", "names social posts"),
        ("conversational", "asks for a conversational tone"),
        ("more formal than the original", "forbids over-formality"),
        ("intent", "preserves intent"),
        ("translate it into English", "translates non-English input"),
        ("exactly as written", "protects code and identifiers"),
        ("Preserve the existing structure", "preserves formatting"),
        ("Return only the rewritten text", "returns only the text"),
    ]
    for (needle, label) in expectedInContext {
        t.check(context.contains(needle), "style context \(label)")
    }

    for mode in RewriteMode.allCases {
        t.check(mode.instruction.contains(context), "\(mode.rawValue): instruction carries the shared style context")
        t.check(mode.instruction.contains(mode.task), "\(mode.rawValue): instruction carries its own task")
        t.check(mode.instruction.contains("translate it into English"),
                "\(mode.rawValue): non-English input is translated to English")
    }

    t.equal(Set(RewriteMode.allCases.map(\.task)).count, 4, "every mode has a distinct task")

    t.equal(RewriteMode.rewrite.defaultShortcut.display, "⌘⇧R", "rewrite defaults to ⌘⇧R")
    t.equal(RewriteMode.grammar.defaultShortcut.display, "⌘⇧G", "grammar defaults to ⌘⇧G")
    t.equal(RewriteMode.concise.defaultShortcut.display, "⌘⇧C", "concise defaults to ⌘⇧C")
    t.equal(RewriteMode.professional.defaultShortcut.display, "⌘⇧P", "professional defaults to ⌘⇧P")

    t.equal(Set(RewriteMode.allCases.map(\.defaultKeyCode)).count, 4, "default key codes do not collide")
    t.equal(Set(RewriteMode.allCases.map(\.shortcutKey)).count, 4, "menu key equivalents do not collide")

    // kVK_ANSI_R / G / C / P
    t.equal(RewriteMode.rewrite.defaultKeyCode, 15, "R maps to key code 15")
    t.equal(RewriteMode.grammar.defaultKeyCode, 5, "G maps to key code 5")
    t.equal(RewriteMode.concise.defaultKeyCode, 8, "C maps to key code 8")
    t.equal(RewriteMode.professional.defaultKeyCode, 35, "P maps to key code 35")

    for mode in RewriteMode.allCases {
        t.check(mode.defaultShortcut.isValid, "\(mode.rawValue): the default shortcut is valid")
    }
}
