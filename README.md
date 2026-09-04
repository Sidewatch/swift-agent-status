# Swift Agent Status

What a terminal is doing, as a rail beside it should report it: idle, running something, running a coding agent, waiting on you, or finished — derived from the pty's foreground process (name, executable path, argv) plus the signals an agent's hooks deliver, with a screen-scrape fallback for agents that have no hooks.

Extracted from Sidewatch, where it drives the Terminals rail for Claude Code, Codex, Gemini CLI, OpenCode, Aider, Hermes, Grok and pi.

## Features

- 🧭 **Status derivation** — `TerminalStatus.derive(foreground:unseenCompletion:attention:)`: one rule, no defaulted parameters, hook signals outranking the process table
- 🕵️ **Agent recognition** — a deliberate whitelist across the three install shapes: by name (`codex`), by executable path (`…/claude/versions/2.1.223`), by argv (`node …/@openai/codex/cli.js`); exact-only for names too short to prefix-match (`pi`)
- 🏷️ **Command naming from argv** — `AgentProcess.commandName(fromArgs:)`: "codex", not "node"; "claude", not a version number
- 👀 **Screen-state fallback** — `ScreenStateClassifier.classify(rows)`: a numbered choice with a cursor, a y/n question, an explicit "Allow …?" → waiting; "esc to interrupt" → working; nil otherwise (the honest answer, most of the time)
- 📋 **Row models** — `TerminalSummary`, `SubagentSummary`, `AgentActivity`, `ForegroundInfo`, `TerminalAttention`; all `Sendable` values
- 🪶 **Zero dependencies** — Foundation only; colours and fonts are the host's

## Requirements

- macOS 14+
- Swift 6.2+ (Swift 6 language mode)

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/Sidewatch/swift-agent-status.git", from: "0.1.0")
]
```

## Usage

```swift
import AgentStatus

let fg = ForegroundInfo(isBusy: true, process: "node", processPath: "/usr/local/bin/node",
                        processArgs: "node /usr/local/lib/node_modules/@openai/codex/bin/codex.js")
TerminalStatus.derive(foreground: fg, unseenCompletion: false, attention: nil)   // .agent
AgentProcess.commandName(fromArgs: fg.processArgs)                                // "codex"

ScreenStateClassifier.classify(["Run `npm test`? [y/N]"])                          // .waitingForInput

[TerminalStatus.idle, .agent, .waiting].sorted { $0.priority < $1.priority }       // waiting first
```

## For agents

Read `CONTRIBUTING.md` first: the folder layout and the PR rules. `swift test` is the whole
check, and a new test must fail before the change it covers. `CLAUDE.md` / `AGENTS.md` carry a
module map.

## License

MIT © 2026 David Sherlock (ArrayPress)
