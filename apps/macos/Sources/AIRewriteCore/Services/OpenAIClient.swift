import Foundation

/// The abstraction the rest of the app talks to. Swap in another provider by conforming to this.
public protocol RewriteService: Sendable {
    func rewrite(text: String, mode: RewriteMode) async throws -> String
}

/// Injectable transport so response parsing and error mapping are unit-testable without network.
public protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct URLSessionTransport: HTTPTransport {
    private let session: URLSession

    public init(timeout: TimeInterval = 30) {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        config.urlCache = nil  // never cache the user's text
        session = URLSession(configuration: config)
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw RewriteError.network("Unexpected response from server.")
        }
        return (data, http)
    }
}

/// Client for the OpenAI Responses API (POST /v1/responses).
///
/// Privacy: the selected text is only ever placed in the request body. It is never logged,
/// never written to disk, and `store: false` asks OpenAI not to retain the response.
public struct OpenAIClient: RewriteService {
    public static let defaultEndpoint = URL(string: "https://api.openai.com/v1/responses")!

    /// Selections above this are refused before any request is made. Guards against accidentally
    /// sending a whole document (⌘A then the shortcut) and against runaway cost.
    public static let maxInputCharacters = 8_000

    private let endpoint: URL
    private let transport: HTTPTransport
    private let apiKeyProvider: @Sendable () -> String?
    private let modelProvider: @Sendable () -> String

    public init(endpoint: URL = OpenAIClient.defaultEndpoint,
                transport: HTTPTransport = URLSessionTransport(),
                apiKey: @escaping @Sendable () -> String?,
                model: @escaping @Sendable () -> String) {
        self.endpoint = endpoint
        self.transport = transport
        self.apiKeyProvider = apiKey
        self.modelProvider = model
    }

    // MARK: - Request

    public func makeRequest(text: String, mode: RewriteMode) throws -> URLRequest {
        guard let key = apiKeyProvider()?.trimmingCharacters(in: .whitespacesAndNewlines), !key.isEmpty else {
            throw RewriteError.missingAPIKey
        }
        guard text.count <= Self.maxInputCharacters else {
            throw RewriteError.selectionTooLong(count: text.count, limit: Self.maxInputCharacters)
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": modelProvider(),
            "instructions": mode.instruction,
            "input": text,
            "store": false,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])
        return request
    }

    // MARK: - Call

    public func rewrite(text: String, mode: RewriteMode) async throws -> String {
        let request = try makeRequest(text: text, mode: mode)

        let data: Data
        let http: HTTPURLResponse
        do {
            (data, http) = try await transport.send(request)
        } catch let error as RewriteError {
            throw error
        } catch let error as URLError {
            throw RewriteError.network(error.localizedDescription)
        } catch {
            throw RewriteError.network(error.localizedDescription)
        }

        guard (200..<300).contains(http.statusCode) else {
            throw RewriteError.api(status: http.statusCode, message: Self.errorMessage(from: data, status: http.statusCode))
        }

        let output = try Self.parseOutputText(from: data)

        // The model is told to return only rewritten text, but it can still answer
        // conversationally — usually when the selection is rude or reads like a question aimed
        // at it. Pasting that would replace the user's writing with a chat message.
        guard !Self.looksLikeConversationalReply(output: output, input: text) else {
            throw RewriteError.modelDeclined
        }
        return output
    }

    // MARK: - Output guard

    /// Phrases that only ever appear when the model is talking *as an assistant*.
    private static let assistantTells = [
        "as an ai", "i'm an ai", "i am an ai", "language model",
        "i can't assist", "i cannot assist",
        "i can't help with", "i cannot help with",
        "i'm here to help", "i am here to help",
    ]

    /// Phrases that are suspicious but appear in ordinary prose too — "I'm unable to join the
    /// call" is a perfectly good rewrite. These only count alongside a task word.
    private static let hedgeTells = [
        "i'm unable", "i am unable", "i won't be able", "i will not be able",
        "sorry, but i", "i'm sorry, but", "i apologize, but", "i apologise, but",
        "please share", "please provide", "let me know what", "if you have any text",
    ]

    /// Vocabulary that means the sentence is about the rewriting job rather than about the
    /// user's own life. "I can't come tomorrow" is content; "I can't rewrite that" is a refusal.
    private static let taskWords = [
        "rewrite", "rewritten", "rewriting", "assist", "request", "content",
        "the text", "your text", "respectful", "appropriate",
    ]

    /// True when the model answered the user instead of transforming their text.
    ///
    /// An earlier version compared output and input lengths. That was wrong: a refusal is often
    /// about the same length as what it refuses, so real refusals slipped through. What actually
    /// separates the two is vocabulary — a refusal talks about the *task*, a rewrite talks about
    /// whatever the user was writing about.
    ///
    /// Tuned to over-block rather than under-block. A false positive shows an alert and pastes
    /// nothing, so the user retries; a false negative overwrites their writing with a chat reply.
    public static func looksLikeConversationalReply(output: String, input: String) -> Bool {
        let lowered = output.lowercased()

        if assistantTells.contains(where: { lowered.contains($0) }) { return true }

        let hedged = hedgeTells.contains(where: { lowered.contains($0) })
        let aboutTheTask = taskWords.contains(where: { lowered.contains($0) })
        return hedged && aboutTheTask
    }

    // MARK: - Parsing

    /// Walks `output[]` for assistant `message` items and concatenates their `output_text` parts.
    /// Reasoning models emit a `reasoning` item first, so we must scan rather than take `output[0]`.
    public static func parseOutputText(from data: Data) throws -> String {
        let payload: ResponsesPayload
        do {
            payload = try JSONDecoder().decode(ResponsesPayload.self, from: data)
        } catch {
            throw RewriteError.api(status: 200, message: "Could not parse the API response.")
        }

        if let apiError = payload.error?.message, !apiError.isEmpty {
            throw RewriteError.api(status: 200, message: apiError)
        }

        let text = (payload.output ?? [])
            .filter { $0.type == "message" }
            .flatMap { $0.content ?? [] }
            .filter { $0.type == "output_text" }
            .compactMap { $0.text }
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            if payload.status == "incomplete" {
                throw RewriteError.api(status: 200, message: "The model stopped before finishing (incomplete response).")
            }
            throw RewriteError.emptyResponse
        }
        return text
    }

    static func errorMessage(from data: Data, status: Int) -> String {
        if let payload = try? JSONDecoder().decode(ResponsesPayload.self, from: data),
           let message = payload.error?.message, !message.isEmpty {
            return message
        }
        if let raw = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !raw.isEmpty {
            return String(raw.prefix(200))
        }
        return HTTPURLResponse.localizedString(forStatusCode: status)
    }

    // MARK: - Wire format

    struct ResponsesPayload: Decodable {
        let status: String?
        let output: [OutputItem]?
        let error: APIError?
    }

    struct OutputItem: Decodable {
        let type: String?
        let content: [ContentPart]?
    }

    struct ContentPart: Decodable {
        let type: String?
        let text: String?
    }

    struct APIError: Decodable {
        let message: String?
        let type: String?
        let code: String?
    }
}
