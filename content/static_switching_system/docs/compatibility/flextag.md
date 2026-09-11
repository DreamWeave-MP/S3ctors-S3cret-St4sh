+++
title = "FlexTag Compatibility"
description = "Use FlexTag tags as optional SSS conditions and actions."
weight = 10

[extra]
api_docs = true
kind = "compatibility"
+++

## What integrates

SSS can use the FlexTag global interface for four instance features:

- `has_tag` checks tags on the active object.
- `cell_tag` checks tags on the object's cell.
- `add_tag` assigns a tag.
- `remove_tag` removes a tag.

`cell_tag` and `has_tag` match any value when given a list. Use tag names provided by the FlexTag installation.

## Dependency behavior

These features are optional from SSS's point of view. When the `FlexTagG` interface is not available, tag conditions return false and tag actions cannot perform their operation. SSS does not create tag definitions for you. A module that depends on FlexTag should document and install that dependency before testing its rule.

## Persistence

Tags assigned by an instance action are not static replacement-chain steps. `once: true` can prevent the rule from being attempted again for that object, but changing the SSS YAML does not automatically remove a tag. If the tag must be cleaned up, author a deliberate `remove_tag` rule while the required interface is present, or use the owning tag system's normal cleanup process.
