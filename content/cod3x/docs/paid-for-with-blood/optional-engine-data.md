---
title: Paid For With Blood — The Content Does Not Owe You a Happy Path
description: Cells do not necessarily have pathgrids, and annotations must describe real data.
weight: 40
extra:
  kind: guide
---

Cod3x once annotated a cell pathgrid as though it necessarily existed.

Real content disagreed.

Commit [`f834f17e`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/f834f17e9bd18837d68faf60b80678bad23aa384) corrected the field to be optional.

## The rule

**Model what the engine can actually return, not what well-behaved content usually contains.**

This matters for:

- optional records;
- ownership fields;
- cell data;
- magic fields;
- content added by mods;
- transitional engine state;
- objects in inventories/containers.

A type system that lies confidently is worse than one that admits uncertainty.

The same principle applies to runtime code. If absence is valid input, handle it. If absence violates a true invariant, assert with a useful message.

Source: S3ctors S3cret St4sh [commit `f834f17e`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/f834f17e9bd18837d68faf60b80678bad23aa384).
