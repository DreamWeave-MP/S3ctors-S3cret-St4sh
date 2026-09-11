+++
title = "Experiments and Oddities"
description = "Executable SSS documentation for useful, strange, and deliberately excessive module combinations."
template = "docs/section.html"
page_template = "docs/page.html"
sort_by = "weight"
weight = 20

[extra]
api_docs = true
kind = "guide"
+++

These are not the core recipes. They are a small gallery of executable documentation: each module demonstrates several SSS primitives at once, stresses an interaction that a basic example does not, and states the catch before showing the YAML.

The shared rule is simple: SSS gets one shot when an object becomes active. Nothing here is a hidden polling loop or a substitute for an event-driven Lua script. Objects change when activation-time conditions match, and normal save-state semantics determine what remains changed, while `once` controls whether the rule may apply again.

## Gallery

- [The House Moves When You're Not Looking](@/static_switching_system/docs/experiments/house-moves.md) — accumulated relative transforms on fresh activation batches.
- [Necromantic Compound Interest](@/static_switching_system/docs/experiments/necromantic-compound-interest.md) — generated-object feedback and a self-propagating undead population.
- [Low Health Makes Vvardenfell Worse](@/static_switching_system/docs/experiments/low-health-vvardenfell.md) — persistent world scarring controlled by player health at activation time.
- [Bad Weather Has Consequences](@/static_switching_system/docs/experiments/bad-weather-consequences.md) — weather as a condition, never as a trigger.
- [The Door Knows What You're Wearing](@/static_switching_system/docs/experiments/door-disguise.md) — equipment and faction ownership becoming an access system.
- [Caius Takes Weekends Off](@/static_switching_system/docs/experiments/caius-takes-weekends-off.md) — the Tamrielic weekday as an activation-time world condition.
- [You Probably Want Lua](@/static_switching_system/docs/experiments/you-probably-want-lua.md) — the deliberate warning label for over-composing declarative rules.

The corresponding YAML files are source fixtures under `Examples/`. Copy one into `scripts/staticSwitcher/data/` only after reading its catch. Several examples use FlexTag conventions or deliberately dramatic effects.
