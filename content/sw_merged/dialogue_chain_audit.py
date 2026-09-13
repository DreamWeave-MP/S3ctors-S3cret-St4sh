#!/usr/bin/env python3
"""
Reconstruct OpenMW TES3 dialogue ordering, compute the current liveness-aware
Starwind + required-vanilla slice, and compare it to Standalone.

v12 mirrors the narrowed dialogue-text materialization policy: arbitrary words in
response text do not create DIAL dependencies. Only explicitly allowlisted inherited
text topics may be materialized (currently 'price on your head'). It also retains
staged-master replay, provenance triage, actor proofs, and Rust telemetry.

This mirrors OpenMW's current ESM3 dialogue loading semantics:

- DIAL records are merged by ID; later DIAL data overrides earlier DIAL data.
- INFO records belong to the preceding DIAL.
- INFO ordering follows OpenMW ESM::InfoOrder::insertInfo():
    * Existing INFO with same ID and same prev_id is replaced in place.
    * Otherwise, INFO is inserted/moved immediately after prev_id.
    * If prev_id is non-empty and not found, INFO is appended.
    * If prev_id is empty, INFO is inserted at the beginning.
- Deleted INFOs remain during loading so later insertions can reference them.
- Deleted INFOs are removed only after all content files finish loading.
- next_id is NOT used by OpenMW to determine effective order.
- Deleted DIAL records erase the dialogue from the store.

Default expected load order for Starwind standalone equivalence:
    Morrowind.json
    Tribunal.json
    Bloodmoon.json
    StarwindRemasteredV1.15.json
    StarwindRemasteredPatch.json

Minimal.json is not included because it currently contains no DIAL/INFO records.
You can override the source stack with repeated --source arguments.

Usage:
    ./dialogue_chain_audit.py \
      --standalone .swbuild/standalone/out/Starwind-Standalone.omwaddon

Behavioral success means:
    1. Same required effective DIAL/INFO set and INFO payloads.
    2. Any OpenMW-effective INFO precedence inversions are provably unable to compete.
    3. No orphan INFOs.

Physical INFO order and serialized prev/next links are still audited, but are
diagnostic unless --strict-structure is requested.
"""
from __future__ import annotations

import argparse
import copy
import json
import os
import shutil
import subprocess
import sys
import tempfile
import regex as re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent
PLUGINS = ROOT / "plugins"

BASE_SOURCES = [
    PLUGINS / "Morrowind.json",
    PLUGINS / "Tribunal.json",
    PLUGINS / "Bloodmoon.json",
]

STAGED_STANDALONE_BASES = [
    ROOT / ".swbuild" / "standalone" / "work" / "Morrowind.esm",
    ROOT / ".swbuild" / "standalone" / "work" / "Tribunal.esm",
    ROOT / ".swbuild" / "standalone" / "work" / "Bloodmoon.esm",
]


def default_expected_bases() -> tuple[list[Path], str]:
    """Prefer the exact staged masters addVanillaRefs saw.

    These may contain intentional build-time pruning that is not present in the
    canonical plugins/*.json sources. Falling back to source JSONs keeps the
    validator usable before a standalone build exists.
    """
    if all(path.exists() for path in STAGED_STANDALONE_BASES):
        return STAGED_STANDALONE_BASES, "staged-standalone-workdir"
    return BASE_SOURCES, "canonical-source-json"


DEFAULT_EXPECTED_STARWIND = (
    ROOT / ".swbuild" / "solo" / "out" / "Starwind-Solo.omwaddon"
)

DEFAULT_PROVENANCE_SOURCES = [
    PLUGINS / "Morrowind.json",
    PLUGINS / "Tribunal.json",
    PLUGINS / "Bloodmoon.json",
    PLUGINS / "StarwindRemasteredV1.15.json",
    PLUGINS / "StarwindRemasteredPatch.json",
]


def norm_id(value: Any) -> str:
    return str(value or "").casefold()


def is_deleted(record: dict) -> bool:
    flags = str(record.get("flags", ""))
    return "DELETED" in flags.upper()


def dialogue_id(record: dict) -> str:
    return norm_id(record.get("id", ""))


def info_id(record: dict) -> str:
    return norm_id(record.get("id", ""))


def info_prev(record: dict) -> str:
    return norm_id(record.get("prev_id", ""))


def info_next(record: dict) -> str:
    return norm_id(record.get("next_id", ""))


def tool(name: str) -> Path:
    local = ROOT / name
    if local.exists() and os.access(local, os.X_OK):
        return local
    found = shutil.which(name)
    if found:
        return Path(found)
    raise SystemExit(f"ERROR: required tool {
                     name!r} not found beside script or in PATH")


def run(argv: list[str | Path], *, cwd: Path | None = None) -> None:
    cmd = [str(x) for x in argv]
    print("[dialogue-audit] $ " + " ".join(repr(x)
          if " " in x else x for x in cmd), flush=True)
    subprocess.run(cmd, cwd=cwd, check=True)


def load_records(path: Path) -> list[dict]:
    if path.suffix.lower() == ".json":
        return json.loads(path.read_text(encoding="utf-8"))

    with tempfile.TemporaryDirectory() as td:
        out = Path(td) / "plugin.json"
        run([tool("tes3conv"), "-o", path, out], cwd=ROOT)
        return json.loads(out.read_text(encoding="utf-8"))


@dataclass
class InfoEntry:
    record: dict
    deleted: bool
    source: str
    source_index: int


@dataclass
class DialogueState:
    record: dict
    source: str
    ordered_ids: list[str] = field(default_factory=list)
    infos: dict[str, InfoEntry] = field(default_factory=dict)

    def insert_info(self, record: dict, deleted: bool, source: str, source_index: int) -> None:
        """
        Python transcription of OpenMW components/esm3/infoorder.hpp insertInfo().
        """
        iid = info_id(record)
        prev = info_prev(record)

        if not iid:
            # TES3 INFO IDs should not be empty. Keep this visible as a hard anomaly.
            iid = f"__empty_info_id__:{source}:{source_index}"

        existing = self.infos.get(iid)

        # OpenMW:
        # if existing ID && existing.mPrev == value.mPrev:
        #     replace value in place, update deleted flag, return.
        if existing is not None and info_prev(existing.record) == prev:
            existing.record = copy.deepcopy(record)
            existing.deleted = deleted
            existing.source = source
            existing.source_index = source_index
            return

        # Determine insertion position.
        if not prev:
            before_index = 0
        elif prev in self.infos and prev in self.ordered_ids:
            before_index = self.ordered_ids.index(prev) + 1
        else:
            before_index = len(self.ordered_ids)

        if existing is None:
            self.ordered_ids.insert(before_index, iid)
            self.infos[iid] = InfoEntry(
                record=copy.deepcopy(record),
                deleted=deleted,
                source=source,
                source_index=source_index,
            )
            return

        # Existing ID with changed prev_id: replace record and splice/move it.
        # OpenMW determines the insertion iterator while the existing node is still
        # present, then std::list::splice moves the node.  Translate that iterator
        # into a post-removal list index.
        old_index = self.ordered_ids.index(iid)
        self.ordered_ids.pop(old_index)
        insertion_index = before_index - int(old_index < before_index)
        self.ordered_ids.insert(insertion_index, iid)
        self.infos[iid] = InfoEntry(
            record=copy.deepcopy(record),
            deleted=deleted,
            source=source,
            source_index=source_index,
        )

    def finalized_order(self) -> list[str]:
        # OpenMW Dialogue::setUp() => removeDeleted(), then extractOrderedInfo().
        return [iid for iid in self.ordered_ids if iid in self.infos and not self.infos[iid].deleted]


@dataclass
class ReplayResult:
    dialogues: dict[str, DialogueState]
    orphan_infos: list[dict]
    duplicate_dials_same_file: list[dict]


def replay_openmw(paths: list[Path]) -> ReplayResult:
    dialogues: dict[str, DialogueState] = {}
    orphan_infos: list[dict] = []
    duplicate_dials_same_file: list[dict] = []

    for path in paths:
        records = load_records(path)
        current_dialogue: DialogueState | None = None
        seen_dials_this_file: set[str] = set()

        for idx, rec in enumerate(records):
            typ = rec.get("type")

            if typ == "Dialogue":
                did = dialogue_id(rec)

                if did in seen_dials_this_file:
                    duplicate_dials_same_file.append({
                        "source": str(path),
                        "record_index": idx,
                        "dialogue_id": did,
                    })
                seen_dials_this_file.add(did)

                if is_deleted(rec):
                    # ESMStore::load(): erased static DIAL and `continue`s.
                    dialogues.pop(did, None)
                    # Preserve current_dialogue exactly like the C++ control flow does.
                    # A well-formed deleted DIAL should not be followed by INFO records.
                    continue

                if did in dialogues:
                    # Store<Dialogue>::load() calls loadData() on the existing Dialogue,
                    # preserving its InfoOrder.
                    dialogues[did].record = copy.deepcopy(rec)
                    dialogues[did].source = str(path)
                else:
                    dialogues[did] = DialogueState(
                        record=copy.deepcopy(rec),
                        source=str(path),
                    )

                current_dialogue = dialogues[did]
                continue

            if typ == "DialogueInfo":
                if current_dialogue is None:
                    orphan_infos.append({
                        "source": str(path),
                        "record_index": idx,
                        "info_id": rec.get("id", ""),
                    })
                else:
                    current_dialogue.insert_info(
                        rec,
                        is_deleted(rec),
                        str(path),
                        idx,
                    )
                continue

            # ESMStore sets dialogue=nullptr after any recognized non-DIAL record.
            # Header/other records similarly break INFO association in valid plugin layout.
            current_dialogue = None

    return ReplayResult(
        dialogues=dialogues,
        orphan_infos=orphan_infos,
        duplicate_dials_same_file=duplicate_dials_same_file,
    )


def extract_raw_standalone_chains(path: Path) -> tuple[dict[str, dict], list[dict]]:
    records = load_records(path)
    chains: dict[str, dict] = {}
    orphan_infos: list[dict] = []
    current: dict | None = None

    for idx, rec in enumerate(records):
        typ = rec.get("type")
        if typ == "Dialogue":
            did = dialogue_id(rec)
            current = {
                "dialogue_record": copy.deepcopy(rec),
                "physical_info_ids": [],
                "info_records": {},
                "record_index": idx,
            }
            # If malformed duplicate DIALs exist, preserve the last physical group;
            # replay_openmw() separately detects effective semantics.
            chains[did] = current
        elif typ == "DialogueInfo":
            if current is None:
                orphan_infos.append({
                    "record_index": idx,
                    "info_id": rec.get("id", ""),
                })
            else:
                iid = info_id(rec)
                current["physical_info_ids"].append(iid)
                current["info_records"][iid] = copy.deepcopy(rec)
        else:
            current = None

    return chains, orphan_infos


def semantic_info(record: dict) -> dict:
    """
    Compare effective INFO payload while excluding ordering/serialization-only fields.
    """
    r = copy.deepcopy(record)
    r.pop("flags", None)
    r.pop("prev_id", None)
    r.pop("next_id", None)
    return r


def semantic_dialogue(record: dict) -> dict:
    r = copy.deepcopy(record)
    r.pop("flags", None)
    return r


ENGINE_DIALOGUE_TYPES = {"greeting", "voice", "persuasion"}

def collect_physical_dialogue_ids(path: Path) -> dict[str, set[str]]:
    """Topic -> INFO IDs physically present in the pre-standalone Starwind plugin."""
    records = load_records(path)
    out: dict[str, set[str]] = {}
    current: str | None = None
    for rec in records:
        typ = rec.get("type")
        if typ == "Dialogue":
            current = dialogue_id(rec)
            out.setdefault(current, set())
        elif typ == "DialogueInfo" and current is not None:
            out[current].add(info_id(rec))
        else:
            current = None
    return out


def collect_scripts(path: Path) -> list[str]:
    return [
        str(rec.get("text", ""))
        for rec in load_records(path)
        if rec.get("type") == "Script"
    ]


def collect_actor_population(path: Path) -> list[dict[str, str]]:
    """
    The pruning pass runs after addVanillaRefs has imported dependency closure.
    The final standalone therefore provides the closest observable population
    for independently checking the dialogue liveness decision.

    Sex is included for precedence analysis. NPCs without FEMALE are male in TES3.
    Creature sex is left unknown so it never becomes an unsafe exclusion proof.
    """
    actors: list[dict[str, str]] = []
    for rec in load_records(path):
        typ = rec.get("type")
        if typ == "Npc":
            flags = str(rec.get("npc_flags", "")).upper()
            actors.append({
                "id": norm_id(rec.get("id")),
                "race": norm_id(rec.get("race")),
                "class": norm_id(rec.get("class")),
                "sex": "female" if "FEMALE" in flags else "male",
            })
        elif typ == "Creature":
            actors.append({
                "id": norm_id(rec.get("id")),
                "race": "",
                "class": "",
                "sex": "",
            })
    return actors


def parse_liveness_actor_population(path: Path | None) -> list[dict[str, str]] | None:
    """Read the actor snapshot emitted before Rust prunes dialogue."""
    if path is None or not path.exists():
        return None

    actors: list[dict[str, str]] = []
    in_snapshot = False
    complete = False
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if line == "Dialogue liveness population begin":
            actors = []
            in_snapshot = True
            complete = False
            continue
        if line == "Dialogue liveness population end":
            complete = in_snapshot
            in_snapshot = False
            continue
        if not in_snapshot or not line.startswith("Dialogue liveness actor\t"):
            continue
        fields = line.split("\t")
        if len(fields) != 6:
            continue
        _, actor_type, actor_id, race, cls, sex = fields
        actors.append({
            "id": norm_id(actor_id),
            "race": norm_id(race),
            "class": norm_id(cls),
            "sex": norm_id(sex),
        })

    return actors if complete else None


def normalize_dialogue_type(value: Any) -> str:
    return norm_id(value).replace("_", " ").strip()


def add_script_topic_references(
    text: str,
    topic_ids: list[str],
    live_topics: dict[str, set[str]],
) -> None:
    # Mirrors current removeVanillaDials.patch: actual AddTopic command parsing,
    # one operand, quoted or bare, case-insensitive.
    lookup = {topic.casefold(): topic for topic in topic_ids}
    for line in text.splitlines():
        stripped = line.lstrip()
        if stripped.startswith(";") or len(stripped) < len("AddTopic"):
            continue
        command = stripped[:len("AddTopic")]
        rest = stripped[len("AddTopic"):]
        if command.casefold() != "addtopic" or not rest[:1].isspace():
            continue
        operand = rest.lstrip()
        if operand.startswith('"'):
            operand = operand[1:].split('"', 1)[0]
        else:
            operand = operand.split(None, 1)[0] if operand else ""
        topic = lookup.get(operand.casefold())
        if topic:
            live_topics.setdefault(topic, set()).add("SCRIPT_TOPIC")


def info_can_match_actor(record: dict, actors: list[dict[str, str]]) -> bool:
    speaker_id = norm_id(record.get("speaker_id"))
    race = norm_id(record.get("speaker_race"))
    cls = norm_id(record.get("speaker_class"))
    faction = norm_id(record.get("speaker_faction"))

    has_known = bool(speaker_id or race or cls)
    has_candidate = any(
        (not speaker_id or actor["id"] == speaker_id)
        and (not race or actor["race"] == race)
        and (not cls or actor["class"] == cls)
        for actor in actors
    )

    if has_known and not has_candidate:
        return False

    # Faction membership/rank is runtime state; current pruning deliberately
    # treats it as unable to prove impossibility.
    if faction:
        return True

    return True


def build_liveness_projection(
    effective: ReplayResult,
    starwind_ids: dict[str, set[str]],
    scripts: list[str],
    actors: list[dict[str, str]],
) -> tuple[dict[str, dict], dict]:
    """
    Independently mirrors the current removeVanillaDials.patch policy:

       live topic =
         physically present in Starwind
         OR engine-driven Greeting/Voice/Persuasion
         OR referenced by Starwind AddTopic

      live INFO in a live topic =
        Starwind-owned
        OR can plausibly match a standalone actor

    Surviving INFOs remain in the effective OpenMW order and are canonically
    relinked after pruning.
    """
    live_topics: dict[str, set[str]] = {}

    for topic in starwind_ids:
        live_topics.setdefault(topic, set()).add("STARWIND_TOPIC")

    for topic, state in effective.dialogues.items():
        dtype = normalize_dialogue_type(state.record.get("dialogue_type"))
        if dtype in ENGINE_DIALOGUE_TYPES:
            live_topics.setdefault(topic, set()).add("ENGINE_TOPIC")

    topic_ids = [t for t in effective.dialogues if t]
    for script in scripts:
        add_script_topic_references(script, topic_ids, live_topics)

    projection: dict[str, dict] = {}
    audit = {
        # All effective INFOs in the reconstructed OpenMW database, before liveness.
        "effective_infos": sum(
            len(state.finalized_order()) for state in effective.dialogues.values()
        ),
        # INFOs examined because their containing topic is live.
        "live_topic_effective_infos": 0,
        "starwind_owned_infos": 0,
        "retained_vanilla_infos": 0,
        "pruned_vanilla_infos": 0,
        "keep_reasons": {},
        "live_topics": len(live_topics),
    }

    def reason(name: str) -> None:
        audit["keep_reasons"][name] = audit["keep_reasons"].get(name, 0) + 1

    for topic, state in effective.dialogues.items():
        if topic not in live_topics:
            continue

        order: list[str] = []
        infos: dict[str, InfoEntry] = {}
        owned_ids = starwind_ids.get(topic, set())

        for iid in state.finalized_order():
            entry = state.infos[iid]
            audit["live_topic_effective_infos"] += 1
            owned = iid in owned_ids

            if owned:
                audit["starwind_owned_infos"] += 1

            live = owned or info_can_match_actor(entry.record, actors)
            if not live:
                if not owned:
                    audit["pruned_vanilla_infos"] += 1
                continue

            order.append(iid)
            infos[iid] = entry

            if not owned:
                audit["retained_vanilla_infos"] += 1
                rec = entry.record
                sid = norm_id(rec.get("speaker_id"))
                race = norm_id(rec.get("speaker_race"))
                cls = norm_id(rec.get("speaker_class"))
                fac = norm_id(rec.get("speaker_faction"))
                dtype = normalize_dialogue_type(
                    state.record.get("dialogue_type"))

                if not (sid or race or cls or fac) and dtype in ENGINE_DIALOGUE_TYPES:
                    reason("VANILLA_ENGINE_TOPIC_GENERIC")
                if sid:
                    reason("VANILLA_MATCHING_SPEAKER_ID")
                if race:
                    reason("VANILLA_MATCHING_RACE")
                if cls:
                    reason("VANILLA_MATCHING_CLASS")
                if fac:
                    reason("VANILLA_FACTION_UNKNOWN")
                rs = live_topics.get(topic, set())
                if "SCRIPT_TOPIC" in rs:
                    reason("VANILLA_SCRIPT_TOPIC")
                if "STARWIND_TOPIC" in rs:
                    reason("VANILLA_DIALOGUE_TOPIC")

        # Physical Starwind DIAL shells survive even when they have no live INFOs.
        # Vanilla-only topics are materialized only when at least one INFO survives.
        if not order and topic not in starwind_ids:
            continue

        links = {}
        for i, iid in enumerate(order):
            links[iid] = (
                order[i - 1] if i else "",
                order[i + 1] if i + 1 < len(order) else "",
            )

        projection[topic] = {
            "dialogue_record": state.record,
            "order": order,
            "infos": infos,
            "links": links,
            "topic_reasons": sorted(live_topics.get(topic, set())),
        }

    return projection, audit


def semantic_dialogue_v6(record: dict) -> dict:
    r = copy.deepcopy(record)
    r.pop("flags", None)
    return r


def semantic_info_v6(record: dict) -> dict:
    r = copy.deepcopy(record)
    for key in ("prev_id", "next_id"):
        r.pop(key, None)
    return r


def diff_paths(expected: Any, actual: Any, prefix: str = "") -> list[str]:
    """Return dotted/indexed paths whose values differ between two JSON-like values."""
    if type(expected) is not type(actual):
        return [prefix or "<root>"]

    if isinstance(expected, dict):
        out: list[str] = []
        for key in sorted(set(expected) | set(actual)):
            path = f"{prefix}.{key}" if prefix else str(key)
            if key not in expected or key not in actual:
                out.append(path)
            else:
                out.extend(diff_paths(expected[key], actual[key], path))
        return out

    if isinstance(expected, list):
        out: list[str] = []
        common = min(len(expected), len(actual))
        for index in range(common):
            path = f"{prefix}[{index}]" if prefix else f"[{index}]"
            out.extend(diff_paths(expected[index], actual[index], path))
        if len(expected) != len(actual):
            out.append(f"{prefix}.length" if prefix else "<root>.length")
        return out

    if expected != actual:
        return [prefix or "<root>"]

    return []


def filter_value(filter_record: dict) -> Any:
    value = filter_record.get("value")
    if isinstance(value, dict):
        return value.get("data")
    return value


def comparable_number(value: Any) -> float | None:
    if isinstance(value, bool):
        return float(int(value))
    if isinstance(value, (int, float)):
        return float(value)
    try:
        return float(str(value))
    except (TypeError, ValueError):
        return None


def filter_subject(filter_record: dict) -> tuple[str, str, str]:
    """
    Conservative identity for a dialogue condition.

    We only use two filters as a proof of mutual exclusion when they constrain
    the exact same observable subject.
    """
    return (
        norm_id(filter_record.get("filter_type")),
        norm_id(filter_record.get("function")),
        norm_id(filter_record.get("id")),
    )


def comparison_allows(comparison: str, target: float, value: float) -> bool:
    comparison = norm_id(comparison)
    if comparison == "equal":
        return target == value
    if comparison == "notequal":
        return target != value
    if comparison == "less":
        return target < value
    if comparison == "lessequal":
        return target <= value
    if comparison == "greater":
        return target > value
    if comparison == "greaterequal":
        return target >= value
    return True


def numeric_constraints_disjoint(a: dict, b: dict) -> bool:
    """
    Prove that two comparisons on the same scalar cannot both be true.

    This intentionally recognizes only the TES3 comparisons we can prove
    algebraically. Unknown forms return False (not proven disjoint).
    """
    av = comparable_number(filter_value(a))
    bv = comparable_number(filter_value(b))
    if av is None or bv is None:
        return False

    ac = norm_id(a.get("comparison"))
    bc = norm_id(b.get("comparison"))
    known = {"equal", "notequal", "less",
             "lessequal", "greater", "greaterequal"}
    if ac not in known or bc not in known:
        return False

    # Equality gives an exact witness candidate.
    if ac == "equal":
        return not comparison_allows(bc, av, bv)
    if bc == "equal":
        return not comparison_allows(ac, bv, av)

    # NotEqual alone leaves an open domain, so it only proves disjointness
    # against an equality (handled above).
    if ac == "notequal" or bc == "notequal":
        return False

    # Convert each comparison into lower/upper bounds.
    def bounds(comp: str, val: float) -> tuple[float | None, bool, float | None, bool]:
        if comp == "greater":
            return val, False, None, False
        if comp == "greaterequal":
            return val, True, None, False
        if comp == "less":
            return None, False, val, False
        if comp == "lessequal":
            return None, False, val, True
        raise AssertionError(comp)

    alo, aloinc, ahi, ahiinc = bounds(ac, av)
    blo, bloinc, bhi, bhiinc = bounds(bc, bv)

    lo = alo
    loinc = aloinc
    if blo is not None and (lo is None or blo > lo or (blo == lo and not bloinc)):
        lo, loinc = blo, bloinc
    elif blo is not None and blo == lo:
        loinc = loinc and bloinc

    hi = ahi
    hiinc = ahiinc
    if bhi is not None and (hi is None or bhi < hi or (bhi == hi and not bhiinc)):
        hi, hiinc = bhi, bhiinc
    elif bhi is not None and bhi == hi:
        hiinc = hiinc and bhiinc

    if lo is None or hi is None:
        return False
    if lo > hi:
        return True
    if lo == hi and not (loinc and hiinc):
        return True
    return False


def info_speaker_sex(record: dict) -> str:
    data = record.get("data") or {}
    raw = norm_id(data.get("speaker_sex"))
    if raw in {"male", "female"}:
        return raw
    return ""


def actor_matches_static_info(actor: dict[str, str], record: dict) -> bool:
    """
    Conservative static speaker-domain check.

    Cell and faction are deliberately omitted: actors can move, and faction state
    is treated elsewhere as runtime/insufficiently static for a hard exclusion.
    """
    sid = norm_id(record.get("speaker_id"))
    race = norm_id(record.get("speaker_race"))
    cls = norm_id(record.get("speaker_class"))
    sex = info_speaker_sex(record)

    if sid and actor.get("id", "") != sid:
        return False
    if race and actor.get("race", "") != race:
        return False
    if cls and actor.get("class", "") != cls:
        return False
    if sex:
        actor_sex = actor.get("sex", "")
        if actor_sex and actor_sex != sex:
            return False
    return True


def shared_actor_candidates(
    a: dict,
    b: dict,
    actors: list[dict[str, str]],
    *,
    sample_limit: int = 12,
) -> tuple[int, list[str]]:
    matches: list[str] = []
    count = 0
    for actor in actors:
        if actor_matches_static_info(actor, a) and actor_matches_static_info(actor, b):
            count += 1
            if len(matches) < sample_limit:
                matches.append(actor.get("id", ""))
    return count, matches


def order_blocks(expected: list[str], actual: list[str]) -> list[dict]:
    """
    Decompose the common IDs in actual order into maximal runs that remain
    contiguous in expected order. This turns a Cartesian inversion explosion
    into a handful of human-readable moved blocks.
    """
    epos = {iid: i for i, iid in enumerate(expected)}
    common_actual = [iid for iid in actual if iid in epos]
    if not common_actual:
        return []

    blocks: list[dict] = []
    start = 0
    prev_pos = epos[common_actual[0]]

    def emit(a: int, b: int) -> None:
        ids = common_actual[a:b]
        if not ids:
            return
        ep = [epos[iid] for iid in ids]
        blocks.append({
            "actual_start": a,
            "actual_end": b - 1,
            "expected_start": ep[0],
            "expected_end": ep[-1],
            "length": len(ids),
            "first_id": ids[0],
            "last_id": ids[-1],
            "ids": ids[:40],
            "truncated": len(ids) > 40,
        })

    for i in range(1, len(common_actual)):
        pos = epos[common_actual[i]]
        if pos != prev_pos + 1:
            emit(start, i)
            start = i
        prev_pos = pos
    emit(start, len(common_actual))
    return blocks


MATERIALIZED_RE = re.compile(
    r'^Dialogue DIAL materialized: topic="(?P<topic>.*)" '
    r'source=(?P<source>\S+) live_infos=(?P<count>\d+) '
    r'topic_reason=(?P<reasons>\[.*\])$'
)


def parse_materialization_log(path: Path | None) -> dict[str, dict]:
    if path is None or not path.exists():
        return {}

    out: dict[str, dict] = {}
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        m = MATERIALIZED_RE.match(line.strip())
        if not m:
            continue
        topic = norm_id(m.group("topic"))
        try:
            reasons = json.loads(m.group("reasons"))
        except json.JSONDecodeError:
            reasons = [m.group("reasons")]
        out[topic] = {
            "topic": m.group("topic"),
            "source": m.group("source"),
            "live_infos": int(m.group("count")),
            "topic_reason": reasons,
        }
    return out


def mutually_exclusive_info(
    a: dict,
    b: dict,
    actors: list[dict[str, str]] | None = None,
) -> tuple[bool, list[str]]:
    """
    Conservatively prove that two INFOs cannot both match the same dialogue event.

    A False result does NOT mean they can compete; only that this static audit
    could not prove they are disjoint.
    """
    reasons: list[str] = []

    # Speaker identity/static actor constraints.
    scalar_fields = [
        ("speaker_id", "speaker_id"),
        ("speaker_race", "speaker_race"),
        ("speaker_class", "speaker_class"),
        ("speaker_cell", "speaker_cell"),
    ]
    for field, label in scalar_fields:
        av = norm_id(a.get(field))
        bv = norm_id(b.get(field))
        if av and bv and av != bv:
            reasons.append(f"different_{label}")
            return True, reasons

    adata = a.get("data") or {}
    bdata = b.get("data") or {}
    asex = norm_id(adata.get("speaker_sex"))
    bsex = norm_id(bdata.get("speaker_sex"))
    if asex and bsex and asex != "any" and bsex != "any" and asex != bsex:
        reasons.append("different_speaker_sex")
        return True, reasons

    # Rank constraints on a known same faction are safely disjoint only when
    # both INFOs name the same non-empty faction and exact speaker-rank values differ.
    afac = norm_id(a.get("speaker_faction"))
    bfac = norm_id(b.get("speaker_faction"))
    arank = adata.get("speaker_rank", -1)
    brank = bdata.get("speaker_rank", -1)
    if afac and afac == bfac and arank not in (-1, None) and brank not in (-1, None) and arank != brank:
        reasons.append("different_exact_speaker_rank")
        return True, reasons

    # Compare conditions on identical scalar subjects.
    afilters = a.get("filters") or []
    bfilters = b.get("filters") or []
    by_subject_b: dict[tuple[str, str, str], list[dict]] = {}
    for f in bfilters:
        if isinstance(f, dict):
            by_subject_b.setdefault(filter_subject(f), []).append(f)

    for fa in afilters:
        if not isinstance(fa, dict):
            continue
        subject = filter_subject(fa)
        for fb in by_subject_b.get(subject, []):
            if numeric_constraints_disjoint(fa, fb):
                ft, fn, fid = subject
                subject_name = ":".join(x for x in (ft, fn, fid) if x)
                reasons.append(f"contradictory_filter:{subject_name}")
                return True, reasons

    # Cross-constraint actor-domain proof. This catches cases such as a
    # speaker-specific INFO versus a generic race/class/sex INFO where the
    # specific NPC cannot satisfy the generic side.
    if actors is not None:
        candidates, _ = shared_actor_candidates(a, b, actors)
        if candidates == 0:
            reasons.append("no_shared_actor_candidate")
            return True, reasons

    return False, reasons


def precedence_inversions(expected: list[str], actual: list[str]) -> list[tuple[str, str]]:
    """
    Return pairs (A, B) where A precedes B in expected order but B precedes A
    in actual order. Only common IDs participate.
    """
    actual_pos = {iid: i for i, iid in enumerate(actual)}
    common = [iid for iid in expected if iid in actual_pos]
    out: list[tuple[str, str]] = []
    for i, left in enumerate(common):
        lp = actual_pos[left]
        for right in common[i + 1:]:
            if lp > actual_pos[right]:
                out.append((left, right))
    return out


def analyze_order_semantics(
    topic: str,
    expected_order: list[str],
    actual_order: list[str],
    expected_infos: dict[str, InfoEntry],
    actual_infos: dict[str, InfoEntry],
    actors: list[dict[str, str]],
) -> dict:
    inversions = precedence_inversions(expected_order, actual_order)
    proven: list[dict] = []
    unproven: list[dict] = []

    for first, second in inversions:
        # Payload equality is audited elsewhere. Prefer expected records so the
        # semantic proof is about the intended effective slice.
        a = expected_infos.get(first)
        b = expected_infos.get(second)
        if a is None or b is None:
            unproven.append({"first": first, "second": second,
                            "reason": "missing_expected_payload"})
            continue

        disjoint, reasons = mutually_exclusive_info(a.record, b.record, actors)
        item = {
            "first": first,
            "second": second,
            "proof": reasons,
            "first_source": a.source,
            "second_source": b.source,
        }
        if disjoint:
            proven.append(item)
        else:
            candidate_count, candidate_ids = shared_actor_candidates(
                a.record, b.record, actors
            )
            item["shared_actor_candidate_count"] = candidate_count
            item["shared_actor_candidate_ids"] = candidate_ids

            # Include useful constraints in the JSON report for forensic follow-up.
            item["first_constraints"] = {
                "speaker_id": a.record.get("speaker_id", ""),
                "speaker_race": a.record.get("speaker_race", ""),
                "speaker_class": a.record.get("speaker_class", ""),
                "speaker_faction": a.record.get("speaker_faction", ""),
                "speaker_cell": a.record.get("speaker_cell", ""),
                "data": a.record.get("data", {}),
                "filters": a.record.get("filters", []),
            }
            item["second_constraints"] = {
                "speaker_id": b.record.get("speaker_id", ""),
                "speaker_race": b.record.get("speaker_race", ""),
                "speaker_class": b.record.get("speaker_class", ""),
                "speaker_faction": b.record.get("speaker_faction", ""),
                "speaker_cell": b.record.get("speaker_cell", ""),
                "data": b.record.get("data", {}),
                "filters": b.record.get("filters", []),
            }
            unproven.append(item)

    blocks = order_blocks(expected_order, actual_order)
    return {
        "dialogue_id": topic,
        "inversions": len(inversions),
        "proven_mutually_exclusive": len(proven),
        "potentially_competing": len(unproven),
        "order_blocks": blocks,
        "order_block_count": len(blocks),
        "proven_samples": proven[:50],
        "potentially_competing_pairs": unproven[:50],
    }


def index_dialogue_info_occurrences(path: Path) -> dict[tuple[str, str], list[dict]]:
    """
    Index every physical INFO occurrence by (topic_id, info_id), preserving raw
    source payload and record position. This is deliberately independent of the
    OpenMW effective replay so we can distinguish inherited vanilla records from
    Starwind overrides/copies/corruption.
    """
    records = load_records(path)
    out: dict[tuple[str, str], list[dict]] = {}
    current_topic: str | None = None

    for record_index, rec in enumerate(records):
        typ = rec.get("type")
        if typ == "Dialogue":
            current_topic = dialogue_id(rec)
        elif typ == "DialogueInfo" and current_topic is not None:
            iid = info_id(rec)
            out.setdefault((current_topic, iid), []).append({
                "source": str(path),
                "record_index": record_index,
                "deleted": is_deleted(rec),
                "record": copy.deepcopy(rec),
            })
        else:
            current_topic = None
    return out


def build_provenance_index(paths: list[Path]) -> dict[tuple[str, str], list[dict]]:
    out: dict[tuple[str, str], list[dict]] = {}
    for path in paths:
        for key, occurrences in index_dialogue_info_occurrences(path).items():
            out.setdefault(key, []).extend(occurrences)
    return out


def compact_filter(filter_record: dict) -> dict:
    return {
        "filter_type": filter_record.get("filter_type"),
        "function": filter_record.get("function"),
        "id": filter_record.get("id"),
        "comparison": filter_record.get("comparison"),
        "value": filter_record.get("value"),
    }


def compact_info_record(record: dict) -> dict:
    data = record.get("data") or {}
    return {
        "id": record.get("id"),
        "prev_id": record.get("prev_id"),
        "next_id": record.get("next_id"),
        "speaker_id": record.get("speaker_id"),
        "speaker_race": record.get("speaker_race"),
        "speaker_class": record.get("speaker_class"),
        "speaker_faction": record.get("speaker_faction"),
        "speaker_cell": record.get("speaker_cell"),
        "speaker_sex": data.get("speaker_sex"),
        "speaker_rank": data.get("speaker_rank"),
        "text": record.get("text"),
        "result": record.get("result"),
        "filters": [
            compact_filter(f)
            for f in (record.get("filters") or [])
            if isinstance(f, dict)
        ],
    }


def provenance_for_info(
    topic: str,
    iid: str,
    provenance_index: dict[tuple[str, str], list[dict]],
    effective_entry: InfoEntry | None,
) -> dict:
    occurrences = provenance_index.get((topic, iid), [])
    compact_occurrences = []
    for occ in occurrences:
        compact_occurrences.append({
            "source": occ["source"],
            "record_index": occ["record_index"],
            "deleted": occ["deleted"],
            "payload": compact_info_record(occ["record"]),
        })

    return {
        "dialogue_id": topic,
        "info_id": iid,
        "effective_winner_source": effective_entry.source if effective_entry else None,
        "effective_winner_source_index": effective_entry.source_index if effective_entry else None,
        "physical_sources": sorted({occ["source"] for occ in occurrences}),
        "occurrence_count": len(occurrences),
        "occurrences": compact_occurrences,
        "effective_payload": (
            compact_info_record(effective_entry.record)
            if effective_entry is not None else None
        ),
    }


def attach_corruption_triage(
    order_semantics: list[dict],
    projected: dict[str, dict],
    provenance_index: dict[tuple[str, str], list[dict]],
) -> tuple[list[dict], dict[str, dict]]:
    """
    Expand each still-unproven precedence pair with physical source provenance.
    Also produce one grouped patch-candidate entry per implicated INFO ID.
    """
    detailed_pairs: list[dict] = []
    candidates: dict[str, dict] = {}

    for topic_result in order_semantics:
        topic = topic_result["dialogue_id"]
        expected = projected.get(topic)
        if expected is None:
            continue

        for pair in topic_result.get("potentially_competing_pairs", []):
            first_id = pair["first"]
            second_id = pair["second"]
            first_entry = expected["infos"].get(first_id)
            second_entry = expected["infos"].get(second_id)

            first_prov = provenance_for_info(
                topic, first_id, provenance_index, first_entry
            )
            second_prov = provenance_for_info(
                topic, second_id, provenance_index, second_entry
            )

            detailed = copy.deepcopy(pair)
            detailed["dialogue_id"] = topic
            detailed["first_provenance"] = first_prov
            detailed["second_provenance"] = second_prov
            detailed_pairs.append(detailed)

            for iid, prov, role in (
                (first_id, first_prov, "first"),
                (second_id, second_prov, "second"),
            ):
                key = f"{topic}::{iid}"
                entry = candidates.setdefault(key, {
                    "dialogue_id": topic,
                    "info_id": iid,
                    "effective_winner_source": prov["effective_winner_source"],
                    "physical_sources": prov["physical_sources"],
                    "effective_payload": prov["effective_payload"],
                    "pair_count": 0,
                    "roles": {"first": 0, "second": 0},
                    "competes_with": set(),
                })
                entry["pair_count"] += 1
                entry["roles"][role] += 1
                other = second_id if iid == first_id else first_id
                entry["competes_with"].add(other)

    # JSON-safe and sort most-connected candidates first.
    for entry in candidates.values():
        entry["competes_with"] = sorted(entry["competes_with"])

    sorted_candidates = dict(sorted(
        candidates.items(),
        key=lambda kv: (
            -kv[1]["pair_count"],
            kv[1]["dialogue_id"],
            kv[1]["info_id"],
        )
    ))
    return detailed_pairs, sorted_candidates


def compare_liveness_projection(
    projected: dict[str, dict],
    standalone: ReplayResult,
    standalone_raw: dict[str, dict],
    actors: list[dict[str, str]],
    materialized: dict[str, dict] | None = None,
) -> dict:
    exp_topics = set(projected)
    got_topics = set(standalone.dialogues)

    missing_topics = sorted(exp_topics - got_topics)
    extra_topics = sorted(got_topics - exp_topics)

    missing_infos = []
    extra_infos = []
    engine_order_mismatches = []
    order_semantics = []
    physical_order_mismatches = []
    serialized_link_mismatches = []
    dialogue_content_mismatches = []
    info_content_mismatches = []

    for topic in sorted(exp_topics & got_topics):
        exp = projected[topic]
        got = standalone.dialogues[topic]

        exp_order = exp["order"]
        got_order = got.finalized_order()

        exp_set, got_set = set(exp_order), set(got_order)
        for iid in sorted(exp_set - got_set):
            missing_infos.append({"dialogue_id": topic, "info_id": iid})
        for iid in sorted(got_set - exp_set):
            extra_infos.append({"dialogue_id": topic, "info_id": iid})

        if exp_order != got_order:
            first = None
            for i in range(max(len(exp_order), len(got_order))):
                a = exp_order[i] if i < len(exp_order) else None
                b = got_order[i] if i < len(got_order) else None
                if a != b:
                    first = {"index": i, "expected": a, "standalone": b}
                    break
            engine_order_mismatches.append({
                "dialogue_id": topic,
                "expected_count": len(exp_order),
                "standalone_count": len(got_order),
                "first_difference": first,
            })
            order_semantics.append(analyze_order_semantics(
                topic,
                exp_order,
                got_order,
                exp["infos"],
                got.infos,
                actors,
            ))

        if semantic_dialogue_v6(exp["dialogue_record"]) != semantic_dialogue_v6(got.record):
            dialogue_content_mismatches.append({"dialogue_id": topic})

        for iid in sorted(exp_set & got_set):
            er = semantic_info_v6(exp["infos"][iid].record)
            ar = semantic_info_v6(got.infos[iid].record)
            if er != ar:
                info_content_mismatches.append({
                    "dialogue_id": topic,
                    "info_id": iid,
                    "differing_fields": diff_paths(er, ar),
                })

        raw = standalone_raw.get(topic)
        if raw is None:
            continue

        physical = raw["physical_info_ids"]
        if physical != exp_order:
            first = None
            for i in range(max(len(exp_order), len(physical))):
                a = exp_order[i] if i < len(exp_order) else None
                b = physical[i] if i < len(physical) else None
                if a != b:
                    first = {"index": i, "expected": a,
                             "standalone_physical": b}
                    break
            physical_order_mismatches.append({
                "dialogue_id": topic,
                "expected_count": len(exp_order),
                "standalone_physical_count": len(physical),
                "first_difference": first,
            })

        for iid in exp_order:
            rec = raw["info_records"].get(iid)
            if rec is None:
                serialized_link_mismatches.append({
                    "dialogue_id": topic,
                    "info_id": iid,
                    "problem": "missing physical INFO",
                })
                continue
            want_prev, want_next = exp["links"][iid]
            if info_prev(rec) != want_prev or info_next(rec) != want_next:
                serialized_link_mismatches.append({
                    "dialogue_id": topic,
                    "info_id": iid,
                    "expected_prev": want_prev,
                    "actual_prev": info_prev(rec),
                    "expected_next": want_next,
                    "actual_next": info_next(rec),
                })

    extra_topic_details = []
    extra_topic_infos = 0
    for topic in extra_topics:
        got = standalone.dialogues[topic]
        order = got.finalized_order()
        extra_topic_infos += len(order)
        rust = (materialized or {}).get(topic)
        extra_topic_details.append({
            "dialogue_id": topic,
            "dialogue_type": got.record.get("dialogue_type", ""),
            "effective_info_count": len(order),
            "effective_info_ids": order[:100],
            "rust_materialization": rust,
            "rust_live_info_count_matches": (
                rust is not None and rust.get("live_infos") == len(order)
            ),
        })

    materialized = materialized or {}
    materialized_topics = set(materialized)
    expected_topics = set(projected)
    materialized_not_expected = sorted(materialized_topics - expected_topics)
    extra_with_materialization = sum(
        1 for t in extra_topics if t in materialized)
    extra_without_materialization = sum(
        1 for t in extra_topics if t not in materialized)

    total_inversions = sum(x["inversions"] for x in order_semantics)
    proven_inversions = sum(x["proven_mutually_exclusive"]
                            for x in order_semantics)
    risky_inversions = sum(x["potentially_competing"] for x in order_semantics)
    semantically_safe_order_mismatches = sum(
        1 for x in order_semantics
        if x["inversions"] > 0 and x["potentially_competing"] == 0
    )
    behaviorally_risky_order_mismatches = sum(
        1 for x in order_semantics if x["potentially_competing"] > 0
    )

    return {
        "summary": {
            "expected_live_dialogues": len(exp_topics),
            "standalone_dialogues": len(got_topics),
            "missing_dialogues": len(missing_topics),
            "extra_dialogues": len(extra_topics),
            "missing_live_infos": len(missing_infos),
            "extra_dead_infos": len(extra_infos),
            "engine_order_mismatches": len(engine_order_mismatches),
            "precedence_inversions": total_inversions,
            "proven_disjoint_inversions": proven_inversions,
            "potentially_competing_inversions": risky_inversions,
            "semantically_safe_order_mismatches": semantically_safe_order_mismatches,
            "behaviorally_risky_order_mismatches": behaviorally_risky_order_mismatches,
            "extra_topic_infos": extra_topic_infos,
            "rust_materialized_topics": len(materialized_topics),
            "rust_materialized_not_expected": len(materialized_not_expected),
            "extra_dialogues_with_rust_materialization": extra_with_materialization,
            "extra_dialogues_without_rust_materialization": extra_without_materialization,
            "standalone_physical_order_mismatches": len(physical_order_mismatches),
            "serialized_link_mismatches": len(serialized_link_mismatches),
            "dialogue_content_mismatches": len(dialogue_content_mismatches),
            "info_content_mismatches": len(info_content_mismatches),
            "standalone_orphan_infos": len(standalone.orphan_infos),
        },
        "missing_dialogues": missing_topics,
        "extra_dialogues": extra_topics,
        "extra_dialogue_details": extra_topic_details,
        "rust_materialized_not_expected": [
            materialized[t] for t in materialized_not_expected
        ],
        "missing_live_infos": missing_infos,
        "extra_dead_infos": extra_infos,
        "engine_order_mismatches": engine_order_mismatches,
        "order_semantics": order_semantics,
        "standalone_physical_order_mismatches": physical_order_mismatches,
        "serialized_link_mismatches": serialized_link_mismatches,
        "dialogue_content_mismatches": dialogue_content_mismatches,
        "info_content_mismatches": info_content_mismatches,
        "standalone_orphan_infos": standalone.orphan_infos,
    }


def raw_info_occurrences(path: Path) -> dict[str, dict[str, list[dict]]]:
    records = load_records(path)
    out: dict[str, dict[str, list[dict]]] = {}
    current_did: str | None = None
    for idx, rec in enumerate(records):
        typ = rec.get("type")
        if typ == "Dialogue":
            current_did = dialogue_id(rec)
            out.setdefault(current_did, {})
        elif typ == "DialogueInfo" and current_did is not None:
            iid = info_id(rec)
            out[current_did].setdefault(iid, []).append({
                "record_index": idx,
                "prev_id": info_prev(rec),
                "next_id": info_next(rec),
                "deleted": is_deleted(rec),
            })
        else:
            current_did = None
    return out


def test_self_predecessor_does_not_move_existing_info() -> None:
    state = DialogueState(
        record={"type": "Dialogue", "id": "test"}, source="<test>")
    state.insert_info(
        {"type": "DialogueInfo", "id": "First", "prev_id": "", "next_id": ""},
        False, "<test>", 0,
    )
    state.insert_info(
        {"type": "DialogueInfo", "id": "Second",
            "prev_id": "First", "next_id": ""},
        False, "<test>", 1,
    )
    state.insert_info(
        {"type": "DialogueInfo", "id": "First", "prev_id": "First", "next_id": ""},
        False, "<test>", 2,
    )
    assert state.finalized_order() == [
        "first", "second"], state.finalized_order()


def main() -> None:
    ap = argparse.ArgumentParser(
        description="Validate the one-hop liveness-aware Starwind standalone dialogue slice."
    )
    ap.add_argument(
        "--standalone",
        type=Path,
        default=ROOT / ".swbuild" / "standalone" /
        "out" / "Starwind-Standalone.omwaddon",
    )
    ap.add_argument(
        "--starwind-solo",
        type=Path,
        default=DEFAULT_EXPECTED_STARWIND,
        help="Post-Builder/pre-addVanillaRefs Starwind plugin used for ownership/scripts.",
    )
    ap.add_argument(
        "--base",
        action="append",
        type=Path,
        default=None,
        help=("Vanilla base plugin in load order; repeat to override defaults. "
              "By default v11 uses .swbuild/standalone/work/*.esm when present, "
              "otherwise canonical plugins/*.json."),
    )
    ap.add_argument(
        "--report",
        type=Path,
        default=ROOT / ".swbuild" / "reports" /
        "Starwind-Standalone-dialogue-chain-audit.json",
    )
    ap.add_argument(
        "--provenance-source",
        action="append",
        type=Path,
        default=None,
        help=(
            "Raw source plugin/JSON used to identify where suspicious INFOs physically "
            "exist. Repeat to override defaults: Morrowind, Tribunal, Bloodmoon, "
            "StarwindRemasteredV1.15, StarwindRemasteredPatch."
        ),
    )
    ap.add_argument(
        "--decouple-log",
        type=Path,
        default=ROOT / ".swbuild" / "standalone" / "work" / "decoupleLog.txt",
        help="Optional addVanillaRefs stdout containing 'Dialogue DIAL materialized' telemetry.",
    )
    ap.add_argument("--no-fail", action="store_true")
    ap.add_argument(
        "--strict-structure",
        action="store_true",
        help="Also fail on physical INFO order / serialized prev-next differences.",
    )
    args = ap.parse_args()

    test_self_predecessor_does_not_move_existing_info()

    if args.base:
        bases = args.base
        expected_base_mode = "explicit-cli"
    else:
        bases, expected_base_mode = default_expected_bases()

    full_stack = [*bases, args.starwind_solo]
    provenance_sources = (
        args.provenance_source
        if args.provenance_source
        else DEFAULT_PROVENANCE_SOURCES
    )

    missing = [p for p in [*full_stack, args.standalone,
                           *provenance_sources] if not p.exists()]
    if missing:
        print("ERROR: missing required files:", file=sys.stderr)
        for p in missing:
            print(f"  {p}", file=sys.stderr)
        raise SystemExit(2)

    print(f"[dialogue-audit] Expected base mode: {expected_base_mode}")
    print("[dialogue-audit] Reconstructing mixed OpenMW dialogue:")
    for i, p in enumerate(full_stack):
        print(f"  {i + 1}. {p}")
    print("[dialogue-audit] Standalone:")
    print(f"  {args.standalone}")

    effective = replay_openmw(full_stack)
    starwind_ids = collect_physical_dialogue_ids(args.starwind_solo)
    scripts = collect_scripts(args.starwind_solo)
    final_actors = collect_actor_population(args.standalone)
    liveness_actors = parse_liveness_actor_population(args.decouple_log)
    actors = liveness_actors if liveness_actors is not None else final_actors

    projected, liveness_audit = build_liveness_projection(
        effective, starwind_ids, scripts, actors
    )

    standalone = replay_openmw([args.standalone])
    standalone_raw, raw_orphans = extract_raw_standalone_chains(
        args.standalone)
    if raw_orphans and not standalone.orphan_infos:
        standalone.orphan_infos.extend(raw_orphans)

    materialized = parse_materialization_log(args.decouple_log)
    provenance_index = build_provenance_index(provenance_sources)
    report = compare_liveness_projection(
        projected, standalone, standalone_raw, actors, materialized
    )

    triage_pairs, patch_candidates = attach_corruption_triage(
        report["order_semantics"],
        projected,
        provenance_index,
    )
    report["potential_corruption_pairs"] = triage_pairs
    report["patch_candidates"] = patch_candidates
    report["liveness_audit"] = liveness_audit
    report["expected_base_mode"] = expected_base_mode
    report["reconstruction_stack"] = [str(p) for p in full_stack]
    report["starwind_ownership_source"] = str(args.starwind_solo)
    report["actor_population_source"] = (
        str(args.decouple_log) + " (pre-dialogue-liveness snapshot)"
        if liveness_actors is not None
        else str(args.standalone) + " (fallback; no Rust snapshot found)"
    )
    report["final_actor_population_count"] = len(final_actors)
    report["liveness_actor_population_count"] = len(actors)
    report["materialization_log"] = (
        str(args.decouple_log) if args.decouple_log.exists() else None
    )
    report["provenance_sources"] = [str(p) for p in provenance_sources]
    report["notes"] = [
        "Expected dialogue is a liveness slice, not a Starwind-provenance-only slice.",
        "Starwind response-text words do not create DIAL dependencies.",
        "Same-named typed dependencies such as RACE 'Argonian' remain independent of DIAL 'argonian'.",
        "When staged standalone vanilla masters exist, v11 reconstructs against those exact build-local masters so intentional pre-addVanillaRefs pruning is reflected in expected dialogue.",
        "Vanilla INFOs are retained when the current pruning policy says they can still match.",
        "Dialogue INFO text is not used for DIAL topic discovery; vanilla topics do not expand the topic graph.",
        "Actor population is read from the addVanillaRefs pre-dialogue-liveness snapshot; final Standalone is only a fallback for older logs.",
        "speaker_cell and dialogue filters are preserved and compared verbatim.",
        "OpenMW-effective order differences are classified by whether inverted INFO pairs can statically compete.",
        "Mutual-exclusion proofs are deliberately conservative; unproven does not mean definitely harmful.",
        "v9 additionally intersects INFO speaker constraints against the actual Standalone actor population.",
        "Order mismatches include compact contiguous block decomposition to avoid interpreting Cartesian inversion counts as bug counts.",
        "If decoupleLog telemetry is available, extra vanilla DIALs are correlated directly with Rust materialization reasons.",
        "Every unresolved precedence pair is cross-indexed against raw vanilla/V1.15/Patch physical INFO occurrences for source-corruption triage.",
        "Physical INFO order and prev/next links remain audited but are diagnostic unless --strict-structure is used.",
    ]

    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, indent=2), encoding="utf-8")

    report["summary"]["potential_patch_candidate_infos"] = len(
        report.get("patch_candidates", {})
    )
    args.report.write_text(json.dumps(report, indent=2), encoding="utf-8")

    print()
    print("Dialogue chain audit v12")
    print("=======================")

    la = liveness_audit
    print("Expected liveness model")
    print("-----------------------")
    print(f"effective_infos_all_topics              {la['effective_infos']}")
    print(f"effective_infos_live_topics             {
          la['live_topic_effective_infos']}")
    print(f"starwind_owned_infos                    {
          la['starwind_owned_infos']}")
    print(f"retained_vanilla_infos                  {
          la['retained_vanilla_infos']}")
    print(f"pruned_vanilla_infos                    {
          la['pruned_vanilla_infos']}")
    print(f"live_topics                             {la['live_topics']}")
    for reason, count in sorted(la["keep_reasons"].items()):
        print(f"keep {reason:32} {count}")

    print()
    print("Standalone equivalence")
    print("----------------------")
    for key, value in report["summary"].items():
        print(f"{key:40} {value}")

    if report["engine_order_mismatches"]:
        print()
        print("First engine-order mismatches")
        print("-----------------------------")
        for item in report["engine_order_mismatches"][:20]:
            print(json.dumps(item, ensure_ascii=False))

    if report["order_semantics"]:
        print()
        print("Behavioral precedence analysis")
        print("------------------------------")
        for item in report["order_semantics"]:
            print(
                f"{item['dialogue_id']}: inversions={item['inversions']}, "
                f"proven_disjoint={item['proven_mutually_exclusive']}, "
                f"potentially_competing={item['potentially_competing']}, "
                f"blocks={item['order_block_count']}"
            )
            for block in item["order_blocks"]:
                print(
                    "  BLOCK "
                    f"actual[{block['actual_start']}:{block['actual_end']}] "
                    f"<- expected[{block['expected_start']
                                   }:{block['expected_end']}] "
                    f"len={block['length']} "
                    f"{block['first_id']}..{block['last_id']}"
                )
            for pair in item["potentially_competing_pairs"][:10]:
                print("  UNPROVEN " + json.dumps(pair, ensure_ascii=False))

    if report["extra_dialogue_details"]:
        print()
        print("Extra dialogue details")
        print("----------------------")
        for item in report["extra_dialogue_details"][:50]:
            rust = item.get("rust_materialization")
            if rust:
                print(
                    f"{item['dialogue_id']}: infos={
                        item['effective_info_count']} "
                    f"rust_infos={rust.get('live_infos')} "
                    f"reason={rust.get('topic_reason')}"
                )
            else:
                print(json.dumps(item, ensure_ascii=False))

    if report.get("patch_candidates"):
        print()
        print("Potential source-corruption / build-patch candidates")
        print("----------------------------------------------------")
        for candidate in list(report["patch_candidates"].values())[:60]:
            payload = candidate.get("effective_payload") or {}
            text_preview = str(payload.get(
                "text") or "").replace("\n", " ")[:120]
            print(
                f"{candidate['dialogue_id']} :: {candidate['info_id']} "
                f"pairs={candidate['pair_count']} "
                f"winner={candidate['effective_winner_source']}"
            )
            print(f"  physical_sources={candidate['physical_sources']}")
            print(
                "  speaker="
                f"id={payload.get('speaker_id')!r} "
                f"race={payload.get('speaker_race')!r} "
                f"class={payload.get('speaker_class')!r} "
                f"faction={payload.get('speaker_faction')!r} "
                f"cell={payload.get('speaker_cell')!r}"
            )
            if text_preview:
                print(f"  text={text_preview!r}")
            filters = payload.get("filters") or []
            if filters:
                print(f"  filters={json.dumps(filters, ensure_ascii=False)}")

    if report["summary"]["rust_materialized_topics"]:
        print()
        print("Rust materialization parity")
        print("---------------------------")
        print(f"materialized topics                     {
              report['summary']['rust_materialized_topics']}")
        print(f"materialized not expected                {
              report['summary']['rust_materialized_not_expected']}")
        print(f"extra DIALs with Rust telemetry          {
              report['summary']['extra_dialogues_with_rust_materialization']}")
        print(f"extra DIALs without Rust telemetry       {
              report['summary']['extra_dialogues_without_rust_materialization']}")

    if report["serialized_link_mismatches"]:
        print()
        print("First serialized-link mismatches")
        print("--------------------------------")
        for item in report["serialized_link_mismatches"][:20]:
            print(json.dumps(item, ensure_ascii=False))

    if report["info_content_mismatches"]:
        field_counts: dict[str, int] = {}
        for item in report["info_content_mismatches"]:
            for field in item.get("differing_fields", []):
                field_counts[field] = field_counts.get(field, 0) + 1
        print()
        print("INFO content mismatch fields")
        print("----------------------------")
        for field, count in sorted(field_counts.items(), key=lambda kv: (-kv[1], kv[0]))[:30]:
            print(f"{count:8}  {field}")

    behavioral_hard = any(report["summary"][k] for k in [
        "missing_dialogues",
        "extra_dialogues",
        "missing_live_infos",
        "extra_dead_infos",
        "potentially_competing_inversions",
        "dialogue_content_mismatches",
        "info_content_mismatches",
        "standalone_orphan_infos",
    ])

    structural_drift = any(report["summary"][k] for k in [
        "engine_order_mismatches",
        "standalone_physical_order_mismatches",
        "serialized_link_mismatches",
    ])

    hard = behavioral_hard or (
        args.strict_structure
        and any(report["summary"][k] for k in [
            "engine_order_mismatches",
            "standalone_physical_order_mismatches",
            "serialized_link_mismatches",
        ])
    )

    print()
    if hard:
        if behavioral_hard:
            print("RESULT: BEHAVIORAL MISMATCH / UNPROVEN")
            print(
                "Standalone has missing/extra dialogue payload or precedence inversions")
            print("that this validator cannot prove behaviorally irrelevant.")
        else:
            print("RESULT: STRUCTURAL MISMATCH")
            print(
                "Behavioral equivalence passed, but --strict-structure requires exact order/links.")
        print(f"Full report: {args.report}")
        if not args.no_fail:
            raise SystemExit(4)
    elif structural_drift:
        print("RESULT: BEHAVIORALLY EQUIVALENT WITH STRUCTURAL DRIFT")
        print("All observed OpenMW precedence inversions were proven mutually exclusive.")
        print("Physical order/link differences are reported for diagnostics but are not behavioral failures.")
        print(f"Full report: {args.report}")
    else:
        print("RESULT: EXACT LIVENESS-AWARE DIALOGUE MATCH")
        print("Standalone contains exactly the expected Starwind + required-vanilla dialogue slice.")
        print(f"Full report: {args.report}")


if __name__ == "__main__":
    main()
