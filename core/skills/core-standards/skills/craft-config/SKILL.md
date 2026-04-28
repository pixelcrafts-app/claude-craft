---
name: craft-config
description: Apply when setting up a new project with claude-craft, or when craft.json is absent and needs to be generated. Documents the .claude/craft.json schema, what each field activates, and how to maintain it. Also governs disabled_rules transparency rules.
---

# Craft Config

`.claude/craft.json` is the project-level configuration that tells the verification system which skills apply to this project. It removes the need for verification to guess from file types alone.

---

## Schema

```json
{
  "stacks": ["web", "api"],
  "features": {
    "auth": "jwt-refresh",
    "realtime": false,
    "i18n": false,
    "payments": false
  },
  "disabled_rules": []
}
```

### `stacks[]`

Which skill domains are PROJECT-MANDATORY for this codebase.

| Value | Activates |
|---|---|
| `"web"` | web-standards skills (craft-guide, nextjs, premium-signals, etc.) |
| `"mobile"` | mobile-standards skills (craft-guide, design-tokens, premium-signals) |
| `"flutter"` | flutter-standards skills (engineering, accessibility, etc.) |
| `"api"` | api-standards skills (nestjs, code-quality, etc.) |

Multiple stacks: `["web", "api"]` activates cross-stack-contracts automatically.

### `features{}`

Which conditional skills are active for this project.

| Key | Value options | Activates |
|---|---|---|
| `auth` | `"jwt-refresh"`, `"oauth"`, `"session"`, `true`, `false` | `core-standards:auth-flows` |
| `realtime` | `true`, `false` | `api-standards:websockets` |
| `i18n` | `true`, `false` | `web-standards:i18n` |
| `payments` | `"stripe"`, `"other"`, `false` | (future skill) |

When a feature is `false`: the skill is inactive. Verification does not enforce it. If the feature's trigger conditions are detected in code anyway, verification emits `INFO` — not `FAIL`.

### `disabled_rules[]`

Escape hatch for rules that genuinely do not apply to this project. Each entry requires a reason.

```json
"disabled_rules": [
  {
    "rule": "flutter-standards:engineering §3.2",
    "reason": "Third-party SDK requires synchronous init before async context is available"
  }
]
```

**Every verification report surfaces all disabled rules with their reasons.** This makes bypasses visible — they are not silent. If a disabled rule has no reason, verification flags it: `WARN: rule disabled without documented reason — add reason or re-enable.`

Disabled rules are not deleted rules. They appear in every report as a reminder that they are opted out.

---

## Auto-Generation

When planning detects no `.claude/craft.json`:

1. Detect stacks from: file extensions (`.tsx` → web, `.dart` → flutter, `@nestjs` imports → api), package manifests (`package.json`, `pubspec.yaml`)
2. Detect features from: auth guard patterns → `auth`, socket imports → `realtime`, i18n packages → `i18n`
3. Generate a draft craft.json and present it inline
4. Ask: "Does this look correct for your project?"
5. If confirmed: write to `.claude/craft.json`
6. If skipped: note in the plan block that config is absent; verification uses auto-detection with INFO notice

Auto-generation produces a reasonable default. Manual review is required before the file is authoritative.

---

## Maintenance Rules

- Update `craft.json` when a new stack or feature is added to the project
- Do not remove features from `craft.json` when removing the feature from the project — mark as `false` instead of deleting the key, so the absence is explicit
- `craft.json` is committed to the repo and reviewed in PRs — it is a project decision, not a personal preference file
- `.claude/craft.json` is the path; `.claude/` directory should be in `.gitignore` for secrets but `craft.json` should be committed (it contains no secrets)

---

## Verification Integration

The verification skill reads `craft.json` in Step 0 before detecting active skills. The 4-tier detection model uses it as the authoritative source for PROJECT-MANDATORY skills. Auto-detection is a fallback, not the primary mechanism.
