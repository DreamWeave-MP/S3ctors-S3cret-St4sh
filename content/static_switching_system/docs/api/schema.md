+++
title = "Schema and Editor Validation"
description = "Use SSS's JSON Schema and understand what it validates before runtime."
weight = 120

[extra]
api_docs = true
kind = "schema"
+++

The authoring schema is shipped at:

```text
Scripts/staticSwitcher/schema/replacerSchema.json
```

The schema is editor metadata; OpenMW does not read it at runtime. Put a directive at the top of each YAML file or associate the schema with the module glob in your editor.

For an installed module next to the packaged SSS scripts, use the equivalent path from the module file to the schema, for example:

```yaml
# yaml-language-server: $schema=../schema/replacerSchema.json
```

The relative path must match the files in your authoring workspace. If the module is maintained separately or the editor cannot resolve a VFS path, configure it with a filesystem copy of the shipped schema instead. A VS Code YAML extension association looks like this:

```json
{
  "yaml.schemas": {
    "/absolute/path/to/replacerSchema.json": [
      "**/scripts/staticSwitcher/data/*.yaml",
      "**/scripts/staticSwitcher/data/*.yml"
    ]
  }
}
```

Use the schema shipped with the SSS release, not one from a different release.

## Schema versus runtime validation

**Use your editor properly.** The shipped schema is the real authoring check. It catches field names, types, required fields, enum values, mutually exclusive root fields, and invalid range shapes, including top-level `once` on static modules, mixed static/instance roots, stale condition names such as `ref_num`, random action ranges with only `min`, and unknown priority values.

Runtime validation is only a smoke alarm. It reports warnings such as unknown top-level keys, an empty module root, or mixed root markers. Passing it does not make a module valid.

See [Module Format](@/static_switching_system/docs/api/module-format.md) for fields, [Comparison Ranges](@/static_switching_system/docs/api/conditions/comparison-ranges.md) and [Random Action Ranges](@/static_switching_system/docs/api/actions/random-ranges.md) for range syntax, and [Validation and Debugging](@/static_switching_system/docs/concepts/validation-and-debugging.md) for runtime diagnosis.
