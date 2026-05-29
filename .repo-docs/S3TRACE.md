# S3TRACE

`S3TRACE` lines are temporary OpenMW-Lua runtime evidence for debugging and review. They should be easy to grep, safe to paste into issue notes, and small enough to remove before release unless explicitly needed.

## Canonical Format

```text
S3TRACE|fixture=<fixture>|ctx=<context>|seq=<seq>|event=<event>|phase=<phase>|key=value
```

Required fields:

- `fixture`: short fixture or probe label, for example `music`, `ui`, `settings`.
- `ctx`: OpenMW-Lua context, for example `global`, `player`, `menu`, `local`.
- `seq`: monotonically increasing sequence, frame, tick, generation, or `na` when unavailable.
- `event`: stable trace event name, for example `request`, `ack`, `render`, `dispose`.
- `phase`: compact lifecycle phase, for example `send`, `receive`, `defer`, `apply`, `done`.

Optional fields:

- `id`: request, widget, object, or generation identifier.
- `receiver`: expected event or interface receiver.
- `state`: compact state label.
- `reason`: compact branch or failure reason.
- `count`: small numeric count.
- `ms`: elapsed milliseconds when already measured.

The H3 fixture formatter in `content/h3lp_yours3lf/scripts/s3/fixtures/trace.lua` is canonical for fixture output. It emits priority fields in this order: `fixture`, `ctx`, `seq`, `event`, `phase`, then any extra fields sorted by key. Older generated or ad hoc tooling may still emit space-separated lines such as `S3TRACE seq=... context=... phase=... event=...`; treat those as legacy evidence, not the H3 fixture canonical format.

## Rules

- Keep one trace fact per line.
- Prefer stable keys and low-cardinality values.
- Do not dump large tables, protected tables, UI trees, storage blobs, inventory lists, or full serialized payloads.
- Do not create golden logs or compare against golden trace output.
- Remove stale traces after the runtime question is answered, unless the trace is intentionally guarded and documented for ongoing diagnostics.
- Avoid trace lines in per-frame hot paths unless they are gated by a local debug flag.

## Examples

```text
S3TRACE|fixture=music|ctx=player|seq=1284|event=request|phase=send|id=region-ashlands|receiver=s3.music.global
S3TRACE|fixture=music|ctx=global|seq=1285|event=ack|phase=receive|id=region-ashlands|state=queued
S3TRACE|fixture=ui|ctx=menu|seq=42|event=dispose|phase=done|id=settings-panel|reason=generation-mismatch
```
