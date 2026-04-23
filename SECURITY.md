# Security Policy

## Reporting a vulnerability

If you find a security issue — a skill that could be tricked into exfiltrating data, a hook that fails open when it should fail closed, a malicious pattern the marketplace would accept — please report it privately rather than opening a public issue.

Email: `security@pixelcrafts.app`

Include:
- What the issue is
- How to reproduce it (minimal example if possible)
- Which plugin/skill/version is affected
- Your suggested severity (low / medium / high / critical)

We'll acknowledge receipt within 72 hours and work with you on a disclosure timeline.

## Scope

In-scope:

- Plugins in this repo (`flutter-standards`, `api-standards`, `web-standards`, `core-hooks`, `core-standards`)
- Hooks shipped by `core-hooks` that could fail to block dangerous operations
- Skills (including those in `core-standards`) that could be prompt-injected into leaking user code or secrets

Out-of-scope:

- Issues in Claude Code itself — report to [Anthropic](https://claude.com/claude-code)
- Issues in third-party tools consuming the export output (Cursor, Antigravity, Codex, Aider)
- Issues in the user's own project where a skill was installed

## Safe-harbour

Good-faith research on the latest released version of any plugin here is welcome. Please do not test against third-party projects without authorization, and do not exfiltrate data beyond what's necessary to demonstrate the issue.
