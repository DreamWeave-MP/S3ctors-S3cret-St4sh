---
title: Glossary
description: The OpenMW-Lua terms that cause the most confusion.
weight: 30
extra:
  kind: api
---

**Context** — the execution environment of a script (`global`, `local`, `player`, `menu`, or `load`) and therefore its available APIs/authority.

**Record** — content definition such as an NPC, weapon, door, race, static, or other data record.

**Object / instance** — one runtime thing in the world or a container/inventory, usually associated with a record.

**Object ID** — identity of a runtime object instance (`object.id`).

**Record ID** — identity of the underlying content record (`object.recordId`).

**LObject** — local/read-only object handle available to local/player code.

**GObject** — global/mutable object handle available to global code.

**SelfObject** — the object a local/player script is attached to.

**Interface** — named script contract exposed through `openmw.interfaces`.

**Local event** — event sent to one object's local scripts with `object:sendEvent`.

**Global event** — event routed to global scripts through `core.sendGlobalEvent`.

**Storage section** — engine-provided persistent/shared key-value surface with context-dependent access and subscriptions.

**Userdata** — Lua value backed by native/runtime-managed data rather than a normal Lua table. OpenMW exposes many engine values this way.

**Hot path** — code executed frequently enough that small costs accumulate meaningfully in the measured workload.

**Generation / epoch** — monotonically changing identity used to reject deferred work created under older state.

**Trace** — LuaJIT compiled hot execution path.

**Side exit** — runtime departure from a compiled trace when a guard fails.

**Trace abort** — LuaJIT recorder failing to compile an attempted trace path.

**Engine boundary** — transition from Lua execution through bindings into OpenMW/native work and back.

**Paid For With Blood** — a Cod3x lesson backed by an actual historical failure rather than hypothetical preference.
