import Foundation
@testable import AIRewriteCore

private func makeClient(transport: HTTPTransport,
                        key: String? = "sk-test",
                        model: String = "gpt-4.1-mini") -> OpenAIClient {
    OpenAIClient(transport: transport, apiKey: { key }, model: { model })
}

private func bodyJSON(_ request: URLRequest?) -> [String: Any] {
    guard let data = request?.httpBody,
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return [:] }
    return json
}

func runOpenAIClientTests() async {
    t.suite("OpenAI Responses API — request construction")

    do {
        let request = try makeClient(transport: StubTransport()).makeRequest(text: "hello world", mode: .concise)
        t.equal(request.url?.absoluteString, "https://api.openai.com/v1/responses", "posts to /v1/responses")
        t.equal(request.httpMethod, "POST", "uses POST")
        t.equal(request.value(forHTTPHeaderField: "Authorization"), "Bearer sk-test", "sends the bearer token")
        t.equal(request.value(forHTTPHeaderField: "Content-Type"), "application/json", "sends JSON")

        let body = bodyJSON(request)
        t.equal(body["model"] as? String, "gpt-4.1-mini", "sends the configured model")
        t.equal(body["input"] as? String, "hello world", "sends the selected text as input")
        t.equal(body["instructions"] as? String, RewriteMode.concise.instruction, "sends the mode's instruction")
        t.equal(body["store"] as? Bool, false, "asks OpenAI not to retain the text")
    } catch {
        t.check(false, "builds a request", "threw \(error)")
    }

    do {
        let request = try makeClient(transport: StubTransport(), model: "some-other-model")
            .makeRequest(text: "x", mode: .rewrite)
        t.equal(bodyJSON(request)["model"] as? String, "some-other-model",
                "uses the configured model rather than a hardcoded one")
    } catch {
        t.check(false, "honours a custom model", "threw \(error)")
    }

    await expectThrows(.missingAPIKey, "a missing API key throws before any network call") {
        _ = try await makeClient(transport: StubTransport(), key: nil).rewrite(text: "hi", mode: .rewrite)
    }

    await expectThrows(.missingAPIKey, "a blank API key is treated as missing") {
        _ = try await makeClient(transport: StubTransport(), key: "   ").rewrite(text: "hi", mode: .rewrite)
    }

    // MARK: - Parsing

    t.suite("OpenAI Responses API — response parsing")

    func parse(_ payload: String, _ label: String, expect expected: String) {
        do {
            t.equal(try OpenAIClient.parseOutputText(from: Data(payload.utf8)), expected, label)
        } catch {
            t.check(false, label, "threw \(error)")
        }
    }

    parse("""
          {"status":"completed","output":[{"type":"message","role":"assistant",
           "content":[{"type":"output_text","text":"Rewritten text."}]}]}
          """,
          "parses a normal response", expect: "Rewritten text.")

    parse("""
          {"status":"completed","output":[
            {"type":"reasoning","summary":[]},
            {"type":"message","content":[{"type":"output_text","text":"The answer."}]}]}
          """,
          "skips reasoning items that precede the message", expect: "The answer.")

    parse("""
          {"output":[{"type":"message","content":[
            {"type":"refusal","refusal":"nope"},
            {"type":"output_text","text":"Hello "},
            {"type":"output_text","text":"world."}]}]}
          """,
          "concatenates output_text parts and ignores other types", expect: "Hello world.")

    parse(#"{"output":[{"type":"message","content":[{"type":"output_text","text":"\n  Trimmed.  \n"}]}]}"#,
          "trims surrounding whitespace", expect: "Trimmed.")

    // MARK: - Empty responses

    t.suite("OpenAI Responses API — empty responses")

    let emptyPayloads = [
        (#"{"output":[]}"#, "an empty output array"),
        (#"{"status":"completed"}"#, "a missing output key"),
        (#"{"output":[{"type":"message","content":[{"type":"output_text","text":"   "}]}]}"#, "whitespace-only text"),
        (#"{"output":[{"type":"reasoning","summary":[]}]}"#, "reasoning with no message"),
    ]
    for (payload, description) in emptyPayloads {
        expectThrows(.emptyResponse, "\(description) is reported as an empty response") {
            _ = try OpenAIClient.parseOutputText(from: Data(payload.utf8))
        }
    }

    do {
        _ = try OpenAIClient.parseOutputText(from: Data(#"{"status":"incomplete","output":[]}"#.utf8))
        t.check(false, "an incomplete response explains itself", "nothing was thrown")
    } catch let error as RewriteError {
        if case .api(_, let message) = error {
            t.check(message.contains("incomplete"), "an incomplete response explains itself", message)
        } else {
            t.check(false, "an incomplete response explains itself", "got \(error)")
        }
    } catch {
        t.check(false, "an incomplete response explains itself", "unexpected \(error)")
    }

    expectThrows(.api(status: 200, message: "Could not parse the API response."),
                 "an unparseable body is reported as an API error") {
        _ = try OpenAIClient.parseOutputText(from: Data("not json".utf8))
    }

    // MARK: - API errors

    t.suite("OpenAI Responses API — error handling")

    await expectThrows(.api(status: 401, message: "Incorrect API key provided."),
                       "surfaces the server's message on 401") {
        let body = #"{"error":{"message":"Incorrect API key provided.","type":"invalid_request_error"}}"#
        _ = try await makeClient(transport: StubTransport(json: body, status: 401)).rewrite(text: "hi", mode: .rewrite)
    }

    await expectThrows(.api(status: 429, message: "Rate limit reached."),
                       "surfaces rate-limit messages") {
        let body = #"{"error":{"message":"Rate limit reached."}}"#
        _ = try await makeClient(transport: StubTransport(json: body, status: 429)).rewrite(text: "hi", mode: .rewrite)
    }

    await expectThrows(.api(status: 500, message: "upstream exploded"),
                       "falls back to the raw body when the error isn't JSON") {
        _ = try await makeClient(transport: StubTransport(json: "upstream exploded", status: 500))
            .rewrite(text: "hi", mode: .rewrite)
    }

    await expectThrows(matching: { if case .api(let status, let message) = $0 { return status == 503 && !message.isEmpty }; return false },
                       "falls back to the status line when the body is empty") {
        _ = try await makeClient(transport: StubTransport(body: Data(), status: 503)).rewrite(text: "hi", mode: .rewrite)
    }

    t.equal(OpenAIClient.errorMessage(from: Data(String(repeating: "x", count: 5_000).utf8), status: 500).count,
            200, "error messages never leak an unbounded body")

    for code in [URLError.Code.notConnectedToInternet, .timedOut, .cannotFindHost, .networkConnectionLost] {
        await expectThrows(matching: { if case .network(let detail) = $0 { return !detail.isEmpty }; return false },
                           "URLError.\(code.rawValue) becomes a network error") {
            _ = try await makeClient(transport: StubTransport(error: URLError(code))).rewrite(text: "hi", mode: .rewrite)
        }
    }

    // MARK: - Happy path

    t.suite("OpenAI Responses API — end to end")

    do {
        let payload = #"{"output":[{"type":"message","content":[{"type":"output_text","text":"Polished."}]}]}"#
        let result = try await makeClient(transport: StubTransport(json: payload)).rewrite(text: "raw", mode: .professional)
        t.equal(result, "Polished.", "returns only the rewritten text")
    } catch {
        t.check(false, "returns only the rewritten text", "threw \(error)")
    }

    do {
        let seen = LockedBox<URLRequest>()
        let payload = #"{"output":[{"type":"message","content":[{"type":"output_text","text":"ok"}]}]}"#
        let client = makeClient(transport: StubTransport(body: Data(payload.utf8), status: 200,
                                                         error: nil, inspector: { seen.value = $0 }))
        _ = try await client.rewrite(text: "raw", mode: .grammar)
        t.equal(bodyJSON(seen.value)["instructions"] as? String, RewriteMode.grammar.instruction,
                "the prompt sent matches the mode that was triggered")
    } catch {
        t.check(false, "the prompt sent matches the mode that was triggered", "threw \(error)")
    }
}

/// Thread-safe box so a `@Sendable` inspector closure can hand a value back.
final class LockedBox<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: T?
    var value: T? {
        get { lock.lock(); defer { lock.unlock() }; return stored }
        set { lock.lock(); stored = newValue; lock.unlock() }
    }
}
