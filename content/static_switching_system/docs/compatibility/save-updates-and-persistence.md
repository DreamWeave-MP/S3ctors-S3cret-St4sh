+++
title = "Updating and Removing Modules"
description = "Change or remove SSS modules without mistaking YAML edits for world-state edits."
weight = 20

[extra]
api_docs = true
kind = "compatibility"
+++

Changing a YAML module affects future matching. It does not rewrite changes already written to a save. A cleanup rule must be explicit and safe for the current quest/world state.

## Removing modules

> **Existing saves:** SSS does not guarantee safe module removal. Removing a module does not reverse changes it has already made. Keep a backup save before removing or substantially changing SSS modules.

## Updating modules

Keep a backup save before changing a broad instance rule or changing a module's path. An edited rule may have a different action hash and can be treated as a new application for an object; an old once-cache entry is not a general schema migration for arbitrary world effects. Use a new, intentional rule or a cleanup rule when the change needs to be staged.

Priority controls future module execution. It does not retroactively reorder historical static replacement chains in existing saves.

## Safe update sequence

1. Make a backup of the save.
2. Keep module paths and replacement assets stable when updating a static module.
3. Save and exit through the normal game flow.
4. Test broad module edits on a copy of the save first.
5. Load the save and inspect the log and affected cells.

Do not treat a YAML change as a rewrite of already-saved world state. Use a deliberate follow-up rule when a saved effect needs to change.
