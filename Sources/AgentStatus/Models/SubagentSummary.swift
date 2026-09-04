import Foundation

/// One live subagent under an agent row: "⤷ Explore · 12s".
public struct SubagentSummary: Equatable, Sendable {
    public let id: String
    public let type: String?
    public let since: Date
    public init(id: String, type: String?, since: Date) { self.id = id; self.type = type; self.since = since }
}
