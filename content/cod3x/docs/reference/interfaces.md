---
title: Built-In Interfaces
description: Built-in interface availability and what the concept means architecturally.
weight: 20
extra:
  kind: api
---

`openmw.interfaces` is a registry of script-facing capabilities published by OpenMW's built-in scripts and mods.

Do not confuse an interface with a C++ class or a generic language “interface” keyword. In OpenMW Lua, the important concept is **a named script contract available in specific contexts**.

Cod3x currently models built-in availability approximately as:

| Interface | Context |
| --- | --- |
| `Activation` | global |
| `AnimationController` | local, player |
| `AI` | local |
| `Camera` | player |
| `Combat` | global, local, player |
| `Crimes` | global |
| `Controls` | player |
| `GamepadControls` | player |
| `ItemUsage` | global |
| `MWUI` | player, menu |
| `Projectiles` | global |
| `Settings` | global, player, menu |
| `SkillProgression` | player |
| `SpellCasting` | global, local, player |
| `UI` | player |

The exact fields and signatures live in `content/cod3x/openmw/interfaces/*.lua`.

## Mod interfaces

A mod can publish its own interface by returning it from the script registration.

Treat that table as public API:

- version deliberately;
- type it;
- document ownership;
- avoid exposing internal mutable tables accidentally;
- make required/optional dependencies clear.

H3 and S3maphore are useful examples of interface-driven reusable infrastructure.
