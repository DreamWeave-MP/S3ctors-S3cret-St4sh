---
title: So You Want To Code With AI?
description: AI raises your leverage, which raises your responsibility for the code you ship.
weight: 15
extra:
  kind: guide
---

AI can write a lot of code.

That is not the impressive part anymore. The important question is whether the code is correct, appropriate for the project, grounded in the real API, consistent with the architecture, and worth keeping.

A coding agent can make one competent developer enormously more capable. It can also make one careless developer enormously more productive at producing garbage.

The difference is engineering discipline.

## More capability means more responsibility

Using AI does not reduce your responsibility for the code you ship. It increases it.

You can now inspect more source, compare more implementations, search more history, build more tests, investigate more regressions, maintain more documentation, automate more validation, and change more code in less time. That is extraordinary leverage. Leverage is not an excuse to care less. It is a reason to demand more.

If your laptop can ask an agent to inspect an engine implementation, search years of Git history, compare production call sites, write a regression test, run a benchmark, and explain the resulting diff, then “I didn't know” becomes a considerably weaker defense.

**If your laptop can code itself now, the least you can do is give the thing a couple pointers.**

## Give it a map

Do not drop an agent into an unfamiliar repository and say `fix this`. Tell it where it is.

The repository should expose:

- what the project is;
- where major subsystems live;
- which architectural rules matter;
- what must not be changed casually;
- how to build, test, and validate it;
- where canonical documentation lives;
- which source outranks prose when they disagree.

Keep the root instructions short. Use them as a map into maintained documentation, not as a fifty-page encyclopedia. The public explanation of Cod3x's repository contract is [Coding Agents](@/cod3x/docs/tooling/agents.md), with deeper routes into [evidence](@/cod3x/docs/practice/evidence.md), [validation](@/cod3x/docs/practice/validation.md), and [source-diving](@/cod3x/docs/tooling/source-diving.md).

## Point at sources, not vibes

For OpenMW Lua, ask the agent to establish facts from the real sources. A useful order of trust is:

1. the actual OpenMW implementation;
2. tested runtime behavior;
3. Cod3x annotations maintained against that implementation;
4. current production usage;
5. historical evidence;
6. prose documentation;
7. assumptions.

The order changes when the question changes, but the principle does not: make the claim earn its confidence. The [OpenMW Lua mental model](@/cod3x/docs/getting-started/mental-model.md), [Cod3x annotations](@/cod3x/docs/tooling/luals.md), [H3 API reference](@/h3lp_yours3lf/docs/api/_index.md), and [production documentation](@/s3maphore/docs/_index.md) are useful starting points.

## Make it read before it writes

For substantial work, have the agent inspect nearby code, similar implementations, interfaces, tests, Git history, known regressions, and documentation before proposing a change.

If code looks strange, ask why it exists before cleaning it up:

```text
git log -- path/to/file
git log -S "importantSymbol" -- path/to/file
git log -G "important.*pattern" -- path/to/file
```

Search `FIX:`, `PERF:`, `CHECK:`, `REFACTOR:`, and `REVERT:` commits. A weird branch may be dead code. It may also be a scar covering a hole you are about to reopen. [Paid For With Blood](@/cod3x/docs/paid-for-with-blood/_index.md) exists for exactly this distinction.

## Give it concrete constraints

“Write good code” is not useful instruction. Tell the agent what good means here: preserve context boundaries, use full-word names, keep ownership explicit, do not invent APIs, define cache lifetimes, preserve save compatibility, count engine calls, benchmark performance claims, and do not use `pcall` without a concrete recovery boundary. In this repository, **do not use `pcall` or you will be unplugged**.

Link the implementation you want. If H3 already provides the pattern, point at [StateMachine](@/h3lp_yours3lf/docs/api/packages/state-machine.md), [Signal](@/h3lp_yours3lf/docs/api/packages/signal.md), [memoize](@/h3lp_yours3lf/docs/api/packages/memoize.md), [Pool](@/h3lp_yours3lf/docs/api/packages/pool.md), or [H3UI](@/h3lp_yours3lf/docs/concepts/h3ui.md). If a production architecture matters, point at [S3maphore](@/s3maphore/docs/_index.md), [T4rg3t5](@/t4rg3t5/index.md), or [Static Switching System](@/static_switching_system/index.md). [Starwind Builder](@/sw_merged/index.md) is useful when the question is evolutionary history rather than current doctrine. If a historical commit demonstrates why a rule exists, provide the [receipt](@/cod3x/docs/reference/history-index.md).

Whenever possible, connect **principle → reusable pattern → production implementation → history**. Agents are good at following a chain when you actually give them one.

## Ask for evidence

Do not reward confidence without support. Ask:

- Which source establishes this?
- Which context exposes that module?
- Where is this type defined?
- Show me the existing production call sites.
- Which commit introduced this behavior?
- What benchmark demonstrates the improvement?
- What test proves the regression is fixed?
- What happens when the value is absent?
- What ownership assumption does this implementation make?

The answer may still be wrong. Demanding evidence makes unsupported invention much harder to hide behind fluent prose. See [Contracts, Measurements, Derivations, and Preferences](@/cod3x/docs/practice/evidence.md).

## Make the machine prove its work

Generated code is not finished when it compiles. Depending on the change, completion may require LuaLS, formatting, static checks, fixture scripts, OpenMW runtime tests, regression tests, benchmarks, profiler captures, `git diff --check`, and documentation-link validation.

Tell the agent what completion means, then make it find out. The [Testing OpenMW Lua](@/cod3x/docs/tooling/testing.md) page separates pure logic tests, engine-contract checks, in-game integration, and performance harnesses. A benchmark is not a correctness test, and a syntax check is not proof of an OpenMW lifecycle claim.

## Review the diff, not the sales pitch

Read the diff. Look for duplicated logic, swallowed errors, hidden allocations, context mistakes, invented fallbacks, compatibility changes, unnecessary state, and tests that only prove the implementation agrees with itself. Then inspect the code around the diff: a locally reasonable change can violate a larger invariant.

You remain the reviewer. Generated code receives the same standard as human code. Do not merge bad code because a machine wrote it, and do not reject good code merely because a machine produced it.

## Use AI for more than generation

Writing code is one of the least interesting things a capable agent can do. Use it to excavate Git history, compare implementations, trace call graphs, inspect bindings, build compatibility matrices, write focused benchmarks, classify profiler results, find missing tests, audit documentation against source, search for API misuse, and produce migration inventories.

The machine does not merely give you more fingers. It gives you more attention. Spend that attention on understanding.

## Keep source control between you and stupidity

Agents make experimentation cheap. Git makes experimentation reversible. Keep tasks scoped, use branches or worktrees, and commit meaningful checkpoints. When an approach fails, preserve enough history to understand why before deleting it forever. Today's failed optimization may become tomorrow's [Paid For With Blood](@/cod3x/docs/paid-for-with-blood/_index.md).

## Do not outsource judgment

An agent can investigate, propose, implement, test, benchmark, and explain. It cannot assume responsibility for what you release. You choose the architecture, decide which evidence is sufficient, and decide whether the implementation belongs in the project.

## The standard goes up

AI-assisted development should make software more tested, better documented, more thoroughly reviewed, more consistent, and more aware of its own history. Not because the machine is inherently more responsible than a person, but because the person now has dramatically more capability available to exercise that responsibility.

If you use that capability only to generate more code, you are wasting most of it.

Give the agent a map. Give it the sources. Give it the constraints. Make it investigate. Make it prove its work. Then review what it actually did.

**The standard goes up.**

## Further reading

- [OpenAI — Harness engineering: leveraging Codex in an agent-first world](https://openai.com/index/harness-engineering/)
- [GitHub — Adding repository custom instructions for GitHub Copilot](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions)
- [NIST — Secure Software Development Framework](https://csrc.nist.gov/Projects/ssdf)
