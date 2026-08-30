import Foundation
@testable import AIRewriteCore

// MARK: - Pasteboard

final class FakePasteboard: PasteboardType {
    private(set) var contents: [[String: Data]] = []
    private(set) var restoreCount = 0
    private(set) var writeCount = 0
    var changeCount: Int = 0

    init(initialString: String? = nil) {
        if let initialString { seed(string: initialString) }
    }

    func seed(string: String) {
        contents = [["public.utf8-plain-text": Data(string.utf8)]]
        changeCount += 1
    }

    func seed(items: [[String: Data]]) {
        contents = items
        changeCount += 1
    }

    func string() -> String? {
        guard let data = contents.first?["public.utf8-plain-text"] else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func snapshot() -> PasteboardSnapshot { PasteboardSnapshot(items: contents) }

    func restore(_ snapshot: PasteboardSnapshot) {
        contents = snapshot.items
        changeCount += 1
        restoreCount += 1
    }

    func write(_ string: String) {
        contents = [["public.utf8-plain-text": Data(string.utf8)]]
        changeCount += 1
        writeCount += 1
    }
}

// MARK: - HTTP

struct StubTransport: HTTPTransport {
    let body: Data
    let status: Int
    let error: Error?
    /// Captures the request that was sent, for assertions.
    let inspector: (@Sendable (URLRequest) -> Void)?

    init(body: Data = Data(), status: Int = 200, error: Error? = nil,
         inspector: (@Sendable (URLRequest) -> Void)? = nil) {
        self.body = body
        self.status = status
        self.error = error
        self.inspector = inspector
    }

    init(json: String, status: Int = 200) {
        self.init(body: Data(json.utf8), status: status)
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        inspector?(request)
        if let error { throw error }
        let response = HTTPURLResponse(url: request.url!, statusCode: status,
                                       httpVersion: nil, headerFields: nil)!
        return (body, response)
    }
}

// MARK: - Secrets

final class InMemorySecretStore: SecretStore {
    private var storage: [String: String] = [:]
    var failWrites = false

    func secret(for account: String) -> String? { storage[account] }

    func setSecret(_ value: String, for account: String) -> Bool {
        if failWrites { return false }
        storage[account] = value
        return true
    }

    func deleteSecret(for account: String) -> Bool {
        storage[account] = nil
        return true
    }
}

// MARK: - Coordinator collaborators

final class StubReader: SelectionReading {
    var result: Result<Selection, RewriteError>
    private(set) var captureCount = 0

    init(text: String = "hello", method: Selection.Method = .clipboard) {
        result = .success(Selection(text: text, pid: 42, appName: "Test", method: method))
    }

    init(error: RewriteError) { result = .failure(error) }

    func capture() async throws -> Selection {
        captureCount += 1
        return try result.get()
    }
}

final class StubWriter: SelectionWriting {
    var error: RewriteError?
    private(set) var written: [String] = []

    func replace(_ text: String, for selection: Selection) async throws {
        written.append(text)
        if let error { throw error }
    }
}

struct StubRewriteService: RewriteService {
    let result: Result<String, RewriteError>
    /// Optional delay so the busy-guard test has a window to fire a second trigger.
    var delay: TimeInterval = 0

    func rewrite(text: String, mode: RewriteMode) async throws -> String {
        if delay > 0 { try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        return try result.get()
    }
}
