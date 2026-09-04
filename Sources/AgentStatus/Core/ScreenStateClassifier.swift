//
//  ScreenStateClassifier.swift
//  AgentStatus
//
//  The no-hooks fallback for "is the agent waiting on me?". Hooks are the truth when they
//  are installed; without them an agent blocked on a permission prompt and an agent thinking
//  have the same foreground process, so the only other evidence is what is ON THE SCREEN.
//  This reads the bottom rows of the terminal and looks for the shapes every agent CLI's
//  prompt takes: a numbered choice with a cursor, a y/n question, an explicit "Allow …?".
//  Deliberately narrow — a false "Needs you" teaches the user to ignore the rail — and it
//  stands down entirely the moment a hook has spoken for the run.
//

import Foundation

public enum ScreenStateClassifier {
    /// Numbered choice with a selection cursor: Claude Code ("❯ 1. Yes"), Gemini ("● 1. Yes,
    /// allow once"), Codex ("> 1. Yes").
    private static let numberedChoice = try! NSRegularExpression(pattern: #"^\s*[❯>●▸►]\s*\d+\.\s"#)
    /// A yes/no question in any of the usual spellings.
    private static let yesNo = try! NSRegularExpression(pattern: #"(\(y/n\)|\[y/n\]|\[Y/n\]|\[y/N\]|\(yes/no\))"#, options: [.caseInsensitive])
    /// Plain-language permission prompts — only when phrased as a question.
    private static let asks: [String] = [
        "do you want to proceed", "do you want to make this edit", "do you want to allow",
        "allow execution", "allow this", "allow once", "approve", "permission",
        "press enter to continue", "waiting for your", "what would you like to do",
    ]
    private static let workingMarkers: [String] = ["esc to interrupt", "esc to cancel", "ctrl+c to interrupt", "ctrl-c to interrupt"]

    /// Classifies the bottom rows of a screen (top→bottom order). Nil when nothing on screen
    /// says either way — which is most of the time, and the honest answer.
    public static func classify(_ rows: [String]) -> ScreenState? {
        let trimmed = rows.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard !trimmed.isEmpty else { return nil }
        let lower = trimmed.map { $0.lowercased() }
        // A prompt outranks a working marker: Claude keeps "esc to interrupt" on screen
        // while its permission dialog is up, and the dialog is what matters.
        for (i, line) in trimmed.enumerated() {
            let range = NSRange(line.startIndex..., in: line)
            if numberedChoice.firstMatch(in: line, range: range) != nil { return .waitingForInput }
            if yesNo.firstMatch(in: line, range: range) != nil { return .waitingForInput }
            if asks.contains(where: { lower[i].contains($0) }), lower[i].contains("?") || lower[i].hasSuffix(":") { return .waitingForInput }
        }
        if lower.contains(where: { l in workingMarkers.contains(where: { l.contains($0) }) }) { return .working }
        return nil
    }
}
