#!/usr/bin/env python3
"""Split a masterless Starwind plugin into stable data and content layers."""
from __future__ import annotations

import argparse
import collections
import json
import subprocess
import tempfile
from pathlib import Path

from motherjungle_audit import HARD_KINDS, dependencies, editor_id


ROOT = Path(__file__).resolve().parent
DEFAULT_SOURCE = ROOT / "Starwind-Standalone.omwaddon"
DEFAULT_DATA = ROOT / "Star_Data.omwaddon"
DEFAULT_CONTENT = ROOT / "Starwind.omwaddon"
DEFAULT_REPORT = ROOT / ".swbuild" / "split" / "starwind-split-report.json"
CONVERTER = ROOT / "tes3conv"

# These definition families default to Data. Individual records with a
# content-only dependency remain in Starwind; a type name alone is not enough
# to make a masterless reusable record.
ALWAYS_DATA_TYPES = {
    "Alchemy",
    "Apparatus",
    "Birthsign",
    "Bodypart",
    "Class",
    "Enchanting",
    "Faction",
    "GameSetting",
    "Ingredient",
    "Lockpick",
    "MagicEffect",
    "Probe",
    "Race",
    "RepairItem",
    "Skill",
    "Sound",
    "SoundGen",
    "Spell",
    "Static",
}

# These families are candidates only when their recognized dependencies can
# also live in Star_Data. BOOK is intentionally not a candidate: its text is
# authored world content even when it has no script.
CANDIDATE_DATA_TYPES = {
    "Activator",
    "Armor",
    "Clothing",
    "Container",
    "Creature",
    "Door",
    "LeveledCreature",
    "LeveledItem",
    "Light",
    "MiscItem",
    "Weapon",
}

# An approved stable script must be named explicitly before it can cross the
# boundary with its dependent definition. The initial split approves none.
APPROVED_DATA_SCRIPT_IDS: set[str] = set()

DATA_TYPES = ALWAYS_DATA_TYPES | CANDIDATE_DATA_TYPES

ITEM_TYPES = {
    "Activator", "Alchemy", "Apparatus", "Armor", "Book", "Clothing",
    "Container", "Creature", "Door", "Ingredient", "Light", "Lockpick",
    "LeveledCreature", "LeveledItem", "MiscItem", "Probe", "RepairItem",
    "Weapon",
}

# dependencies() records the semantic field in `kind`, but TES3 editor IDs
# share one string namespace. Resolve each field against its actual record
# namespace so BODY race="Droid" cannot match DIAL "droid".
DEPENDENCY_TARGET_TYPES = {
    "race.spells": {"Spell"},
    "soundgen.creature": {"Creature"},
    "soundgen.sound": {"Sound"},
    "region.sleep_creature": {"Creature"},
    "region.sounds": {"Sound"},
    "magic_effect.area_sound": {"Sound"},
    "magic_effect.bolt_sound": {"Sound"},
    "magic_effect.cast_sound": {"Sound"},
    "magic_effect.hit_sound": {"Sound"},
    "magic_effect.area_visual": {"Static"},
    "magic_effect.bolt_visual": {"Static", "Weapon"},
    "magic_effect.cast_visual": {"Static"},
    "magic_effect.hit_visual": {"Static"},
    "birthsign.spells": {"Spell"},
    "weapon.enchanting": {"Enchanting"},
    "book.enchanting": {"Enchanting"},
    "armor.enchanting": {"Enchanting"},
    "clothing.enchanting": {"Enchanting"},
    "armor.male_bodypart": {"Bodypart"},
    "armor.female_bodypart": {"Bodypart"},
    "clothing.male_bodypart": {"Bodypart"},
    "clothing.female_bodypart": {"Bodypart"},
    "door.open_sound": {"Sound"},
    "door.close_sound": {"Sound"},
    "light.sound": {"Sound"},
    "creature.sound": {"Sound"},
    "creature.spells": {"Spell", "MagicEffect"},
    "creature.ai.activate": {"Activator"},
    "bodypart.race": {"Race"},
    "npc.race": {"Race"},
    "npc.class": {"Class"},
    "npc.faction": {"Faction"},
    "npc.head": {"Bodypart"},
    "npc.hair": {"Bodypart"},
    "npc.sound": {"Sound"},
    "npc.ai.activate": {"Activator"},
    "info.speaker_race": {"Race"},
    "info.speaker_class": {"Class"},
    "info.speaker_faction": {"Faction"},
    "info.player_faction": {"Faction"},
    "cell.region": {"Region"},
    "faction.reaction": {"Faction"},
    "leveled_creature.creatures": {"Creature", "Npc", "LeveledCreature"},
    "container.inventory": ITEM_TYPES,
    "creature.inventory": ITEM_TYPES,
    "npc.inventory": ITEM_TYPES,
    "leveled_item.items": ITEM_TYPES,
}


def dependency_target_keys(
    dependency: dict, known_keys_by_id: dict[str, set[str]]
) -> set[tuple[str, str]]:
    target = dependency["target"]
    target_types = DEPENDENCY_TARGET_TYPES.get(dependency["kind"])
    if target_types is None and dependency["kind"].endswith(".script"):
        target_types = {"Script"}
    if target_types is None:
        # Generic references are resolved only against known typed records,
        # never against a bare editor-ID set.
        return {(record_type, target) for record_type in known_keys_by_id.get(target, set())}
    return {(record_type, target) for record_type in target_types
            if record_type in known_keys_by_id.get(target, set())}


def dependency_identity(dependency: dict) -> tuple[str, str, str, str]:
    return (
        dependency["source_type"],
        dependency["source_id"].casefold(),
        dependency["kind"],
        dependency["target"],
    )


def unresolved_dependencies(
    records: list[dict], known_keys_by_id: dict[str, set[str]]
) -> list[dict]:
    unresolved = []
    for index, record in enumerate(records, 1):
        for dependency in dependencies(record, index):
            if (
                dependency["kind"] in HARD_KINDS
                and not dependency_target_keys(dependency, known_keys_by_id)
            ):
                unresolved.append(dependency)
    return unresolved


def load_plugin(path: Path) -> list[dict]:
    if path.suffix.lower() == ".json":
        return json.loads(path.read_text(encoding="utf-8"))
    with tempfile.TemporaryDirectory(prefix="starwind-split-") as directory:
        output = Path(directory) / "plugin.json"
        subprocess.run(
            [str(CONVERTER), "-o", str(path), str(output)],
            cwd=ROOT,
            check=True,
        )
        return json.loads(output.read_text(encoding="utf-8"))


def write_plugin(records: list[dict], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="starwind-split-") as directory:
        source = Path(directory) / "plugin.json"
        source.write_text(json.dumps(records, indent=2) + "\n", encoding="utf-8")
        subprocess.run(
            [str(CONVERTER), "-o", str(source), str(path)],
            cwd=ROOT,
            check=True,
        )


def record_key(record: dict) -> tuple[str, str]:
    return str(record.get("type", "")), editor_id(record).casefold()


def record_signature(record: dict) -> str:
    return json.dumps(record, sort_keys=True, separators=(",", ":"))


def unique_records(records: list[dict]) -> dict[tuple[str, str], dict]:
    result = {}
    for record in records:
        key = record_key(record)
        if key[1]:
            result[key] = record
    return result


def namespace_index(keys: set[tuple[str, str]]) -> dict[str, set[str]]:
    result: dict[str, set[str]] = collections.defaultdict(set)
    for record_type, record_id in keys:
        result[record_id].add(record_type)
    return result


def choose_data_records(records: list[dict]) -> tuple[set[int], list[dict]]:
    indexed = {index: record for index, record in enumerate(records)}
    candidate_indices = {
        index
        for index, record in indexed.items()
        if (
            record.get("type") in DATA_TYPES
            or (
                record.get("type") == "Script"
                and editor_id(record).casefold() in APPROVED_DATA_SCRIPT_IDS
            )
        ) and editor_id(record)
    }
    demotions: list[dict] = []

    # A fixed point is necessary because a candidate may depend on another
    # candidate that is itself demoted by a script, actor, or world reference.
    while True:
        all_keys = {
            record_key(record)
            for index, record in indexed.items()
            if index != 0 and editor_id(record)
        }
        all_keys_by_id = namespace_index(all_keys)
        content_keys = {
            record_key(record)
            for index, record in indexed.items()
            if index not in candidate_indices and index != 0 and editor_id(record)
        }
        to_demote: list[tuple[int, dict, dict]] = []
        for index in sorted(candidate_indices):
            record = indexed[index]
            for dependency in dependencies(record, index):
                if dependency_target_keys(dependency, all_keys_by_id) & content_keys:
                    to_demote.append((index, record, dependency))
                    break
        if not to_demote:
            return candidate_indices, demotions
        for index, record, dependency in to_demote:
            candidate_indices.remove(index)
            demotions.append({
                "type": record.get("type", ""),
                "id": editor_id(record),
                "dependency": dependency,
                "reason": "dependency resolves to Starwind content",
            })


def set_header(
    records: list[dict], *, masters: list[list[object]], file_type: str
) -> list[dict]:
    result = [dict(record) for record in records]
    header = dict(result[0])
    header["num_objects"] = len(result) - 1
    header["masters"] = masters
    header["file_type"] = file_type
    result[0] = header
    return result


def validate_partition(
    source: list[dict], data: list[dict], content: list[dict]
) -> dict:
    source_records = source[1:]
    data_records = data[1:]
    content_records = content[1:]
    source_counter = collections.Counter(record_signature(record) for record in source_records)
    split_counter = collections.Counter(
        record_signature(record) for record in data_records + content_records
    )

    data_keys = set(unique_records(data_records))
    content_keys = set(unique_records(content_records))
    all_keys = data_keys | content_keys
    all_keys_by_id = namespace_index(all_keys)
    if data_keys & content_keys:
        raise RuntimeError("split produced duplicate type/ID records")
    source_effective = unique_records(source_records)
    pair_effective = unique_records(data_records + content_records)
    effective_record_mismatches = []
    for key in sorted(source_effective.keys() | pair_effective.keys()):
        expected = source_effective.get(key)
        actual = pair_effective.get(key)
        if expected is None or actual is None or record_signature(expected) != record_signature(actual):
            effective_record_mismatches.append({
                "type": key[0],
                "id": key[1],
                "source_present": expected is not None,
                "pair_present": actual is not None,
            })
    data_to_content_dependencies = []
    content_to_data_dependencies = []
    for index, record in enumerate(data_records, 1):
        for dependency in dependencies(record, index):
            target_keys = dependency_target_keys(dependency, all_keys_by_id)
            if target_keys & content_keys and not target_keys & data_keys:
                data_to_content_dependencies.append(dependency)
    for index, record in enumerate(content_records, 1):
        for dependency in dependencies(record, index):
            target_keys = dependency_target_keys(dependency, all_keys_by_id)
            if target_keys & data_keys and not target_keys & content_keys:
                content_to_data_dependencies.append(dependency)

    source_keys = set(unique_records(source_records))
    source_unresolved = unresolved_dependencies(
        source_records, namespace_index(source_keys)
    )
    pair_unresolved = unresolved_dependencies(
        data_records + content_records, all_keys_by_id
    )
    source_unresolved_ids = {
        dependency_identity(dependency) for dependency in source_unresolved
    }
    new_unresolved_dependencies = [
        dependency for dependency in pair_unresolved
        if dependency_identity(dependency) not in source_unresolved_ids
    ]

    report = {
        "source_records": len(source_records),
        "data_records": len(data_records),
        "content_records": len(content_records),
        "reconstruction_exact": source_counter == split_counter,
        "effective_record_mismatch_count": len(effective_record_mismatches),
        "effective_record_mismatches": effective_record_mismatches,
        "data_to_content_dependency_count": len(data_to_content_dependencies),
        "data_to_content_dependencies": data_to_content_dependencies,
        "content_to_data_dependency_count": len(content_to_data_dependencies),
        "content_to_data_dependencies": content_to_data_dependencies,
        "source_unresolved_dependency_count": len(source_unresolved),
        "unresolved_dependency_count": len(pair_unresolved),
        "unresolved_dependencies": pair_unresolved,
        "new_unresolved_dependency_count": len(new_unresolved_dependencies),
        "new_unresolved_dependencies": new_unresolved_dependencies,
        "data_header_masters": data[0].get("masters", []),
        "content_header_masters": content[0].get("masters", []),
        "data_header_file_type": data[0].get("file_type"),
        "content_header_file_type": content[0].get("file_type"),
        "forbidden_content_types_in_data": sorted({
            record.get("type", "")
            for record in data_records
            if (
                record.get("type") in {
                    "Cell", "PathGrid", "Dialogue", "DialogueInfo", "Npc",
                    "StartScript", "GlobalVariable", "Region", "Book",
                }
                or (
                    record.get("type") == "Script"
                    and editor_id(record).casefold() not in APPROVED_DATA_SCRIPT_IDS
                )
            )
        }),
    }
    if not report["reconstruction_exact"]:
        raise RuntimeError("Star_Data + Starwind does not reconstruct the source records")
    if report["data_to_content_dependency_count"]:
        raise RuntimeError("Star_Data contains a dependency on Starwind content")
    if report["new_unresolved_dependency_count"]:
        raise RuntimeError("Star_Data + Starwind introduces unresolved dependencies")
    if report["effective_record_mismatch_count"]:
        raise RuntimeError("Star_Data + Starwind changes effective records")
    if report["forbidden_content_types_in_data"]:
        raise RuntimeError("content record family leaked into Star_Data")
    return report


def split(source_path: Path, data_path: Path, content_path: Path, report_path: Path) -> dict:
    source = load_plugin(source_path)
    if not source or source[0].get("type") != "Header":
        raise RuntimeError(f"{source_path} does not begin with a TES3 Header")

    data_indices, demotions = choose_data_records(source)
    data_records = [record for index, record in enumerate(source) if index in data_indices]
    content_records = [
        record
        for index, record in enumerate(source)
        if index not in data_indices and index != 0
    ]

    data_records.insert(0, dict(source[0]))
    data_records = set_header(data_records, masters=[], file_type="Esm")
    write_plugin(data_records, data_path)

    data_size = data_path.stat().st_size
    content_records.insert(0, dict(source[0]))
    content_records = set_header(
        content_records,
        masters=[[data_path.name, data_size]],
        file_type="Esp",
    )
    write_plugin(content_records, content_path)

    # Validate what tes3conv actually serialized, not only the in-memory split.
    data_records = load_plugin(data_path)
    content_records = load_plugin(content_path)
    report = validate_partition(source, data_records, content_records)
    report.update({
        "source": str(source_path),
        "data_output": str(data_path),
        "content_output": str(content_path),
        "always_data_types": sorted(ALWAYS_DATA_TYPES),
        "candidate_data_types": sorted(CANDIDATE_DATA_TYPES),
        "approved_data_script_ids": sorted(APPROVED_DATA_SCRIPT_IDS),
        "data_types": sorted({record.get("type", "") for record in data_records[1:]}),
        "data_type_counts": dict(collections.Counter(
            record.get("type", "") for record in data_records[1:]
        )),
        "content_type_counts": dict(collections.Counter(
            record.get("type", "") for record in content_records[1:]
        )),
        "demoted_candidates": demotions,
    })
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return report


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--data-output", type=Path, default=DEFAULT_DATA)
    parser.add_argument("--content-output", type=Path, default=DEFAULT_CONTENT)
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    args = parser.parse_args()
    report = split(args.source, args.data_output, args.content_output, args.report)
    print(json.dumps({
        "data_records": report["data_records"],
        "content_records": report["content_records"],
        "data_types": report["data_types"],
        "demoted_candidates": len(report["demoted_candidates"]),
        "reconstruction_exact": report["reconstruction_exact"],
        "data_to_content_dependency_count": report["data_to_content_dependency_count"],
        "content_to_data_dependency_count": report["content_to_data_dependency_count"],
        "unresolved_dependency_count": report["unresolved_dependency_count"],
        "new_unresolved_dependency_count": report["new_unresolved_dependency_count"],
        "report": str(args.report),
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
