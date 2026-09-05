//
//  AgentActivity.swift
//  AgentStatus
//
//  What the agent is doing, per its hooks — `TerminalController.activity`.
//
//  Created by David Sherlock on 9/5/26.
//

import Foundation

/// What the agent is doing, per its hooks — `TerminalController.activity`.
public struct AgentActivity: Equatable, Sendable {
    public let tool: String
    public let summary: String
    public let since: Date
    public var isFinished: Bool
    public init(tool: String, summary: String, since: Date, isFinished: Bool) {
        self.tool = tool; self.summary = summary; self.since = since; self.isFinished = isFinished
    }
    /// "Bash ./scripts/test.sh" — the tool alone when it took nothing showable.
    public var label: String { summary.isEmpty ? tool : "\(tool) \(summary)" }
}
