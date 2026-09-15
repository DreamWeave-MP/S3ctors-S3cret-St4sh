---
title: Reduce the Problem
description: Complex requirements do not automatically require complex abstractions.
weight: 10
extra:
  kind: guide
---

## The problem

A system can sound enormous before anyone asks what one layer actually needs to know.

“Several things may apply at once” sounds like a request for a conflict-resolution framework. “Many kinds of OpenMW object exist” sounds like a request for every consumer to understand every kind. “Work may return after the world changes” sounds like a request to cancel every operation perfectly.

Those descriptions may be true. They are not yet designs.

## The tempting design

The natural response is to model the whole problem in the next layer:

- a resolver that understands every playlist category and interaction;
- consumers that repeat record, instance, and type inspection;
- cancellation machinery that knows every way work can become stale.

This feels thorough. It also makes the next layer responsible for knowledge it does not need. Every new case becomes a new concept in the central machinery, and every caller learns another piece of the external system.

## The reduction

Ask one smaller question:

> What is the smallest piece of information the next layer needs to make its decision?

For S3maphore, the resolver needs to know whether a playlist is eligible for the current playback state:

```text
fun(playback) -> boolean
```

For S3lf, the consumer needs a stable view over the attached object that can reuse safe engine-backed values, not repeated reconstruction of those values and their access paths. For deferred work, the consumer needs to know whether the result still belongs to the current world, not a perfect history of every superseded request.

The smaller contract does not deny the complexity. It puts the complexity where it belongs and stops exporting it everywhere else.

## Why this works

Small contracts compose because they leave room for their owners to decide how the answer is produced.

- A simple playlist can use one state check.
- A complicated playlist can combine state and cached rules.
- The resolver does not need to know why the answer is true.
- A facade can hide many engine-specific lookups without pretending the values are plain Lua tables.
- A generation token can reject stale work without understanding the work's entire internal history.

This is policy/mechanism separation, but that name is less important than the move that produced it: reduce the question before adding machinery.

## Concrete first, formal second

Do not begin with “predicate-based policy inversion” or “information hiding across a semantic boundary.” Begin with:

> The solution was to make the problem smaller.

Show the tiny contract. Walk through the code that consumes it. Only then give the design move a name. Formal language is useful when it labels an idea the reader already understands; before that, it is mostly fog.

## What to steal

Before adding a framework, write down the decision the next layer must make and the minimum information required to make it.

Then keep the rest of the knowledge behind the boundary that owns it.

Do not copy `fun(playback) -> boolean` into an unrelated problem because it looks elegant. Copy the reasoning that found it.

See [S3maphore Playlist Eligibility](@/cod3x/docs/good-designs/s3maphore-playlist-eligibility.md) and [I.s3.lf](@/cod3x/docs/good-designs/s3lf-semantic-boundary.md) for the idea in real systems. [API and Interface Design](@/cod3x/docs/practice/api-design.md) describes the same discipline from the contract side.

## When not to use this

Do not force a one-value contract onto a decision that genuinely requires coordinated facts, shared ownership, or ordering information. Reduction means removing unnecessary knowledge, not throwing away knowledge the next layer actually needs.
