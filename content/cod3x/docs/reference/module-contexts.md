---
title: Module Context Matrix
description: Where the major OpenMW and openmw_aux modules are available.
weight: 10
extra:
  kind: api
---

This matrix mirrors Cod3x's current context model. Member-level restrictions may be narrower than the module itself.

| Module | Contexts |
| --- | --- |
| `openmw.async` | all |
| `openmw.core` | all, with narrower runtime members |
| `openmw.markup` | all |
| `openmw.storage` | all, with section/member restrictions |
| `openmw.types` | global, local, player |
| `openmw.util` | all |
| `openmw.vfs` | all |
| `openmw.interfaces` | runtime |
| `openmw_aux.calendar` | runtime |
| `openmw_aux.calendarconfig` | runtime |
| `openmw_aux.time` | runtime |
| `openmw_aux.util` | runtime |
| `openmw.content` | load |
| `openmw.world` | global |
| `openmw.animation` | local, player |
| `openmw.nearby` | local, player |
| `openmw.self` | local, player |
| `openmw.ambient` | player, menu |
| `openmw.input` | player, menu |
| `openmw.ui` | player, menu |
| `openmw_aux.ui` | player, menu |
| `openmw.camera` | player |
| `openmw.debug` | player |
| `openmw.postprocessing` | player |
| `openmw.menu` | menu |

## Important broad-module exceptions

`openmw.core` is available everywhere, but several members are runtime-only. Cod3x currently treats runtime world-facing members such as game time, weather, sound, world pause state, `quit`, and `sendGlobalEvent` as unavailable in load scripts.

`openmw.storage` is available everywhere, but player/global section access varies by context.

`openmw.interfaces` itself is runtime-wide, while individual built-in interfaces can be narrower.

Use Cod3x diagnostics rather than copying this table into conditionals.
