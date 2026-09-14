---
title: Dialogue canonicalization
weight: 40
description: OpenMW dialogue reconstruction, liveness, TESCS dirt cleanup, provenance, and canonical physical serialization.
---

# Dialogue canonicalization

Dialogue was the hardest part of master decoupling because Starwind does all of
the following at once:

- defines thousands of new INFOs;
- semantically modifies some Bethesda INFOs;
- intentionally deletes large portions of inherited dialogue;
- relies on some inherited Bethesda INFOs unchanged;
- contains substantial TESCS-generated chain/link dirt;
- reuses Bethesda races/classes/factions without necessarily reusing same-named dialogue topics.

The final solution is a physical canonicalization pass validated against
OpenMW's effective behavior.

## Compatibility oracle: OpenMW

`merge_to_master` has a deliberate Morrowind.exe-oriented dialogue merge model.
During investigation, its `DialogueGroup::insert_info()` and final link repair
were compared with OpenMW behavior.

The project did **not** fork MTM. Once source dirt and liveness errors were
removed, the final masterless plugin could match OpenMW exactly without
changing MTM itself.

Definitive asks one question:

> Does OpenMW construct exactly the intended effective dialogue database from the final plugin?

Morrowind.exe is not a target.

## OpenMW insertion model

The independent validator models the important placement rules:

- INFO identity is TES3 case-insensitive;
- `prev_id` is the placement authority;
- empty `prev_id` inserts at the beginning;
- known predecessor inserts after the predecessor;
- missing predecessor appends;
- same-ID override with unchanged predecessor replaces in place;
- same-ID override with changed predecessor moves the existing node;
- the insertion location is determined before the existing node is moved, matching OpenMW list/splice behavior;
- `next_id` is audited but is not treated as the insertion authority.

## Why exact physical equality eventually became achievable

Early validators distinguished behavioral equivalence from physical equality
because old source history produced many harmless link/order discrepancies.
After source cleanup and tombstone stripping, that distinction no longer needs
to excuse the final product: current strict builds have zero effective-order,
physical-order, and serialized-link mismatches.

## Evolution of the liveness model

Several broader models were deliberately tried and rejected.

### Full inherited dialogue: rejected

Keeping all Morrowind/Tribunal/Bloodmoon dialogue defeated the purpose of a
masterless Starwind edition and imported enormous quantities of irrelevant
TES lore.

### Starwind-owned INFOs only: rejected

Starwind genuinely relies on some unchanged inherited engine/generic dialogue.
A provenance-only slice was therefore too aggressive.

### Recursive response-text topic discovery: rejected

Following clickable-topic-looking words through vanilla response text exploded
through the Morrowind dialogue graph.

### One-hop response-text discovery: rejected

Even one hop imported ordinary words/lore topics such as `argonian`, `bosmer`,
`nord`, `orc`, `vivec`, `skooma`, `Ghostgate`, and `Nerevar` simply because
those strings happened to match vanilla DIAL IDs.

The last proposed exception, `price on your head`, was manually inspected. Its
six inherited INFOs were Morrowind Thieves Guild bounty-removal dialogue
involving Phane Rielle, Tongue-Toad, Rissinia, Crazy-Legs Arantamo,
`PCHasGoldDiscount`, `PayFineThief`, and `Gold_001`. That confirmed the final
rule: **plain response text does not create inherited DIAL dependencies.**

### Current topic-liveness sources

Dialogue-specific evidence may keep/materialize a topic when it is justified by
things such as:

- physical Starwind DIAL/INFO ownership;
- engine-driven dialogue families;
- explicit script `AddTopic` dependencies;
- explicitly reviewed special cases.

Typed non-dialogue dependency is independent. Reusing `RACE "Argonian"` for
Gungans does not imply keeping Morrowind's `DIAL "argonian"` lore topic.

## Source hygiene: parent-aware classification

`dialogue_source_hygiene.py` compares each Starwind source to the parent state
it actually inherits:

```text
V1.15 parent:
    Morrowind -> Tribunal -> Bloodmoon

RemasteredPatch parent:
    Morrowind -> Tribunal -> Bloodmoon -> V1.15
```

Physical INFOs are classified as:

| Category | Meaning |
| --- | --- |
| `NEW_INFO` | no active inherited INFO with this topic/ID |
| `MODIFIED_PARENT` | same inherited ID, semantic payload changed |
| `REDUNDANT_EXACT_COPY` | byte-for-byte inherited copy |
| `PROBABLE_TESCS_LINK_DIRT` | semantic payload identical; only `prev_id` / `next_id` changed |
| `DELETED_PARENT_OVERRIDE` | intentionally suppresses active inherited INFO |
| `REDUNDANT_DELETE` | parent was already deleted |
| `ORPHAN_DELETE` | deletes no known inherited INFO |

The label `PROBABLE_TESCS_LINK_DIRT` does **not** mean automatically safe to
delete: a neighbor's link change can be the mechanical representation of an
intentional inserted Starwind INFO. Those records must be evaluated in context.

## The 3,002 exact-copy cleanup

A parent-aware audit of the old RemasteredPatch found:

```text
13,077 physical INFOs

4,659  NEW_INFO
  337  MODIFIED_PARENT
3,002  REDUNDANT_EXACT_COPY
  260  PROBABLE_TESCS_LINK_DIRT
4,819  DELETED_PARENT_OVERRIDE
```

The **3,002 exact inherited copies** were removed as source dirt. They changed
neither payload nor chain links relative to the inherited parent.

### `Hello` example

At one point RemasteredPatch physically carried **5,121 `Hello` INFOs**:

```text
 979  genuinely new
  11  semantic parent modifications
 810  exact inherited copies
 129  link-only inherited overrides
3192  inherited deletions
```

That shape is classic TESCS dialogue history, not 5,121 intentional Starwind
responses.

Removing exact copies also eliminated an apparent Helseth ordering problem
without any special merge-engine workaround.

## Dead Tribunal-journal leftovers

Three V1.15 INFOs depended on Tribunal journal `TR08_Hlaalu >= 70` even though
masterless Starwind had no path that advanced that Tribunal quest:

```text
19191290671947220251
192701535310983235
3221696071812632454
```

They were removed from Starwind source with `tes3cmd`.

A fourth Helseth `Hello` INFO requiring `TR08_Hlaalu >= 100` had already
vanished as part of the exact-copy cleanup.

`TR08_Hlaalu` itself is a valid Tribunal Journal DIAL; the error was retaining
unreachable Tribunal dialogue, not referencing a nonexistent ID.

## The 53 staged vanilla faction INFOs

The closure model identified 53 unique inherited INFOs responsible for all real
Morag Tong / Hands of Almalexia / Census and Excise faction dependencies in the
then-current masterless build. They were intentionally removed only from the
staged Bethesda masters.

This is documented in detail under [Master decoupling](../master-decoupling/).

## Actor-liveness timing

An important later discovery was that the expected dialogue population must be
the actor population **at the moment Rust performs dialogue liveness**, not the
final population after surviving dialogue has triggered the second closure.

Rust now emits a pre-dialogue population snapshot into `decoupleLog.txt`; the
Python validator consumes that snapshot. This eliminated a false expectation
of hundreds of inherited INFOs for actors that were imported only after
liveness was decided.

## Late-actor provenance cleanup

A provenance pass on an earlier corpus found 94 actors imported only after
dialogue liveness. Eighty-two were kept solely by Starwind physical INFOs that
were semantically identical to inherited INFOs and differed only in chain
links. Removing that TESCS dirt caused the late actor trees and their transitive
dependencies to disappear naturally.

The full Definitive corpus currently has a much smaller late-actor diagnostic
set under review. Late-actor presence is forensic information, not by itself a
reason to delete an NPC.

## Final tombstone result

Before final INFO tombstone suppression, a prior masterless artifact contained
exactly **4,826** more physical INFO records than the expected effective set.
Every excess record was a deletion tombstone.

The decoupler was changed so deleted INFOs:

- still suppress inherited parent INFOs during reconstruction;
- do not count as live owned INFOs;
- do not participate in liveness;
- are not serialized into the final masterless DIAL/INFO section.

Afterward:

```text
physical INFO set == expected live INFO set
physical INFO order == OpenMW effective order
serialized prev/next == canonical survivor links
```

That is the current Definitive standard.

## Current result

```text
expected live DIALs                    591
Definitive DIALs                       591
missing / extra DIALs                  0 / 0
missing / extra live INFOs             0 / 0
engine-order mismatches                 0
precedence inversions                   0
physical-order mismatches               0
serialized-link mismatches              0
dialogue content mismatches             0
INFO content mismatches                 0
orphan INFOs                            0
```

The current dialogue layer is therefore not merely behaviorally equivalent; it
is physically canonical according to the project's OpenMW model.

[API index](../) · [Master decoupling](../master-decoupling/) · [Historical cleanup ledger](../historical-cleanup-ledger/)
