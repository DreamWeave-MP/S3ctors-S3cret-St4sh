---
title: State and Context
description: Separate module access, script permissions, ownership, and lifetime.
weight: 10
extra:
  kind: concept
---

Before choosing a helper, answer two questions: **where does this code run, and who owns its state?** A convenient wrapper changes neither answer.

## Modules versus installed interfaces

A plain module returns a function or table when required. [Signal](@/h3lp_yours3lf/docs/api/packages/signal.md), [Pool](@/h3lp_yours3lf/docs/api/packages/pool.md), and [normalizePath](@/h3lp_yours3lf/docs/api/packages/normalize-path.md) do not import OpenMW APIs.

A runtime helper uses engine facilities. [Debounce](@/h3lp_yours3lf/docs/api/packages/debounce.md) reads an OpenMW clock, but still requires your script to call it.

An installed interface is provided by another registered script. [S3lf](@/h3lp_yours3lf/docs/api/interfaces/s3lf.md) is obtained through `I.s3.lf`; requiring an implementation file is not a substitute for installing its provider.

{% usage_note(title="Script context is a permission boundary") %}
Local scripts work with their attached object; player scripts have additional player facilities. Global and menu scripts have different APIs and lifecycles. A helper using `openmw.self` cannot become global-safe because its require path looks generic.
{% end %}

## Synchronous calls versus engine events

Signal listeners run during `fire`. OpenMW events cross an engine-managed delivery boundary; sending one does not mean its handler has already completed. Use the engine's event facilities for cross-context communication, not two independently constructed Signal objects.

## Lifetime belongs to the owner

| Value | Ownership rule |
| --- | --- |
| A normalized string | Keep the returned value as long as needed. |
| A Signal connection | Retain its handle and disconnect when no longer needed. |
| A pooled table | Borrow until release; never use it afterward. |
| A debounce input table | The helper keeps your reference, not a snapshot. |
| An engine-backed S3lf field | Engine context/type restrictions still apply; do not assume it is serializable plain data. |

Ordinary Lua locals are not automatically a save format. Decide which values are runtime scratch state and which belong in your script's explicit save/load contract. Avoid saving closures, connection handles, or pool internals.

The [bootstrap](@/h3lp_yours3lf/docs/getting-started/overview.md) demonstrates a script with no persistent state. The [pooling example](@/h3lp_yours3lf/docs/examples/pooling-and-signals.md) demonstrates a deliberately shorter lifetime: one synchronous dispatch.

Cod3x explains the larger OpenMW constraints in [Contexts](@/cod3x/docs/getting-started/contexts.md), [Object Lifetime](@/cod3x/docs/practice/object-lifetime.md), and [Storage and Lifecycle](@/cod3x/docs/getting-started/storage-and-lifecycle.md).
