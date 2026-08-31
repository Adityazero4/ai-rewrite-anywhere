import Foundation
@testable import PencilMarkCore

@MainActor
func runRewriteCoordinatorTests() async {
    t.suite("Rewrite coordinator")

    func makeCoordinator(reader: StubReader = StubReader(),
                         writer: StubWriter = StubWriter(),
                         service: StubRewriteService = StubRewriteService(result: .success("rewritten")),
                         errors: ErrorCollector = ErrorCollector()) -> RewriteCoordinator {
        RewriteCoordinator(reader: reader, writer: writer, service: service,
                           indicatorDelay: 0.02, onError: { errors.append($0) })
    }

    // Happy path
    do {
        let writer = StubWriter()
        let errors = ErrorCollector()
        let coordinator = makeCoordinator(writer: writer, errors: errors)

        t.check(await coordinator.run(.rewrite), "a successful rewrite reports success")
        t.equal(writer.written, ["rewritten"], "the model's output replaces the selection")
        t.check(errors.all.isEmpty, "a successful rewrite never interrupts the user")
    }

    // Capture failures
    for error in [RewriteError.noSelection, .emptySelection, .accessibilityDenied] {
        let writer = StubWriter()
        let errors = ErrorCollector()
        let coordinator = makeCoordinator(reader: StubReader(error: error), writer: writer, errors: errors)

        let replaced = await coordinator.run(.grammar)
        t.check(!replaced && writer.written.isEmpty, "\(error): nothing is written")
        t.equal(errors.all, [error], "\(error): is surfaced to the user")
    }

    // API failure
    do {
        let writer = StubWriter()
        let errors = ErrorCollector()
        let coordinator = makeCoordinator(
            writer: writer,
            service: StubRewriteService(result: .failure(.api(status: 401, message: "bad key"))),
            errors: errors
        )

        t.check(await coordinator.run(.rewrite) == false, "an API failure reports failure")
        t.check(writer.written.isEmpty, "a failed API call leaves the user's text alone")
        t.equal(errors.all, [.api(status: 401, message: "bad key")], "the API error is surfaced")
    }

    // Empty model response
    do {
        let writer = StubWriter()
        let errors = ErrorCollector()
        let coordinator = makeCoordinator(writer: writer,
                                          service: StubRewriteService(result: .failure(.emptyResponse)),
                                          errors: errors)
        _ = await coordinator.run(.rewrite)
        t.check(writer.written.isEmpty, "an empty model response replaces nothing")
        t.equal(errors.all, [.emptyResponse], "an empty model response is surfaced")
    }

    // Focus changed mid-flight
    do {
        let writer = StubWriter()
        writer.error = .focusChanged
        let errors = ErrorCollector()
        let coordinator = makeCoordinator(writer: writer, errors: errors)

        t.check(await coordinator.run(.rewrite) == false, "a focus change aborts the rewrite")
        t.equal(errors.all, [.focusChanged], "the focus change is explained to the user")
    }

    // Busy guard
    do {
        let reader = StubReader()
        let coordinator = makeCoordinator(reader: reader,
                                          service: StubRewriteService(result: .success("done"), delay: 0.25))

        async let first = coordinator.run(.rewrite)
        try? await Task.sleep(nanoseconds: 50_000_000)
        let second = await coordinator.run(.rewrite)

        t.check(await first, "the first trigger completes")
        t.check(second == false, "a double tap must not race for the clipboard")
        t.equal(reader.captureCount, 1, "the selection is only captured once")
    }

    // Loading indicator
    do {
        let coordinator = makeCoordinator(service: StubRewriteService(result: .success("done"), delay: 0.2))
        async let run = coordinator.run(.rewrite)
        try? await Task.sleep(nanoseconds: 120_000_000)
        t.check(coordinator.isWorking, "slow requests raise the loading indicator")
        _ = await run
        t.check(!coordinator.isWorking, "the indicator clears when the rewrite finishes")
    }

    do {
        let coordinator = makeCoordinator()
        _ = await coordinator.run(.rewrite)
        t.check(!coordinator.isWorking, "fast rewrites never flicker an indicator")
    }
}

final class ErrorCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [RewriteError] = []

    func append(_ error: RewriteError) { lock.lock(); storage.append(error); lock.unlock() }
    var all: [RewriteError] { lock.lock(); defer { lock.unlock() }; return storage }
}
