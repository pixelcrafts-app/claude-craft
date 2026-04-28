---
name: search-first
description: Research-before-coding discipline. Search for existing tools, libraries, MCP servers, and patterns before writing any custom code. Triggers before any "build from scratch" decision.
origin: ECC
---

# Search First

**Default rule:** before writing a utility, helper, or integration — search first. Custom code is the last resort.

## Triggers

- "Add X functionality" and code is about to be written
- Adding a dependency or integration
- Creating a new utility, helper, or abstraction
- Starting a feature that likely has existing solutions

## Decision Matrix

| Signal | Action |
|--------|--------|
| Exact match, well-maintained, MIT/Apache | **Adopt** — install and use directly |
| Partial match, good foundation | **Extend** — install + thin wrapper |
| Multiple weak matches | **Compose** — combine 2-3 small packages |
| Nothing suitable | **Build** — custom, but informed by research |

## Quick Mode (inline — always run this first)

```
0. Repo search    → rg through relevant modules/tests — does it exist already?
1. Package search → npm/PyPI for the exact problem
2. MCP search     → ~/.claude/settings.json — is there already an MCP for this?
3. GitHub search  → maintained OSS before writing net-new code
```

## Full Mode (for non-trivial functionality)

```
Task(subagent_type="general-purpose", prompt="
  Research existing tools for: [DESCRIPTION]
  Language/framework: [LANG]
  Constraints: [ANY]

  Search: npm/PyPI, MCP servers, GitHub
  Evaluate: functionality, maintenance, community, license, deps
  Return: structured comparison with recommendation
")
```

## Search Shortcuts

| Category | Top candidates |
|----------|---------------|
| Linting | `eslint`, `ruff`, `markdownlint` |
| Formatting | `prettier`, `black`, `gofmt` |
| Testing | `jest`, `vitest`, `pytest`, `go test` |
| Pre-commit | `husky`, `lint-staged` |
| HTTP clients | `ky`/`got` (Node), `httpx` (Python) |
| Validation | `zod` (TS), `pydantic` (Python) |
| Markdown | `remark`, `unified`, `markdown-it` |
| Image | `sharp`, `imagemin` |
| Document parsing | `unstructured`, `pdfplumber`, `mammoth` |
| Claude SDK docs | Context7 MCP |

## Examples

```
Need: Check markdown files for broken links
Found: textlint-rule-no-dead-link (9/10)
→ ADOPT: npm install, zero custom code

Need: Resilient HTTP with retries
Found: got (Node) + retry plugin, httpx (Python) built-in retry
→ ADOPT: configure directly, zero custom code

Need: Config file schema validation
Found: ajv-cli (8/10)
→ EXTEND: install + write project-specific schema, no custom validation
```

## Anti-Patterns

- Writing a utility without checking if one exists in the repo first
- Skipping MCP server check when the capability is a natural fit
- Wrapping a library so heavily it loses its benefits
- Installing a 500KB package for a 5-line problem
