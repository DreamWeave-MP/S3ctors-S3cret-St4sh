---
title: Why Cod3x Exists
description: The mission behind the OpenMW-Lua field manual.
weight: 1
extra:
  kind: guide
---

I've been writing OpenMW Lua for a long time.

Over those years, I've heard some version of the same claim repeatedly:

**OpenMW Lua is slow.**

No.

*Your* OpenMW Lua is slow.

I spent years digging into why.

I dug through script architecture, allocations, table access, object methods, events, serialization, cache behavior, and every unnecessary trip across the engine boundary. I dug through LuaJIT bytecode and traces. I learned where the JIT succeeds, where it gives up, and where OpenMW's bindings make the distinction less important than the work happening on the other side.

When the Lua code was no longer enough to explain the performance, I kept digging.

Eventually I dug through the sandbox.

At that point the question stopped being *How do I make this OpenMW mod faster?* and became *Why does OpenMW expose this this way in the first place?*

That led into the binding layer, userdata, allocation, finalization, garbage collection, engine APIs, scripting architecture, and eventually the runtime itself. Years spent squeezing LuaJIT harder also produced a less convenient conclusion: LuaJIT is not a sufficient endpoint for the scripting system I want OpenMW to have.

The useful part of that work is not the conclusion. It is everything learned on the way down.

## The bodies are part of the documentation

I built a lot of things along the way. Some worked. Some did not. Some looked clever until they encountered reality. Some failed badly enough to permanently change how I write software.

Those failures matter.

The rules in Cod3x are not intended to be commandments handed down without explanation. Wherever possible, a recommendation should tell you:

- what problem it solves;
- what assumption it depends on;
- whether it is required by OpenMW or merely preferred;
- whether it was measured;
- what happens when it is violated;
- where we learned the lesson.

Sometimes the evidence is a benchmark. Sometimes it is OpenMW source. Sometimes it is a profiler capture. Sometimes it is a fix, revert, issue, or merge request where something that looked perfectly reasonable blew up.

Those lessons are **Paid For With Blood**.

You should get to keep the lesson without reproducing the wound.

## More code is not the goal

Writing OpenMW Lua has become easier than ever.

That has not always made OpenMW Lua better.

Code-generation tools can produce enormous amounts of plausible-looking Lua very quickly. They can also reproduce bad abstractions, unnecessary protected calls, excessive event traffic, context violations, invented APIs, allocation churn, cargo-cult optimization, and generic Lua advice that makes little sense inside an embedded game engine.

The failure is not that a machine wrote the code. Bad code is bad because it is bad.

The problem is that generating code without a sufficiently precise body of OpenMW-specific knowledge is now extremely cheap.

Generating more code is not the problem we need to solve.

We need to make it easier for humans and agents to produce **good code**.

That is why Cod3x exists.

The manual is not meant to be a sealed book. It should connect the reason for a rule to the [H3 implementation](@/h3lp_yours3lf/docs/_index.md), the production code that uses it, and the [history](@/cod3x/docs/reference/history-index.md) that established the constraint. If you are using a coding agent, [So You Want To Code With AI?](@/cod3x/docs/tooling/so-you-want-to-code-with-ai.md) explains how to follow that trail responsibly.

## A field manual, not a tutorial island

Cod3x is intended to become the field manual for OpenMW Lua engineering: API reference, practical handbook, cookbook, performance guide, tooling, and historical record.

It begins with the basics because everybody has to begin somewhere. That educational lineage includes Yvan/Hebi's *Effective OpenMW Lua* work and the accumulated community knowledge around OpenMW scripting.

It does not stop at the basics.

It should be possible to arrive here wondering how to put a black square on the screen and eventually leave understanding:

- script contexts;
- objects and records;
- interfaces and events;
- state ownership and invalidation;
- serialization and persistence;
- engine boundaries;
- allocation behavior;
- LuaJIT bytecode;
- traces and side exits;
- profiling;
- benchmark construction;
- reusable API design;
- the runtime costs OpenMW imposes before your Lua gets a vote.

The goal is not to make everyone write exactly like I do.

The goal is to give you the things I had to spend years digging for, explain why they matter, show you where I was wrong, and let you begin from there.

You should not have to rediscover all of this.

**I already paid for it.**

And if you're using `pcall` to hide programming errors:

**I will hunt you for using `pcall`.**
