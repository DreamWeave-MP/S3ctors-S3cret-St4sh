+++
title = "VFS and Package Boundaries"
description = "Put SSS modules and their assets where OpenMW can actually see them."
weight = 30

[extra]
api_docs = true
kind = "compatibility"
+++

## Module discovery

SSS scans the OpenMW VFS prefix:

```text
scripts/staticSwitcher/data/
```

Only `.yaml` and `.yml` files under that prefix are loaded as modules. A file in the repository's `Examples/` directory is useful source material but is not discovered merely because it exists in a checkout. Put the copyable module in an active OpenMW data directory with the VFS path above.

The release page's `data_directories` metadata describes the package root. Your mod manager or `openmw.cfg` must make that root visible, and the content list must enable `Static Switching System.esp` as documented on the [product page](@/static_switching_system/index.md).

## Resource paths

Static replacement values and action paths such as `add_lua_script`, `remove_lua_script`, and sound `file` are VFS paths. They are not paths relative to the YAML file and are not guaranteed to resolve from a source checkout. Use forward slashes in module data and make the exact resource available in an active package.

For meshes, SSS normalizes separators and treats the `meshes/` prefix consistently when matching records. The replacement file still has to exist in the VFS. For Lua scripts, the path must be the script's VFS path, not a `require` module name.

## Case and package boundaries

OpenMW data and VFS visibility are authoritative. Keep directory and file spelling consistent, especially when moving a mod between platforms or mod managers. A path that exists on disk but is outside the configured data directories is missing to SSS.

## Content and record IDs

Values such as `mudcrab`, `gold_001`, `trap_fire00`, and `Morrowind.esm` are content identifiers or content filenames, not filesystem paths. They must be supplied by the active content set. `content_file_target` additionally requires the matching local reference number in that content file.

## Diagnostic checklist

- Confirm the data directory containing `scripts/staticSwitcher/data/` is enabled.
- Confirm the YAML extension is `.yaml` or `.yml` and the file is below the exact discovery prefix.
- Confirm the replacement mesh, Lua script, or sound file is in an active VFS package.
- Confirm the relevant plugin/content file is enabled when a record ID or destination cell comes from it.
- Read the first missing-resource or module-load error in `openmw.log`, not only the final symptom.

Continue with [troubleshooting](@/static_switching_system/docs/compatibility/troubleshooting.md).
