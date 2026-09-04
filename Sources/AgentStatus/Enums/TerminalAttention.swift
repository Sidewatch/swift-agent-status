import Foundation

/// Kept separate from ``TerminalStatus`` because it is a different KIND of fact: status is
/// observed continuously from the process table, while this is an event that arrived once and
/// stays true until you look. Merging them would mean re-deriving an event on every poll.
public enum TerminalAttention: Equatable, Sendable {
    /// A `Notification` hook — permission prompt or question. Nothing moves until you answer.
    case waiting
    /// A `Stop` hook — the turn finished.
    case done
}

/// One terminal's row in the rail: identity, how to name it, what it is doing, and where.
///
