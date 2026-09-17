---
title: Putting Agents and Skills Together
description: Compose Cod3x agents and skills into focused OpenMW investigation, implementation, review, and release workflows.
weight: 40
extra:
  kind: guide
---

Agents and skills are designed to compose, but not to become one enormous “OpenMW expert” prompt.

A useful task usually has one primary owner, zero or one specialist investigation, and one or two skills that define the important engineering contracts.

## UI work

For a normal implementation, stay in the primary coding agent and load the narrow skills you need:

```text
Implement this inventory panel using openmw-ui-layout-author and
openmw-lua-context-guard. Preserve the existing root ownership model.
```

When the bug depends on runtime behavior, delegate the investigation:

```text
Use openmw-ui-specialist to investigate this disappearing root. Have it
apply openmw-ui-runtime-debugger and openmw-lifecycle-debugger, and return
the smallest evidenced fix rather than rewriting the UI.
```

The distinction matters. `openmw-ui-layout-author` describes how to build a sane surface. `openmw-ui-runtime-debugger` describes how to prove a runtime failure. `openmw-ui-specialist` is useful when the task requires enough source, trace, or lifecycle investigation to deserve its own child context.

## Existing-save bugs

Start from compatibility, not from the current default value:

```text
Use openmw-save-data-specialist to investigate why this works on a new game
but not an upgraded save. Apply openmw-persistence-storage-auditor and
openmw-lifecycle-debugger. Identify the old persisted shape before editing it.
```

If cross-context timing is involved, add `openmw-runtime-ordering-auditor`. Do not “fix” an existing-save report by unconditionally reinitializing state on load; that is often just data loss with better timing.

## Missing or wrong assets

A repository tree is not the VFS.

```text
Use openmw-vfs-specialist to establish the requested path, provider order,
winning file, shadowed files, and casing. If the shipped asset itself is
wrong, use openmw-asset-pipeline-checker to trace it back to its source or
generator.
```

If the repository is correct but the release is not, bring in `openmw-mod-release-packager` and compare the staged archive against the documented paths.

## TES3 compatibility work

Keep record evidence separate from runtime conclusions:

```text
Use tes3-plugin-analyst to identify the exact records and placed references
changed by these plugins. State which conclusions require the complete load
order. Then review any affected asset paths with openmw-vfs-specialist.
```

When the plugin change also changes Lua initialization or persistent state, involve `openmw-save-data-specialist` rather than asking the plugin agent to improvise a save contract outside its domain.

## Performance work

Do not ask a performance skill to bless a clever diff after the fact.

```text
Use openmw-performance-hotpath-reviewer to establish why this path is hot,
its frequency/fanout, the suspected mechanism, and the measurement needed.
Only then propose the smallest change.
```

For Cod3x itself, a performance-related stub/API change may also need `cod3x-luals-stub-maintainer`; for a public helper used by downstream mods, it may need `lua-public-api-curator`.

## Public API changes

A common sequence for shared Lua infrastructure is:

1. use `lua-public-api-curator` to define the intended public path and contract;
2. use `openmw-lua-context-guard` if the API reaches engine-owned modules;
3. use `openmw-persistence-storage-auditor` if callers will persist its values;
4. use `openmw-performance-hotpath-reviewer` only when the API sits on a measured hot path;
5. update Cod3x annotations with `cod3x-luals-stub-maintainer` only when Cod3x itself is the API model being changed.

This keeps public contract work from becoming an accidental dump of internal implementation details.

## Release review

A release pass should be boring:

```text
Use openmw-mod-release-packager to compare the staged archive, manifests,
.omwscripts, plugin names, asset paths, install docs, and release notes.
Do not publish or tag anything.
```

If the release contains generated assets, add `openmw-asset-pipeline-checker`. If it changes plugins, ask `tes3-plugin-analyst` only for the plugin questions that actually need record-level verification.

## Ask for output you can review

Good delegation ends with artifacts and evidence, not a personality report.

Useful requests specify what should come back:

```text
Return:
- concrete findings in severity order;
- file/record/path references;
- which claims came from source, runtime evidence, or inference;
- the smallest proposed change;
- validation performed;
- anything still version-sensitive or unverified.
```

That shape matches Cod3x's [evidence language](@/cod3x/docs/practice/evidence.md) and makes the specialist's result easy to integrate into the primary task.

## Do not outsource architecture by committee

Subagents are useful for parallel evidence gathering. They are not votes.

If three specialists touch a change, the primary agent or human maintainer must still reconcile ownership, compatibility, and architecture. Do not merge three locally reasonable recommendations into one globally incoherent subsystem merely because every specialist was correct inside its own boundary.

The final review remains the same one Cod3x expects from human-written code: inspect the diff, validate the contracts, run the relevant tests, and keep only the complexity that earned its existence.
