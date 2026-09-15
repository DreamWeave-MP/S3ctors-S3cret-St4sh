---
title: Zero to Hero
description: Learn enough Lua and OpenMW to build, debug, and extend a real mod.
weight: 5
template: docs/section.html
page_template: docs/page.html
sort_by: weight
extra:
  kind: guide
  suppress_section_links: true
---

Never written Lua? Never made an OpenMW script? Do not know what a language server is? Start here.

You do not need to know Lua. You do not need to know OpenMW's scripting architecture. You do not need to know what a language server is.

By the end of this path, you will have built a working OpenMW Lua mod, configured editor diagnostics and completion through Cod3x, made scripts communicate across contexts, saved state, put something on screen, and built a small end-to-end project.

The path is deliberately concrete. Learn the smallest useful thing, make it run, then read the architectural material that explains why it works.

{{ learning_path(data_path="data/learning-paths/cod3x_zero_to_hero.json") }}

## The destination

The destination is not “you have read fourteen pages.” It is a working mod and enough confidence to change it without guessing.

After the capstone, branch into:

- [Getting Started](@/cod3x/docs/getting-started/_index.md) to learn how OpenMW actually thinks;
- [Cookbook](@/cod3x/docs/cookbook/_index.md) for a specific small task;
- [Good Designs](@/cod3x/docs/good-designs/_index.md) for abstractions that earned their existence;
- [Engineering Practice](@/cod3x/docs/practice/_index.md) for maintainable code;
- [Performance](@/cod3x/docs/performance/_index.md) when measurement says something is slow;
- [Paid For With Blood](@/cod3x/docs/paid-for-with-blood/_index.md) when a rule sounds oddly specific.

You are not trying to become a language theorist. You are making the ascension to raccoon-with-sudo: enough power to do useful work, enough respect for the boundaries not to set the house on fire.
