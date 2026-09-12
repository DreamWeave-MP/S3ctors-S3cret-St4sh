---
title: normalizePath
description: Normalize path spelling without resolving files or validating containment.
weight: 50
extra:
  kind: api
---

{{ api_signature(value="normalizePath(path: string) → string") }}

```lua
local normalizePath = require 'scripts.s3.normalizePath'
assert(normalizePath('Config\\MyMod//Icon') == 'config/mymod/icon')
```

The function lowercases the string, converts backslashes to forward slashes, and collapses repeated forward slashes. It returns the transformed string without mutating anything outside the call. It has no OpenMW imports or filesystem access.

{% usage_note(title="Normalization is not validation") %}
This does not check file existence, resolve `.` or `..`, remove a leading slash, or prove that a path stays inside a directory. Do not use it as a filesystem security boundary or blindly apply it to case-sensitive operating-system paths.
{% end %}

Input must be a string. There is no result cache; normalization performs string operations each time. Normalize stable identifiers once rather than repeatedly inside a hot callback.

See [Your First H3 Integration](@/h3lp_yours3lf/docs/getting-started/overview.md) for a runnable script and [Migrating helpers](@/h3lp_yours3lf/docs/migration/from-local-helpers.md) for a before/after comparison.
