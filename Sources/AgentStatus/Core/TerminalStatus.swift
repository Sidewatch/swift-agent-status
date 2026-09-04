import Foundation

/// Derived from signals Sidewatch already has locally — the pty's foreground process group and
/// its name — rather than from anything the agent tells us. That is the point: it works for any
/// agent CLI, and for a plain shell running a build, without integration on the other side.
public enum TerminalStatus: Equatable, Sendable {

    /// Sitting at the prompt with nothing running.
    case idle
    /// A recognised agent CLI is in the foreground.
    case agent
    /// Some other program is in the foreground — a build, a test run, an editor.
    case running
    /// The agent is blocked on you — a permission prompt, or a question.
    ///
    /// The state the rail exists for, and the only one that cannot be inferred from the process
    /// table: an agent waiting for input looks exactly like an agent thinking, because both have
    /// the same foreground process. It comes from Claude Code's `Notification` hook, attributed
    /// to this terminal via ``ClaudeSessionIndex``.
    case waiting
    /// An agent finished here and nobody has looked at this terminal since.
    ///
    /// The state the rail exists for. Two sources feed it, hook first:
    ///   - a `Stop` hook attributed to this terminal (``TerminalAttention/done``). For Claude
    ///     Code this is the ONLY working signal — it stays resident between turns, so its
    ///     process transition happens when you quit it, not when a turn ends;
    ///   - the terminal's own transition (agent running → back at the prompt, unfocused) — the
    ///     fallback that needs no hooks installed and covers agents that have none. It stands
    ///     down for any run the hooks have spoken for (`TerminalController.noteAgentTransition`),
    ///     so one completion can never raise two notices.
    case finished

    /// Process names treated as agents. Matched case-insensitively against the pty's foreground
    /// process name, and by prefix so versioned binaries (`claude-code`, `codex-cli`) still count.
    ///
    /// A deliberate whitelist: guessing from the process name alone would catch `node` and
    /// `python`, which run half the tools on a developer's machine, and a terminal wrongly
    /// showing "agent working" is worse than one showing the honest "running".
    public static let agentProcessNames = [
        "claude", "codex", "aider", "goose", "gemini", "copilot", "amp", "opencode", "cursor",
        "hermes", "grok",
    ]

    /// Agents whose name is too short to prefix-match: `pi` would otherwise claim `pip`,
    /// `ping` and `pigz`. Matched by equality only.
    public static let exactAgentProcessNames: Set<String> = ["pi"]

    /// Whether the foreground program is an agent, by name OR by executable path.
    ///
    /// The path matters more than the name, which is the opposite of what you would expect.
    /// Claude Code's native installer runs `~/.local/share/claude/versions/2.1.223` — the
    /// executable IS the version number, so `proc_name` reports "2.1.223" and no list of program
    /// names can ever match it. The directory it lives in is the part that identifies it.
    ///
    /// Checking path COMPONENTS rather than a substring, so a project that happens to be called
    /// `claude-notes` does not make every shell in it look like an agent.
    /// Runtimes that tell you nothing on their own. An agent installed from npm or pip runs as
    /// one of these, so its identity is only in its ARGUMENTS — and reading those is worth it
    /// only here, never for a process that already named itself.
    public static let genericRuntimes: Set<String> = [
        "node", "node22", "node20", "bun", "deno", "python", "python3", "ruby", "perl", "sh", "env",
    ]

    /// Published package/binary names for the same agents, for the ARGUMENTS tier.
    ///
    /// Listed explicitly rather than derived by splitting on hyphens. Deriving would match any
    /// token merely starting with an agent's name, so a project called `claude-notes` would read
    /// as a running agent — the precise false positive the whitelist exists to prevent. The npm
    /// package really is `@anthropic-ai/claude-code`, so "claude" alone never appears as a token.
    public static let agentPackageNames = [
        "claude-code", "codex-cli", "aider-chat", "gemini-cli", "amp-cli", "opencode-ai", "goose-ai",
    ]

    public static func isGenericRuntime(_ name: String?) -> Bool {
        guard let name = name?.lowercased() else { return false }
        return genericRuntimes.contains(name)
    }

    /// Whether the foreground program is an agent, by name, executable path, or arguments.
    ///
    /// Three tiers because agents install three ways:
    ///   - `/usr/local/bin/codex`             → the NAME says it
    ///   - `.../claude/versions/2.1.223`      → only the PATH says it (the binary is a version)
    ///   - `node .../@openai/codex/cli.js`    → only the ARGUMENTS say it
    ///
    /// Without all three, whichever way you happened to install decides whether Sidewatch can
    /// see your agent, which is not a distinction a user would ever guess at.
    public static func isAgentProcess(_ name: String?, path: String? = nil, args: String? = nil) -> Bool {
        if let name = name?.lowercased(), !name.isEmpty,
           exactAgentProcessNames.contains(name)
            || agentProcessNames.contains(where: { name == $0 || name.hasPrefix($0) }) { return true }
        if let args = args?.lowercased(), !args.isEmpty {
            // Split on separators so `@openai/codex/cli.js` yields "codex" as its own token, and a
            // path merely CONTAINING the word does not.
            let tokens = Set(args.split(whereSeparator: { "/\\ \t@".contains($0) }).map(String.init))
            if (agentProcessNames + agentPackageNames).contains(where: { tokens.contains($0) }) { return true }
        }
        guard let path = path?.lowercased(), !path.isEmpty else { return false }
        // EXACT component match. A prefix rule would fire on any directory merely starting with
        // an agent's name — a project called `claude-notes` would make every shell inside it look
        // like a running agent, which is the false positive the whitelist exists to prevent.
        // Versioned or suffixed BINARIES are already covered by the name check above.
        let components = Set(path.split(separator: "/").map(String.init))
        return agentProcessNames.contains { components.contains($0) }
            || exactAgentProcessNames.contains { components.contains($0) }
    }

    /// The whole rule, in one place.
    ///
    /// A free function rather than a computed property on `TerminalController` so the test can
    /// call the REAL derivation instead of a copy of it. A probe that restates the rule agrees
    /// with itself no matter what the app does, which is how a wrong rule survives a green test.
    ///
    /// Precedence, top down: an unacknowledged hook signal outranks EVERYTHING — Claude Code
    /// keeps running between turns, so a waiting agent and a thinking one are indistinguishable
    /// from the process table, and a resident agent is always "busy", so hook-reported
    /// completion must outrank busy or it could never show. Below that, busy outranks the
    /// transition-derived completion flag: a terminal that has started new work is working,
    /// whatever it finished a moment ago.
    ///
    /// No parameter has a default. Three of these used to default to nil, and omitting one
    /// silently degraded the answer — forget `attention:` and a waiting agent reports `.agent` —
    /// with nothing for the compiler to catch. See ``ForegroundInfo``.
    public static func derive(foreground fg: ForegroundInfo, unseenCompletion: Bool,
                       attention: TerminalAttention?) -> TerminalStatus {
        switch attention {
        case .waiting: return .waiting
        case .done:    return .finished
        case nil:      break
        }
        if fg.isBusy { return isAgentProcess(fg.process, path: fg.processPath, args: fg.processArgs) ? .agent : .running }
        return unseenCompletion ? .finished : .idle
    }

    /// SF Symbol for the status dot.
    /// A hook-delivered state the user may need to act on — the only states that earn
    /// a badge on the tab and a dot in the rail. A working agent announces itself in its
    /// own title; a badge beside it said the same thing twice.
    public var isActionable: Bool { self == .waiting || self == .finished }

    /// Whether an agent is (or was, per the hooks) the foreground process — the
    /// terminals whose cwd is where that agent's transcript lives.
    public var impliesAgent: Bool { self == .agent || self == .waiting || self == .finished }

    public var symbolName: String {
        switch self {
        case .idle:     return "circle"
        case .agent:    return "circle.fill"
        case .running:  return "circle.dotted"
        case .finished: return "checkmark.circle.fill"
        case .waiting:  return "exclamationmark.circle.fill"
        }
    }

    /// Short label shown beside the terminal's name.
    public var label: String {
        switch self {
        case .idle:     return "Idle"
        case .agent:    return "Working"
        case .running:  return "Running"
        case .finished: return "Done"
        case .waiting:  return "Needs you"
        }
    }

    /// Sort rank: what needs you first. Finished agents outrank working ones because a finished
    /// agent is BLOCKED on you and a working one is not — the rail's whole job is to surface
    /// which terminal is waiting.
    public var priority: Int {
        switch self {
        // Waiting outranks finished: both want you, but a waiting agent is STALLED — nothing
        // moves until you answer — while a finished one has at least delivered its work.
        case .waiting:  return 0
        case .finished: return 1
        case .agent:    return 2
        case .running:  return 3
        case .idle:     return 4
        }
    }
}

/// The pty's foreground process, as ONE value for ``TerminalStatus/derive(foreground:unseenCompletion:attention:)``.
///
