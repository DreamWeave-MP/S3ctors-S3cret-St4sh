---
name: cod3x-luals-stub-maintainer
description: "Cod3x LuaLS/OpenMW stubs, openmw/*.lua, context annotations, classes/fields/overloads, and context-aware editor metadata."
---

# Cod3x LuaLS Stub Maintainer

Use this skill when maintaining Cod3x LuaLS/OpenMW stub files or context-diagnostic behavior.

## Core Rules

- Stubs are tooling/documentation contracts, not runtime code.
- The matching OpenMW source/API revision is authoritative. Official generated docs are the next reference; Cod3x should model them, not supersede them.
- Prefer incomplete but accurate types over confident incorrect precision.
- Do not invent precise shapes for dynamic handles, userdata, record-backed values, or version-dependent tables when OpenMW does not guarantee them.
- Keep LuaLS annotations valid: classes, fields, params, returns, overloads, aliases, generics, and custom context tags.
- Context annotations must reflect actual API availability for the target OpenMW revision.
- Document member-level context/version caveats next to the member when only part of a module or type is restricted.
- Do not change LuaLS project configuration merely to silence a bad stub; fix the model unless the configuration change is actually intended.

## Maintenance Guidance

- Preserve the boundary between runtime APIs and editor-only metadata.
- Keep any Cod3x context plugin aligned with the annotation vocabulary used by the stubs.
- When tightening a type or context, check upstream source/docs and representative project usage first.
- Prefer small targeted updates over broad rewrites that make review of generated metadata difficult.
- Add compatibility aliases only when upstream exposes them or Cod3x intentionally documents a supported compatibility layer.
- Include hover docs when they clarify semantics, ownership, lifetime, nil behavior, versioning, or context.

## Validation

- Run LuaLS diagnostics and Cod3x context checks when available.
- Confirm edited annotations parse and do not degrade completion, hover, or go-to-definition behavior.
- When upstream changed, record the OpenMW revision/source basis for the stub change.
- If automated validation is unavailable, state the manual checks and remaining uncertainty.
