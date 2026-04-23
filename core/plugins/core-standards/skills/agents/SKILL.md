---
name: agents
description: Apply when spawning subagents or delegating work via Task or Agent tool. Defines the delegation contract.
---

# Agents

Every agent prompt must contain: GOAL (what to produce), CONTEXT (what the parent already knows — paste excerpts, not file names), SCOPE (files or areas in play), OUTPUT (exact shape of what the agent returns). Prompts missing any of these are cold — do not spawn.

Agent count and spawn order is Claude's decision. The parent states which tasks are parallel-safe in the plan (planning skill step 6). Claude decides how many agents to spawn and whether to run them serially or in parallel based on dependencies.

Trust but verify. Never use agent output as ground truth without cross-checking. The parent reads the agent's output, verifies it against the plan's verification steps, and flags any gap before reporting to the user.

Transparency. Before spawning, tell the user what is being delegated and why. After receiving results, tell the user what each agent returned and whether cross-check passed.
