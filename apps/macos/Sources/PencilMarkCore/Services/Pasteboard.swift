import AppKit
import Foundation

/// Everything the app does to the clipboard, behind a protocol so tests can prove we always
/// restore what the user had.
public protocol PasteboardType: AnyObject {
    var changeCount: Int { get }
    func string() -> String?
    func snapshot() -> PasteboardSnapshot
    func restore(_ snapshot: PasteboardSnapshot)
    func write(_ string: String)
}

/// A deep copy of the clipboard: every item, every type, so images/RTF/files survive a rewrite.
public struct PasteboardSnapshot {
    /// One entry per pasteboard item: type identifier -> raw data.
    public let items: [[String: Data]]
    public init(items: [[String: Data]]) { self.items = items }
    public var isEmpty: Bool { items.allSatisfy { $0.isEmpty } }
}

public final class SystemPasteboard: PasteboardType {
    private let pasteboard: NSPasteboard

    public init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    public var changeCount: Int { pasteboard.changeCount }

    public func string() -> String? { pasteboard.string(forType: .string) }

    public func snapshot() -> PasteboardSnapshot {
        let items = (pasteboard.pasteboardItems ?? []).map { item -> [String: Data] in
            var copy: [String: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) { copy[type.rawValue] = data }
            }
            return copy
        }
        return PasteboardSnapshot(items: items)
    }

    public func restore(_ snapshot: PasteboardSnapshot) {
        pasteboard.clearContents()
        guard !snapshot.items.isEmpty else { return }
        let items = snapshot.items.map { stored -> NSPasteboardItem in
            let item = NSPasteboardItem()
            for (type, data) in stored {
                item.setData(data, forType: NSPasteboard.PasteboardType(type))
            }
            return item
        }
        pasteboard.writeObjects(items)
    }

    public func write(_ string: String) {
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }
}
