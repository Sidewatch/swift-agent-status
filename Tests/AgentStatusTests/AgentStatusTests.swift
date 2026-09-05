//
//  AgentStatusTests.swift
//  AgentStatusTests
//
//  Ported from Sidewatch's --dump-terminal-status: the rules, calling the REAL derivation.
//
//  Created by David Sherlock on 9/5/26.
//

import XCTest
@testable import AgentStatus

/// Ported from Sidewatch's --dump-terminal-status: the rules, calling the REAL derivation.
final class AgentStatusTests: XCTestCase {
    func testAgentWhitelistByNameExactNamesAndNeverGenericRuntimes() {
        for name in ["claude", "Claude", "claude-code", "codex", "aider", "goose", "opencode", "hermes", "grok", "grok-cli", "pi"] {
            XCTAssertTrue(TerminalStatus.isAgentProcess(name), name)
        }
        for name in ["node", "python3", "vim", "npm", "cargo", "swift", "", "bash", "pip", "ping", "pigz", "pipx"] {
            XCTAssertFalse(TerminalStatus.isAgentProcess(name), "\(name) is not an agent (pi is exact-only)")
        }
        XCTAssertFalse(TerminalStatus.isAgentProcess(nil))
    }

    func testScreenStateFallbackReadsPromptsAndWorkingMarkers() {
        let screens: [(String, [String], ScreenState?)] = [
            ("claude permission dialog", ["Do you want to make this edit to main.swift?", "❯ 1. Yes", "  2. Yes, and don't ask again this session", "  3. No"], .waitingForInput),
            ("claude working", ["✻ Baking… (esc to interrupt)", "", "> "], .working),
            ("gemini allow prompt", ["Allow execution of 'rm -rf build'?", "● 1. Yes, allow once", "  2. Yes, allow always", "  3. No (esc)"], .waitingForInput),
            ("codex y/n", ["Run `npm test`? [y/N]"], .waitingForInput),
            ("plain shell prompt", ["user@mac proj % "], nil),
            ("agent output, nothing asked", ["Found 3 TODO comments in src/:", "- src/main.py:7 — read config_path from argv"], nil),
            ("numbered list without cursor is not a prompt", ["1. Initial commit", "2. Added parser"], nil),
            ("empty screen", ["", "", ""], nil),
        ]
        for (label, rows, want) in screens { XCTAssertEqual(ScreenStateClassifier.classify(rows), want, label) }
    }

    private func status(_ busy: Bool, _ process: String?, _ path: String?, _ args: String?, unseen: Bool) -> TerminalStatus {
        TerminalStatus.derive(foreground: ForegroundInfo(isBusy: busy, process: process, processPath: path, processArgs: args),
                              unseenCompletion: unseen, attention: nil)
    }

    func testDerivationCoversTheThreeInstallShapesAndTheFalsePositives() {
        XCTAssertEqual(status(false, nil, nil, nil, unseen: false), .idle)
        XCTAssertEqual(status(true, "claude", nil, nil, unseen: false), .agent)
        XCTAssertEqual(status(true, "cargo", nil, nil, unseen: false), .running)
        XCTAssertEqual(status(false, nil, nil, nil, unseen: true), .finished)
        XCTAssertEqual(status(true, "claude", nil, nil, unseen: true), .agent, "busy outranks a pending notice")
        XCTAssertEqual(status(true, "2.1.223", "/Users/x/.local/share/claude/versions/2.1.223", nil, unseen: false), .agent, "native: the binary is a version number; the PATH says claude")
        XCTAssertEqual(status(true, "node", "/usr/local/bin/node", "node /usr/local/lib/node_modules/@openai/codex/bin/codex.js", unseen: false), .agent, "npm: only the ARGS say codex")
        XCTAssertEqual(status(true, "python3", "/opt/homebrew/bin/python3", "python3 /opt/homebrew/bin/aider --model gpt-4", unseen: false), .agent)
        XCTAssertEqual(status(true, "vim", "/Users/x/claude-notes/bin/vim", nil, unseen: false), .running, "a project merely named claude-notes")
        XCTAssertEqual(status(true, "node", "/usr/local/bin/node", "node server.js", unseen: false), .running)
        XCTAssertEqual(status(true, "python3", "/opt/homebrew/bin/python3", "python3 manage.py", unseen: false), .running)
    }

    func testAttentionOutranksTheProcessAndNeedsYouSortsFirst() {
        let running = ForegroundInfo(isBusy: true, process: "claude", processPath: nil, processArgs: nil)
        XCTAssertEqual(TerminalStatus.derive(foreground: running, unseenCompletion: false, attention: .waiting), .waiting)
        XCTAssertEqual(TerminalStatus.derive(foreground: running, unseenCompletion: false, attention: .done), .finished)
        XCTAssertEqual(TerminalStatus.derive(foreground: running, unseenCompletion: false, attention: nil), .agent)
        XCTAssertEqual([TerminalStatus.idle, .running, .agent, .finished, .waiting].sorted { $0.priority < $1.priority }, [.waiting, .finished, .agent, .running, .idle])
        XCTAssertEqual([TerminalStatus.idle, .running, .agent, .finished, .waiting].filter(\.isActionable), [.finished, .waiting])
        XCTAssertEqual([TerminalStatus.idle, .running, .agent, .finished, .waiting].filter(\.impliesAgent), [.agent, .finished, .waiting])
    }

    func testCommandNameComesFromArgvNotTheExecutable() {
        let cases: [(String?, String?)] = [
            ("claude", "claude"),
            ("/Users/x/.local/share/claude/versions/2.1.223", "2.1.223"),
            ("node /opt/homebrew/lib/node_modules/@openai/codex/cli.js", "codex"),
            ("node /Users/x/.npm/lib/node_modules/@anthropic-ai/claude-code/cli.js", "claude-code"),
            ("python3 /opt/homebrew/bin/aider --model gpt-4", "aider"),
            ("node server.js", "server"),
            ("cargo build --release", "cargo"),
            ("vim README.md", "vim"),
            (nil, nil), ("", nil),
        ]
        for (args, want) in cases { XCTAssertEqual(AgentProcess.commandName(fromArgs: args), want, args ?? "nil") }
    }
}
