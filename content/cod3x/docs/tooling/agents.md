---
title: Coding Agents
description: Cod3x should make machine-assisted OpenMW Lua less plausible-looking and more correct.
weight: 20
extra:
  kind: guide
---

Coding agents are useful precisely because they can apply a large body of explicit knowledge quickly.

They are dangerous when that knowledge is generic Lua advice plus confident autocomplete.

Cod3x is intended to be agent-readable engineering context.

## What an agent needs to know

A competent OpenMW-Lua agent must understand:

- script contexts;
- object versus record identity;
- interface and event ownership;
- storage/persistence boundaries;
- engine-backed userdata;
- OpenMW API availability;
- the difference between Lua cost and engine cost;
- project style and error policy;
- how to validate claims against source.

A model that knows Lua but not those constraints can produce code that looks professional while being architecturally wrong.

## Repository instructions should be short and hard

`content/cod3x/AGENTS.md` is the condensed operational contract for work in Cod3x.

It should point into the field manual rather than duplicating every explanation.

The documentation explains *why*.

The agent file says *do this*.

## Agents should investigate history

When an existing pattern looks unusual, do not immediately “simplify” it.

Search:

- `git log -- <file>`;
- commit messages around the code;
- related `FIX:`/`PERF:`/`REVERT:` commits;
- current OpenMW source/annotations;
- tests and benchmarks.

A weird branch may be obsolete. It may also be a scar covering a hole you are about to reopen.

## Generated code is held to the same standard

Do not keep code because it was generated cheaply.

Do not reject code because a model wrote it.

Review the architecture, contracts, types, performance, and readability exactly as you would human code.

The whole point of Cod3x is to raise the floor of machine-assisted work, not to create a separate lower standard for it.
