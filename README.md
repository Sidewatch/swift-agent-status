# Swift Agent Status

What a terminal is doing: idle, running something, running a coding agent, waiting on you, or finished — derived from the pty's foreground process (name, executable path, argv), with a screen-scrape fallback for telling a waiting agent from a thinking one.

Extracted from Sidewatch. Recognises Claude Code, Codex, Gemini CLI, OpenCode, Aider, Hermes, Grok and pi.

> **Note (11 Sep 2026):** the hook-fed half was removed. This reads the process table and the screen and nothing else, so it needs nothing installed and has no config file to go stale. The row models that fed a rail (`TerminalSummary`, `SubagentSummary`, `AgentActivity`) went with it.

## Features

- 🧭 **Status derivation** — `TerminalStatus.derive(foreground:unseenCompletion:attention:)`: one rule, no defaulted parameters, an explicit attention signal outranking the process table
- 🕵️ **Agent recognition** — a deliberate whitelist across the three install shapes: by name (`codex`), by executable path (`…/claude/versions/2.1.223`), by argv (`node …/@openai/codex/cli.js`); exact-only for names too short to prefix-match (`pi`)
- 🏷️ **Command naming from argv** — `AgentProcess.commandName(fromArgs:)`: "codex", not "node"; "claude", not a version number
- 👀 **Screen-state fallback** — `ScreenStateClassifier.classify(rows)`: a numbered choice with a cursor, a y/n question, an explicit "Allow …?" → waiting; "esc to interrupt" → working; nil otherwise (the honest answer, most of the time)
- 📋 **Value types** — `ForegroundInfo`, `TerminalAttention`, `ScreenState`; all `Sendable`
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
