---
title: Where Do I Go From Here?
description: Choose the next Cod3x section now that you have a working OpenMW Lua mod.
weight: 140
extra:
  kind: guide
---

You now know enough to become dangerous. More importantly, you have a working mod behind you.

Choose the problem in front of you:

| You want to... | Go here |
| --- | --- |
| Understand how OpenMW actually thinks | [Getting Started](@/cod3x/docs/getting-started/_index.md) |
| Find the smallest correct way to do one thing | [Cookbook](@/cod3x/docs/cookbook/_index.md) |
| Learn how good abstractions earn their place | [Good Designs](@/cod3x/docs/good-designs/_index.md) |
| Write maintainable code | [Engineering Practice](@/cod3x/docs/practice/_index.md) |
| Find a reusable H3 helper | [H3 API reference](@/h3lp_yours3lf/docs/api/_index.md) |
| Make scripts communicate cleanly | [Events and Interfaces](@/cod3x/docs/getting-started/events-and-interfaces.md) |
| Understand save/load and migrations | [Storage, Save State, and Lifecycle](@/cod3x/docs/getting-started/storage-and-lifecycle.md) |
| Find out why something is slow | [Performance](@/cod3x/docs/performance/_index.md) |
| Investigate a failure | [Debugging OpenMW Lua](@/cod3x/docs/getting-started/debugging.md) |
| Learn what happens when a rule was discovered the hard way | [Paid For With Blood](@/cod3x/docs/paid-for-with-blood/_index.md) |

The field manual is an encyclopedia attached to a course. You do not need to read it in order. Follow the question you have, and keep the [OpenMW Lua mental model](@/cod3x/docs/getting-started/mental-model.md) nearby when the answer starts involving contexts, objects, records, lifetime, or ownership.

If you want to improve Cell Greeter, make the UI a real window, move cell counting behind a small module, and expose a query interface only if another script actually needs it. That is how the next abstraction earns its existence.
