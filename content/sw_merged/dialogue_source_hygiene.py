#!/usr/bin/env python3
"""
Starwind dialogue source hygiene auditor v2.

This audits each Starwind source against its *actual inherited dialogue state*:

    V1.15 baseline:
        Morrowind -> Tribunal -> Bloodmoon

    RemasteredPatch baseline:
        Morrowind -> Tribunal -> Bloodmoon -> V1.15

That distinction matters: Patch records may override/delete Starwind records from
V1.15 rather than vanilla records.

Per physical INFO, categories are:

    NEW_INFO
        No active inherited INFO with this topic/id exists.

    MODIFIED_PARENT
        Same inherited INFO exists, but Starwind changes semantic payload.

    REDUNDANT_EXACT_COPY
        Record is byte-for-byte identical to inherited parent INFO.

    PROBABLE_TESCS_LINK_DIRT
        Semantic payload is identical to inherited parent INFO; only prev_id and/or
        next_id differ. This is the classic TESCS "I inserted nearby dialogue and
        dirtied surrounding nodes" pattern.

    DELETED_PARENT_OVERRIDE
        Deletes an active inherited INFO. Potentially meaningful; never auto-clean.

    REDUNDANT_DELETE
        Parent state already has this INFO deleted. Usually tombstone duplication.

    ORPHAN_DELETE
        Deletes an INFO not known in inherited active/tombstoned state.

The auditor also scores link-only records:
    HIGH   changed linkage touches a NEW_INFO/MODIFIED_PARENT INFO in the same topic
    MEDIUM semantic payload is identical to parent but adjacency cause is not obvious

Cleanup script generation:
    --emit-tes3cmd FILE
        emits REDUNDANT_EXACT_COPY deletion only.

    --include-link-dirt
        additionally emits PROBABLE_TESCS_LINK_DIRT deletion. This is intended for
        an OpenMW-targeted cleanup and MUST be regression-tested with the dialogue
        validator afterward.

Deleted overrides and semantic modifications are never emitted automatically.
"""
from __future__ import annotations

import argparse
import collections
import copy
import json
import shlex
from dataclasses import dataclass
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent
PLUGINS = ROOT / "plugins"

VANILLA = [
    (PLUGINS / "Morrowind.json", "Morrowind"),
    (PLUGINS / "Tribunal.json", "Tribunal"),
    (PLUGINS / "Bloodmoon.json", "Bloodmoon"),
]

STARWIND = [
    (PLUGINS / "StarwindRemasteredV1.15.json", "StarwindRemasteredV1.15.esm", "V1.15"),
    (PLUGINS / "StarwindRemasteredPatch.json", "StarwindRemasteredPatch.esm", "RemasteredPatch"),
]


def norm(value: Any) -> str:
    return str(value or "").casefold()


def is_deleted(record: dict) -> bool:
    return "DELETED" in str(record.get("flags", "")).upper()


def load(path: Path) -> list[dict]:
    return json.loads(path.read_text(encoding="utf-8"))


def physical_infos(path: Path) -> list[dict]:
    out = []
    current_topic: str | None = None
    for index, record in enumerate(load(path)):
        typ = record.get("type")
        if typ == "Dialogue":
            current_topic = norm(record.get("id"))
        elif typ == "DialogueInfo" and current_topic is not None:
            out.append({
                "topic": current_topic,
                "id": norm(record.get("id")),
                "record_index": index,
                "record": record,
                "source": str(path),
            })
        else:
            current_topic = None
    return out


def strip_links(record: dict) -> dict:
    value = copy.deepcopy(record)
    value.pop("prev_id", None)
    value.pop("next_id", None)
    return value


def compact(record: dict | None) -> dict | None:
    if record is None:
        return None
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
        "filters": record.get("filters", []),
    }


@dataclass
class StateEntry:
    record: dict
    source: str
    record_index: int


class DialogueState:
    def __init__(self) -> None:
        self.active: dict[tuple[str, str], StateEntry] = {}
        self.tombstones: dict[tuple[str, str], StateEntry] = {}

    def apply_infos(self, path: Path, label: str) -> None:
        for item in physical_infos(path):
            key = (item["topic"], item["id"])
            entry = StateEntry(
                record=copy.deepcopy(item["record"]),
                source=label,
                record_index=item["record_index"],
            )
            if is_deleted(item["record"]):
                self.active.pop(key, None)
                self.tombstones[key] = entry
            else:
                self.active[key] = entry
                self.tombstones.pop(key, None)


def build_vanilla_state() -> DialogueState:
    state = DialogueState()
    for path, label in VANILLA:
        state.apply_infos(path, label)
    return state


def duplicate_metadata(items: list[dict]) -> dict[tuple[str, str], dict]:
    groups: dict[tuple[str, str], list[int]] = collections.defaultdict(list)
    for i, item in enumerate(items):
        groups[(item["topic"], item["id"])].append(i)

    meta = {}
    for key, positions in groups.items():
        if len(positions) > 1:
            meta[key] = {
                "count": len(positions),
                "physical_occurrence_numbers": positions,
            }
    return meta


def initial_category(record: dict, parent_active: StateEntry | None, parent_tombstone: StateEntry | None) -> str:
    if is_deleted(record):
        if parent_active is not None:
            return "DELETED_PARENT_OVERRIDE"
        if parent_tombstone is not None:
            return "REDUNDANT_DELETE"
        return "ORPHAN_DELETE"

    if parent_active is None:
        return "NEW_INFO"

    if record == parent_active.record:
        return "REDUNDANT_EXACT_COPY"

    if strip_links(record) == strip_links(parent_active.record):
        return "PROBABLE_TESCS_LINK_DIRT"

    return "MODIFIED_PARENT"


def changed_links(child: dict, parent: dict | None) -> dict:
    if parent is None:
        return {}
    result = {}
    for field in ("prev_id", "next_id"):
        c = norm(child.get(field))
        p = norm(parent.get(field))
        if c != p:
            result[field] = {"parent": p, "child": c}
    return result


def classify_source(
    path: Path,
    binary_name: str,
    source_label: str,
    parent: DialogueState,
    topic_filter: str | None,
) -> dict:
    items = physical_infos(path)
    dup_meta = duplicate_metadata(items)

    # First pass: classify against inherited state.
    rows: list[dict] = []
    source_changed_ids_by_topic: dict[str, set[str]] = collections.defaultdict(set)

    for item in items:
        if topic_filter and item["topic"] != topic_filter:
            continue

        key = (item["topic"], item["id"])
        parent_active = parent.active.get(key)
        parent_tombstone = parent.tombstones.get(key)
        category = initial_category(item["record"], parent_active, parent_tombstone)

        if category in {"NEW_INFO", "MODIFIED_PARENT"}:
            source_changed_ids_by_topic[item["topic"]].add(item["id"])

        parent_entry = parent_active or parent_tombstone
        row = {
            "topic": item["topic"],
            "info_id": item["id"],
            "record_index": item["record_index"],
            "category": category,
            "parent_source": parent_entry.source if parent_entry else None,
            "parent_record_index": parent_entry.record_index if parent_entry else None,
            "starwind": compact(item["record"]),
            "parent": compact(parent_entry.record) if parent_entry else None,
            "changed_links": changed_links(
                item["record"],
                parent_active.record if parent_active else None,
            ),
            "duplicate_in_source": dup_meta.get(key),
        }
        rows.append(row)

    # Second pass: score probable TESCS link dirt.
    for row in rows:
        if row["category"] != "PROBABLE_TESCS_LINK_DIRT":
            continue

        changed = row["changed_links"]
        changed_targets = {
            side["child"]
            for side in changed.values()
            if side.get("child")
        }
        local_changed = source_changed_ids_by_topic.get(row["topic"], set())
        touched = sorted(changed_targets & local_changed)

        row["tescs_dirt_confidence"] = "HIGH" if touched else "MEDIUM"
        row["changed_link_targets_owned_by_source"] = touched

    counts = collections.Counter(row["category"] for row in rows)
    confidence_counts = collections.Counter(
        row.get("tescs_dirt_confidence")
        for row in rows
        if row["category"] == "PROBABLE_TESCS_LINK_DIRT"
    )
    topic_counts: dict[str, collections.Counter] = collections.defaultdict(collections.Counter)
    for row in rows:
        topic_counts[row["topic"]][row["category"]] += 1

    cleanup_categories = {"REDUNDANT_EXACT_COPY", "PROBABLE_TESCS_LINK_DIRT"}
    topic_cleanup = []
    for topic, counter in topic_counts.items():
        n = sum(counter.get(cat, 0) for cat in cleanup_categories)
        if n:
            topic_cleanup.append({
                "topic": topic,
                "cleanup_candidates": n,
                "redundant_exact": counter.get("REDUNDANT_EXACT_COPY", 0),
                "link_dirt": counter.get("PROBABLE_TESCS_LINK_DIRT", 0),
            })
    topic_cleanup.sort(key=lambda x: (-x["cleanup_candidates"], x["topic"]))

    duplicates = [
        {
            "topic": topic,
            "info_id": iid,
            **meta,
        }
        for (topic, iid), meta in sorted(dup_meta.items())
        if not topic_filter or topic == topic_filter
    ]

    return {
        "source_json": str(path),
        "binary_name": binary_name,
        "source_label": source_label,
        "parent_model": (
            "Morrowind -> Tribunal -> Bloodmoon"
            if source_label == "V1.15"
            else "Morrowind -> Tribunal -> Bloodmoon -> V1.15"
        ),
        "counts": dict(counts),
        "tescs_dirt_confidence": dict(confidence_counts),
        "duplicate_info_groups": len(duplicates),
        "duplicates": duplicates,
        "topic_counts": {
            topic: dict(counter)
            for topic, counter in sorted(topic_counts.items())
        },
        "top_cleanup_topics": topic_cleanup[:100],
        "records": rows,
    }


def apply_starwind_layer(state: DialogueState, path: Path, label: str) -> None:
    state.apply_infos(path, label)


def emit_tes3cmd(path: Path, reports: list[dict], include_link_dirt: bool) -> None:
    allowed = {"REDUNDANT_EXACT_COPY"}
    if include_link_dirt:
        allowed.add("PROBABLE_TESCS_LINK_DIRT")

    lines = [
        "#!/usr/bin/env bash",
        "set -euo pipefail",
        "",
        "# Generated by dialogue_source_hygiene.py v2.",
        "# REVIEW BEFORE EXECUTION.",
        "#",
        "# REDUNDANT_EXACT_COPY: identical to inherited parent record.",
        "# PROBABLE_TESCS_LINK_DIRT: semantic payload identical; only prev/next differs.",
        "# Deleted overrides and semantic modifications are NEVER emitted.",
        "",
    ]

    for report in reports:
        rows = [
            row for row in report["records"]
            if row["category"] in allowed and row["info_id"]
        ]
        if not rows:
            continue

        binary = report["binary_name"]
        by_category: dict[str, list[str]] = collections.defaultdict(list)
        for row in rows:
            by_category[row["category"]].append(row["info_id"])

        lines.append(f"# {binary}")
        for category in ("REDUNDANT_EXACT_COPY", "PROBABLE_TESCS_LINK_DIRT"):
            ids = list(dict.fromkeys(by_category.get(category, [])))
            if not ids:
                continue
            lines.append(f"#   {category}: {len(ids)} INFOs")
            for start in range(0, len(ids), 100):
                chunk = ids[start:start + 100]
                command = ["tes3cmd", "delete", "--type", "INFO"]
                for iid in chunk:
                    command += ["--exact-id", iid]
                command.append(binary)
                lines.append(" ".join(shlex.quote(x) for x in command))
        lines.append("")

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    path.chmod(0o755)


def pct(n: int, total: int) -> str:
    return f"{(100.0 * n / total):5.1f}%" if total else "  0.0%"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--topic", help="Audit one normalized topic, e.g. hello or greeting 0.")
    ap.add_argument(
        "--report",
        type=Path,
        default=ROOT / ".swbuild" / "reports" / "Starwind-dialogue-source-hygiene-v2.json",
    )
    ap.add_argument(
        "--emit-tes3cmd",
        type=Path,
        help="Write reviewable tes3cmd deletion commands for redundant dialogue overrides.",
    )
    ap.add_argument(
        "--include-link-dirt",
        action="store_true",
        help="Also emit PROBABLE_TESCS_LINK_DIRT cleanup candidates.",
    )
    ap.add_argument(
        "--top",
        type=int,
        default=20,
        help="Number of highest-dirt topics to print per source.",
    )
    args = ap.parse_args()

    required = [p for p, _ in VANILLA] + [p for p, _, _ in STARWIND]
    missing = [p for p in required if not p.exists()]
    if missing:
        print("Missing required files:")
        for p in missing:
            print(f"  {p}")
        raise SystemExit(2)

    topic_filter = norm(args.topic) if args.topic else None
    state = build_vanilla_state()

    reports = []
    for path, binary, label in STARWIND:
        report = classify_source(path, binary, label, state, topic_filter)
        reports.append(report)
        apply_starwind_layer(state, path, label)

    result = {
        "version": 2,
        "vanilla_load_order": [str(p) for p, _ in VANILLA],
        "topic_filter": topic_filter,
        "sources": reports,
    }

    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(result, indent=2), encoding="utf-8")

    print("Starwind dialogue source hygiene v2")
    print("==================================")
    categories = (
        "NEW_INFO",
        "MODIFIED_PARENT",
        "REDUNDANT_EXACT_COPY",
        "PROBABLE_TESCS_LINK_DIRT",
        "DELETED_PARENT_OVERRIDE",
        "REDUNDANT_DELETE",
        "ORPHAN_DELETE",
    )

    for report in reports:
        print()
        name = Path(report["source_json"]).name
        print(name)
        print("-" * len(name))
        total = sum(report["counts"].values())
        print(f"parent model: {report['parent_model']}")
        print(f"physical INFOs                         {total:6}")
        for category in categories:
            n = report["counts"].get(category, 0)
            print(f"{category:36} {n:6}  {pct(n, total)}")

        link_total = report["counts"].get("PROBABLE_TESCS_LINK_DIRT", 0)
        if link_total:
            high = report["tescs_dirt_confidence"].get("HIGH", 0)
            medium = report["tescs_dirt_confidence"].get("MEDIUM", 0)
            print(f"  link dirt HIGH confidence            {high:6}")
            print(f"  link dirt MEDIUM confidence          {medium:6}")

        print(f"duplicate physical INFO ID groups      {report['duplicate_info_groups']:6}")

        if topic_filter:
            tc = report["topic_counts"].get(topic_filter, {})
            print(f"\nTopic {topic_filter!r}:")
            for category in categories:
                print(f"  {category:34} {tc.get(category, 0)}")
        elif report["top_cleanup_topics"]:
            print("\nTop cleanup-heavy topics:")
            for row in report["top_cleanup_topics"][:args.top]:
                print(
                    f"  {row['cleanup_candidates']:5}  {row['topic']!r} "
                    f"(exact={row['redundant_exact']}, link_dirt={row['link_dirt']})"
                )

    if args.emit_tes3cmd:
        emit_tes3cmd(args.emit_tes3cmd, reports, args.include_link_dirt)
        print()
        print(f"tes3cmd candidate script: {args.emit_tes3cmd}")
        if args.include_link_dirt:
            print("Includes probable TESCS link dirt; rebuild + dialogue validator are mandatory.")
        else:
            print("Contains only redundant exact-copy overrides.")

    print()
    print(f"JSON report: {args.report}")


if __name__ == "__main__":
    main()
