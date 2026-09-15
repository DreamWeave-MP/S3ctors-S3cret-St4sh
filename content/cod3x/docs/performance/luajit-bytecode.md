---
title: LuaJIT Bytecode Analysis
description: Read what the VM receives before guessing what source syntax costs.
weight: 50
extra:
  kind: guide
---

Bytecode inspection is the first useful step below source code.

It tells you what operations LuaJIT's VM sees before tracing/native compilation enters the picture.

## Start outside the game

For isolated modules or reduced reproductions, use the LuaJIT command-line bytecode dumper.

A typical workflow is:

```bash
luajit -bl script.lua
```

The OpenResty/Rubic0n lineage also contains bytecode-dump extensions for source line display and constant tables. Availability depends on the exact runtime build, so verify the executable you are using rather than assuming every OpenMW LuaJIT has identical tooling.

Useful questions include:

- How many table/global lookups does this source form produce?
- Is a closure allocated inside the loop?
- Is a value recomputed on every iteration?
- Did a refactor change the bytecode shape at all?
- Is a helper abstraction actually in the hot instruction stream?

## Bytecode is not a benchmark

Fewer instructions do not automatically mean faster representative execution.

LuaJIT may trace both forms into similar machine code. An engine call may dominate both. Allocation or GC effects may matter more than instruction count.

Use bytecode to understand shape, then measure.

## Compare small reductions

When investigating one transformation, isolate it.

For example:

```lua
for index = 1, #items do
  consume(items[index])
end
```

versus an iterator form.

Or:

```lua
local Lower = string.lower

for index = 1, #items do
  consume(Lower(items[index]))
end
```

versus pre-normalizing the input before the hot loop.

The second comparison is usually more interesting because it removes work entirely rather than merely changing dispatch.

## Watch constants and closures

Bytecode can expose accidental work such as:

- function construction inside frequently called functions;
- table literals rebuilt each iteration;
- repeated constant/path setup;
- repeated module/member traversal.

Do not mechanically remove every allocation. Ask whether it is on the hot path and whether changing lifetime would complicate ownership.

## Preserve source readability

If two source forms compile equivalently enough for the workload, choose the one people can safely maintain.

Performance work is successful when the code is both faster and still understandable six months later.

## Bytecode is the beginning, not the bottom

If the relevant code becomes hot, LuaJIT's trace compiler may transform the executed path dramatically.

The next questions are about traces, guards, aborts, and side exits.

See [LuaJIT Traces, Aborts, and Side Exits](@/cod3x/docs/performance/luajit-traces.md).
