+++
title = "Getting Started"
description = "Install Static Switching System and author your first YAML module."
page_template = "docs/page.html"
sort_by = "weight"
weight = 10

[extra]
kind = "guide"
+++

New to SSS:

The `Examples/` directory contains **source fixtures**: shipped YAML examples that document valid module shapes but are not scanned by SSS. Copy or adapt one into an active data directory under `scripts/staticSwitcher/data/` before testing it.

1. Follow [Installation](@/static_switching_system/docs/getting-started/installation.md) to enable SSS and expose your module directory through the OpenMW VFS.
2. Follow [Your First Module](@/static_switching_system/docs/getting-started/first-module.md) with a static replacement and an instance rule.
3. Read [Pipelines and Module Boundaries](@/static_switching_system/docs/concepts/pipelines.md) before combining modules from different mods.
4. Keep the [schema reference](@/static_switching_system/docs/api/schema.md) open while authoring.

For a fast installation check, use the copyable [five-minute test](@/static_switching_system/index.md#start-here-a-five-minute-test) before writing a mesh replacement.

If installation succeeds but the module does not, see [Validation and Debugging](@/static_switching_system/docs/concepts/validation-and-debugging.md).
