---
name: openmw-asset-pipeline-checker
description: ".nif, .dds, textures, meshes, atlases, generator scripts, asset paths, and package references for OpenMW mods."
---

# OpenMW Asset Pipeline Checker

Use this skill when reviewing, debugging, or changing OpenMW asset files, generators, atlases, or references.

## Checks

- Treat VFS asset paths as case-sensitive for compatibility analysis.
- Distinguish source assets from generated outputs before editing a binary or reviewing diffs.
- Identify generator inputs, outputs, dependencies, overwrite behavior, and reproducibility before running generation.
- Check NIF/DDS/icon/sound names for exact spelling, extension casing, and downstream references.
- Keep package paths portable: no accidental absolute/user-specific paths or platform-only separators.
- When a pipeline has multiple platform scripts, compare their declared inputs/outputs instead of assuming parity.
- Do not directly rewrite opaque binary assets when a source asset or generator is the intended authority.
- After generation, validate the changed file set and all references; generated output is not self-validating.

## Workflow

1. Search every reference before renaming, moving, or deleting an asset.
2. Map source -> generator -> generated output -> VFS path -> plugin/Lua/site/package consumer.
3. Run generators only after understanding side effects.
4. Compare declared outputs with actual outputs.
5. For atlases, verify dimensions, ordering, and coordinate metadata when applicable.
6. Confirm regeneration inputs are committed or clearly documented.
7. Use VFS/archive inspection when the problem depends on provider order rather than the repository tree alone.

Binary diffs can prove that bytes changed, not that the visual result is correct; use a renderer/runtime or trusted asset inspector when visual correctness matters.
