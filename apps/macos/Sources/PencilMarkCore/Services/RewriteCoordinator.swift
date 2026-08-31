import Combine
import Foundation

/// Orchestrates one rewrite: capture → model → replace.
///
/// Privacy: the selected text exists only as a local value for the duration of this call.
/// It is never logged and never written anywhere except the outgoing API request (and, on the
/// clipboard path, the clipboard — which is restored immediately afterwards).
@MainActor
public final class RewriteCoordinator: ObservableObject {
    /// True once a rewrite has been running long enough to be worth showing an indicator for.
    @Published public private(set) var isWorking = false

    private let reader: SelectionReading
    private let writer: SelectionWriting
    private let service: RewriteService
    private let onError: (RewriteError) -> Void
    private let indicatorDelay: TimeInterval

    private var inFlight = false

    public init(reader: SelectionReading,
                writer: SelectionWriting,
                service: RewriteService,
                indicatorDelay: TimeInterval = 0.4,
                onError: @escaping (RewriteError) -> Void) {
        self.reader = reader
        self.writer = writer
        self.service = service
        self.indicatorDelay = indicatorDelay
        self.onError = onError
    }

    /// Fire-and-forget entry point for hotkeys and menu items.
    public func trigger(_ mode: RewriteMode) {
        Task { await run(mode) }
    }

    /// Returns true if the rewrite completed and text was replaced.
    @discardableResult
    public func run(_ mode: RewriteMode) async -> Bool {
        // A second hotkey press while one is in flight would race for the clipboard. Ignore it.
        guard !inFlight else { return false }
        inFlight = true

        let indicator = Task { [indicatorDelay] in
            try? await Task.sleep(nanoseconds: UInt64(indicatorDelay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self.isWorking = true
        }

        defer {
            indicator.cancel()
            isWorking = false
            inFlight = false
        }

        do {
            let selection = try await reader.capture()
            let rewritten = try await service.rewrite(text: selection.text, mode: mode)
            try await writer.replace(rewritten, for: selection)
            return true
        } catch let error as RewriteError {
            onError(error)
        } catch is CancellationError {
            // Nothing to report.
        } catch {
            onError(.network(error.localizedDescription))
        }
        return false
    }
}
