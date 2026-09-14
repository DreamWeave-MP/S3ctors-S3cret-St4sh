#!/usr/bin/env python3
"""Forensic report for actors imported after dialogue liveness pruning."""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent
PLUGINS = ROOT / "plugins"
WORK = ROOT / ".swbuild" / "standalone" / "work"
REPORTS = ROOT / ".swbuild" / "reports"
LOG = WORK / "decoupleLog.txt"
STANDALONE = ROOT / ".swbuild" / "standalone" / "out" / "Starwind-Standalone.omwaddon"

sys.path.insert(0, str(ROOT))
import dialogue_chain_audit as dialogue  # noqa: E402
import dialogue_source_hygiene as hygiene  # noqa: E402


COPY_RE = re.compile(
    r"Copying '(.+)' \(([^)]+)\) to 'Starwind\.esp' from '([^']+)'"
)
DEPENDENCY_TARGET_RE = re.compile(r"  target=([^ ]+) '(.+)'$")
DEPENDENCY_SOURCE_RE = re.compile(r"  source=([^ ]+) '(.+)'$")
DEPENDENCY_PASS_RE = re.compile(r"  pass=(.+)$")
DEPENDENCY_FIELD_RE = re.compile(r"  field=(.+)$")
ACTOR_TYPES = {"NPC", "NPC_", "CREA", "Npc", "Creature"}
HYGIENE_CATEGORIES = {
    "NEW_INFO",
    "MODIFIED_PARENT",
    "REDUNDANT_EXACT_COPY",
    "PROBABLE_TESCS_LINK_DIRT",
}


def norm(value: Any) -> str:
    return str(value or "").casefold()


def deleted(record: dict) -> bool:
    return "DELETED" in str(record.get("flags", "")).upper()


def compact_actor(record: dict, source: str, index: int) -> dict:
    typ = record.get("type")
    if typ == "Npc":
        flags = str(record.get("npc_flags", "")).upper()
        return {
            "id": record.get("id", ""),
            "type": typ,
            "race": record.get("race", ""),
            "class": record.get("class", ""),
            "faction": record.get("faction", ""),
            "sex": "female" if "FEMALE" in flags else "male",
            "script": record.get("script", ""),
            "source": source,
            "source_record_index": index,
        }
    return {
        "id": record.get("id", ""),
        "type": typ,
        "race": "",
        "class": "",
        "faction": "",
        "sex": "",
        "script": record.get("script", ""),
        "source": source,
        "source_record_index": index,
    }


def parse_liveness_snapshot(path: Path) -> dict[str, dict]:
    actors: dict[str, dict] = {}
    inside = False
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if line == "Dialogue liveness population begin":
            inside = True
            continue
        if line == "Dialogue liveness population end":
            inside = False
            continue
        if not inside or not line.startswith("Dialogue liveness actor\t"):
            continue
        fields = line.split("\t")
        if len(fields) != 6:
            continue
        _, typ, actor_id, race, cls, sex = fields
        actors[norm(actor_id)] = {
            "id": norm(actor_id),
            "type": typ,
            "race": norm(race),
            "class": norm(cls),
            "sex": norm(sex),
        }
    return actors


def parse_second_closure_copies(path: Path) -> dict[str, dict]:
    copies: dict[str, dict] = {}
    inside = False
    for line_number, line in enumerate(
        path.read_text(encoding="utf-8", errors="replace").splitlines(), 1
    ):
        if line == "Dialogue liveness population end":
            inside = True
            continue
        match = COPY_RE.search(line) if inside else None
        if not match or match.group(2) not in ACTOR_TYPES:
            continue
        actor_id, typ, source = match.groups()
        copies.setdefault(norm(actor_id), {
            "id": actor_id,
            "type": typ,
            "source_master": source,
            "copy_log_line": line_number,
        })
    return copies


def parse_dependency_imports(path: Path) -> dict[str, list[dict]]:
    imports: dict[str, list[dict]] = {}
    inside = False
    current: dict[str, Any] | None = None
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    for line_number, line in enumerate(lines, 1):
        if line == "Dialogue liveness population end":
            inside = True
            continue
        if not inside:
            continue
        if line == "Dependency import:":
            current = {"log_line": line_number}
            continue
        if current is None:
            continue
        matchers = (
            (DEPENDENCY_PASS_RE, "pass"),
            (DEPENDENCY_TARGET_RE, "target"),
            (DEPENDENCY_SOURCE_RE, "source"),
            (DEPENDENCY_FIELD_RE, "field"),
        )
        for matcher, key in matchers:
            match = matcher.match(line)
            if not match:
                continue
            if key in {"target", "source"}:
                current[key + "_type"], current[key + "_id"] = match.groups()
            else:
                current[key] = match.group(1)
            break
        if "target_id" in current and "field" in current:
            imports.setdefault(norm(current["target_id"]), []).append(current)
            current = None
    return imports


def final_actor_population(records: list[dict], path: Path) -> dict[str, dict]:
    actors: dict[str, dict] = {}
    for index, record in enumerate(records):
        if record.get("type") not in {"Npc", "Creature"} or deleted(record):
            continue
        actor = compact_actor(record, str(path), index)
        actors[norm(actor["id"])] = actor
    return actors


def dialogue_info_topics(records: list[dict]) -> dict[str, str]:
    topics: dict[str, str] = {}
    topic = ""
    for record in records:
        if record.get("type") == "Dialogue":
            topic = str(record.get("id", ""))
        elif record.get("type") == "DialogueInfo" and record.get("id"):
            topics[norm(record["id"])] = topic
    return topics


def source_actor_index() -> dict[str, dict]:
    result: dict[str, dict] = {}
    # This is the same priority used by Rust's VanillaIndex.
    paths = [
        (PLUGINS / "Bloodmoon.json", "Bloodmoon.esm"),
        (PLUGINS / "Tribunal.json", "Tribunal.esm"),
        (PLUGINS / "Morrowind.json", "Morrowind.esm"),
    ]
    for path, label in paths:
        for index, record in enumerate(dialogue.load_records(path)):
            if record.get("type") not in {"Npc", "Creature"} or deleted(record):
                continue
            actor = compact_actor(record, label, index)
            result.setdefault(norm(actor["id"]), actor)
    return result


def source_hygiene_index() -> dict[tuple[str, str], dict]:
    result: dict[tuple[str, str], dict] = {}
    state = hygiene.build_vanilla_state()
    for path, binary, label in hygiene.STARWIND:
        report = hygiene.classify_source(path, binary, label, state, None)
        for row in report["records"]:
            result[(row["topic"], row["info_id"])] = row
        hygiene.apply_starwind_layer(state, path, label)
    return result


def dialogue_projection(actors: list[dict]) -> tuple[dict, dict, dict]:
    bases, _ = dialogue.default_expected_bases()
    stack = bases + [dialogue.DEFAULT_EXPECTED_STARWIND]
    effective = dialogue.replay_openmw(stack)
    starwind_ids = dialogue.collect_physical_dialogue_ids(dialogue.DEFAULT_EXPECTED_STARWIND)
    scripts = dialogue.collect_scripts(dialogue.DEFAULT_EXPECTED_STARWIND)
    projection, audit = dialogue.build_liveness_projection(
        effective, starwind_ids, scripts, actors
    )

    canonical = dialogue.replay_openmw(
        dialogue.BASE_SOURCES + [
            PLUGINS / "StarwindRemasteredV1.15.json",
            PLUGINS / "StarwindRemasteredPatch.json",
        ]
    )
    canonical_infos = {
        (topic, info_id): entry
        for topic, state in canonical.dialogues.items()
        for info_id, entry in state.infos.items()
        if not entry.deleted
    }
    return projection, audit, canonical_infos


def record_values(value: Any, path: str = ""):
    if isinstance(value, dict):
        for key, child in value.items():
            child_path = f"{path}.{key}" if path else key
            yield from record_values(child, child_path)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from record_values(child, f"{path}[{index}]")
    else:
        yield path, value


def scan_non_dialogue_references(
    records: list[dict], path: Path, actor_ids: set[str]
) -> tuple[dict[str, list], dict[str, list], dict[str, list]]:
    exact: dict[str, list] = {actor_id: [] for actor_id in actor_ids}
    scripts: dict[str, list] = {actor_id: [] for actor_id in actor_ids}
    placed: dict[str, list] = {actor_id: [] for actor_id in actor_ids}
    for index, record in enumerate(records):
        typ = record.get("type")
        record_id = norm(record.get("id"))
        if typ in {"Dialogue", "DialogueInfo"}:
            continue
        for field_path, value in record_values(record):
            target = norm(value)
            if target not in actor_ids:
                continue
            if field_path == "id" and target == record_id:
                continue
            hit = {
                "source": "Starwind-Standalone.omwaddon",
                "source_file": str(path),
                "record_type": typ,
                "record_id": record.get("id", ""),
                "record_index": index,
                "field": field_path,
            }
            exact[target].append(hit)
            if typ == "Cell" and "references" in field_path:
                placed[target].append(hit)
        if typ == "Script":
            text = str(record.get("text", ""))
            folded = text.casefold()
            for actor_id in actor_ids:
                if re.search(rf"(?<![\w-]){re.escape(actor_id)}(?![\w-])", folded):
                    scripts[actor_id].append({
                        "source": "Starwind-Standalone.omwaddon",
                        "source_file": str(path),
                        "record_type": typ,
                        "record_id": record.get("id", ""),
                        "record_index": index,
                    })
    return exact, scripts, placed


def scan_source_reference_candidates(
    actor_ids: set[str],
) -> tuple[dict[str, list], dict[str, list], dict[str, list]]:
    exact: dict[str, list] = {actor_id: [] for actor_id in actor_ids}
    scripts: dict[str, list] = {actor_id: [] for actor_id in actor_ids}
    placed: dict[str, list] = {actor_id: [] for actor_id in actor_ids}
    sources = [
        (PLUGINS / "Morrowind.json", "Morrowind"),
        (PLUGINS / "Tribunal.json", "Tribunal"),
        (PLUGINS / "Bloodmoon.json", "Bloodmoon"),
        (PLUGINS / "StarwindRemasteredV1.15.json", "V1.15"),
        (PLUGINS / "StarwindRemasteredPatch.json", "RemasteredPatch"),
    ]
    for path, label in sources:
        for index, record in enumerate(dialogue.load_records(path)):
            typ = record.get("type")
            record_id = norm(record.get("id"))
            if typ in {"Dialogue", "DialogueInfo"}:
                continue
            for field_path, value in record_values(record):
                target = norm(value)
                if target not in actor_ids or (field_path == "id" and target == record_id):
                    continue
                hit = {
                    "source": label,
                    "source_file": str(path),
                    "record_type": typ,
                    "record_id": record.get("id", ""),
                    "record_index": index,
                    "field": field_path,
                }
                exact[target].append(hit)
                if typ == "Cell" and "references" in field_path:
                    placed[target].append(hit)
            if typ == "Script":
                text = str(record.get("text", "")).casefold()
                for actor_id in actor_ids:
                    if re.search(rf"(?<![\w-]){re.escape(actor_id)}(?![\w-])", text):
                        scripts[actor_id].append({
                            "source": label,
                            "source_file": str(path),
                            "record_type": typ,
                            "record_id": record.get("id", ""),
                            "record_index": index,
                        })
    return exact, scripts, placed


def info_reference(topic: str, entry: Any, canonical_infos: dict, hygiene_rows: dict) -> dict:
    record = entry.record
    key = (topic, dialogue.info_id(record))
    source_entry = canonical_infos.get(key, entry)
    row = hygiene_rows.get(key)
    return {
        "dial": topic,
        "info_id": record.get("id", ""),
        "source": Path(source_entry.source).name,
        "source_record_index": source_entry.source_index,
        "hygiene_classification": row["category"] if row else "INHERITED_VANILLA",
        "tescs_dirt_confidence": row.get("tescs_dirt_confidence") if row else None,
        "changed_links": row.get("changed_links", {}) if row else {},
        "parent_source": row.get("parent_source") if row else None,
        "parent_record_index": row.get("parent_record_index") if row else None,
        "speaker_id": record.get("speaker_id", ""),
        "speaker_race": record.get("speaker_race", ""),
        "speaker_class": record.get("speaker_class", ""),
        "speaker_faction": record.get("speaker_faction", ""),
        "speaker_cell": record.get("speaker_cell", ""),
        "speaker_sex": (record.get("data") or {}).get("speaker_sex", ""),
        "speaker_rank": (record.get("data") or {}).get("speaker_rank", -1),
        "player_faction": record.get("player_faction", ""),
        "text": record.get("text", ""),
        "result": record.get("result", ""),
        "filters": record.get("filters", []),
    }


def classify(
    references: list[dict],
    non_dialogue: list[dict],
    source_candidates: list[dict],
    causal_imports: list[dict],
) -> tuple[str, str]:
    categories = {item["hygiene_classification"] for item in references}
    if non_dialogue:
        return "D", "has a surviving non-dialogue dependency in the final standalone"
    if references and not non_dialogue and categories == {"PROBABLE_TESCS_LINK_DIRT"}:
        return "A", "all surviving speaker_id INFOs are probable TESCS link dirt"
    if "NEW_INFO" in categories:
        return "C", "at least one surviving speaker_id INFO is a new Starwind INFO"
    if "MODIFIED_PARENT" in categories:
        return "B", "at least one surviving speaker_id INFO semantically modifies its parent"
    if causal_imports:
        return "D", "post-dialogue dependency telemetry identifies the import cause"
    if not references and source_candidates:
        return "D", "no surviving dependency found; canonical source has candidate references to trace"
    if not references or non_dialogue:
        return "D", "not explained solely by probable link dirt or a Starwind semantic INFO"
    return "D", "surviving speaker_id INFO is inherited or otherwise not a classified Starwind modification"


def make_report(args: argparse.Namespace) -> dict:
    snapshot = parse_liveness_snapshot(args.log)
    copies = parse_second_closure_copies(args.log)
    dependency_imports = parse_dependency_imports(args.log)
    final_records = dialogue.load_records(args.standalone)
    final = final_actor_population(final_records, args.standalone)
    info_topics = dialogue_info_topics(final_records)
    late_ids = sorted(set(final) - set(snapshot))
    actors = [snapshot[actor_id] for actor_id in sorted(snapshot)]
    projection, audit, canonical_infos = dialogue_projection(actors)
    hygiene_rows = source_hygiene_index()
    exact, script_mentions, placed = scan_non_dialogue_references(
        final_records, args.standalone, set(late_ids)
    )
    source_exact, source_script_mentions, source_placed = scan_source_reference_candidates(
        set(late_ids)
    )
    vanilla_actors = source_actor_index()

    rows = []
    for actor_id in late_ids:
        actor = final[actor_id]
        direct_infos = []
        for topic, item in projection.items():
            for entry in item["infos"].values():
                if norm(entry.record.get("speaker_id")) == actor_id:
                    direct_infos.append(info_reference(topic, entry, canonical_infos, hygiene_rows))
        non_dialogue = [
            hit for hit in exact[actor_id]
            if hit["record_type"] not in {"Npc", "Creature"}
        ]
        copy = copies.get(actor_id, {})
        causal_imports = dependency_imports.get(actor_id, [])
        for causal_import in causal_imports:
            if causal_import.get("source_type", "").casefold() == "info":
                causal_import["source_topic"] = info_topics.get(
                    norm(causal_import.get("source_id", "")), ""
                )
        category, rationale = classify(
            direct_infos, non_dialogue, source_exact[actor_id], causal_imports
        )
        rows.append({
            "actor": actor,
            "source_master": copy.get("source_master") or vanilla_actors.get(actor_id, {}).get("source"),
            "source_record_index": vanilla_actors.get(actor_id, {}).get("source_record_index"),
            "copy_log_line": copy.get("copy_log_line"),
            "why_imported_on_second_closure": {
                "direct_live_dialogue_speaker_id_references": len(direct_infos),
                "non_dialogue_exact_references": len(non_dialogue),
                "source_reference_candidates": len(source_exact[actor_id]),
                "causal_dependency_imports": len(causal_imports),
                "reason_class": category,
                "classification_rationale": rationale,
            },
            "surviving_info_references": direct_infos,
            "non_dialogue_references": non_dialogue,
            "script_text_mentions": script_mentions[actor_id],
            "placed_references": placed[actor_id],
            "source_reference_candidates": source_exact[actor_id],
            "source_script_text_mentions": source_script_mentions[actor_id],
            "source_placed_references": source_placed[actor_id],
            "causal_dependency_imports": causal_imports,
        })

    classes = Counter(row["why_imported_on_second_closure"]["reason_class"] for row in rows)
    class_a_info_ids: dict[str, set[str]] = {}
    for row in rows:
        if row["why_imported_on_second_closure"]["reason_class"] != "A":
            continue
        for reference in row["surviving_info_references"]:
            if reference["hygiene_classification"] != "PROBABLE_TESCS_LINK_DIRT":
                continue
            class_a_info_ids.setdefault(reference["source"], set()).add(
                norm(reference["info_id"])
            )
    return {
        "version": 1,
        "log": str(args.log),
        "standalone": str(args.standalone),
        "snapshot_actor_count": len(snapshot),
        "final_actor_count": len(final),
        "late_actor_count": len(rows),
        "late_actor_class_counts": dict(sorted(classes.items())),
        "class_a_info_ids_by_source": {
            source: sorted(ids) for source, ids in sorted(class_a_info_ids.items())
        },
        "dialogue_liveness_audit": audit,
        "actors": rows,
    }


def write_markdown(path: Path, report: dict) -> None:
    lines = [
        "# Late Actor Provenance",
        "",
        f"Second-closure actors: **{report['late_actor_count']}** "
        f"({report['snapshot_actor_count']} pre-liveness, {report['final_actor_count']} final).",
        "",
        "| Class | Count |",
        "| --- | ---: |",
    ]
    for category, count in report["late_actor_class_counts"].items():
        lines.append(f"| {category} | {count} |")
    lines += [
        "",
        "| Actor | Master | Class | Dialogue refs | Other refs | Causal imports |",
        "| --- | --- | --- | ---: | ---: | ---: |",
    ]
    for row in report["actors"]:
        why = row["why_imported_on_second_closure"]
        lines.append(
            f"| `{row['actor']['id']}` | `{row.get('source_master') or '?'}` | "
            f"{why['reason_class']} | {why['direct_live_dialogue_speaker_id_references']} | "
            f"{why['non_dialogue_exact_references']} | "
            f"{why['causal_dependency_imports']} |"
        )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_class_a_cleanup(path: Path, report: dict) -> None:
    lines = [
        "#!/usr/bin/env bash",
        "set -euo pipefail",
        "",
        "# Generated by late_actor_provenance.py. REVIEW BEFORE EXECUTION.",
        "# Run from the sw_merged/plugins directory, or set TES3CMD explicitly.",
        'TES3CMD="${TES3CMD:-../tes3cmd}"',
        "",
    ]
    binary_by_source = {
        "StarwindRemasteredPatch.json": "StarwindRemasteredPatch.esm",
        "StarwindRemasteredV1.15.json": "StarwindRemasteredV1.15.esm",
    }
    for source, info_ids in report["class_a_info_ids_by_source"].items():
        binary = binary_by_source.get(source)
        if binary is None:
            raise ValueError(f"no binary mapping for {source}")
        lines.append(f"# {binary}: {len(info_ids)} Class-A INFOs")
        command = ["\"$TES3CMD\"", "delete", "--type", "INFO"]
        for info_id in info_ids:
            command += ["--exact-id", info_id]
        command.append(binary)
        lines.append(" ".join(command))
        lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")
    path.chmod(0o755)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--log", type=Path, default=LOG)
    parser.add_argument("--standalone", type=Path, default=STANDALONE)
    parser.add_argument("--report", type=Path, default=REPORTS / "Starwind-late-actor-provenance.json")
    parser.add_argument("--markdown", type=Path, default=REPORTS / "Starwind-late-actor-provenance.md")
    parser.add_argument(
        "--cleanup-script",
        type=Path,
        default=PLUGINS / "cleanup-class-a-dialogue.sh",
    )
    args = parser.parse_args()
    report = make_report(args)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    write_markdown(args.markdown, report)
    if report["class_a_info_ids_by_source"]:
        write_class_a_cleanup(args.cleanup_script, report)
    print("Late actor provenance report")
    print("============================")
    print(f"pre-liveness actors                     {report['snapshot_actor_count']}")
    print(f"final actors                             {report['final_actor_count']}")
    print(f"second-closure actors                    {report['late_actor_count']}")
    for category, count in report["late_actor_class_counts"].items():
        print(f"class {category}                                {count}")
    print(f"JSON report: {args.report}")
    print(f"Markdown report: {args.markdown}")
    print(f"Class-A cleanup script: {args.cleanup_script}")


if __name__ == "__main__":
    main()
