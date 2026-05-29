# Event Contract Annotations

Use local comments to document OpenMW-Lua event contracts near the sender, receiver, or shared event name. These comments are repo guidance and review aids; they are not public API docs unless the code already exposes a public contract.

## Syntax

```lua
---@event-contract <EventName> key=value key=value
```

Supported fields:

- `ack`: acknowledgement event name. Omit `ack` when no acknowledgement is required.
- `mutates`: compact mutation target, for example `storage`, `ui`, `actor`, `settings`, or `none`.
- `delayed`: `true` when delivery or handling may be intentionally deferred. Omit it otherwise.
- `receiver`: expected receiver context or module, for example `global`, `player`, `menu`, `scripts.s3.music.global`.

## Request/Ack/Defer Pattern

When an event crosses context boundaries and the sender needs evidence of handling, use a request event with a documented acknowledgement. `ack=<AckEventName>` is a checked contract: `openmw-event-lifecycle-contract-check` expects the scanned set to include a matching acknowledgement event send or handler unless the contract has an explicit external caveat. If the receiver may defer work because storage, UI ownership, or object lifetime is not ready, mark `delayed=true` and emit a compact ack or trace when the deferred work is accepted.

## Examples

```lua
---@event-contract S3MusicRequest ack=S3MusicAck mutates=storage delayed=true receiver=global
local EVENT_REQUEST = 'S3MusicRequest'

---@event-contract S3MusicAck mutates=none receiver=player
local EVENT_ACK = 'S3MusicAck'
```

```lua
---@event-contract S3UiRefresh mutates=ui receiver=menu
self:sendEvent('S3UiRefresh', { generation = generation })
```

## Validation Tools

Use these when annotations touch Lua behavior:

- `openmw-event-bus-check` for event sender/handler consistency.
- `openmw-event-lifecycle-contract-check` for `---@event-contract` syntax, `ack=<AckEventName>` evidence, and deferred contract fields.
- `openmw-context-check` for context legality and require boundaries.
- `openmw-engine-handler-check` when contracts interact with handlers or lifecycle.
- `openmw-storage-audit` when `mutates=storage`, settings, or persistent state is involved.
