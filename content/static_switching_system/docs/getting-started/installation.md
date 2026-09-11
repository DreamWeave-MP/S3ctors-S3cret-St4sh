+++
title = "Installation and VFS Discovery"
description = "Install SSS and put YAML modules in the directory the global script scans."
weight = 20

[extra]
kind = "guide"
+++

Install the Static Switching System release in an OpenMW data directory and enable `Static Switching System.esp`. The plugin registers the menu and global SSS scripts. SSS uses H3lp Yours3lf's shared `scripts.s3.*` helpers, so install and enable [H3lp Yours3lf](@/h3lp_yours3lf/index.md) first as a dependency.

Optional integrations have their own dependency: `has_tag`, `cell_tag`, `add_tag`, and `remove_tag` use the FlexTag interface when FlexTag is installed. Without FlexTag, those conditions do not match and those actions do not apply.

## Module directory

The global script scans the VFS prefix:

```text
scripts/staticSwitcher/data/
```

Every `.yaml` and `.yml` file under that prefix is a module candidate. Put your files in a mod data directory that OpenMW exposes at that VFS path. The scan is VFS-based, not relative to this documentation repository.

The shipped examples are not discovered modules. Copy one to your own VFS data directory and give it a stable filename. A useful installed layout is:

```text
MyMod/
├── scripts/
│   └── staticSwitcher/
│       └── data/
│           └── my_static_module.yaml
└── meshes/
    └── my_mod/
        └── replacement.nif
```

SSS normalizes path separators and mesh paths while loading. Use the exact VFS paths and casing shipped by the asset provider, and verify that every replacement mesh is actually available. A missing replacement mesh is reported and that replacement is skipped.

## First-load checklist

- `Static Switching System.esp` is enabled.
- `H3lp Yours3lf.esp` is enabled before SSS's shared helpers are needed.
- The YAML file is below `scripts/staticSwitcher/data/` and ends in `.yaml` or `.yml`.
- The module contains exactly one of `replace_meshes` or `instances`.
- Every referenced record, script path, sound path, and mesh is installed by the relevant mod.
- The file validates against the [module schema](@/static_switching_system/docs/api/schema.md).

SSS discovers modules when its global script initializes. Changes to the module set should be tested from a fresh load or a deliberately selected save; see [Loading, Processing, and Persistence](@/static_switching_system/docs/api/lifecycle.md).
