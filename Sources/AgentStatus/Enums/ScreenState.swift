import Foundation

public enum ScreenState: Equatable, Sendable {
    /// A prompt is on screen: the agent is blocked until the user answers.
    case waitingForInput
    /// The agent's own "esc to interrupt" (or equivalent) is showing: it is working.
    case working
}
