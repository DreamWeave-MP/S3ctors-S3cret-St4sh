---
title: 'Design Study: Delete the Fake Object'
description: Why a few functions and a table do not become better software merely by receiving a constructor.
weight: 95
extra:
  kind: guide
---

## The question

An object should have a reason to be an object.

That reason is usually some combination of independent identity, state, ownership, or lifetime. If none of those exist, a constructor is often just ceremony around a table and three functions.

Ask:

> Does this thing have independent identity, state, ownership, or lifetime?

If not, why is it an object?

## The tempting design

AI-assisted code loves this shape:

```lua
local Manager = {}
Manager.__index = Manager

function Manager.new() return setmetatable({}, Manager) end

function Manager:doThing(value) ... end
function Manager:otherThing(value) ... end

return Manager
```

Sometimes that is exactly right. Often the instance owns no data that differs between callers, has no meaningful identity, and cannot be destroyed or transferred independently. The constructor exists because “manager” sounds like architecture.

## SilenceManager: delete the ceremony

S3maphore's silence manager had a constructor even though the values it coordinated were not meaningfully stateful. Commit [`cec95881`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/cec95881e63e6439564548d4d40dc2183b97e596) simplified the setup and removed the unnecessary object-shaped machinery.

The useful result was not a clever replacement. It was a smaller ownership story: the module's functions and shared values were already the thing being managed. Pretending there were independent silence-manager instances obscured that fact.

## CellPresence: flatten the data shape

The same mistake can happen without a constructor. A nested object-looking representation can imply an independent lifetime even when its fields are merely part of one larger state machine.

Commit [`382df1e0`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/382df1e03077ab2d5ea9f71d5bbff7120d112ed5) flattened CellPresence fields back into PlaylistState. The separate representation did not own a distinct lifetime or authority; it was another shape for state that already belonged to playlist playback.

That flattening made the state machine easier to read. Cell transitions, presence data, and playlist decisions could be discussed in terms of the state that actually governed them instead of passing a decorative sub-object around.

## PlaylistRules: constructors are not free identity

PlaylistRules briefly used a constructor to capture playlist state. Commit [`e3501182`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/e3501182d41bc0d92953a0a9e4508f82cab8757e) refactored it to import and assign the relevant state directly instead.

That does not mean constructors are bad. It means the constructor was not establishing independent identity. There was one rules module, one playback state boundary, and no useful reason for callers to manufacture multiple rule objects.

The later [PlaylistRules genealogy](@/cod3x/docs/good-designs/playlist-rules-private-machinery.md) is the complementary lesson: keep the semantic rule boundary, but do not confuse a boundary with an instance when the implementation has no per-instance state.

## What the object was hiding

Fake objects usually hide one of three simpler truths:

- **module ownership:** one module owns a stable set of functions and data;
- **state ownership:** a field belongs inside an existing state machine;
- **plain transformation:** a function takes inputs and returns an answer without needing identity at all.

Flattening is not anti-abstraction. It is choosing an abstraction whose ownership and lifetime are real.

The [readable-code guidance](@/cod3x/docs/practice/readable-code.md) and [object lifetime guidance](@/cod3x/docs/practice/object-lifetime.md) cover the broader rule. The [earned shared infrastructure genealogy](@/cod3x/docs/good-designs/earned-shared-infrastructure.md) covers the opposite direction: when repeated consumers prove that a boundary should become a shared H3 contract.

## What to steal

Before adding `new`, `Manager`, `Service`, or `Context`, write down what the instance owns that another instance would not. If the answer is “nothing,” start with a module, a table, or a plain function.

If a real independent lifetime appears later, adding an object boundary is easy. Removing a fake one after every caller has learned its ceremony is much more annoying.

## When not to use this

Keep the object when instances have independent state, identity, lifetime, ownership, or substitution behavior. A constructor is justified when two instances can meaningfully differ or be managed independently. Do not flatten a real boundary merely because the syntax looks verbose.
