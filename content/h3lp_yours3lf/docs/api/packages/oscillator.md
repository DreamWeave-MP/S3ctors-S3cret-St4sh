---
title: oscillator
description: Sample a smooth periodic value from real or simulation time.
weight: 71
extra:
  kind: api
---

{{ api_signature(value="require 'scripts.s3.oscillator'(period, simulation?) → pulse") }}

Use `oscillator` for presentation values such as fades, pulses, and breathing indicators when the caller wants to sample a phase inside an existing update loop. It does not register a handler or advance when sampled.

```lua
local oscillator = require 'scripts.s3.oscillator'
local pulse = oscillator(2.0, true)

local smooth, phase = pulse()
setAlpha(smooth)
```

`period` must be greater than zero. Omit `simulation` or pass `false` to use real time; pass `true` to use simulation time, which follows pause and time scale. Each call returns a smooth sine-shaped value in `[0, 1]` and the raw sawtooth phase in `[0, 1)`.

The constructor captures the selected clock's start time and returns a closure. Sampling does not allocate a result table and does not depend on how often the caller polls. The closure is runtime state, not save data; reconstruct it from persisted inputs if its phase matters.
