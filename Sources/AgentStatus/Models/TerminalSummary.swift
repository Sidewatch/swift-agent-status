//
//  TerminalSummary.swift
//  AgentStatus
//
//  A flat snapshot rather than a live reference, so the pane renders from a value and cannot
//  accidentally keep a closed terminal alive.
//
//  Created by David Sherlock on 9/5/26.
//

import Foundation

/// A flat snapshot rather than a live reference, so the pane renders from a value and cannot
/// accidentally keep a closed terminal alive.
public struct TerminalSummary: Equatable, Sendable {
    public let id: UUID
    /// What to call it: the manual rename, else the shell/agent title — and
    /// where that would only say "zsh", the directory's name instead. A column of identical
    /// "zsh" rows identifies nothing, which is the one job the name has here.
    public let name: String
    /// The foreground process's working directory as a real URL (`directory` is the
    /// abbreviated display form). For a terminal running an agent this is the folder the
    /// agent files its transcript under — `MainWindowController.agentRootCandidates`
    /// puts it first. Defaulted so the harness's hand-built summaries need not set it.
    public var cwd: URL? = nil
    /// When it entered this status, so the row can say how long it has been that way.
    public let statusSince: Date
    public let status: TerminalStatus
    public let branch: String?
    public let directory: String?
    /// The foreground process, when one is running.
    public let process: String?
    /// Its executable path — how an agent whose binary is named after its version is recognised.
    public let processPath: String?
    /// Its argv, gathered only for generic runtimes — how an npm/pip-installed agent is recognised.
    public let processArgs: String?
    /// Uncommitted line changes in this terminal's repo, or nil when it isn't in one / not
    /// yet gathered.
    public var insertions: Int?
    public var deletions: Int?
    /// The repo root, so the pane can gather the diff stat off-main without re-deriving it.
    public let repoRoot: URL?
    /// What the agent is doing right now, from its hooks: "Bash ./scripts/test.sh",
    /// "Edit src/main.py". Nil without hooks or between turns.
    public var activity: String? = nil
    /// When the current turn began (UserPromptSubmit / BeforeAgent) — the working clock.
    public var workingSince: Date? = nil
    /// Claude Code subagents alive under this terminal's session, oldest first.
    public var subagents: [SubagentSummary] = []

    public init(id: UUID, name: String, cwd: URL? = nil, statusSince: Date, status: TerminalStatus, branch: String?,
                directory: String?, process: String?, processPath: String?, processArgs: String?,
                insertions: Int? = nil, deletions: Int? = nil, repoRoot: URL?, activity: String? = nil,
                workingSince: Date? = nil, subagents: [SubagentSummary] = []) {
        self.id = id; self.name = name; self.cwd = cwd; self.statusSince = statusSince; self.status = status
        self.branch = branch; self.directory = directory; self.process = process; self.processPath = processPath
        self.processArgs = processArgs; self.insertions = insertions; self.deletions = deletions; self.repoRoot = repoRoot
        self.activity = activity; self.workingSince = workingSince; self.subagents = subagents
    }
}
