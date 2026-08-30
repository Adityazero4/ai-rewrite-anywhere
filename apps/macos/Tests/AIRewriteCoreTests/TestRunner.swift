import Foundation
@testable import AIRewriteCore

/// A ~60 line assertion harness.
///
/// XCTest.framework ships only with Xcode, and SwiftPM can't load swift-testing bundles with just
/// the Command Line Tools installed, so the suite is a plain executable: `swift run AIRewriteCoreTests`.
final class TestReporter: @unchecked Sendable {
    private let lock = NSLock()
    private var suiteName = ""
    private(set) var passed = 0
    private(set) var failures: [String] = []

    func suite(_ name: String) {
        lock.lock(); suiteName = name; lock.unlock()
        print("\n\u{001B}[1m\(name)\u{001B}[0m")
    }

    func check(_ condition: Bool, _ label: String, _ detail: @autoclosure () -> String = "",
               file: StaticString = #filePath, line: UInt = #line) {
        let extra = condition ? "" : detail()
        lock.lock()
        if condition {
            passed += 1
        } else {
            let location = "\((("\(file)") as NSString).lastPathComponent):\(line)"
            failures.append("\(suiteName) › \(label)  [\(location)]" + (extra.isEmpty ? "" : "\n      \(extra)"))
        }
        lock.unlock()
        print(condition ? "  ✓ \(label)" : "  ✗ \(label)" + (extra.isEmpty ? "" : " — \(extra)"))
    }

    func equal<V: Equatable>(_ actual: V, _ expected: V, _ label: String,
                             file: StaticString = #filePath, line: UInt = #line) {
        check(actual == expected, label, "expected \(expected), got \(actual)", file: file, line: line)
    }

    func summarize() -> Int32 {
        print("\n" + String(repeating: "─", count: 60))
        if failures.isEmpty {
            print("\u{001B}[32m\(passed) checks passed.\u{001B}[0m")
            return 0
        }
        print("\u{001B}[31m\(failures.count) failed, \(passed) passed.\u{001B}[0m")
        for failure in failures { print("  • \(failure)") }
        return 1
    }
}

let t = TestReporter()

// MARK: - Throwing helpers

func expectThrows(_ expected: RewriteError, _ label: String,
                  file: StaticString = #filePath, line: UInt = #line,
                  _ body: () throws -> Void) {
    do {
        try body()
        t.check(false, label, "expected \(expected) but nothing was thrown", file: file, line: line)
    } catch let error as RewriteError {
        t.check(error == expected, label, "expected \(expected), got \(error)", file: file, line: line)
    } catch {
        t.check(false, label, "unexpected \(error)", file: file, line: line)
    }
}

func expectThrows(_ expected: RewriteError, _ label: String,
                  file: StaticString = #filePath, line: UInt = #line,
                  _ body: () async throws -> Void) async {
    do {
        try await body()
        t.check(false, label, "expected \(expected) but nothing was thrown", file: file, line: line)
    } catch let error as RewriteError {
        t.check(error == expected, label, "expected \(expected), got \(error)", file: file, line: line)
    } catch {
        t.check(false, label, "unexpected \(error)", file: file, line: line)
    }
}

/// For errors carrying values we don't want to spell out in full.
func expectThrows(matching predicate: @escaping (RewriteError) -> Bool, _ label: String,
                  file: StaticString = #filePath, line: UInt = #line,
                  _ body: () async throws -> Void) async {
    do {
        try await body()
        t.check(false, label, "expected a throw but nothing was thrown", file: file, line: line)
    } catch let error as RewriteError {
        t.check(predicate(error), label, "got \(error)", file: file, line: line)
    } catch {
        t.check(false, label, "unexpected \(error)", file: file, line: line)
    }
}
