---
title: Source-Diving Workflow
description: When documentation stops, inspect annotations, OpenMW source, production use, and history in that order.
weight: 30
extra:
  kind: guide
---

OpenMW Lua occasionally requires source archaeology.

Do it systematically.

## 1. Start with Cod3x annotations

The annotations are maintained against a live OpenMW source checkout and often contain details that are awkward to discover from prose:

- optional fields;
- concrete object/record types;
- context availability;
- interface members;
- method signatures.

## 2. Inspect the OpenMW implementation

If behavior, lifetime, or cost matters, find the C++ binding and engine call.

Questions worth answering include:

- Does this property construct a value?
- Is a list a copied table, userdata view, or engine-backed iterable?
- Is a call synchronous?
- Which context enforces the operation?
- What is the mutation timing?

## 3. Find production use

Search the St4sh and other maintained mods for real call sites.

Production code can reveal:

- necessary guards;
- typical ownership;
- cache lifetimes;
- assumptions the API docs do not foreground.

Do not treat one call site as law. Look for recurring patterns.

## 4. Read history

Use `git log -S`, `git log -G`, file history, and conventional commit prefixes.

A fix often contains the missing reason.

## 5. Reproduce

When the answer still matters, build the smallest script/benchmark that isolates it.

Cod3x should prefer a tested ugly fact over an elegant guess.
