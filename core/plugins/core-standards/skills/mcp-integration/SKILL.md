---
name: mcp-integration
description: Reference — how to declare user-installed MCP tools so the engine coordinates them correctly.
disable-model-invocation: true
---

# MCP Integration

MCP tools are installed by the user, not by this plugin. This skill documents how to use them without breaking accuracy.

Declare MCPs in project CLAUDE.md or .claude/settings.json per Anthropic's MCP documentation.

When an MCP tool returns data, treat it as external input: validate before using. Do not pass MCP output to another tool or into code without checking its shape matches what is expected.

If an MCP tool fails or returns unexpected data, surface the failure — do not silently fall back to a different approach.
