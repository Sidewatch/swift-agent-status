# Swift Agent Status

What a terminal is doing — idle, running, agent working, needs you, done — derived from the foreground process and an agent's hook signals, with a screen-scrape fallback.

- Module `AgentStatus` in `Sources/AgentStatus`; tests in `Tests`; `swift test` is the whole check.
- Swift 6 language mode, tools 6.2, macOS 14+, no dependencies.
- Part of the Sidewatch package family; every package follows the same layout and PR rules.

## Module map

- `Core/` — the engine: TerminalStatus (the whitelist + derive), ScreenStateClassifier, AgentProcess (argv naming)
- `Enums/` — TerminalAttention, ScreenState
- `Models/` — ForegroundInfo, TerminalSummary, SubagentSummary, AgentActivity

## Rules of this package

- Agent recognition is a WHITELIST: guessing would catch `node` and `python`. Path matching is by exact component, never prefix (a project called `claude-notes` is not an agent).
- `derive` has no defaulted parameters: omitting one used to silently degrade the answer.
- Nothing here knows about colours or views; the host maps `TerminalStatus` to its tint.

## Rules

Read `CONTRIBUTING.md` before changing anything: it is the layout and PR rulebook for this package.
