---
title: LogMessage
description: Print diagnostic messages from local, player, global, and load scripts.
weight: 61
extra:
  kind: api
---

{{ api_signature(value="require 'scripts.s3.logmessage' → LogMessage; LogMessage(...)") }}

Use LogMessage when the same debug helper needs to work from more than one OpenMW script context. It picks the available output path for you.

{% usage_note(title="OpenMW runtime · Context-specific delivery") %}
This helper supports `local`, `player`, `global`, and `load` scripts. It is not a menu helper. The context is selected when the module is required; do not move a loaded function between contexts and expect its delivery behavior to change.
{% end %}

```lua
local LogMessage = require 'scripts.s3.logmessage'

LogMessage('Loaded record', recordId, 'count', count)
```

| Context | Delivery |
| --- | --- |
| `player` | Prints to the player's console with the success color. |
| `local` | Sends `S3LFDisplay` to nearby players. |
| `global` | Sends `S3LFDisplay` to every current player. |
| `load` | Uses ordinary `print`, which is available during load processing. |

There is no H3 prefix. Each call allocates an argument table and joined string, returns nothing, and stringifies arguments with `tostring`.

S3lf exposes the same helper as lowercase `s3lf.consoleLog(...)`; use this module when you do not need the S3lf facade.

Use LogMessage for diagnostics, not gameplay events or persistence. Local and global delivery is event-based and may not be displayed when the call returns.
