---
title: Tools & commands
weight: 90
description: Build executables, provenance, report scripts, and common forensic commands.
---

# Tools & commands

## `build_starwind.py`

The supported build entry point.

```bash
./build_starwind.py --strict
./build_starwind.py --strict --keep-work
```

It owns the definitive source graph, preprocessing sequence, merge order,
decoupling, validation, and Data/content split orchestration.

## `tes3conv`

Converts canonical JSON source to TES3 plugins and is also used by validators
to inspect final binaries as JSON.

Historical Builder provenance established `tes3conv` **0.4.1** as the expected
version; the old Makron build image used the same release.

## `merge_to_master`

Greatness7's TES3 merge tool.

Invocation convention:

```bash
merge_to_master <plugin> <master>
```

The merged result is written to the second argument.

Its dialogue implementation was studied closely during the dialogue work, but
Definitive validates against OpenMW rather than requiring MTM's
Morrowind.exe-oriented internal chain behavior to be the final oracle.

## `tes3cmd`

Used for deterministic source/build-workdir surgery and diagnostics.

Common forensic patterns:

```bash
tes3cmd dump --type INFO --exact-id "<id>" plugin.esm

tes3cmd dump --type INFO --sub-match "text" plugin.esm

tes3cmd delete --type INFO --exact-id "<id>" plugin.esm
```

`--sub-match` is broad. It can match response text and unrelated fields, so its
output must not be treated as an exact dependency list without further
provenance filtering. This was demonstrated by the dead-faction dialogue audit:
a broad search produced 563 IDs while exact closure provenance found 53 actual
causal INFOs.

`tes3cmd` writes backup files (`~1.esm`, etc.). Validation code that scans staged
plugins must exclude those backups unless it explicitly intends to inspect
history.

## `addVanillaRefs`

motherJungle decoupler.

Responsibilities include:

- recursive Bethesda dependency import;
- dialogue reconstruction/liveness/materialization;
- pre-dialogue actor-population telemetry;
- second closure after dialogue materialization;
- master removal;
- final masterless canonicalization helpers.

Its build log is captured as:

```text
.swbuild/definitive/work/decoupleLog.txt
```

The log is part of the validator API: dialogue materialization reasons and the
pre-liveness actor population are consumed by independent Python tools.

## `motherjungle_audit.py`

Historical build/helper module and hard-reference closure auditor.

The modern Definitive builder reuses parsing/audit helpers but does not expose
the old build-mode matrix as a product interface.

## `dialogue_source_hygiene.py`

Parent-aware source dialogue forensics.

Typical use:

```bash
./dialogue_source_hygiene.py
./dialogue_source_hygiene.py --topic hello
```

Use it to distinguish new INFOs, semantic parent modifications, exact copies,
link-only TESCS dirt, and deletion overrides.

## `dialogue_chain_audit.py`

Independent OpenMW dialogue oracle.

```bash
./dialogue_chain_audit.py
./dialogue_chain_audit.py --strict-structure
```

The Definitive builder invokes the appropriate strict checks automatically.
Manual invocation is useful when iterating on dialogue/source cleanup.

## `late_actor_provenance.py`

Explains actors that appear only after dialogue liveness and second closure.

Typical invocation:

```bash
python3 late_actor_provenance.py \
  --log .swbuild/definitive/work/decoupleLog.txt \
  --standalone .swbuild/definitive/out/Starwind-Definitive.omwaddon \
  --report .swbuild/definitive/reports/late-actor-provenance.json \
  --markdown .swbuild/definitive/reports/late-actor-provenance.md
```

Late actors are investigation targets, not automatic prune candidates.

## `split_starwind.py`

Partitions an already-valid masterless monolith and validates the serialized
pair.

```bash
./split_starwind.py \
  --source .swbuild/definitive/out/Starwind-Definitive.omwaddon \
  --data-output .swbuild/definitive/out/Star_Data.omwaddon \
  --content-output .swbuild/definitive/out/Starwind.omwaddon \
  --report .swbuild/definitive/reports/starwind-split-report.json
```

## External provenance

- Starwind-Builder: <https://github.com/DreamWeave-MP/Starwind-Builder/>
- motherJungle: <https://github.com/DreamWeave-MP/motherJungle>
- merge_to_master: <https://github.com/Greatness7/merge_to_master>
- tes3conv 0.4.1: <https://github.com/Greatness7/tes3conv/releases/tag/v0.4.1>
- OpenMW: <https://github.com/OpenMW/openmw>

## Debugging order

When a build fails, investigate from the earliest violated invariant rather
than patching the final output:

```text
source preprocessing / MQ guard
    -> canonical merge
    -> hard closure
    -> dialogue liveness/order/content
    -> split dependency direction/reconstruction
    -> late-actor provenance / optional source hygiene
```

If closure is nonzero, do not "fix" the final plugin by importing whatever is
missing until the causal source reference has been inspected. Several major
cleanup wins came from deciding that the causal dialogue/list/region edge was
wrong and should disappear instead.

[API index](../) · [Validation](../validation-and-reports/) · [Historical cleanup ledger](../historical-cleanup-ledger/)
