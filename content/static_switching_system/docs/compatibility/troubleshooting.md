+++
title = "Troubleshooting"
description = "Diagnose an SSS module from the VFS boundary inward."
weight = 40

[extra]
api_docs = true
kind = "compatibility"
+++

## Nothing happens

1. Check that `Static Switching System.esp` is enabled and SSS's data directory is active.
2. Check that the module is below `scripts/staticSwitcher/data/` and ends in `.yaml` or `.yml`.
3. Check the OpenMW log for an SSS “Loaded module” line, and for `Skipped module` or `Skipped rule` lines naming your file. A rule with a misspelled condition or action name is skipped rather than applied without it.
4. Confirm the object becomes active in the cell you are testing. SSS processes active objects in batches; it does not pre-patch every unloaded cell.
5. For instance modules, verify every condition. Conditions in one rule are ANDed; array values for most conditions are OR-lists.

The [VFS and package boundaries](@/static_switching_system/docs/compatibility/vfs-package-boundaries.md) page covers the most common installation mistake.

## The module loads but a replacement is missing

For a static module, confirm both mesh values are VFS-visible. SSS logs a missing replacement mesh with the requested model, source model, object, and module name, then skips that swap. A source mesh path copied from another mod is not evidence that the replacement asset is installed.

For an instance `replace`, confirm the replacement record ID exists in enabled content; SSS logs a `could not create an object from record` warning when it does not. For `teleport`, confirm the destination cell name/ID or exterior coordinates resolve. For `add`, `equip`, and `create`, confirm the item or object record is available.

## A condition never matches

- `record_id` uses Lua pattern matching; use `^` and `$` when a substring match is too broad. Escape a literal pattern character where needed.
- `cell_match` is a case-insensitive substring match. `cell` is a case-insensitive exact name or ID comparison.
- `replace_regions` on a static module uses exact, case-insensitive region matching, while `region` is an instance condition.
- `has_journal` checks the player's quest stage when the object is processed. It is not a general event subscription. `index` is a minimum, so a rule meant for one stage keeps matching at later stages unless it also sets `max`.
- `content_file_target` requires both the content filename and the local reference number.
- `cell_tag` and `has_tag` require FlexTag; see [FlexTag compatibility](@/static_switching_system/docs/compatibility/flextag.md).

## A triggered rule never runs

- A world trigger (`journal`, `hour`, `day`, `weather`) only reaches objects in the player's cell and the eight exterior cells around it, and is checked only while the game is unpaused.
- A `journal` rule fires when the quest in its own `has_journal` changes stage, not when it is already at that stage on load.
- `death` needs the current `Static Switching System.esp`; look for `The death trigger is unavailable` in the log. An actor that was already dead when it loaded does not fire it.
- A log line saying a trigger was `suspended until the next load` means it fired more than four times in ten seconds.
- `by_player` and `used_item` are only valid under the interaction triggers; a rule misusing them is reported as a skipped rule.

## A random value errors or behaves unexpectedly

Condition ranges and action ranges are not interchangeable. Condition tables can provide `min`, `max`, or both. A table-form sampled action value requires `max`; this includes transform components, create position/rotation/scale values, lock levels, and teleport position/rotation components.

`transform.scale` is relative by default. A repeated rule can multiply an already changed scale. Use `transform_type: absolute` when the number should replace the reference scale.

## A disabled object does not change again

This is expected for SSS's activation path. Disabled objects do not produce a later `onObjectActive` event for SSS to re-enable them. Use `once: true` for a one-time disable, and do not use a disable-and-reroll design when the object must toggle on later visits.

## An update or removal made the save stranger

Instance actions are not generally reversible by changing a YAML file. Restore a backup save or author a carefully scoped follow-up rule. Existing static replacement chains are historical; see [save updates and persistence](@/static_switching_system/docs/compatibility/save-updates-and-persistence.md).

## Read the log first

When reporting a problem, include:

- OpenMW version and enabled content files;
- the exact VFS/data-directory layout for SSS and the module;
- the smallest YAML rule that reproduces the issue;
- the first SSS warning/error from the log;
- whether the save is new or already contains earlier SSS changes.

Do not diagnose a missing VFS resource from a filesystem search alone. If the issue remains unclear, reduce the rule to one condition and one action, test a fresh save or a backup copy, and reintroduce the other conditions one at a time.
