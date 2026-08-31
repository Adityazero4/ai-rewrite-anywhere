import Foundation

/// Every user-visible failure. Messages are written to be shown verbatim in an alert.
public enum RewriteError: LocalizedError, Equatable {
    case accessibilityDenied
    case missingAPIKey
    case noSelection
    case emptySelection
    case focusChanged
    case network(String)
    case api(status: Int, message: String)
    case emptyResponse
    case modelDeclined
    case selectionTooLong(count: Int, limit: Int)
    case pasteFailed
    case replacementFailed

    public var errorDescription: String? {
        switch self {
        case .accessibilityDenied:
            return "Pencil Mark needs Accessibility permission to read and replace selected text. Open Settings from the menu bar icon to grant it."
        case .missingAPIKey:
            return "No OpenAI API key set. Add one in Settings from the menu bar icon."
        case .noSelection:
            return "Couldn't read a selection from the frontmost app. Select some text and try again."
        case .emptySelection:
            return "The selected text is empty."
        case .focusChanged:
            return "You switched apps while the rewrite was running, so nothing was replaced. Your text and clipboard are untouched."
        case .network(let detail):
            return "Network error: \(detail)"
        case .api(let status, let message):
            return "OpenAI request failed (HTTP \(status)): \(message)"
        case .emptyResponse:
            return "The model returned an empty response. Nothing was replaced."
        case .modelDeclined:
            return "The model replied instead of rewriting your text, so nothing was replaced. Your selection is untouched. Try a different mode, or rephrase the text."
        case .selectionTooLong(let count, let limit):
            return "That selection is \(count) characters — over the \(limit) character limit. Select a smaller passage."
        case .pasteFailed:
            return "Couldn't send the paste keystroke to the frontmost app. Your clipboard has been restored."
        case .replacementFailed:
            return "Couldn't replace the text in the frontmost app."
        }
    }
}
