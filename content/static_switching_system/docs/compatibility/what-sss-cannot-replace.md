+++
title = "What SSS Cannot Replace"
description = "Know when a compatibility fix belongs in SSS and when it still needs plugin surgery."
weight = 30

[extra]
api_docs = true
kind = "compatibility"
+++

SSS is not a generic replacement for `tes3cmd` or an ESP patch. Its strength is live object-level world patching after OpenMW has resolved the content set.

## Good SSS candidates

Use SSS when the problem is a placed reference:

- a rock, tree, tower, chest, or NPC is in the wrong place;
- a specific placed object should not exist;
- a live object needs a different state;
- a mesh needs contextual replacement;
- a one-shot placement script only moves one object.

The [real-world translations](real-world-patches.md) demonstrate this boundary. They use `content_file_target`, cell constraints, `transform`, `teleport`, and `disable` without reproducing the original patch plugin.

## Keep plugin surgery

Keep using a plugin patch or the relevant build-time tool when the conflict is in plugin resolution itself:

- removing a `CELL` override;
- removing a `PGRD` record;
- deleting `LAND` data;
- deleting dialogue `INFO` records;
- removing or forwarding a base NPC record override;
- filtering plugin records before OpenMW resolves the world.

The [Modding-OpenMW actions catalog](https://gitlab.com/modding-openmw/modding-openmw.com/-/raw/master/momw/momw/data_seeds/data/actions.json) contains examples of these operations. They are valuable compatibility work, but they are not SSS conversions. A runtime object rule cannot change which plugin record wins resolution.

The rule is simple:

```text
placed reference is wrong or unwanted → SSS
plugin record must not participate in resolution → plugin patch / tes3cmd
```

Samarys Ancestral Tomb Corpse Fix remains on the plugin side of that line because it combines persistence and dialogue `INFO` behavior with object changes. SSS should not claim a translation where it cannot preserve the original contract.
