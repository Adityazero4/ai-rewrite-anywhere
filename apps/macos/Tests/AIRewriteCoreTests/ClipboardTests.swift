import Foundation
@testable import AIRewriteCore

/// The clipboard is the user's, not ours. These pin the contract that we always give it back.
func runClipboardTests() async {
    t.suite("Clipboard restoration — replacing text")

    do {
        let board = FakePasteboard(initialString: "user's original clipboard")
        let service = TextReplacementService(pasteboard: board, pasteSettleDelay: 0.01, postPaste: { true })
        try await service.pasteViaClipboard("rewritten text")

        t.equal(board.string(), "user's original clipboard", "a successful paste restores the original clipboard")
        t.equal(board.writeCount, 1, "the rewritten text is staged exactly once")
        t.equal(board.restoreCount, 1, "the clipboard is restored exactly once")
    } catch {
        t.check(false, "a successful paste restores the original clipboard", "threw \(error)")
    }

    do {
        let board = FakePasteboard(initialString: "precious")
        let service = TextReplacementService(pasteboard: board, pasteSettleDelay: 0.01, postPaste: { false })

        await expectThrows(.pasteFailed, "a failed paste keystroke is reported") {
            try await service.pasteViaClipboard("rewritten")
        }
        t.equal(board.string(), "precious", "a failed paste must not eat the clipboard")
        t.equal(board.restoreCount, 1, "the clipboard is restored even when the paste never went out")
    }

    do {
        let imageData = Data([0x89, 0x50, 0x4E, 0x47])
        let board = FakePasteboard()
        board.seed(items: [["public.png": imageData]])

        let service = TextReplacementService(pasteboard: board, pasteSettleDelay: 0.01, postPaste: { true })
        try await service.pasteViaClipboard("rewritten")

        t.check(board.snapshot().items == [["public.png": imageData]],
                "non-text clipboard contents survive a rewrite")
        t.check(board.string() == nil, "the rewritten text is not left behind as a string")
    } catch {
        t.check(false, "non-text clipboard contents survive a rewrite", "threw \(error)")
    }

    do {
        let board = FakePasteboard()
        let service = TextReplacementService(pasteboard: board, pasteSettleDelay: 0.01, postPaste: { true })
        try await service.pasteViaClipboard("rewritten")
        t.check(board.snapshot().items.isEmpty, "an empty clipboard stays empty")
    } catch {
        t.check(false, "an empty clipboard stays empty", "threw \(error)")
    }

    t.suite("Clipboard restoration — capturing a selection")

    do {
        let board = FakePasteboard(initialString: "original")
        let service = TextSelectionService(pasteboard: board, copyTimeout: 1.0, postCopy: {
            board.seed(string: "the selected text")  // the target app answers ⌘C
            return true
        })

        let captured = await service.copyViaClipboard()
        t.equal(captured, "the selected text", "the copy fallback returns the selected text")
        t.equal(board.string(), "original", "the user's clipboard is put back after capture")
        t.equal(board.restoreCount, 1, "capture restores exactly once")
    }

    do {
        let board = FakePasteboard(initialString: "original")
        let service = TextSelectionService(pasteboard: board, copyTimeout: 0.1, postCopy: { true })

        t.check(await service.copyViaClipboard() == nil, "an unanswered ⌘C means nothing was selected")
        t.equal(board.string(), "original", "an empty selection leaves the clipboard alone")
        t.equal(board.restoreCount, 1, "the clipboard is restored after a failed capture")
    }

    do {
        let board = FakePasteboard(initialString: "original")
        let service = TextSelectionService(pasteboard: board, copyTimeout: 0.1, postCopy: { false })

        t.check(await service.copyViaClipboard() == nil, "an unsendable ⌘C gives up cleanly")
        t.equal(board.string(), "original", "the clipboard survives an unsendable keystroke")
    }

    t.suite("Clipboard snapshot fidelity")

    let board = FakePasteboard()
    board.seed(items: [
        ["public.utf8-plain-text": Data("hello".utf8), "public.rtf": Data(#"{\rtf1}"#.utf8)],
        ["public.file-url": Data("file:///tmp/a".utf8)],
    ])

    let snapshot = board.snapshot()
    board.write("clobbered")
    board.restore(snapshot)

    t.equal(board.snapshot().items.count, 2, "every pasteboard item is preserved")
    t.equal(board.snapshot().items[0].count, 2, "every type on an item is preserved")
    t.equal(board.string(), "hello", "the original text comes back")
}
