---
title: Coding with AI
description: Give coding agents OpenMW-specific context, specialist roles, reusable skills, and an evidence burden.
weight: 55
template: docs/section.html
page_template: docs/page.html
sort_by: weight
extra:
  kind: guide
---

A capable coding agent can search more source, inspect more history, write more tests, and attempt more changes than you could reasonably do by hand in the same time.

That makes good project context more important, not less.

Cod3x ships an OpenCode-oriented agent pack under `.opencode/`: four specialist subagents for investigation-heavy domains and twelve reusable skills for narrower engineering constraints. They are not a replacement for the field manual. They are the operational layer that helps an agent apply it while working.

Start with [OpenCode Setup](@/cod3x/docs/ai/opencode.md), then skim [Specialist Agents](@/cod3x/docs/ai/agents.md) and [Reusable Skills](@/cod3x/docs/ai/skills.md). [Putting Agents and Skills Together](@/cod3x/docs/ai/workflows.md) shows which pieces compose naturally for real OpenMW work.

For the broader discipline behind this pack, read [So You Want To Code With AI?](@/cod3x/docs/tooling/so-you-want-to-code-with-ai.md). For repository-level instructions such as build commands, architecture, and hard project rules, read [Repository Instructions for Coding Agents](@/cod3x/docs/tooling/agents.md).

## The split

Cod3x uses three different layers deliberately:

| Layer | Purpose | Typical scope |
| --- | --- | --- |
| `AGENTS.md` | persistent project rules and navigation | the whole repository or directory subtree |
| specialist agent | a focused investigator with its own child context | plugin analysis, saves, UI, VFS |
| skill | reusable task-specific engineering guidance loaded on demand | context safety, lifecycle, UI layout, persistence, performance, packaging |

Do not turn every rule into an agent and do not dump every skill into every prompt. The useful architecture is **small persistent contract + specialist when the domain warrants one + narrow skills when the task warrants them**.

## What Cod3x is trying to prevent

These files exist because generic Lua competence is not enough for OpenMW Lua. The recurring failure modes are domain-specific: wrong script context, stale object lifetime assumptions, unsafe save-state changes, incorrect runtime ordering, VFS path mistakes, broad UI rebuilds, engine-bound hot paths treated like ordinary Lua, and confident claims based on the wrong OpenMW revision.

The pack makes those constraints available to the model at the point where they matter.
